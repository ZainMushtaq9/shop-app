import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'l10n/app_strings.dart';
import 'providers/app_providers.dart';

import 'package:flutter/foundation.dart';
import 'screens/auth/login_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/app_shell.dart';
import 'screens/customer_portal/portal_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Backend
  await Supabase.initialize(
    url: 'https://wzypjlnexfmkghwmhyrf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind6eXBqbG5leGZta2dod21oeXJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMzMDQ5MTEsImV4cCI6MjA4ODg4MDkxMX0.iM1faqxzH6sA-JhvweKHWDNqDxLqvsDaHpaFRi1LdEM',
  );

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
      themeMode: ThemeMode.light, // Force light mode as requested
      home: const LoginScreen(),
      // Directionality for Urdu (RTL) support
      builder: (context, child) {
        return Directionality(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          child: Semantics(
            // Enable semantics to help Playwright find text inputs
            scopesRoute: true,
            namesRoute: true,
            child: child!,
          ),
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/dashboard': (context) => const AppShell(),
        '/pos': (context) => const AppShell(),
        '/inventory': (context) => const AppShell(),
        '/customers': (context) => const AppShell(),
        '/reports': (context) => const AppShell(),
        '/settings': (context) => const AppShell(),
        '/customer/login': (context) => const PortalLoginScreen(),
      },
    );
  }
}
