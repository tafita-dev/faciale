import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import 'camera_actions.dart';

class EnrollScreen extends ConsumerStatefulWidget {
  const EnrollScreen({super.key});

  @override
  ConsumerState<EnrollScreen> createState() => _EnrollScreenState();
}

class _EnrollScreenState extends ConsumerState<EnrollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedDept;
  String? _imagePath;
  bool _isLoading = false;

  final List<String> _departments = ['Engineering', 'HR', 'Marketing', 'Sales'];

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_imagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please capture a reference photo'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Simulating enrollment process
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Success and redirection to Employee List
        context.go('/employees');
      }
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
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Enrollment')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedDept,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      border: OutlineInputBorder(),
                    ),
                    items: _departments.map((dept) {
                      return DropdownMenuItem(
                        value: dept,
                        child: Text(dept),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDept = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select department';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('Reference Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _handleCapture,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        image: _imagePath != null && _imagePath != 'fake_path.jpg'
                            ? DecorationImage(
                                image: FileImage(File(_imagePath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _imagePath == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Capture Reference Photo', style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          : _imagePath == 'fake_path.jpg'
                              ? const Center(child: Text('Photo Captured!'))
                              : null,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Generating Secure Identity...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

class CameraPreviewDialog extends StatefulWidget {
  final CameraDescription camera;

  const CameraPreviewDialog({super.key, required this.camera});

  @override
  State<CameraPreviewDialog> createState() => _CameraPreviewDialogState();
}

class _CameraPreviewDialogState extends State<CameraPreviewDialog> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  XFile? _capturedFile;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Capture Reference Photo'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: _capturedFile == null
            ? FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return CameraPreview(_controller);
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              )
            : Image.file(File(_capturedFile!.path), fit: BoxFit.cover),
      ),
      actions: [
        if (_capturedFile == null) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _initializeControllerFuture;
                final image = await _controller.takePicture();
                setState(() {
                  _capturedFile = image;
                });
              } catch (e) {
                debugPrint(e.toString());
              }
            },
            child: const Text('Capture'),
          ),
        ] else ...[
          TextButton(
            onPressed: () {
              setState(() {
                _capturedFile = null;
              });
            },
            child: const Text('Retake'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(_capturedFile!.path);
            },
            child: const Text('Confirm'),
          ),
        ],
      ],
    );
  }
}
