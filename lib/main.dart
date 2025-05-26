import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';
import 'landing_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'artvault_screen.dart';
import 'notifications_screen.dart';
import 'pinboards.dart';
import 'profile.dart';
import 'supabase_service.dart';
import 'package:logging/logging.dart';
import 'createpost_screen.dart';
import 'edit_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    if (record.level.value >= Logger.root.level.value) {
      debugPrint(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
      );
    }
  });

  // Initialize Supabase
  await SupabaseService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StudHue',
      theme: ThemeData(primarySwatch: Colors.blue),
      // Set initial screen
      initialRoute: '/welcome',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LandingScreen(),
        '/log': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
        '/vault': (context) => const ArtVault(),
        '/profile': (context) => const ProfileScreen(),
        '/pinboards': (context) => const PinboardsScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/createpost': (context) => const CreatePostScreen(),
        '/edit_profile': (context) => const EditProfileScreen(),
      },
      // We don't add user_profile to routes because it needs a username parameter
      // It will be accessed using Navigator.push instead
    );
  }
}
