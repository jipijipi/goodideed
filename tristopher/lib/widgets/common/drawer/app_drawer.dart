import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tristopher_app/constants/app_constants.dart';
import 'package:tristopher_app/providers/providers.dart';

// Helper function to handle navigation from drawer
void navigateFromDrawer(BuildContext context, String routeName) {
  Navigator.pop(context); // Close drawer first
  
  // Check if we're already on this route to avoid pushing the same screen
  final currentRoute = ModalRoute.of(context)?.settings.name;
  if (currentRoute != routeName) {
    // Use pushReplacementNamed to replace the current screen rather than stacking
    Navigator.of(context).pushReplacementNamed(routeName);
  }
}

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    
    return Drawer(
      backgroundColor: AppColors.backgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.accentColor,
              image: DecorationImage(
                image: AssetImage('assets/images/paper_texture.jpg'),
                fit: BoxFit.cover,
                opacity: 0.7,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tristopher',
                  style: AppTextStyles.header(size: 28),
                ),
                const SizedBox(height: 8),
                userAsync.when(
                  data: (user) => user != null
                      ? Text(
                          user.displayName ?? 'Guest',
                          style: AppTextStyles.userText(size: 18),
                        )
                      : const SizedBox(),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error loading user'),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: Text(
              'Chat',
              style: AppTextStyles.userText(size: 16, weight: FontWeight.bold),
            ),
            onTap: () => navigateFromDrawer(context, AppRoutes.mainChat),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(
              'Goal',
              style: AppTextStyles.userText(size: 16, weight: FontWeight.bold),
            ),
            onTap: () => navigateFromDrawer(context, AppRoutes.goalStake),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(
              'Account',
              style: AppTextStyles.userText(size: 16, weight: FontWeight.bold),
            ),
            onTap: () => navigateFromDrawer(context, AppRoutes.account),
          ),
          const Divider(),
          // You can add more items here as needed
          userAsync.when(
            data: (user) => user != null
                ? ListTile(
                    leading: const Icon(Icons.local_fire_department),
                    title: Text(
                      'Current Streak: ${user.streakCount ?? 0} days',
                      style: AppTextStyles.userText(size: 14),
                    ),
                  )
                : const SizedBox(),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          userAsync.when(
            data: (user) => user != null && (user.currentStakeAmount ?? 0) > 0
                ? ListTile(
                    leading: const Icon(Icons.attach_money),
                    title: Text(
                      'Current Stake: \$${user.currentStakeAmount?.toStringAsFixed(2) ?? '0.00'}',
                      style: AppTextStyles.userText(size: 14),
                    ),
                  )
                : const SizedBox(),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}
