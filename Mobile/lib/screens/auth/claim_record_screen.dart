import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../main_navigation_screen.dart';
import '../staff/staff_dashboard_screen.dart';

enum ClaimInputMethod { qrScan, manualToken }

class ClaimRecordScreen extends StatefulWidget {
  const ClaimRecordScreen({Key? key}) : super(key: key);

  @override
  State<ClaimRecordScreen> createState() => _ClaimRecordScreenState();
}

class _ClaimRecordScreenState extends State<ClaimRecordScreen> {
  final _setupFormKey = GlobalKey<FormState>();

  // State: Has the record been verified?
  bool _isVerified = false;
  bool _isVerifying = false;
  Map<String, dynamic>? _verifiedData;
  String _activeToken = '';

  // Input Method (QR Code Scanner vs Manual Token)
  ClaimInputMethod _inputMethod = ClaimInputMethod.qrScan;

  // Manual Token Input
  final _tokenController = TextEditingController();

  // QR scanning (camera + gallery image)
  final MobileScannerController _scannerController = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 1000,
  );
  final ImagePicker _imagePicker = ImagePicker();
  String? _lastScannedValue;
  DateTime? _lastScannedAt;
  bool _torchOn = false;

  // Streamlined Account Credentials Form
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Password Policy Checklist
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecial = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPassword);
  }

  void _checkPassword() {
    final v = _passwordController.text;
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
    _scannerController.dispose();
    _tokenController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SCANNER HELPERS
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _stopScanner() async {
    try {
      await _scannerController.stop();
    } catch (_) {}
  }

  Future<void> _startScanner() async {
    try {
      await _scannerController.start();
    } catch (_) {}
  }

  /// Accepts either a raw token or the MilkLink QR JSON and returns the token.
  String _extractToken(String raw) {
    final value = raw.trim();
    if (value.startsWith('{') && value.endsWith('}')) {
      try {
        final parsed = jsonDecode(value);
        if (parsed is Map && parsed['token'] != null) {
          return parsed['token'].toString().trim();
        }
      } catch (_) {}
    }
    return value;
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isVerifying || _isVerified) return;

    String? raw;
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.trim().isNotEmpty) {
        raw = barcode.rawValue;
        break;
      }
    }
    if (raw == null) return;

    // Cooldown so a bad code isn't re-submitted in a loop
    final now = DateTime.now();
    if (_lastScannedValue == raw &&
        _lastScannedAt != null &&
        now.difference(_lastScannedAt!) < const Duration(seconds: 3)) {
      return;
    }
    _lastScannedValue = raw;
    _lastScannedAt = now;

    HapticFeedback.mediumImpact();
    _handleVerifyToken(_extractToken(raw));
  }

  Future<void> _pickQrFromGallery() async {
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final capture = await _scannerController.analyzeImage(picked.path);
      if (!mounted) return;

      String? raw;
      if (capture != null) {
        for (final barcode in capture.barcodes) {
          if (barcode.rawValue != null && barcode.rawValue!.trim().isNotEmpty) {
            raw = barcode.rawValue;
            break;
          }
        }
      }

      if (raw == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No QR code found in that image. Try a clearer, closer photo.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      await _handleVerifyToken(_extractToken(raw));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read the selected image.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pasteIntoTokenField() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) return;
    setState(() {
      _tokenController.text = _extractToken(text).toUpperCase();
    });
  }

  void _switchMethod(ClaimInputMethod method) {
    if (_inputMethod == method) return;
    setState(() => _inputMethod = method);
    if (method == ClaimInputMethod.qrScan) {
      _startScanner();
    } else {
      _stopScanner();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // VERIFY / BIND
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _handleVerifyToken(String tokenToVerify) async {
    final clean = tokenToVerify.trim();
    if (clean.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan a QR code or enter a claim token.')),
      );
      return;
    }

    setState(() => _isVerifying = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.verifyClaimToken(clean);

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (result != null && result['valid'] == true) {
      await _stopScanner();
      setState(() {
        _isVerified = true;
        _verifiedData = result;
        _activeToken = result['claimToken'] ?? clean;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile verified for ${result['details']?['fullName'] ?? 'User'}!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Invalid claim token or QR code'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleFinalAccountBinding() async {
    if (!_setupFormKey.currentState!.validate()) return;

    if (!_isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password does not meet security requirements.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.claimRecord(
      claimToken: _activeToken,
      username: _usernameController.text.trim().toLowerCase(),
      password: _passwordController.text,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      profileType: _verifiedData?['profileType'],
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created and profile linked successfully! Welcome to MilkLink.'),
          backgroundColor: AppColors.success,
        ),
      );

      final user = authProvider.user;
      if (user != null && (user.isStaff || user.isAdmin)) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const StaffDashboardScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Account binding failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildPolicyRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: met ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: met ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTab({
    required ClaimInputMethod method,
    required IconData icon,
    required String label,
  }) {
    final selected = _inputMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchMethod(method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryNavy : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : AppColors.textPrimary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // VIEW 1: CLAIM VERIFICATION (Camera / Image Upload OR Manual Token Input)
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildCameraError(MobileScannerException error) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 40),
            const SizedBox(height: 12),
            Text(
              denied
                  ? 'Camera permission is turned off. Enable it in your phone settings, or upload a QR image instead.'
                  : 'Camera is unavailable. You can upload a QR image or enter the token instead.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrScannerCard() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        // Live camera preview
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 280,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                  // 7.x signature: (context, error)
                  errorBuilder: (context, error) => _buildCameraError(error),
                ),
                // Reticle
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
                // Hint label
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Align QR Code in frame',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                // Torch + flip camera
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Row(
                    children: [
                      _scannerIconButton(
                        icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                        onTap: () async {
                          try {
                            await _scannerController.toggleTorch();
                            if (mounted) setState(() => _torchOn = !_torchOn);
                          } catch (_) {}
                        },
                      ),
                      const SizedBox(width: 8),
                      _scannerIconButton(
                        icon: Icons.cameraswitch_outlined,
                        onTap: () async {
                          try {
                            await _scannerController.switchCamera();
                          } catch (_) {}
                        },
                      ),
                    ],
                  ),
                ),
                // Verifying overlay
                if (_isVerifying)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Point your camera at the QR code provided by Milk Bank staff.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        Row(
          children: const [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('OR', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),

        // Upload QR image from gallery
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isVerifying ? null : _pickQrFromGallery,
            icon: const Icon(Icons.image_outlined, color: AppColors.primaryNavy),
            label: const Text(
              'Upload QR Code Image',
              style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.primaryNavy),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _scannerIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildClaimVerificationView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Information Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.verified_user_outlined, color: AppColors.primaryNavy, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Hospital Intake Onboarding',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryNavy),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Account profiles are created by Pasig Human Milk Bank staff. Use your official QR Code or Claim Token to activate your account.',
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Method Selector
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _buildMethodTab(
                method: ClaimInputMethod.qrScan,
                icon: Icons.qr_code_scanner,
                label: 'Scan QR Code',
              ),
              _buildMethodTab(
                method: ClaimInputMethod.manualToken,
                icon: Icons.tag,
                label: 'Enter Token',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // METHOD 1: CAMERA SCAN / IMAGE UPLOAD
        if (_inputMethod == ClaimInputMethod.qrScan)
          _buildQrScannerCard()

        // METHOD 2: ENTER CLAIM TOKEN MANUALLY
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '16-Character Claim Token',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryNavy),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Type or paste the 16-character code found on your screening intake slip.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Claim Token *',
                  hint: 'e.g. B47AF901D2E45C89',
                  controller: _tokenController,
                  prefixIcon: const Icon(Icons.vpn_key_outlined, color: AppColors.primaryNavy),
                  suffixIcon: IconButton(
                    tooltip: 'Paste',
                    icon: const Icon(Icons.content_paste, color: AppColors.primaryNavy),
                    onPressed: _pasteIntoTokenField,
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Verify Claim Token',
                  isLoading: _isVerifying,
                  onPressed: () => _handleVerifyToken(_extractToken(_tokenController.text)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // VIEW 2: STREAMLINED ACCOUNT SETUP (Verified Identity + Credentials)
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildAccountSetupView() {
    final details = _verifiedData?['details'] as Map<String, dynamic>? ?? {};
    final profileType = _verifiedData?['profileType'] ?? 'Record';
    final fullName = details['fullName'] ?? 'Medical Member';
    final contactPhone = details['contactPhone'] ?? '—';
    final addressSnippet = details['addressSnippet'] ?? 'Pasig City';

    final authProvider = Provider.of<AuthProvider>(context);

    return Form(
      key: _setupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Verified Record Confirmation Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Verified $profileType Record Found',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success),
                    ),
                    const Spacer(),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () {
                        setState(() {
                          _isVerified = false;
                          _lastScannedValue = null;
                          _lastScannedAt = null;
                        });
                        if (_inputMethod == ClaimInputMethod.qrScan) _startScanner();
                      },
                      child: const Text('Change', style: TextStyle(fontSize: 12, color: AppColors.primaryNavy)),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Text(
                  fullName,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                ),
                const SizedBox(height: 4),
                Text('Phone: $contactPhone', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                Text('Address: $addressSnippet', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                if (details['screeningStatus'] != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'Status: ${details['screeningStatus']}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Create Your Login Credentials',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryNavy),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your personal information and medical intake records are already securely stored. Choose your login credentials below:',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),

          // Username Field
          CustomTextField(
            label: 'Username *',
            hint: 'e.g. maria_delacruz',
            controller: _usernameController,
            prefixIcon: const Icon(Icons.alternate_email, color: AppColors.primaryNavy),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Username is required';
              if (v.trim().length < 4) return 'Username must be at least 4 characters';
              if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(v.trim())) {
                return 'Only alphanumeric characters, _, . or - allowed';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Email Field (Optional)
          CustomTextField(
            label: 'Email Address (Optional)',
            hint: 'Optional — for milk release & status notifications',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.mail_outline, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // Password Field
          CustomTextField(
            label: 'Password *',
            hint: 'Create a secure password',
            controller: _passwordController,
            obscureText: _obscurePassword,
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryNavy),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (!_isPasswordValid) return 'Password does not meet requirements';
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Password Policy Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPolicyRow('At least 8 characters long', _hasMinLength),
                _buildPolicyRow('At least one uppercase letter (A-Z)', _hasUppercase),
                _buildPolicyRow('At least one lowercase letter (a-z)', _hasLowercase),
                _buildPolicyRow('At least one number (0-9)', _hasDigit),
                _buildPolicyRow('At least one special symbol (!@#\$%^&*)', _hasSpecial),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          CustomTextField(
            label: 'Confirm Password *',
            hint: 'Re-enter your password',
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryNavy),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Submit & Link Button
          CustomButton(
            text: 'Activate & Link My Account',
            isLoading: authProvider.status == AuthStatus.loading,
            onPressed: _handleFinalAccountBinding,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isVerified ? 'Setup Account Credentials' : 'Link MilkLink Profile'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: _isVerified ? _buildAccountSetupView() : _buildClaimVerificationView(),
        ),
      ),
    );
  }
}