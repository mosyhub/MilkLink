import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/wave_footer.dart';
import '../main_navigation_screen.dart';
import '../staff/staff_dashboard_screen.dart';

enum ClaimInputMethod { qrScan, manualToken }

class ClaimRecordScreen extends StatefulWidget {
  const ClaimRecordScreen({super.key});

  @override
  State<ClaimRecordScreen> createState() => _ClaimRecordScreenState();
}

class _ClaimRecordScreenState extends State<ClaimRecordScreen> {
  final _setupFormKey = GlobalKey<FormState>();

  // Verification state
  bool _isVerified = false;
  bool _isVerifying = false;
  Map<String, dynamic>? _verifiedData;
  String _activeToken = '';

  // Input method (QR vs manual token)
  ClaimInputMethod _inputMethod = ClaimInputMethod.qrScan;

  // Controllers
  final _tokenController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocus = FocusNode();

  // QR scanning
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

  // Obscure toggles
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Password checklist state
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecial = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPassword);
    _passwordFocus.addListener(() => setState(() {}));
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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _showToast(String message, {Color? bg}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bg ?? AppColors.primaryNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
        _showToast('No QR code found in that image. Try a clearer photo.', bg: AppColors.error);
        return;
      }

      await _handleVerifyToken(_extractToken(raw));
    } catch (_) {
      if (!mounted) return;
      _showToast('Could not read the selected image.', bg: AppColors.error);
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
  // VERIFY & BIND LOGIC
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _handleVerifyToken(String tokenToVerify) async {
    final clean = tokenToVerify.trim();
    if (clean.isEmpty) {
      _showToast('Please scan a QR code or enter a claim token.');
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
      _showToast(
        'Profile verified for ${result['details']?['fullName'] ?? 'User'}!',
        bg: AppColors.success,
      );
    } else {
      _showToast(
        authProvider.errorMessage ?? 'Invalid claim token or QR code',
        bg: AppColors.error,
      );
    }
  }

  Future<void> _handleFinalAccountBinding() async {
    if (!_setupFormKey.currentState!.validate()) return;

    if (!_isPasswordValid) {
      _showToast('Password does not meet security requirements.', bg: AppColors.error);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showToast('Passwords do not match', bg: AppColors.error);
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
      _showToast(
        'Account created and profile linked successfully!',
        bg: AppColors.success,
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
      _showToast(authProvider.errorMessage ?? 'Account binding failed', bg: AppColors.error);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI COMPONENTS
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        // Top Back Button
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(height: 8),

        // Small Logo
        Center(
          child: Image.asset(
            'assets/images/milklink_logo.png',
            height: 72,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),

        // Title
        Text(
          _isVerified ? 'Create Your Login' : 'Claim Your Account',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 4),

        // Subtitle
        Text(
          _isVerified
              ? 'Choose your username and password'
              : 'Scan your QR code or enter your token',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMethodSelector() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _buildMethodTab(ClaimInputMethod.qrScan, 'Scan QR'),
          _buildMethodTab(ClaimInputMethod.manualToken, 'Enter Token'),
        ],
      ),
    );
  }

  Widget _buildMethodTab(ClaimInputMethod method, String label) {
    final isSelected = _inputMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchMethod(method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraError(MobileScannerException error) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 36),
            const SizedBox(height: 10),
            Text(
              denied
                  ? 'Camera permission denied. Enable it in settings or upload a QR image.'
                  : 'Camera unavailable. Upload a QR image or enter token below.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildQrScannerView() {
    return Column(
      children: [
        // Camera Preview directly with rounded corners
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 240,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => _buildCameraError(error),
                ),
                // Clean white reticle
                Center(
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
                ),
                // Torch & Flip buttons
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Row(
                    children: [
                      _buildScannerIconButton(
                        icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                        onTap: () async {
                          try {
                            await _scannerController.toggleTorch();
                            if (mounted) setState(() => _torchOn = !_torchOn);
                          } catch (_) {}
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildScannerIconButton(
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
                // Loading overlay
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
        const SizedBox(height: 12),

        // Text link for gallery upload
        Center(
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: _isVerifying ? null : _pickQrFromGallery,
            child: const Text(
              'Upload QR image instead',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualTokenView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _tokenController,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Claim token',
            prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
            suffixIcon: IconButton(
              tooltip: 'Paste',
              icon: const Icon(Icons.content_paste, size: 20),
              onPressed: _pasteIntoTokenField,
            ),
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isVerifying
                ? null
                : () => _handleVerifyToken(_extractToken(_tokenController.text)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isVerifying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Verify Token',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildClaimVerificationView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMethodSelector(),
        const SizedBox(height: 20),
        if (_inputMethod == ClaimInputMethod.qrScan)
          _buildQrScannerView()
        else
          _buildManualTokenView(),
      ],
    );
  }

  Widget _buildPolicyInline() {
    if (!_passwordFocus.hasFocus && _passwordController.text.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        children: [
          _buildPolicyItem('8+ chars', _hasMinLength),
          _buildPolicyItem('A-Z', _hasUppercase),
          _buildPolicyItem('a-z', _hasLowercase),
          _buildPolicyItem('0-9', _hasDigit),
          _buildPolicyItem('symbol', _hasSpecial),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(String text, bool met) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: met ? AppColors.success : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildAccountSetupView() {
    final details = _verifiedData?['details'] as Map<String, dynamic>? ?? {};
    final fullName = details['fullName'] ?? 'Medical Member';
    final contactPhone = details['contactPhone'] ?? '—';
    final addressSnippet = details['addressSnippet'] ?? 'Pasig City';
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.status == AuthStatus.loading;

    return Form(
      key: _setupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Compact softBlue verified card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$contactPhone · $addressSnippet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    setState(() {
                      _isVerified = false;
                      _lastScannedValue = null;
                      _lastScannedAt = null;
                    });
                    if (_inputMethod == ClaimInputMethod.qrScan) _startScanner();
                  },
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Username
          TextFormField(
            controller: _usernameController,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Username *',
              prefixIcon: Icon(Icons.alternate_email, size: 20),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Username is required';
              if (v.trim().length < 4) return 'Username must be at least 4 characters';
              if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(v.trim())) {
                return 'Only alphanumeric, _, . or - allowed';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Email (optional)
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Email (optional)',
              prefixIcon: Icon(Icons.mail_outline, size: 20),
            ),
          ),
          const SizedBox(height: 12),

          // Password
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: _obscurePassword,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Password *',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (!_isPasswordValid) return 'Password does not meet requirements';
              return null;
            },
          ),

          // Password checklist inline
          _buildPolicyInline(),
          const SizedBox(height: 8),

          // Confirm Password
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Confirm Password *',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm password';
              if (v != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleFinalAccountBinding,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Activate Account',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final waveHeight = MediaQuery.sizeOf(context).height * 0.16;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Pinned bottom wave (behind content)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: WaveFooter(),
            ),

            // Main scrollable content
            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 12,
                  bottom: waveHeight + 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    _isVerified ? _buildAccountSetupView() : _buildClaimVerificationView(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
