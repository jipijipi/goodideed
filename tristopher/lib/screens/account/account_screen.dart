import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tristopher_app/constants/app_constants.dart';
import 'package:tristopher_app/providers/providers.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _nameController = TextEditingController();
  bool _notificationsEnabled = true;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Load user data
  Future<void> _loadUserData() async {
    final userAsync = ref.read(userProvider);
    
    userAsync.when(
      data: (user) {
        if (user != null) {
          // Populate form fields with existing data
          _nameController.text = user.displayName ?? '';
          
          if (user.preferences != null && 
              user.preferences!.containsKey('notificationsEnabled')) {
            setState(() {
              _notificationsEnabled = user.preferences!['notificationsEnabled'] as bool;
            });
          }
        }
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }

  // Save display name
  Future<void> _saveDisplayName() async {
    if (_nameController.text.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userService = ref.read(userServiceProvider);
      final currentUser = await userService.getCurrentUser();
      
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not found')),
        );
        return;
      }
      
      // Create updated user
      final updatedUser = currentUser.copyWith(
        displayName: _nameController.text,
      );
      
      // Save changes
      await userService.updateUser(updatedUser);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Display name updated')),
        );
        
        setState(() {
          _isEditing = false;
        });
        
        // Refresh user data
        ref.invalidate(userProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Update notification settings
  Future<void> _updateNotificationSettings(bool value) async {
    setState(() {
      _notificationsEnabled = value;
      _isLoading = true;
    });
    
    try {
      final userService = ref.read(userServiceProvider);
      final currentUser = await userService.getCurrentUser();
      
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not found')),
        );
        return;
      }
      
      // Update preferences
      final preferences = currentUser.preferences ?? {};
      preferences['notificationsEnabled'] = value;
      
      // Create updated user
      final updatedUser = currentUser.copyWith(
        preferences: preferences,
      );
      
      // Save changes
      await userService.updateUser(updatedUser);
      
      // Refresh user data
      ref.invalidate(userProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Reset user data (for debugging)
  Future<void> _resetUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userService = ref.read(userServiceProvider);
      final currentUser = await userService.getCurrentUser();
      
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not found')),
        );
        return;
      }
      
      // Create a new user with same ID but reset data
      final newUser = await userService.createUser(currentUser.uid);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User data reset')),
        );
        
        // Navigate back to splash for onboarding
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.splash,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Account & Settings',
          style: AppTextStyles.header(size: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          image: DecorationImage(
            image: const AssetImage('assets/images/paper_texture.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.8),
              BlendMode.dstATop,
            ),
          ),
        ),
        child: userAsync.when(
          data: (user) {
            if (user == null) {
              return const Center(child: Text('User not found'));
            }
            return _buildSettings(user);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error: ${error.toString()}'),
          ),
        ),
      ),
    );
  }

  Widget _buildSettings(user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Section
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: BorderSide(color: Colors.black.withOpacity(0.2)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Display Name',
                        style: AppTextStyles.header(size: 16),
                      ),
                      const Spacer(),
                      if (!_isEditing)
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.accentColor),
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Enter your name',
                              hintStyle: AppTextStyles.userText().copyWith(
                                color: Colors.black.withOpacity(0.5),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(
                                  color: Colors.black.withOpacity(0.2),
                                ),
                              ),
                            ),
                            style: AppTextStyles.userText(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.check, color: AppColors.accentColor),
                          onPressed: _saveDisplayName,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black54),
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              _nameController.text = user.displayName ?? '';
                            });
                          },
                        ),
                      ],
                    )
                  else
                    Text(
                      user.displayName ?? 'Not set',
                      style: AppTextStyles.userText(),
                    ),
                  const Divider(height: 32),
                  Text(
                    'Current Streak',
                    style: AppTextStyles.header(size: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.streakCount} days',
                    style: AppTextStyles.userText(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Longest Streak',
                    style: AppTextStyles.header(size: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.longestStreak} days',
                    style: AppTextStyles.userText(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Preferences Section
          Text(
            'Preferences',
            style: AppTextStyles.header(size: 18),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: BorderSide(color: Colors.black.withOpacity(0.2)),
            ),
            color: Colors.white,
            child: SwitchListTile(
              title: Text(
                'Notifications',
                style: AppTextStyles.userText(),
              ),
              subtitle: Text(
                'Enable daily check-in reminders',
                style: AppTextStyles.userText(size: 14).copyWith(
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
              value: _notificationsEnabled,
              onChanged: _isLoading ? null : _updateNotificationSettings,
              activeColor: AppColors.accentColor,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // About Section
          Text(
            'About',
            style: AppTextStyles.header(size: 18),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: BorderSide(color: Colors.black.withOpacity(0.2)),
            ),
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    'Privacy Policy',
                    style: AppTextStyles.userText(),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy Policy not available in demo')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(
                    'Terms of Service',
                    style: AppTextStyles.userText(),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Terms of Service not available in demo')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(
                    'Version',
                    style: AppTextStyles.userText(),
                  ),
                  trailing: Text(
                    '1.0.0',
                    style: AppTextStyles.userText(),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Reset Button (for debugging)
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      'Reset User Data?',
                      style: AppTextStyles.header(size: 18),
                    ),
                    content: Text(
                      'This will clear all your data and restart onboarding. This action cannot be undone.',
                      style: AppTextStyles.userText(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: AppTextStyles.userText().copyWith(
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _resetUserData();
                        },
                        child: Text(
                          'Reset',
                          style: AppTextStyles.userText().copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(
                'Reset App Data',
                style: AppTextStyles.userText().copyWith(
                  color: Colors.red,
                ),
              ),
            ),
          ),
          
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
