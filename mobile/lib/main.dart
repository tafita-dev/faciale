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
import 'features/auth/auth_provider.dart';

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
      child: const ProviderScope(
        child: FacialeApp(),
      ),
    ),
  );
}

class FacialeApp extends ConsumerWidget {
  const FacialeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final connectivity = ref.watch(connectivityProvider);

    // Initialize notification service when token is available
    ref.listen(authProvider, (previous, next) {
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
                  // Suppression du const ici car l'enfant (Text) est dynamique
                  child: SafeArea(
                    bottom: false,
                    child: Center(
                      child: Text(
                        'no_internet'.tr(),
                        // Suppression du const ici aussi
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
