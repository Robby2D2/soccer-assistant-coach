import 'package:flutter/material.dart';
import 'dart:io';

class TeamLogoWidget extends StatelessWidget {
  final String? logoPath;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool showBorder;
  final VoidCallback? onTap;

  const TeamLogoWidget({
    super.key,
    this.logoPath,
    this.size = 48,
    this.backgroundColor,
    this.iconColor,
    this.showBorder = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.25),
        color:
            backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
        border: showBorder
            ? Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: _buildContent(context),
    );

    if (onTap != null) {
      child = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size * 0.25),
        child: child,
      );
    }

    return child;
  }

  Widget _buildContent(BuildContext context) {
    if (logoPath?.isNotEmpty == true) {
      final file = File(logoPath!);
      final exists = file.existsSync();
      debugPrint('TeamLogoWidget: path=$logoPath, exists=$exists');

      if (exists) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.25),
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('TeamLogoWidget: Image loading error: $error');
              return _buildFallbackIcon(context);
            },
          ),
        );
      } else {
        debugPrint('TeamLogoWidget: File does not exist: $logoPath');
      }
    } else {
      debugPrint('TeamLogoWidget: No logo path provided');
    }

    return _buildFallbackIcon(context);
  }

  Widget _buildFallbackIcon(BuildContext context) {
    return Icon(
      Icons.sports_soccer,
      size: size * 0.6,
      color: iconColor ?? Theme.of(context).colorScheme.primary,
    );
  }
}

/// Editable team logo widget with edit button overlay
class EditableTeamLogoWidget extends StatelessWidget {
  final String? logoPath;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final VoidCallback onEdit;

  const EditableTeamLogoWidget({
    super.key,
    this.logoPath,
    this.size = 80,
    this.backgroundColor,
    this.iconColor,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TeamLogoWidget(
          logoPath: logoPath,
          size: size,
          backgroundColor: backgroundColor,
          iconColor: iconColor,
          showBorder: true,
          onTap: onEdit,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: size * 0.3,
            height: size * 0.3,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(size * 0.15),
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.edit,
              size: size * 0.2,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
