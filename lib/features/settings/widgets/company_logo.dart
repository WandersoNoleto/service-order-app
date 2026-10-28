import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/storage/logo_storage.dart';

/// Shows the logo picked in the app, or the flavor's bundled logo when
/// there is none (or its file went missing) — the same rule as the PDF.
class CompanyLogo extends StatefulWidget {
  const CompanyLogo({
    super.key,
    required this.logos,
    required this.customLogoFile,
    required this.fallbackAsset,
    this.height = 80,
  });

  final LogoStorage logos;
  final String? customLogoFile;
  final String fallbackAsset;
  final double height;

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
    return SizedBox(
      height: widget.height,
      child: FutureBuilder<File?>(
        future: _file,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }

          final file = snapshot.data;
          if (file != null) {
            return Image.file(
              file,
              alignment: Alignment.centerLeft,
              errorBuilder: (_, _, _) => _bundled(),
            );
          }
          return _bundled();
        },
      ),
    );
  }

  Widget _bundled() {
    if (widget.fallbackAsset.isEmpty) return const _LogoMissing();
    return Image.asset(
      widget.fallbackAsset,
      alignment: Alignment.centerLeft,
      errorBuilder: (_, _, _) => const _LogoMissing(),
    );
  }
}

class _LogoMissing extends StatelessWidget {
  const _LogoMissing();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;

    return Row(
      children: [
        Icon(Icons.image_not_supported_outlined, color: color),
        const SizedBox(width: 8),
        Text('Logo não encontrada', style: TextStyle(color: color)),
      ],
    );
  }
}
