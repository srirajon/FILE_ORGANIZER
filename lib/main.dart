import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure system navigation and status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: WhatsAppTheme.darkSurface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const FileOrganizerApp());
}

class FileOrganizerApp extends StatelessWidget {
  const FileOrganizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Organizer',
      debugShowCheckedModeBanner: false,
      theme: WhatsAppTheme.lightTheme,
      darkTheme: WhatsAppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to sleek WhatsApp dark mode
      home: const HomeScreen(),
    );
  }
}
