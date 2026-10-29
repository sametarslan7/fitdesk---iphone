import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/auth/auth_service.dart';
import 'core/data/activity.dart';
import 'core/data/activity_cloud.dart';
import 'core/data/favorites.dart';
import 'core/data/settings.dart';
import 'core/notifications/break_reminders.dart';
import 'core/notifications/notification_service.dart';
import 'core/storage/app_prefs.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.initialize();
  runApp(const FitDeskApp());
}

class FitDeskApp extends StatefulWidget {
  const FitDeskApp({super.key});

  @override
  State<FitDeskApp> createState() => _FitDeskAppState();
}

class _FitDeskAppState extends State<FitDeskApp> {
  final _favorites = FavoritesController()..load();
  final _settings = SettingsController();
  final _activity = ActivityController();
  final _user = ValueNotifier<AppUser?>(null);
  late final BreakReminders _reminders;
  late final StreamSubscription<AppUser?> _userSubscription;

  /// Egzersiz kaydının bağlı olduğu hesap.
  String? _connectedUid;

  @override
  void initState() {
    super.initState();
    _reminders = BreakReminders(_settings, _activity);
    _onUser(AuthService.instance.currentUser);
    _userSubscription = AuthService.instance.userChanges.listen(_onUser);
    // Kayıt yoksa load dinleyenleri uyarmaz; bildirimler yine varsayılanlarla
    // kurulsun.
    _settings.load().then((_) => _reminders.sync());
  }

  void _onUser(AppUser? user) {
    _user.value = user;
    _reminders.signedIn = user != null;
    if (user?.uid == _connectedUid) return;
    _connectedUid = user?.uid;
    if (user == null) {
      _activity.disconnect();
      // Sonra giren hesap eski hesabın sayacıyla başlamasın.
      AppPrefs.clearBreakSession();
    } else {
      _activity.connect(ActivityCloud.forUser(user.uid));
    }
  }

  @override
  void dispose() {
    _userSubscription.cancel();
    _reminders.dispose();
    _favorites.dispose();
    _settings.dispose();
    _activity.dispose();
    _user.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitDesk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Saat seçici, ipuçları vb. hazır metinler Türkçe olsun.
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => AuthScope(
        user: _user,
        child: SettingsScope(
          controller: _settings,
          child: BreakRemindersScope(
            reminders: _reminders,
            child: FavoritesScope(
              controller: _favorites,
              child: ActivityScope(controller: _activity, child: child!),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
