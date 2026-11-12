package com.wandersonnoleto.service_order_app

import android.annotation.TargetApi
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Saves PDFs in Documents/<app name>, a folder the user sees in the Files
 * app and that stays when the app is uninstalled.
 *
 * Uses MediaStore, which needs no permission, so it only works on
 * Android 10 (API 29) and newer.
 */
class PdfFolderChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {

    companion object {
        const val NAME = "service_order_app/pdf_folder"
    }

    private val resolver get() = activity.contentResolver

    /** "Documents/Ordens de Serviço" (no slashes from the app name). */
    private val relativePath: String
        get() {
            val label = activity.applicationInfo.loadLabel(activity.packageManager)
                .toString()
                .replace('/', '-')
            return "${Environment.DIRECTORY_DOCUMENTS}/$label"
        }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "isSupported" -> result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
                "folder" -> result.success(relativePath)
                "save" -> {
                    check(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) { "Android 10+ only" }
                    result.success(
                        save(
                            call.argument<String>("name")!!,
                            call.argument<ByteArray>("bytes")!!,
                            call.argument<String>("replacing"),
                        ),
                    )
                }
                "delete" -> {
                    delete(call.argument<String>("uri")!!)
                    result.success(null)
                }
                "open" -> result.success(open())
                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            result.error("pdf_folder", error.message, null)
        }
    }

    /** Overwrites [replacing] when it still exists, otherwise creates a new file. */
    @TargetApi(Build.VERSION_CODES.Q)
    private fun save(name: String, bytes: ByteArray, replacing: String?): String {
        if (replacing != null) {
            val uri = Uri.parse(replacing)
            try {
                resolver.openOutputStream(uri, "wt")!!.use { it.write(bytes) }
                rename(uri, name)
                return replacing
            } catch (ignored: Exception) {
                // Deleted by the user, or not ours anymore (app reinstalled).
            }
        }

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val collection = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val uri = resolver.insert(collection, values)
            ?: throw IllegalStateException("MediaStore refused $name")
        try {
            resolver.openOutputStream(uri, "w")!!.use { it.write(bytes) }
        } catch (error: Exception) {
            resolver.delete(uri, null, null)
            throw error
        }
        values.clear()
        values.put(MediaStore.MediaColumns.IS_PENDING, 0)
        resolver.update(uri, values, null, null)
        return uri.toString()
    }

    /** The name changes when the customer or number is edited. */
    private fun rename(uri: Uri, name: String) {
        try {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            }
            resolver.update(uri, values, null, null)
        } catch (ignored: Exception) {
            // Keeps the old name; the content is already up to date.
        }
    }

    private fun delete(uri: String) {
        try {
            resolver.delete(Uri.parse(uri), null, null)
        } catch (ignored: Exception) {
            // Already gone, or not ours anymore.
        }
    }

    /** Opens the folder in the system Files app. False when no app can. */
    private fun open(): Boolean {
        val folder = DocumentsContract.buildDocumentUri(
            "com.android.externalstorage.documents",
            "primary:$relativePath",
        )
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(folder, DocumentsContract.Document.MIME_TYPE_DIR)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        return try {
            activity.startActivity(intent)
            true
        } catch (ignored: ActivityNotFoundException) {
            false
        }
    }
}
