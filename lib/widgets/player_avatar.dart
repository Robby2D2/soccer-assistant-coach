import 'dart:io';
import 'package:flutter/material.dart';

class PlayerAvatar extends StatelessWidget {
  final String firstName;
  final String lastName;
  final int? jerseyNumber;
  final String? profileImagePath;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;

  const PlayerAvatar({
    super.key,
    required this.firstName,
    required this.lastName,
    this.jerseyNumber,
    this.profileImagePath,
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
  });

  String get _initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  Widget _buildFallbackAvatar() {
    // Priority: Jersey number > Initials
    final text = jerseyNumber?.toString() ?? _initials;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.blue.shade100,
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? Colors.blue.shade800,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If we have a profile image path, try to load it
    if (profileImagePath != null && profileImagePath!.isNotEmpty) {
      final imageFile = File(profileImagePath!);
      if (imageFile.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? Colors.grey.shade200,
          backgroundImage: FileImage(imageFile),
        );
      }
    }

    // Fallback to jersey number or initials
    return _buildFallbackAvatar();
  }
}
