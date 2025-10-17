import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../utils/team_theme.dart'; // TeamColorContrast for contrast-aware icon

class TeamColorPicker extends StatefulWidget {
  final List<Color> initialColors;
  final ValueChanged<List<Color>> onColorsChanged;

  const TeamColorPicker({
    super.key,
    required this.initialColors,
    required this.onColorsChanged,
  });

  @override
  State<TeamColorPicker> createState() => _TeamColorPickerState();
}

class _TeamColorPickerState extends State<TeamColorPicker> {
  late List<Color> _colors;

  @override
  void initState() {
    super.initState();
    _colors = List.from(widget.initialColors);
    // Ensure we have exactly 3 color slots
    while (_colors.length < 3) {
      _colors.add(Colors.grey);
    }
    if (_colors.length > 3) {
      _colors = _colors.take(3).toList();
    }
  }

  @override
  void didUpdateWidget(covariant TeamColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If parent provides new initial colors (e.g., when editing an existing team),
    // update internal state to reflect saved values once.
    if (oldWidget.initialColors != widget.initialColors &&
        widget.initialColors.isNotEmpty) {
      setState(() {
        _colors = List.from(widget.initialColors);
        while (_colors.length < 3) {
          _colors.add(Colors.grey);
        }
        if (_colors.length > 3) {
          _colors = _colors.take(3).toList();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team Colors',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Select up to 3 primary colors for your team\'s theme',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (int i = 0; i < 3; i++) ...[
              _buildColorPicker(i),
              if (i < 2) const SizedBox(width: 12),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton.icon(
              onPressed: _resetToDefaults,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _showAdvancedColorPicker,
              icon: const Icon(Icons.palette),
              label: const Text('Advanced Picker'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorPicker(int index) {
    final color = _colors[index];
    return Expanded(
      child: Column(
        children: [
          Text(
            'Color ${index + 1}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickSingleColor(index),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.edit,
                  color: TeamColorContrast.onColorFor(color),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pickSingleColor(int index) async {
    final result = await showColorPickerDialog(
      context,
      _colors[index],
      title: Text('Pick Color ${index + 1}'),
      width: 40,
      height: 40,
      spacing: 0,
      runSpacing: 0,
      borderRadius: 20,
      wheelDiameter: 165,
      enableOpacity: false,
      showColorCode: true,
      colorCodeHasColor: true,
      pickersEnabled: <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.bw: false,
        ColorPickerType.custom: false,
        ColorPickerType.wheel: true,
      },
    );

    setState(() {
      _colors[index] = result;
    });
    widget.onColorsChanged(_colors);
  }

  void _showAdvancedColorPicker() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Team Color Palette'),
        content: SizedBox(
          width: 320,
          height: 400,
          child: Column(
            children: [
              for (int i = 0; i < 3; i++) ...[
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _colors[i],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Color ${i + 1}')),
                    IconButton(
                      onPressed: () => _pickSingleColor(i),
                      icon: const Icon(Icons.edit),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 16),
              _buildColorPreview(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPreview() {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: _colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Text(
          'Color Preview',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 2,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      _colors = [
        Theme.of(context).colorScheme.primary,
        Theme.of(context).colorScheme.secondary,
        Theme.of(context).colorScheme.tertiary,
      ];
    });
    widget.onColorsChanged(_colors);
  }
}

/// Helper class to convert between Color and hex string
class ColorHelper {
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  static Color? hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final hexCode = hex.replaceAll('#', '');
    if (hexCode.length != 6) return null;
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  static List<Color> hexListToColors(List<String?> hexList) {
    return hexList
        .map((hex) => hexToColor(hex))
        .where((color) => color != null)
        .cast<Color>()
        .toList();
  }

  static List<String> colorsToHexList(List<Color> colors) {
    return colors.map((color) => colorToHex(color)).toList();
  }
}
