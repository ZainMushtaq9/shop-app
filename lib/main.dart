import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'l10n/app_strings.dart';
import 'providers/app_providers.dart';

import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize desktop SQLite compatibility
  if (!kIsWeb && (io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    const ProviderScope(
      child: ShopApp(),
    ),
  );
}

class ShopApp extends ConsumerWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isUrdu = ref.watch(isUrduProvider);

    return MaterialApp(
      title: 'Super Business Shop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const LoginScreen(),
      // Directionality for Urdu (RTL) support
      builder: (context, child) {
        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
    );
  }
}
