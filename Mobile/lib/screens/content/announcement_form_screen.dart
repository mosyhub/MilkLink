import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../models/article_model.dart';

class AnnouncementFormScreen extends StatefulWidget {
  final AnnouncementModel? announcement; // null if creating, non-null if editing

  const AnnouncementFormScreen({super.key, this.announcement});

  @override
  State<AnnouncementFormScreen> createState() => _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState extends State<AnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  final TextEditingController _tagInputCtrl = TextEditingController();

  late bool _isActive;
  late List<String> _tags;
  late List<dynamic> _images; // List<ContentImage> or base64 String or raw bytes
  bool _isSaving = false;
  bool _hasChanges = false;

  final ImagePicker _picker = ImagePicker();

  bool get _isEditing => widget.announcement != null;

  @override
  void initState() {
    super.initState();
    final a = widget.announcement;
    _titleCtrl = TextEditingController(text: a?.title ?? '');
    _descCtrl = TextEditingController(text: a?.description ?? '');
    _isActive = a?.isActive ?? true;
    _tags = List<String>.from(a?.tags ?? []);
    _images = List<dynamic>.from(a?.images ?? []);

    _titleCtrl.addListener(_onFieldChanged);
    _descCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _tagInputCtrl.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Editing')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images allowed.')),
      );
      return;
    }

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image exceeds 5 MB size limit.')),
          );
        }
        return;
      }

      final ext = picked.path.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'png' : (ext == 'webp' ? 'webp' : 'jpeg');
      final dataUri = 'data:image/$mime;base64,${base64Encode(bytes)}';

      setState(() {
        _images.add(dataUri);
        _hasChanges = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      _hasChanges = true;
    });
  }

  void _addTag() {
    final t = _tagInputCtrl.text.trim();
    if (t.isNotEmpty && !_tags.contains(t)) {
      setState(() {
        _tags.add(t);
        _tagInputCtrl.clear();
        _hasChanges = true;
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
      _hasChanges = true;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final serializedImages = _images.map((img) {
        if (img is ContentImage) {
          return {'public_id': img.publicId, 'url': img.url};
        }
        return img.toString();
      }).toList();

      final payload = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'tags': _tags,
        'isActive': _isActive,
        'images': serializedImages,
      };

      if (_isEditing) {
        await ApiClient.put(
          ApiConstants.announcementById(widget.announcement!.id),
         data: payload,
        );
      } else {
        await ApiClient.post(
          ApiConstants.announcements,
          data: payload,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Announcement updated' : 'Announcement created'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save announcement: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Announcement' : 'Create Announcement'),
          actions: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Save'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Visibility toggle (Is Active)
                Card(
                  elevation: 0,
                  color: AppColors.softBlue.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    title: const Text('Active Status', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      _isActive
                          ? 'Visible to Staff and Patients'
                          : 'Inactive (visible only to Admins)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _isActive,
                    activeColor: AppColors.primaryNavy,
                    onChanged: (val) {
                      setState(() {
                        _isActive = val;
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Announcement Title *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
                ),
                const SizedBox(height: 20),

                // Tags section
                const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tagInputCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Add a tag (e.g. Donation, Event)...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addTag(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                      onPressed: _addTag,
                      child: const Text('Add'),
                    ),
                  ],
                ),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _tags.map((t) {
                      return Chip(
                        label: Text(t),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeTag(t),
                        backgroundColor: AppColors.softBlue.withValues(alpha: 0.3),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),

                // Images section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Images (Up to 5)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('${_images.length} / 5', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                if (_images.isNotEmpty)
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      itemBuilder: (ctx, i) {
                        final img = _images[i];
                        Widget imgWidget;
                        if (img is ContentImage) {
                          imgWidget = Image.network(img.url, fit: BoxFit.cover);
                        } else if (img is String && img.startsWith('data:image')) {
                          final commaIdx = img.indexOf(',');
                          final bytes = base64Decode(img.substring(commaIdx + 1));
                          imgWidget = Image.memory(bytes, fit: BoxFit.cover);
                        } else {
                          imgWidget = const Icon(Icons.image);
                        }

                        return Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: imgWidget,
                            ),
                            Positioned(
                              top: 4,
                              right: 16,
                              child: GestureDetector(
                                onTap: () => _removeImage(i),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                if (_images.length < 5) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Add from Gallery'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

