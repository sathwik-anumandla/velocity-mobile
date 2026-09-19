import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'theme/velocity_colors.dart';
import 'views/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const VelocityApp(),
    ),
  );
}

class VelocityApp extends StatelessWidget {
  const VelocityApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<ChatProvider, ThemeMode>((p) => p.themeMode);

    return MaterialApp(
      title: 'Velocity',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Satoshi',
        scaffoldBackgroundColor: VelocityColors.lightBgPrimary,
        cardColor: VelocityColors.lightBgCard,
        dividerColor: Colors.transparent,
        scrollbarTheme: const ScrollbarThemeData(
          thumbVisibility: WidgetStatePropertyAll(false),
          trackVisibility: WidgetStatePropertyAll(false),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w500),
          bodySmall: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w500),
          labelLarge: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w500),
          labelMedium: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w500),
        ),
        colorScheme: const ColorScheme.light(
          primary: VelocityColors.lightTextPrimary,
          surface: VelocityColors.lightBgCard,
          surfaceContainer: VelocityColors.lightBgCardHover,
          outline: VelocityColors.lightBgPill,
          onSurface: VelocityColors.lightTextPrimary,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Satoshi',
        scaffoldBackgroundColor: VelocityColors.darkBgPrimary, // Pitch Black OLED
        cardColor: VelocityColors.darkBgCard,
        dividerColor: Colors.transparent,
        scrollbarTheme: const ScrollbarThemeData(
          thumbVisibility: WidgetStatePropertyAll(false),
          trackVisibility: WidgetStatePropertyAll(false),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w500),
          bodySmall: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w500),
          labelLarge: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w500),
          labelMedium: TextStyle(fontFamily: 'Satoshi', fontWeight: FontWeight.w500),
        ),
        colorScheme: const ColorScheme.dark(
          primary: VelocityColors.darkTextPrimary,
          surface: VelocityColors.darkBgCard,
          surfaceContainer: VelocityColors.darkBgCardHover,
          outline: VelocityColors.darkBgPill,
          onSurface: VelocityColors.darkTextPrimary,
        ),
      ),
      home: const MainScreen(),
    );
  }
}
