import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';
import 'glass.dart';
import 'sheet.dart';

/// Bottom sheet with the product's deep link and a copy button.
Future<void> showShareSheet(BuildContext context, Product product) {
  return showGlassSheet<void>(
    context,
    title: 'Share product',
    builder: (sheetContext) => _ShareBody(product: product),
  );
}

class _ShareBody extends StatelessWidget {
  const _ShareBody({required this.product});

  final Product product;

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await Clipboard.setData(ClipboardData(text: product.deepLink));
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            'Link copied to clipboard',
            style: TextStyle(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ink,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          product.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 14),
        Glass(
          radius: 18,
          opacity: 0.16,
          padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
          child: Row(
            children: [
              const Icon(Icons.link_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: SelectableText(
                  product.deepLink,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Copy link',
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Copy link',
          icon: Icons.copy_rounded,
          onTap: () => _copy(context),
        ),
      ],
    );
  }
}
