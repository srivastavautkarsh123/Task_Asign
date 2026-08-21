import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:assignment/core/constants/app_colors.dart';
import 'package:assignment/presentation/providers/auth_provider.dart';
import 'package:assignment/presentation/providers/debug_settings_provider.dart';
import 'package:assignment/presentation/providers/theme_provider.dart';
import 'package:assignment/presentation/widgets/app_button.dart';
import 'package:assignment/presentation/screens/auth/login_screen.dart';

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final debugSettings = ref.watch(debugSettingsProvider);
    final debugNotifier = ref.read(debugSettingsProvider.notifier);
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    if (authState is! Authenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final session = authState.session;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User & Org Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      backgroundImage: session.user.avatarUrl != null ? NetworkImage(session.user.avatarUrl!) : null,
                      child: session.user.avatarUrl == null
                          ? Text(session.user.name[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(session.user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(session.user.email, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.business_rounded, size: 16),
                          label: Text('Org: ${session.orgId}'),
                        ),
                        Chip(
                          avatar: const Icon(Icons.admin_panel_settings_rounded, size: 16),
                          label: Text('Role: ${session.isAdmin ? "org_admin" : "member"}'),
                          backgroundColor: session.isAdmin ? AppColors.primary.withValues(alpha: 0.15) : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Appearance & Theme Section
            const Text(
              'Appearance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              child: SwitchListTile(
                secondary: Icon(
                  isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: isDarkMode ? AppColors.primaryLight : AppColors.warning,
                ),
                title: const Text('Dark Mode'),
                subtitle: Text(isDarkMode ? 'Dark theme enabled' : 'Light theme enabled'),
                value: isDarkMode,
                onChanged: (val) {
                  ref.read(themeModeProvider.notifier).toggleTheme(val);
                },
              ),
            ),
            const SizedBox(height: 20),

            // Token Expiration & Refresh Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.key_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text('Simulated JWT Session Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Access Token Expiry: ${DateFormat('hh:mm:ss a').format(session.accessTokenExpiry)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Auto Refresh Timer: Active (Refreshes automatically before 15m expiration)',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: authState.isRefreshingToken
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Simulate Manual Token Refresh Now'),
                      onPressed: authState.isRefreshingToken
                          ? null
                          : () async {
                              await ref.read(authStateProvider.notifier).manualTokenRefresh();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Issued new JWT access_token & updated session!')),
                                );
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Evaluator Debug Control Panel
            const Text(
              'Evaluator Debug Control Panel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Use these toggles to test app resiliency, error UI, offline caching, and network delay.',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 12),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.wifi_off_rounded, color: AppColors.warning),
                    title: const Text('Simulate Offline Mode'),
                    subtitle: const Text('Blocks calls and demonstrates cached data & stale banner'),
                    value: debugSettings.simulateOffline,
                    onChanged: (val) => debugNotifier.toggleOffline(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.search_off_rounded, color: AppColors.error),
                    title: const Text('Simulate 404 Not Found'),
                    subtitle: const Text('Triggers 404 exception on mock repository requests'),
                    value: debugSettings.simulate404,
                    onChanged: (val) => debugNotifier.toggle404(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.timer_off_rounded, color: AppColors.error),
                    title: const Text('Simulate Network Timeout'),
                    subtitle: const Text('Triggers 408 timeout exception'),
                    value: debugSettings.simulateTimeout,
                    onChanged: (val) => debugNotifier.toggleTimeout(val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.rule_rounded, color: AppColors.error),
                    title: const Text('Simulate Validation Error'),
                    subtitle: const Text('Triggers 422 payload validation error'),
                    value: debugSettings.simulateValidationError,
                    onChanged: (val) => debugNotifier.toggleValidationError(val),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Artificial Network Latency', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('${debugSettings.artificialDelayMs} ms', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                        Slider(
                          min: 0,
                          max: 1500,
                          divisions: 15,
                          label: '${debugSettings.artificialDelayMs} ms',
                          value: debugSettings.artificialDelayMs.toDouble(),
                          onChanged: (val) => debugNotifier.setDelay(val.toInt()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            AppButton(
              text: 'Sign Out',
              type: AppButtonType.danger,
              icon: Icons.logout_rounded,
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
