import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/wave_footer.dart';
import 'auth/login_screen.dart';
import 'main_navigation_screen.dart';
import 'staff/staff_dashboard_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.init();
    if (!mounted) return;

    Widget next;
    if (authProvider.isAuthenticated) {
      final user = authProvider.user;
      if (user != null && user.isAdmin) {
        next = const AdminDashboardScreen();
      } else if (user != null && user.isStaff) {
        next = const StaffDashboardScreen();
      } else {
        next = const MainNavigationScreen();
      }
    } else {
      next = const LoginScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Bottom wave graphic
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: WaveFooter(),
            ),
            // Centered logo + tagline with subtle entrance animation
            SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    final scale = 0.92 + (0.08 * value);
                    return Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: scale,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/milklink_logo.png',
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pasig City Human Milk Bank',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
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
