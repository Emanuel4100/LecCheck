import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

Future<void> tryLaunchLectureUrl(BuildContext context, String raw) async {
  var url = raw.trim();
  if (url.isEmpty) return;
  if (!url.contains('://')) {
    url = 'https://$url';
  }
  final uri = Uri.tryParse(url);
  final l10n = AppLocalizations.of(context)!;
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.openLinkFailed)),
      );
    }
    return;
  }
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.openLinkFailed)),
    );
  }
}
