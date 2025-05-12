import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tristopher_app/constants/app_constants.dart';
import 'package:tristopher_app/models/user_model.dart';
import 'package:tristopher_app/providers/providers.dart';
import 'package:tristopher_app/widgets/common/drawer/app_drawer.dart';
import 'package:tristopher_app/widgets/common/paper_background_widget.dart';

class GoalScreen extends ConsumerStatefulWidget {
  const GoalScreen({super.key});

  @override
  ConsumerState<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends ConsumerState<GoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goalController = TextEditingController();
  final _stakeController = TextEditingController();
  String? _selectedAntiCharityId;
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7]; // Default all days
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _goalController.dispose();
    _stakeController.dispose();
    super.dispose();
  }

  // Load user data
  Future<void> _loadUserData() async {
    final userAsync = ref.read(userProvider);
    
    userAsync.when(
      data: (user) {
        if (user != null) {
          // Populate form fields with existing data
          _goalController.text = user.goalTitle ?? '';
          _stakeController.text = user.currentStakeAmount?.toString() ?? '0';
          _selectedAntiCharityId = user.antiCharityChoice;
          _selectedDays = user.goalDaysOfWeek ?? [1, 2, 3, 4, 5, 6, 7];
        }
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }

  // Save user data
  Future<void> _saveUserData() async {
    if (_formKey.currentState?.validate() != true) return;
    
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
        goalTitle: _goalController.text,
        goalDaysOfWeek: _selectedDays,
        currentStakeAmount: double.tryParse(_stakeController.text) ?? 0,
        antiCharityChoice: _selectedAntiCharityId ?? AntiCharities.options[0]['id'],
      );
      
      // Save changes
      await userService.updateUser(updatedUser);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal and stake updated')),
        );
        
        // Refresh user data
        ref.invalidate(userProvider);
        
        // Navigate back
        Navigator.of(context).pop();
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
    
    return PaperBackgroundScaffold(
      appBar: AppBar(
        title: Text(
          'Your Goal & Stake',
          style: AppTextStyles.header(size: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Add hamburger menu icon
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      // Add drawer menu
      drawer: const AppDrawer(),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }
          return _buildForm(user);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
    );
  }

  Widget _buildForm(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Daily Goal',
              style: AppTextStyles.header(size: 18),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _goalController,
              decoration: InputDecoration(
                hintText: 'Enter your "Just One Thing"',
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
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: Colors.black.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(
                    color: AppColors.accentColor,
                  ),
                ),
              ),
              style: AppTextStyles.userText(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a goal';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            Text(
              'Days of the Week',
              style: AppTextStyles.header(size: 18),
            ),
            const SizedBox(height: 8),
            _buildDaysOfWeekSelection(),
            const SizedBox(height: 24),
            
            Text(
              'Your Stake Amount',
              style: AppTextStyles.header(size: 18),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _stakeController,
              decoration: InputDecoration(
                hintText: 'Enter amount (e.g., 10.00)',
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
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: Colors.black.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(
                    color: AppColors.accentColor,
                  ),
                ),
                prefixText: '\$ ',
                prefixStyle: AppTextStyles.userText(),
              ),
              style: AppTextStyles.userText(),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            Text(
              'Anti-Charity Selection',
              style: AppTextStyles.header(size: 18),
            ),
            const SizedBox(height: 8),
            _buildAntiCharitySelection(user.antiCharityChoice),
            const SizedBox(height: 32),
            
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: AppTextStyles.buttonText(),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysOfWeekSelection() {
    final days = [
      {'day': 1, 'label': 'M'},
      {'day': 2, 'label': 'T'},
      {'day': 3, 'label': 'W'},
      {'day': 4, 'label': 'T'},
      {'day': 5, 'label': 'F'},
      {'day': 6, 'label': 'S'},
      {'day': 7, 'label': 'S'},
    ];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: days.map((day) {
        final dayNumber = day['day'] as int;
        final isSelected = _selectedDays.contains(dayNumber);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                // Prevent removing all days
                if (_selectedDays.length > 1) {
                  _selectedDays.remove(dayNumber);
                }
              } else {
                _selectedDays.add(dayNumber);
              }
            });
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.accentColor : Colors.transparent,
              border: Border.all(
                color: isSelected 
                    ? AppColors.accentColor 
                    : Colors.black.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                day['label'] as String,
                style: AppTextStyles.userText().copyWith(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAntiCharitySelection(String? currentSelection) {
    return Column(
      children: AntiCharities.options.map((charity) {
        final isSelected = charity['id'] == (_selectedAntiCharityId ?? currentSelection);
        
        return RadioListTile<String>(
          title: Text(
            charity['name']!,
            style: AppTextStyles.userText(
              weight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            charity['description']!,
            style: AppTextStyles.userText(size: 14).copyWith(
              color: Colors.black.withOpacity(0.7),
            ),
          ),
          value: charity['id']!,
          groupValue: _selectedAntiCharityId ?? currentSelection,
          onChanged: (value) {
            setState(() {
              _selectedAntiCharityId = value;
            });
          },
          activeColor: AppColors.accentColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(
              color: isSelected 
                  ? AppColors.accentColor 
                  : Colors.black.withOpacity(0.2),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          tileColor: Colors.white,
        );
      }).toList(),
    );
  }
}
