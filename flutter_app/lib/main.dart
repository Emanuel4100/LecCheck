import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/leccheck_root.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'core/auth/linux_auth_bridge.dart';
import 'core/firebase/leccheck_firebase.dart';
import 'core/notifications/meeting_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initMeetingNotifications();
  if (firebaseSupportedOnThisPlatform) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (kDebugMode) {
        debugPrint('Firebase initialized (${Firebase.apps.length} app(s)).');
      }
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase init failed (continuing without): $e');
      }
    }
  } else {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux) {
      await restoreLinuxAuthSession();
      if (kDebugMode) {
        debugPrint(
          'Linux REST auth restored: signed_in=$isLinuxAuthSignedIn',
        );
      }
    } else if (kDebugMode) {
      debugPrint(
        'Firebase skipped: not configured for ${defaultTargetPlatform.name}.',
      );
    }
  }
  runApp(const LecCheckApp());
}

class LecCheckApp extends StatefulWidget {
  const LecCheckApp({super.key});

  @override
  State<LecCheckApp> createState() => _LecCheckAppState();
}

class _LecCheckAppState extends State<LecCheckApp> {
  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.system;

  static ThemeData _themeFor(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2A7BCC),
        brightness: brightness,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static const _kAppLocale = 'app_locale';

  @override
  void initState() {
    super.initState();
    unawaited(_loadUiPreferences());
  }

  Future<void> _loadUiPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final themeKey = prefs.getString('theme_mode');
    final nextTheme = switch (themeKey) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final lang = prefs.getString(_kAppLocale);
    final nextLocale =
        (lang == 'he' || lang == 'en') ? Locale(lang!) : _locale;
    if (nextTheme != _themeMode || nextLocale != _locale) {
      setState(() {
        _themeMode = nextTheme;
        _locale = nextLocale;
      });
    }
  }

  Future<void> _persistAppLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAppLocale, languageCode);
  }

  void _setLanguage(String languageCode) {
    final next = Locale(languageCode);
    if (next == _locale) return;
    setState(() {
      _locale = next;
    });
    unawaited(_persistAppLocale(languageCode));
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'theme_mode',
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LecCheck',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      themeMode: _themeMode,
      theme: _themeFor(Brightness.light),
      darkTheme: _themeFor(Brightness.dark),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('he')],
      home: LecCheckRoot(
        key: const ValueKey<String>('leccheck_root'),
        onLanguageChanged: _setLanguage,
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}
