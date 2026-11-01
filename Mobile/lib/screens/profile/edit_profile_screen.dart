import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Editable: username & email
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Editable: password
  bool _changePassword = false;
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Editable: profile photo
  String? _avatarBase64OrUrl;
  Uint8List? _avatarBytes;
  bool _avatarChanged = false; // only send avatar if the user changed it
  final ImagePicker _picker = ImagePicker();

  bool _isSaving = false;

  // Password policy checklist
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecial = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _usernameController.text = user.username;
      _emailController.text = user.email ?? '';

      if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
        _avatarBase64OrUrl = user.avatarUrl;
        _decodeAvatarBytes(user.avatarUrl!);
      }
    }

    _newPasswordController.addListener(_checkPasswordPolicy);
    _recoverLostImage();
  }

  // Android may destroy the activity while the camera/gallery is open
  Future<void> _recoverLostImage() async {
    try {
      final lost = await _picker.retrieveLostData();
      if (lost.isEmpty || lost.file == null) return;
      final bytes = await lost.file!.readAsBytes();
      if (!mounted) return;
      setState(() {
        _avatarBytes = bytes;
        _avatarBase64OrUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        _avatarChanged = true;
      });
    } catch (_) {}
  }

  void _decodeAvatarBytes(String str) {
    if (str.startsWith('data:image')) {
      try {
        final commaIdx = str.indexOf(',');
        if (commaIdx != -1) {
          _avatarBytes = base64Decode(str.substring(commaIdx + 1));
        }
      } catch (_) {}
    }
  }

  void _checkPasswordPolicy() {
    final v = _newPasswordController.text;
    setState(() {
      _hasMinLength = v.length >= 8;
      _hasUppercase = v.contains(RegExp(r'[A-Z]'));
      _hasLowercase = v.contains(RegExp(r'[a-z]'));
      _hasDigit = v.contains(RegExp(r'[0-9]'));
      _hasSpecial = v.contains(RegExp(r"""[!@#$%^&*()\-_=+\[\]{};:'",.<>/?`~\\|]"""));
    });
  }

  bool get _isPasswordValid =>
      _hasMinLength && _hasUppercase && _hasLowercase && _hasDigit && _hasSpecial;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      if (!mounted) return;
      setState(() {
        _avatarBytes = bytes;
        _avatarBase64OrUrl = base64String;
        _avatarChanged = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load image. Please try again.')),
        );
      }
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Profile Photo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primaryNavy),
                title: const Text('Take Photo with Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryNavy),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              if (_avatarBase64OrUrl != null && _avatarBase64OrUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Remove Photo', style: TextStyle(color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _avatarBytes = null;
                      _avatarBase64OrUrl = '';
                      _avatarChanged = true;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_changePassword) {
      if (_currentPasswordController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your current password.')),
        );
        return;
      }
      if (!_isPasswordValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New password does not meet security requirements.')),
        );
        return;
      }
      if (_newPasswordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New passwords do not match.')),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Only username, email, avatar, and password are ever sent
    final Map<String, dynamic> payload = {
      'username': _usernameController.text.trim().toLowerCase(),
      'email': _emailController.text.trim().toLowerCase(),
    };

    if (_avatarChanged) {
      payload['avatar'] = _avatarBase64OrUrl ?? '';
    }

    if (_changePassword) {
      payload['oldPassword'] = _currentPasswordController.text;
      payload['newPassword'] = _newPasswordController.text;
    }

    final success = await authProvider.updateProfile(payload);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to update profile'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildPolicyCheck(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 13,
            color: met ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: met ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isStaffOrAdmin = user != null && (user.isStaff || user.isAdmin);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Profile photo (editable) ────────────────────────────
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryNavy.withOpacity(0.2), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: isStaffOrAdmin ? AppColors.softBlue : AppColors.softPink,
                        backgroundImage: _avatarBytes != null
                            ? MemoryImage(_avatarBytes!)
                            : (_avatarBase64OrUrl != null &&
                                    _avatarBase64OrUrl!.startsWith('http')
                                ? NetworkImage(_avatarBase64OrUrl!) as ImageProvider
                                : null),
                        child: (_avatarBytes == null &&
                                (_avatarBase64OrUrl == null || !_avatarBase64OrUrl!.startsWith('http')))
                            ? Text(
                                user?.name.first.isNotEmpty == true
                                    ? user!.name.first[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: isStaffOrAdmin ? AppColors.primaryNavy : AppColors.accentPink,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showAvatarOptions,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryNavy,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _showAvatarOptions,
                  icon: const Icon(Icons.edit, size: 16, color: AppColors.primaryNavy),
                  label: const Text(
                    'Change Profile Photo',
                    style: TextStyle(fontSize: 13, color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── 2. Verified identity (read-only) ───────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user, color: AppColors.primaryNavy, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Verified Identity',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryNavy),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.softBlue,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                          ),
                          child: Text(
                            user?.role.toUpperCase() ?? 'USER',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18),
                    _buildReadOnlyItem(label: 'Full Name', value: user?.name.fullName ?? '—'),
                    const SizedBox(height: 8),
                    _buildReadOnlyItem(label: 'Phone Number', value: user?.phone ?? '—'),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.lock_outline, size: 13, color: AppColors.textSecondary),
                        SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Legal name and phone number are verified during intake and cannot be altered directly.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── 3. Username & email (editable) ─────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Credentials',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    const Divider(height: 20),
                    CustomTextField(
                      label: 'Username *',
                      hint: 'e.g. maria_santos',
                      controller: _usernameController,
                      prefixIcon: const Icon(Icons.alternate_email, color: AppColors.primaryNavy),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Username required';
                        if (v.trim().length < 4) return 'At least 4 characters';
                        if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(v.trim())) {
                          return 'Only alphanumeric characters, _, . or - allowed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Email Address (Optional)',
                      hint: 'e.g. maria@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.mail_outline, color: AppColors.textSecondary),
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty) {
                          final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegExp.hasMatch(v.trim())) return 'Invalid email address';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── 4. Password (editable) ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_outline, color: AppColors.primaryNavy, size: 22),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Password & Security',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                          ),
                        ),
                        Switch(
                          value: _changePassword,
                          activeColor: AppColors.primaryNavy,
                          onChanged: (val) => setState(() => _changePassword = val),
                        ),
                      ],
                    ),
                    if (_changePassword) ...[
                      const Divider(height: 20),
                      CustomTextField(
                        label: 'Current Password *',
                        hint: 'Enter your existing password',
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrent,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'New Password *',
                        hint: 'Create a new password',
                        controller: _newPasswordController,
                        obscureText: _obscureNew,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.softBlue.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            _buildPolicyCheck('At least 8 characters', _hasMinLength),
                            _buildPolicyCheck('At least 1 uppercase letter (A-Z)', _hasUppercase),
                            _buildPolicyCheck('At least 1 lowercase letter (a-z)', _hasLowercase),
                            _buildPolicyCheck('At least 1 number (0-9)', _hasDigit),
                            _buildPolicyCheck('At least 1 special character (!@#\$%^&*)', _hasSpecial),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'Confirm New Password *',
                        hint: 'Re-type new password',
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 5. Save ────────────────────────────────────────────────
              CustomButton(
                text: 'Save Changes',
                isLoading: _isSaving,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyItem({required String label, required String value}) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}