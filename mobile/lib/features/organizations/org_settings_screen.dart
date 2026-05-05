import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'org_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/neumorphic_card.dart';
import '../../core/widgets/neumorphic_button.dart';

class OrgSettingsScreen extends ConsumerStatefulWidget {
  const OrgSettingsScreen({super.key});

  @override
  ConsumerState<OrgSettingsScreen> createState() => _OrgSettingsScreenState();
}

class _OrgSettingsScreenState extends ConsumerState<OrgSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _lateBufferController;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _lateBufferController = TextEditingController();
    
    // Initialize with current settings if available
    Future.microtask(() async {
      await ref.read(currentOrgProvider.notifier).fetchCurrentOrg();
      final org = ref.read(currentOrgProvider).org;
      if (org != null && org.settings != null) {
        setState(() {
          final parts = org.settings!.startTime.split(':');
          _startTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
          _lateBufferController.text = org.settings!.lateBufferMinutes.toString();
        });
      }
    });
  }

  @override
  void dispose() {
    _lateBufferController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hour.toString().padLeft(2, '0');
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final startTimeStr = _formatTimeOfDay(_startTime);
      final lateBuffer = int.tryParse(_lateBufferController.text) ?? 15;

      await ref.read(currentOrgProvider.notifier).updateSettings(
        startTime: startTimeStr,
        lateBufferMinutes: lateBuffer,
      );

      if (mounted) {
        final state = ref.read(currentOrgProvider);
        if (state.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('settings_updated_success'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(currentOrgProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('organization_settings'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: state.isLoading && state.org == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'work_hours_config'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Start Time Selection
                    Text(
                      'start_time'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    NeumorphicCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        title: Text(
                          _formatTimeOfDay(_startTime),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(Icons.access_time, color: AppColors.primary),
                        onTap: () => _selectTime(context),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Late Buffer Input
                    Text(
                      'late_buffer'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    NeumorphicCard(
                      isInset: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextFormField(
                        controller: _lateBufferController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '15',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'please_enter_value'.tr();
                          }
                          if (int.tryParse(value) == null) {
                            return 'please_enter_number'.tr();
                          }
                          return null;
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    if (state.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      NeumorphicButton(
                        onPressed: _saveSettings,
                        child: Text(
                          'save'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
