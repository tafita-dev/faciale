import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme.dart';
import '../../core/widgets/neumorphic_card.dart';
import '../../core/widgets/neumorphic_button.dart';
import 'camera_actions.dart';
import 'employee_provider.dart';
import '../organizations/department_provider.dart';

class EnrollScreen extends ConsumerStatefulWidget {
  const EnrollScreen({super.key});

  @override
  ConsumerState<EnrollScreen> createState() => _EnrollScreenState();
}

class _EnrollScreenState extends ConsumerState<EnrollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _selectedDeptId;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      ref.read(departmentProvider.notifier).fetchDepartments()
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_imagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('please_capture_photo'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      await ref.read(employeeProvider.notifier).createAndEnrollEmployee(
        name: _nameController.text,
        deptId: _selectedDeptId!,
        email: _emailController.text,
        imagePath: _imagePath!,
      );
    }
  }

  Future<void> _handleCapture() async {
    final captureFn = ref.read(capturePhotoProvider);
    final result = await captureFn(context);
    if (result != null) {
      setState(() {
        _imagePath = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final empState = ref.watch(employeeProvider);
    final deptState = ref.watch(departmentProvider);

    ref.listen(employeeProvider, (previous, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('employee_enrolled_successfully'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(employeeProvider.notifier).reset();
        context.go('/employees');
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('employee_enrollment'.tr())),
      body: Stack(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      NeumorphicCard(
                        isInset: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'full_name'.tr(),
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'please_enter_name'.tr();
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      NeumorphicCard(
                        isInset: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'email'.tr(),
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'please_enter_valid_email'.tr();
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (deptState.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        NeumorphicCard(
                          isInset: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: DropdownButtonFormField<String>(
                            value: _selectedDeptId,
                            decoration: InputDecoration(
                              labelText: 'department_name'.tr(),
                              border: InputBorder.none,
                            ),
                            items: deptState.departments.map((dept) {
                              return DropdownMenuItem(
                                value: dept.id,
                                child: Text(dept.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedDeptId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'please_select_department'.tr();
                              }
                              return null;
                            },
                          ),
                        ),
                      const SizedBox(height: 32),
                      Text(
                        'reference_photo'.tr(), 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text)
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _handleCapture,
                        child: NeumorphicCard(
                          padding: EdgeInsets.zero,
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              image: _imagePath != null && _imagePath != 'fake_path.jpg'
                                  ? DecorationImage(
                                      image: FileImage(File(_imagePath!)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _imagePath == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.camera_alt, size: 48, color: AppColors.primary),
                                      const SizedBox(height: 8),
                                      Text('capture_reference_photo'.tr(), style: const TextStyle(color: Colors.grey)),
                                    ],
                                  )
                                : _imagePath == 'fake_path.jpg'
                                    ? Center(child: Text('photo_captured'.tr()))
                                    : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      NeumorphicButton(
                        onPressed: empState.isLoading ? () {} : _submit,
                        child: Center(
                          child: Text(
                            'save'.tr().toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (empState.isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'generating_secure_identity'.tr(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
