// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Service Orders';

  @override
  String get navHistory => 'Orders';

  @override
  String get navSettings => 'Settings';

  @override
  String get navCreate => 'New order';

  @override
  String get navCreateSemantic => 'Create service order';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get saving => 'Saving…';

  @override
  String get edit => 'Edit';

  @override
  String get automatic => 'Automatic';

  @override
  String get draftNotSaved => 'Draft not saved';

  @override
  String get orderTotal => 'Total';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String get delete => 'Delete';

  @override
  String get discard => 'Discard';

  @override
  String get restore => 'Restore';

  @override
  String get clear => 'Clear';

  @override
  String get tryAgain => 'Try again';

  @override
  String couldNotComplete(String error) {
    return 'Couldn\'t complete: $error';
  }

  @override
  String get historySearchHint => 'Customer, number or service';

  @override
  String get historyTitle => 'Service orders';

  @override
  String get filterAll => 'All';

  @override
  String get filterLast7Days => '7 days';

  @override
  String get filterThisMonth => 'This month';

  @override
  String ordersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count orders',
      one: '1 order',
      zero: 'No orders',
    );
    return '$_temp0';
  }

  @override
  String orderNumberShort(String number) {
    return 'No. $number';
  }

  @override
  String get historyNoResults => 'No service orders found';

  @override
  String get historyEmptyTitle => 'No service orders yet';

  @override
  String get historyEmptyBody =>
      'Tap \"New order\" to issue your first service order.';

  @override
  String get orderNoNumber => 'No number';

  @override
  String get customerNotInformed => 'No customer';

  @override
  String get newOrderTitle => 'New order';

  @override
  String get editOrderTitle => 'Edit order';

  @override
  String get saveOrder => 'Review and create PDF';

  @override
  String get sectionOrder => 'Service order';

  @override
  String get orderNumberField => 'Service order number';

  @override
  String get sectionCustomer => 'Customer';

  @override
  String get customer => 'Customer';

  @override
  String get customerDocument => 'Tax ID';

  @override
  String get address => 'Address';

  @override
  String get city => 'City';

  @override
  String get state => 'State';

  @override
  String get contact => 'Contact';

  @override
  String get zip => 'ZIP code';

  @override
  String get sectionServiceCall => 'Service call';

  @override
  String get invoice => 'Invoice';

  @override
  String get warranty => 'Warranty';

  @override
  String get calledAt => 'Called on';

  @override
  String get scheduledFor => 'Scheduled for';

  @override
  String get scheduledTime => 'Time';

  @override
  String get installedAt => 'Installed on';

  @override
  String get sectionServicesPerformed => 'Services performed';

  @override
  String get description => 'Description';

  @override
  String get partsAndMaterials => 'Parts and materials';

  @override
  String get decreaseQuantity => 'Decrease quantity';

  @override
  String get increaseQuantity => 'Increase quantity';

  @override
  String totalsBreakdown(String parts, String labor) {
    return 'Parts $parts · Labor $labor';
  }

  @override
  String get addPart => 'Add part';

  @override
  String get removePart => 'Remove part';

  @override
  String get partName => 'Part name';

  @override
  String get quantityShort => 'Qty';

  @override
  String get code => 'Code';

  @override
  String unitPriceField(String symbol) {
    return 'Unit price ($symbol)';
  }

  @override
  String laborField(String symbol) {
    return 'Labor ($symbol)';
  }

  @override
  String get total => 'TOTAL';

  @override
  String get notes => 'Notes';

  @override
  String get equipmentOkQuestion =>
      'Was the equipment repaired, checked and left in perfect working order?';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get duplicateNumberTitle => 'Number already used';

  @override
  String duplicateNumberMessage(String number) {
    return 'Service order $number already exists. Save anyway?';
  }

  @override
  String duplicateNumberMessageWithCustomer(String number, String customer) {
    return 'Service order $number already exists, for $customer. Save anyway?';
  }

  @override
  String get saveAnyway => 'Save anyway';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardOrderMessage => 'What you filled in hasn\'t been saved.';

  @override
  String get discardCompanyMessage => 'Your changes haven\'t been saved.';

  @override
  String get orderTitle => 'Service order';

  @override
  String orderTitleWithNumber(String number) {
    return 'Service order $number';
  }

  @override
  String get sendPdf => 'Send PDF';

  @override
  String get image => 'Image';

  @override
  String get print => 'Print';

  @override
  String documentError(String error) {
    return 'Couldn\'t generate the document:\n$error';
  }

  @override
  String get deleteOrderTitle => 'Delete this service order?';

  @override
  String get deleteOrderMessage =>
      'It will be removed from the history. This can\'t be undone.';

  @override
  String get companyCardFooter => 'This data appears on the PDF header';

  @override
  String get viewTemplate => 'View template';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsApp => 'App';

  @override
  String get backup => 'Backup';

  @override
  String get backupNever => 'Last: never';

  @override
  String backupLast(String date) {
    return 'Last: $date';
  }

  @override
  String get backupIntro =>
      'The backup doesn\'t hold the PDFs. It\'s a copy of the app\'s data (orders, settings and logo) in a .zip file, to bring the app back to how it is now if needed. The PDFs are generated again from that data. Keep the file outside the app.';

  @override
  String get backupShare => 'Send (Drive, WhatsApp, e-mail)';

  @override
  String get backupShareHint =>
      'Recommended: stays safe even if the phone is lost';

  @override
  String get backupSave => 'Save on this phone';

  @override
  String get backupSaveHint => 'Pick a folder, such as Downloads';

  @override
  String get backupDone => 'Backup done.';

  @override
  String backupError(String error) {
    return 'Couldn\'t create the backup:\n$error';
  }

  @override
  String get backupRestore => 'Restore a backup';

  @override
  String get backupRestoreHint => 'Replaces the current data';

  @override
  String get restoreTitle => 'Restore this backup?';

  @override
  String restoreMessage(String date) {
    return 'Backup from $date. The current orders, settings and logo will be replaced.';
  }

  @override
  String get restoreConfirm => 'Restore';

  @override
  String get restoreDone => 'Backup restored.';

  @override
  String get restoreUndone => 'The previous data is back.';

  @override
  String get undo => 'Undo';

  @override
  String get restoreNotABackup => 'This file is not a backup from this app.';

  @override
  String get restoreNewerVersion =>
      'This backup was made by a newer version of the app. Update the app and try again.';

  @override
  String restoreError(String error) {
    return 'Couldn\'t restore the backup:\n$error';
  }

  @override
  String get recommended => 'Recommended';

  @override
  String get pdfFolder => 'PDF folder';

  @override
  String pdfFolderIntro(String folder) {
    return 'Each saved order gets a PDF in the phone\'s $folder folder. The files stay there even if the app is uninstalled.';
  }

  @override
  String get pdfFolderUnsupported => 'Available on Android 10 or newer';

  @override
  String get pdfFolderOpen => 'Open folder';

  @override
  String pdfFolderOpenFailed(String folder) {
    return 'Open the Files app and look for the $folder folder.';
  }

  @override
  String get pdfFolderSaveAll => 'Save all PDFs again';

  @override
  String get pdfFolderSaveAllHint => 'Useful after restoring a backup';

  @override
  String pdfFolderSaving(String done, String total) {
    return 'Saving PDFs… $done of $total';
  }

  @override
  String pdfFolderSavedAll(String count) {
    return 'PDFs saved in the folder: $count';
  }

  @override
  String pdfFolderSaveError(String error) {
    return 'The PDF wasn\'t saved in the folder:\n$error';
  }

  @override
  String get updates => 'Updates';

  @override
  String get checkNow => 'Check';

  @override
  String get comingSoon => 'This feature is in development. Coming soon!';

  @override
  String get notConfigured =>
      'App started without a client configuration. Run with --dart-define-from-file=clients/<folder>/config.json.';

  @override
  String get version => 'Version';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get upToDate => 'You\'re on the latest version.';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Automatic (phone)';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageEnglish => 'English';

  @override
  String get region => 'Regional format';

  @override
  String get regionSystem => 'Automatic (phone)';

  @override
  String get regionBrazil => 'Brazil';

  @override
  String get regionUnitedStates => 'United States';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'Automatic (phone)';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get sampleCompanyName => 'Example Company';

  @override
  String get sampleCompanyDocument => '00-0000000';

  @override
  String get sampleCompanyPhone => '(000) 000-0000';

  @override
  String get sampleCompanyAddress => '100 Example Street';

  @override
  String get sampleCompanyCity => 'Example City';

  @override
  String get sampleCompanyState => 'ST';

  @override
  String get sampleResponsible => 'John Doe';

  @override
  String get companyFormTitle => 'Company details';

  @override
  String get restoreAllDefaults => 'Restore all defaults';

  @override
  String get restoreAllTitle => 'Restore everything?';

  @override
  String get restoreAllMessage =>
      'All data and the logo go back to the app\'s defaults.';

  @override
  String get companyNameField => 'Company name';

  @override
  String get companyNameRequired => 'Enter the company name';

  @override
  String get companyDocumentField => 'Tax ID';

  @override
  String get phoneWhatsapp => 'Phone / WhatsApp';

  @override
  String get stateShort => 'State';

  @override
  String get responsible => 'Responsible';

  @override
  String defaultValue(String value) {
    return 'Default: $value';
  }

  @override
  String get restoreDefault => 'Restore default';

  @override
  String get logo => 'Logo';

  @override
  String get noLogo => 'No logo yet';

  @override
  String get changeLogo => 'Change logo';

  @override
  String get removeLogo => 'Remove logo';

  @override
  String get useDefaultLogo => 'Use default logo';

  @override
  String couldNotLoadImage(String error) {
    return 'Couldn\'t load the image: $error';
  }

  @override
  String get newVersionTitle => 'New version available';

  @override
  String newVersionMessage(String version) {
    return 'Version v$version of the app is available.\n\nTap \"Update\" to install the latest improvements.';
  }

  @override
  String get later => 'Later';

  @override
  String get update => 'Update';

  @override
  String get releaseNotes => 'Release notes';

  @override
  String get downloadingUpdate => 'Downloading update';

  @override
  String get starting => 'Starting…';

  @override
  String get updateOffline => 'Can\'t reach the update server.';

  @override
  String updateServerError(int code) {
    return 'The update server answered $code.';
  }

  @override
  String get installPermission =>
      'Allow this app to install updates: Android Settings > Apps > this app > Install unknown apps. Then try again.';

  @override
  String get installDownloadFailed =>
      'Couldn\'t download the update. Check the internet connection and try again.';

  @override
  String get installCanceled => 'Update canceled.';

  @override
  String get installAlreadyRunning => 'An update is already in progress.';

  @override
  String installError(String detail) {
    return 'Couldn\'t install the update ($detail).';
  }

  @override
  String pdfDocumentTitle(String number) {
    return 'Service Order $number';
  }

  @override
  String get pdfFilePrefix => 'SO';

  @override
  String get pdfCompanyDocument => 'Tax ID';

  @override
  String get pdfResponsible => 'Responsible';

  @override
  String pdfContinuation(String company) {
    return '$company · continued';
  }

  @override
  String pdfContinuationWithNumber(String company, String number) {
    return '$company · SO $number · continued';
  }

  @override
  String pdfPage(int page, int total) {
    return 'Page $page/$total';
  }

  @override
  String get pdfTechnicalAssistance => 'TECHNICAL SERVICE';

  @override
  String get pdfOrderNumber => 'SERVICE ORDER No.:';

  @override
  String get pdfServicesPerformed => 'Services Performed';

  @override
  String get pdfPartName => 'PART NAME';

  @override
  String get pdfUnitPrice => 'Unit Price';

  @override
  String get pdfLineTotal => 'Total';

  @override
  String get pdfPartsTotal => 'PARTS';

  @override
  String get pdfLabor => 'LABOR';

  @override
  String get pdfSignatureApproval => 'APPROVED';

  @override
  String get pdfSignatureDate => 'DATE';

  @override
  String get pdfSignatureTechnician => 'TECHNICIAN';

  @override
  String get pdfSignatureCustomer => 'CUSTOMER';

  @override
  String get pdfEquipmentOk =>
      'The equipment was repaired, checked and left in perfect working order';
}
