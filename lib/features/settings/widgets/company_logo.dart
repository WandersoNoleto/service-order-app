import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/storage/logo_storage.dart';

/// Shows the logo picked in the app, or the flavor's bundled logo when
/// there is none (or its file went missing) — the same rule as the PDF.
///
/// Without any logo it takes no space at all, unless [emptyLabel] is set
/// (used by the edit form so the user knows a logo can be added).
class CompanyLogo extends StatefulWidget {
  const CompanyLogo({
    super.key,
    required this.logos,
    required this.customLogoFile,
    required this.fallbackAsset,
    this.height = 80,
    this.alignment = Alignment.centerLeft,
    this.padding = EdgeInsets.zero,
    this.emptyLabel,
  });

  final LogoStorage logos;
  final String? customLogoFile;
  final String fallbackAsset;
  final double height;
  final Alignment alignment;

  /// Space around the logo, applied only when there is a logo to show.
  final EdgeInsets padding;
  final String? emptyLabel;

  @override
  State<CompanyLogo> createState() => _CompanyLogoState();
}

class _CompanyLogoState extends State<CompanyLogo> {
  late Future<File?> _file = widget.logos.resolve(widget.customLogoFile);

  @override
  void didUpdateWidget(CompanyLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customLogoFile != widget.customLogoFile) {
      _file = widget.logos.resolve(widget.customLogoFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _file,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }

        final file = snapshot.data;
        if (file != null) {
          return _framed(
            Image.file(
              file,
              alignment: widget.alignment,
              errorBuilder: (_, _, _) => _bundledOrEmpty(),
            ),
          );
        }
        if (widget.fallbackAsset.isNotEmpty) {
          return _framed(
            Image.asset(
              widget.fallbackAsset,
              alignment: widget.alignment,
              errorBuilder: (_, _, _) => _empty(),
            ),
          );
        }
        return _empty();
      },
    );
  }

  Widget _framed(Widget image) => Padding(
        padding: widget.padding,
        child: SizedBox(height: widget.height, child: image),
      );

  /// A picked logo that can't be read falls back to the bundled one.
  Widget _bundledOrEmpty() {
    if (widget.fallbackAsset.isEmpty) return _empty();
    return Image.asset(
      widget.fallbackAsset,
      alignment: widget.alignment,
      errorBuilder: (_, _, _) => _empty(),
    );
  }

  Widget _empty() {
    final label = widget.emptyLabel;
    if (label == null) return const SizedBox.shrink();

    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Align(
      alignment: widget.alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
