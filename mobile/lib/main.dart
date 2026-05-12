import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/theme.dart';
import 'features/navigation/router.dart';
import 'core/network/connectivity_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/notification_service.dart';
import 'core/ux/ux_provider.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/attendance/offline_storage_service.dart';
import 'features/attendance/sync_service.dart';

import 'features/auth/auth_provider.dart';
import 'features/auth/auth_state.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (only if config exists, otherwise it might throw in some environments)
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final prefs = await SharedPreferences.getInstance();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: AppColors.primary,
    statusBarIconBrightness: Brightness.light, // White icons for dark background
    statusBarBrightness: Brightness.dark, // For iOS
  ));

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const FacialeApp(),
      ),
    ),
  );
}

class FacialeApp extends ConsumerWidget {
  const FacialeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize SyncService
    ref.watch(syncServiceProvider);
    
    final router = ref.watch(routerProvider);
    final connectivity = ref.watch(connectivityProvider);
    final ux = ref.watch(uxProvider);

    // Listen for UX messages to show snackbars
    ref.listen<UXMessage?>(uxProvider.select((s) => s.message), (previous, next) {
      if (next != null && next != previous) {
        final context = rootNavigatorKey.currentContext;
        if (context != null) {
          final color = next.type == UXMessageType.error
              ? Colors.red
              : (next.type == UXMessageType.success ? Colors.green : AppColors.primary);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.args != null ? next.text.tr(args: next.args) : next.text.tr()),
              backgroundColor: color,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          ref.read(uxProvider.notifier).clearMessage();
        }
      }
    });

    // Initialize notification service when token is available
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.token != null && previous?.token == null) {
        ref.read(notificationServiceProvider).initialize();
      }
    });

    return MaterialApp.router(
      title: 'I-POINTEO',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      localizationsDelegates: _safeLocalizationDelegates(context),
      supportedLocales: _safeSupportedLocales(context),
      locale: _safeLocale(context),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            connectivity.when(
              data: (status) => status == ConnectivityStatus.isDisconnected
                  ? Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Material(
                        child: Container(
                          color: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: SafeArea(
                            bottom: false,
                            child: Center(
                              child: Text(
                                'no_internet'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
            ),
            if (ux.isLoading)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          if (ux.loadingMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              ux.loadingMessage!.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<LocalizationsDelegate<dynamic>>? _safeLocalizationDelegates(BuildContext context) {
    try {
      return context.localizationDelegates;
    } catch (_) {
      return [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];
    }
  }

  List<Locale> _safeSupportedLocales(BuildContext context) {
    try {
      return context.supportedLocales;
    } catch (_) {
      return const [Locale('en'), Locale('fr')];
    }
  }

  Locale? _safeLocale(BuildContext context) {
    try {
      return context.locale;
    } catch (_) {
      return const Locale('en');
    }
  }
}
