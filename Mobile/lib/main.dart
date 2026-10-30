import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/constants/api_constants.dart';
import 'core/constants/app_colors.dart';
import 'core/utils/session_manager.dart';
import 'providers/auth_provider.dart';
import 'providers/donor_provider.dart';
import 'providers/events_provider.dart';
import 'providers/articles_provider.dart';
import 'providers/notifications_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load custom base URL if configured by user
  final customUrl = await SessionManager.getCustomBaseUrl();
  if (customUrl != null && customUrl.isNotEmpty) {
    ApiConstants.baseUrl = customUrl;
  }

  runApp(const TchmbApp());
}

class TchmbApp extends StatelessWidget {
  const TchmbApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DonorProvider()),
        ChangeNotifierProvider(create: (_) => EventsProvider()),
        ChangeNotifierProvider(create: (_) => ArticlesProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
      ],
      child: MaterialApp(
        title: 'TCHMB Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryNavy,
            primary: AppColors.primaryNavy,
            secondary: AppColors.accentPink,
            surface: AppColors.surface,
          ),
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryNavy,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNavy,
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

