import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../core/providers.dart';
import '../../widgets/player_avatar.dart';
import '../../core/team_theme_manager.dart';
import '../../widgets/team_header.dart';

class PlayerEditScreen extends ConsumerStatefulWidget {
  final int playerId;
  const PlayerEditScreen({super.key, required this.playerId});
  @override
  ConsumerState<PlayerEditScreen> createState() => _PlayerEditScreenState();
}

class _PlayerEditScreenState extends ConsumerState<PlayerEditScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _jerseyNumber = TextEditingController();
  bool _present = true;
  String? _profileImagePath;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final db = ref.read(dbProvider);
    db.getPlayer(widget.playerId).then((p) {
      if (!mounted || p == null) return;
      setState(() {
        _first.text = p.firstName;
        _last.text = p.lastName;
        _present = p.isPresent;
        _jerseyNumber.text = p.jerseyNumber?.toString() ?? '';
        _profileImagePath = p.profileImagePath;
      });
    });
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // Save the image to app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final playersDir = Directory('${appDir.path}/player_photos');
        if (!playersDir.existsSync()) {
          playersDir.createSync(recursive: true);
        }

        final fileName =
            'player_${widget.playerId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = File('${playersDir.path}/$fileName');
        await File(pickedFile.path).copy(savedImage.path);

        setState(() {
          _profileImagePath = savedImage.path;
        });
      }
    } catch (e) {
      // Handle image picker errors gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to access ${source == ImageSource.camera ? "camera" : "photo library"}. Please check permissions.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    // We need player to derive teamId for theming
    return FutureBuilder<Player?>(
      future: db.getPlayer(widget.playerId),
      builder: (context, snapPlayer) {
        final player = snapPlayer.data;
        final teamId = player?.teamId;
        return TeamScaffold(
          teamId: teamId,
          appBar: const TeamAppBar(titleText: 'Edit Player'),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final f = _first.text.trim();
              final l = _last.text.trim();
              if (f.isEmpty || l.isEmpty) return;

              // Parse jersey number
              int? jerseyNumber;
              final jerseyStr = _jerseyNumber.text.trim();
              if (jerseyStr.isNotEmpty) {
                jerseyNumber = int.tryParse(jerseyStr);
              }

              await db.updatePlayer(
                id: widget.playerId,
                firstName: f,
                lastName: l,
                isPresent: _present,
                jerseyNumber: jerseyNumber,
                profileImagePath: _profileImagePath,
              );
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (teamId != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TeamBrandedHeader(
                      teamId: teamId,
                      title:
                          '${_first.text.isEmpty ? 'Player' : _first.text} ${_last.text}',
                      subtitle: 'Update roster details',
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                TextField(
                  controller: _first,
                  decoration: const InputDecoration(labelText: 'First name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _last,
                  decoration: const InputDecoration(labelText: 'Last name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _jerseyNumber,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jersey number',
                    hintText: 'Optional',
                  ),
                ),
                const SizedBox(height: 16),
                // Profile Picture Section
                Row(
                  children: [
                    PlayerAvatar(
                      firstName: _first.text,
                      lastName: _last.text,
                      jerseyNumber: int.tryParse(_jerseyNumber.text),
                      profileImagePath: _profileImagePath,
                      radius: 30,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _showImagePickerOptions,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Add Photo'),
                          ),
                          if (_profileImagePath != null)
                            TextButton.icon(
                              onPressed: () =>
                                  setState(() => _profileImagePath = null),
                              icon: const Icon(Icons.delete, size: 16),
                              label: const Text('Remove'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _present,
                  title: const Text('Active'),
                  onChanged: (v) => setState(() => _present = v),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
