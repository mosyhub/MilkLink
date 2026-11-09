import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/wave_footer.dart';
import '../main_navigation_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

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
    final success = await authProvider.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      middleName: _middleNameController.text.trim().isNotEmpty ? _middleNameController.text.trim() : null,
      username: _usernameController.text.trim().toLowerCase(),
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim().toLowerCase() : null,
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Welcome to MilkLink.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registration failed. Please check your information.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
      ),
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: WaveFooter(),
            ),
            SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Heading & Subtitle
                    const Text(
                      'Join MilkLink',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Access screening appointments and milk requests',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),

                    CustomTextField(
                      hint: 'First Name *',
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      controller: _firstNameController,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter first name' : null,
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      hint: 'Middle Name (Optional)',
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      controller: _middleNameController,
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      hint: 'Last Name *',
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      controller: _lastNameController,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter last name' : null,
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      hint: 'Username * (min 4 chars)',
                      prefixIcon: const Icon(Icons.alternate_email, size: 20),
                      controller: _usernameController,
                      validator: (v) {
                        if (v == null || v.trim().length < 4) return 'Username must be at least 4 characters';
                        if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(v.trim())) {
                          return 'Alphanumeric, underscores, hyphens, dots only';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      hint: 'Email (Optional)',
                      prefixIcon: const Icon(Icons.mail_outline, size: 20),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      hint: 'Contact Number * (e.g. 09123456789)',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter contact number';
                        if (v.trim().length < 11) return 'Please enter valid 11-digit phone number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      hint: 'Password *',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 8) return 'Password must be at least 8 characters';
                        if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Must contain 1 uppercase letter';
                        if (!RegExp(r'[a-z]').hasMatch(v)) return 'Must contain 1 lowercase letter';
                        if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must contain 1 number';
                        if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(v)) return 'Must contain 1 special character';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      hint: 'Confirm Password *',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please confirm your password' : null,
                    ),
                    const SizedBox(height: 24),

                    CustomButton(
                      text: 'Create Account',
                      isLoading: authProvider.status == AuthStatus.loading,
                      onPressed: _handleRegister,
                    ),
                    const SizedBox(height: 12),

                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Already have an account? Sign In'),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
