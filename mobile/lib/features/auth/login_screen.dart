import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/widgets/responsive_layout.dart';
import 'auth_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/neumorphic_card.dart';
import '../../core/widgets/neumorphic_button.dart';
import '../../core/widgets/logo.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    await ref.read(authProvider.notifier).login(email, password);
    
    final authState = ref.read(authProvider);

    if (authState.error != null) {
      _shakeController.forward(from: 0.0);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error!),
          backgroundColor: AppColors.error,
        ),
      );
    } else if (authState.token != null) {
      if (!mounted) return;
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ResponsiveLayout(
        mobile: _buildLoginForm(context, authState),
        tablet: Center(
          child: SizedBox(
            width: 450,
            child: _buildLoginForm(context, authState),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthState authState) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Logo(size: 80),
            const SizedBox(height: 48),
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final double offset = sin(_shakeController.value * 6 * pi) * 10 * (1 - _shakeController.value);
                
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Column(
                children: [
                  NeumorphicCard(
                    isInset: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'email'.tr(),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  NeumorphicCard(
                    isInset: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'password'.tr(),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: NeumorphicButton(
                onPressed: authState.isLoading ? () {} : _handleLogin,
                backgroundColor: AppColors.background,
                child: Center(
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'login'.tr().toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.push('/forgot-password'),
              child: Text(
                'forgot_password'.tr(),
                style: const TextStyle(
                  color: AppColors.text,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
