import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../providers/app_providers.dart';

class GlobalAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool showDrawer;
  final bool showMenu;
  final bool centerTitle;
  final Color? backgroundColor;
  final List<Widget>? actions;

  const GlobalAppBar({
    super.key,
    required this.title,
    this.showDrawer = false,
    this.showMenu = true,
    this.centerTitle = false,
    this.backgroundColor,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUrdu = ref.watch(isUrduProvider);

    return AppBar(
      title: Text(title),
      leading: showDrawer
          ? Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            )
          : null, // Let Flutter insert the default BackButton if needed
      actions: [
        if (actions != null) ...actions!,
        // Dark / Light mode toggle
        IconButton(
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
          ),
          tooltip: isUrdu ? 'تھیم تبدیل کریں' : 'Toggle Theme',
          onPressed: () {
            final current = ref.read(themeModeProvider);
            ref.read(themeModeProvider.notifier).state =
                current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
          },
        ),
        // Language toggle: Urdu ↔ English
        TextButton.icon(
          icon: Icon(Icons.translate_rounded,
              size: 18, color: Theme.of(context).colorScheme.onSurface),
          label: Text(
            isUrdu ? 'EN' : 'اردو',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          onPressed: () {
            ref.read(isUrduProvider.notifier).state = !isUrdu;
            AppStrings.toggleLanguage();
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
