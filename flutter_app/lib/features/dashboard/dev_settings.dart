import 'dart:collection';

import 'package:flutter/foundation.dart'
    show TargetPlatform, ValueListenable, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/leccheck_firebase.dart';
import '../../core/notifications/meeting_notifications.dart';
import '../../core/schedule/schedule_persistence.dart';
import '../../l10n/app_localizations.dart';

const _kDevModeKey = 'dev_mode_enabled';

Future<bool> isDevModeEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kDevModeKey) ?? false;
}

Future<void> setDevModeEnabled(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kDevModeKey, value);
}

/// Ring buffer capturing debugPrint output for the in-app log viewer.
class AppLogBuffer {
  AppLogBuffer._();
  static final instance = AppLogBuffer._();

  static const int maxLines = 500;
  final _lines = ListQueue<String>();

  UnmodifiableListView<String> get lines => UnmodifiableListView(_lines);

  void add(String line) {
    _lines.addLast(line);
    while (_lines.length > maxLines) {
      _lines.removeFirst();
    }
  }

  void install() {
    final original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) add(message);
      original(message, wrapWidth: wrapWidth);
    };
  }
}

class DevSettingsSection extends StatelessWidget {
  const DevSettingsSection({
    super.key,
    required this.l10n,
    required this.syncStatus,
    required this.onClearCache,
    required this.onRebootstrap,
    required this.onDevModeDisabled,
  });

  final AppLocalizations l10n;
  final ValueListenable<SyncStatus> syncStatus;
  final VoidCallback onClearCache;
  final VoidCallback onRebootstrap;
  final VoidCallback onDevModeDisabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          if (meetingNotificationsSupportedOnPlatform ||
              (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux))
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(l10n.devForceNotification),
              onTap: () async {
                final ok = await scheduleTestNotification();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? l10n.devForceNotificationSent
                          : l10n.notificationPermissionDenied,
                    ),
                  ),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: Text(l10n.devShowLogs),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLogViewer(context),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: Text(l10n.devSyncDetails),
            onTap: () => _showSyncDetails(context),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error),
            title: Text(l10n.devClearCache),
            onTap: () => _confirmClearCache(context),
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: Text(l10n.devRebootstrap),
            onTap: onRebootstrap,
          ),
          ListTile(
            leading: const Icon(Icons.developer_mode),
            title: Text(l10n.devDisableDevMode),
            onTap: () async {
              await setDevModeEnabled(false);
              onDevModeDisabled();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.devModeDisabled)),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showLogViewer(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.devShowLogs),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            reverse: true,
            child: SelectableText(
              AppLogBuffer.instance.lines.join('\n'),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showSyncDetails(BuildContext context) {
    final uid = currentAuthUid;
    final status = syncStatus.value;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.devSyncDetails),
        content: SelectableText(
          'UID: ${uid ?? "not signed in"}\n'
          'Cloud available: $isCloudAvailable\n'
          'Sync status: ${status.name}\n'
          'Platform: ${defaultTargetPlatform.name}\n'
          'Firebase initialized: $isFirebaseInitialized',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearCache(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.devClearCache),
        content: Text(l10n.devClearCacheConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.devClearCache),
          ),
        ],
      ),
    );
    if (ok == true) {
      onClearCache();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.devClearCacheDone)),
        );
      }
    }
  }
}
