import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faciale/core/theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  test('AppColors should have the correct primary color', () {
    expect(AppColors.primary, const Color(0xFF0047AB));
  });

  test('AppTheme.lightTheme should use AppColors.primary', () {
    // Disable runtime fetching to avoid network errors in tests
    GoogleFonts.config.allowRuntimeFetching = false;
    
    final theme = AppTheme.lightTheme;
    expect(theme.primaryColor, AppColors.primary);
  });
}
