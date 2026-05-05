import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../core/widgets/neumorphic_card.dart';
import '../../core/widgets/neumorphic_button.dart';
import 'org_provider.dart';

class CreateOrgScreen extends ConsumerStatefulWidget {
  const CreateOrgScreen({super.key});

  @override
  ConsumerState<CreateOrgScreen> createState() => _CreateOrgScreenState();
}

class _CreateOrgScreenState extends ConsumerState<CreateOrgScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  String _selectedType = 'school';
  File? _logoFile;

  @override
  void dispose() {
    _nameController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _logoFile = File(image.path);
      });
    }
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(orgProvider.notifier).createOrg(
        name: _nameController.text,
        type: _selectedType,
        adminName: _adminNameController.text,
        adminEmail: _adminEmailController.text,
        adminPassword: _adminPasswordController.text,
        logoFile: _logoFile,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orgProvider);

    ref.listen(orgProvider, (previous, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('organization_created_successfully'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(orgProvider.notifier).reset();
        context.pop();
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
      appBar: AppBar(title: Text('create_organization'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: NeumorphicCard(
                    padding: const EdgeInsets.all(4),
                    borderRadius: 60,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                      ),
                      child: _logoFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.file(
                              _logoFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_a_photo,
                                size: 32,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'add_logo'.tr(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'organization_details'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              NeumorphicCard(
                isInset: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'organization_name'.tr(),
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'org_name_required'.tr();
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              NeumorphicCard(
                isInset: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'type'.tr(),
                    border: InputBorder.none,
                  ),
                  items: [
                    DropdownMenuItem(value: 'school', child: Text('school'.tr())),
                    DropdownMenuItem(value: 'company', child: Text('company'.tr())),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'admin_user_account'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              NeumorphicCard(
                isInset: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextFormField(
                  controller: _adminNameController,
                  decoration: InputDecoration(
                    labelText: 'admin_full_name'.tr(),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'admin_name_required'.tr();
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
                  controller: _adminEmailController,
                  decoration: InputDecoration(
                    labelText: 'admin_email'.tr(),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'admin_email_required'.tr();
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'invalid_email'.tr();
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
                  controller: _adminPasswordController,
                  decoration: InputDecoration(
                    labelText: 'admin_password'.tr(),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'admin_password_required'.tr();
                    }
                    if (value.length < 6) {
                      return 'password_too_short'.tr();
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 48),
              NeumorphicButton(
                onPressed: state.isLoading ? () {} : _handleSubmit,
                child: Center(
                  child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'create_organization'.tr().toUpperCase(),
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
    );
  }
}
