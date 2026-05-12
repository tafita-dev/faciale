import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'offline_storage_service.dart';
import '../../core/theme.dart';
import '../../core/widgets/neumorphic_card.dart';
import 'scanner_state.dart';
import 'facial_scanner_widget.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {

  @override
  void initState() {
    super.initState();
    // Hide status bar and navigation bar for immersive view
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerProvider);
    final pendingCount = ref.watch(pendingScansCountProvider);

    // Listen for state changes to manage the modal
    ref.listen(scannerProvider, (previous, next) {
      if ((next.status == ScannerStatus.success || next.status == ScannerStatus.failure) && 
          (previous?.status != ScannerStatus.success && previous?.status != ScannerStatus.failure)) {
        SystemSound.play(SystemSoundType.click);
        _showResultModal(context, next);
      }
      
      if (next.status == ScannerStatus.scanning && 
          (previous?.status == ScannerStatus.success || previous?.status == ScannerStatus.failure)) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          FacialScannerWidget(
            showModeToggle: true,
            onImageCaptured: (path) async {
              if (mounted && ref.read(scannerProvider).status == ScannerStatus.scanning) {
                await ref.read(scannerProvider.notifier).processImage(path);
              }
            },
          ),

          // UI Overlays (Back button, status, etc.)
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (pendingCount > 0) ...[
                            _buildPendingIndicator(context, pendingCount),
                            const SizedBox(width: 8),
                          ],
                          _buildModeSelector(context, ref, scannerState),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                
                // Status Text
                if (scannerState.message != null && scannerState.status == ScannerStatus.scanning)
                  NeumorphicCard(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    borderRadius: 30,
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: Text(
                      scannerState.message!.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 100),
              ],
            ),
          ),

          // Global Loading Overlay
          if (scannerState.status == ScannerStatus.processing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeWidth: 6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showResultModal(BuildContext context, ScannerState state) {
    final color = _getUIColor(state.uiColor);
    final icon = _getUIIcon(state.uiColor);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 60),
                ),
                const SizedBox(height: 24),
                Text(
                  (state.message ?? (state.status == ScannerStatus.success ? 'success'.tr() : 'failed'.tr())).toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.2,
                  ),
                ),
                if (state.matchedName != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.matchedName!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (state.checkInType != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${state.checkInType == "entry" ? "check_in".tr() : "check_out".tr()}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ref.read(scannerProvider.notifier).reset();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getUIColor(String? colorStr) {
    switch (colorStr) {
      case 'green': return Colors.green;
      case 'blue': return AppColors.primary;
      case 'red': return Colors.red;
      default: return AppColors.primary;
    }
  }

  IconData _getUIIcon(String? colorStr) {
    switch (colorStr) {
      case 'green': return Icons.check_circle;
      case 'blue': return Icons.logout;
      case 'red': return Icons.error;
      default: return Icons.info;
    }
  }

  Widget _buildPendingIndicator(BuildContext context, int count) {
    return NeumorphicCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 20,
      backgroundColor: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_upload_outlined, color: Colors.orange, size: 16),
          const SizedBox(width: 6),
          Text(
            '$count ${'pending'.tr()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(BuildContext context, WidgetRef ref, ScannerState state) {
    String label;
    IconData icon;
    Color color;

    switch (state.scanningMode) {
      case ScanningMode.auto:
        label = 'AUTO';
        icon = Icons.sync_rounded;
        color = Colors.white70;
        break;
      case ScanningMode.entry:
        label = 'ENTRY';
        icon = Icons.login_rounded;
        color = Colors.greenAccent;
        break;
      case ScanningMode.exit:
        label = 'EXIT';
        icon = Icons.logout_rounded;
        color = AppColors.primary;
        break;
    }

    return GestureDetector(
      onTap: () {
        final nextMode = ScanningMode.values[(state.scanningMode.index + 1) % ScanningMode.values.length];
        ref.read(scannerProvider.notifier).setScanningMode(nextMode);
        SystemSound.play(SystemSoundType.click);
      },
      child: NeumorphicCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderRadius: 20,
        backgroundColor: Colors.black.withOpacity(0.5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
