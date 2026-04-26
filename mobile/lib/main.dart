import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme.dart';
import 'features/navigation/router.dart';
import 'core/network/connectivity_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    const ProviderScope(
      child: FacialeApp(),
    ),
  );
}

class FacialeApp extends ConsumerWidget {
  const FacialeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final connectivity = ref.watch(connectivityProvider);

    return MaterialApp.router(
      title: 'Faciale',
      theme: AppTheme.lightTheme,
      routerConfig: router,
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
                          child: const SafeArea(
                            bottom: false,
                            child: Center(
                              child: Text(
                                'No Internet Connection',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
}
