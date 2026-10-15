import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/app_provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/timetable_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/timetable_studio_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Web with real Firebase project credentials
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Retrieve Gemini Key injected via compile-time environment flags
  const geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_GEMINI_API_KEY_FALLBACK',
  );

  final authProvider = AuthProvider();
  final timetableProvider = TimetableProvider(geminiApiKey: geminiApiKey);

  runApp(
    AscProvider<AuthProvider>(
      notifier: authProvider,
      child: AscProvider<TimetableProvider>(
        notifier: timetableProvider,
        child: const AscGenAiApp(),
      ),
    ),
  );
}

class AscGenAiApp extends StatelessWidget {
  const AscGenAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenAI aSc Timetable Web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF090D16),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      home: const AuthGate(),
    );
  }
}

/// Dynamic Authentication Gate routing between Glassmorphic Auth and Studio
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.currentUser != null) {
      return const TimetableStudioScreen();
    }
    return const AuthScreen();
  }
}
