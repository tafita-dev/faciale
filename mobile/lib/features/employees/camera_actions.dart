import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Le provider qui gère la logique de capture
final capturePhotoProvider = Provider<Future<String?> Function(BuildContext)>((ref) {
  return (context) async {
    // 1. Récupérer la liste des caméras disponibles
    final cameras = await availableCameras();
    
    if (cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucune caméra trouvée")),
      );
      return null;
    }

    final backCamera = cameras.firstWhere(
  (camera) => camera.lensDirection == CameraLensDirection.back,
  orElse: () => cameras.first, // Repli sur la première si "back" n'est pas trouvé
);

    // 2. Afficher la boîte de dialogue avec la caméra
    return await showDialog<String>(
      context: context,
      barrierDismissible: false, // Force l'utilisateur à choisir ou annuler via les boutons
      builder: (context) => CameraPreviewDialog(camera: backCamera),
    );
  };
});

// --- LE WIDGET QUI MANQUAIT ---
class CameraPreviewDialog extends StatefulWidget {
  final CameraDescription camera;

  const CameraPreviewDialog({super.key, required this.camera});

  @override
  State<CameraPreviewDialog> createState() => _CameraPreviewDialogState();
}

class _CameraPreviewDialogState extends State<CameraPreviewDialog> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // Initialisation du contrôleur de la caméra
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Très important : libérer la caméra quand on ferme le dialogue
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Prendre une photo"),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: CameraPreview(_controller),
              );
            } else {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), // Retourne null
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await _initializeControllerFuture;
              // Capture de l'image
              final image = await _controller.takePicture();
              // Ferme le dialogue et retourne le chemin du fichier
              if (mounted) Navigator.pop(context, image.path);
            } catch (e) {
              debugPrint("Erreur lors de la capture : $e");
            }
          },
          child: const Text("Capturer"),
        ),
      ],
    );
  }
}