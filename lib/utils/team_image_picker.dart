import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class TeamImagePicker {
  static final ImagePicker _picker = ImagePicker();

  /// Show dialog to pick team logo image from gallery or camera
  static Future<String?> pickTeamLogo(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Team Logo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                final imagePath = await _pickImage(ImageSource.gallery);
                if (context.mounted) Navigator.pop(context, imagePath);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                final imagePath = await _pickImage(ImageSource.camera);
                if (context.mounted) Navigator.pop(context, imagePath);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Pick image and save it to app directory
  static Future<String?> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return null;

      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final teamLogosDir = Directory(path.join(appDir.path, 'team_logos'));

      // Create directory if it doesn't exist
      if (!await teamLogosDir.exists()) {
        await teamLogosDir.create(recursive: true);
      }

      // Generate unique filename
      final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final targetPath = path.join(teamLogosDir.path, fileName);

      // Copy image to app directory
      await File(image.path).copy(targetPath);

      debugPrint('TeamImagePicker: Saved image to: $targetPath');
      debugPrint(
        'TeamImagePicker: File exists: ${await File(targetPath).exists()}',
      );

      return targetPath;
    } catch (e) {
      debugPrint('Error picking team logo: $e');
      return null;
    }
  }

  /// Delete team logo file
  static Future<void> deleteTeamLogo(String? logoPath) async {
    if (logoPath?.isNotEmpty != true) return;

    try {
      final file = File(logoPath!);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting team logo: $e');
    }
  }

  /// Check if logo file exists
  static Future<bool> logoExists(String? logoPath) async {
    if (logoPath?.isNotEmpty != true) return false;

    try {
      return await File(logoPath!).exists();
    } catch (e) {
      return false;
    }
  }
}
