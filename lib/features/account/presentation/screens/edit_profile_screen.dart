import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import 'package:universal_io/io.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/account_providers.dart';
import '../../../home/presentation/providers/home_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _initialized = false;
  final _picker = ImagePicker();
  String? _avatarPath;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    // Initialize controllers once
    profileAsync.whenData((profile) {
      if (!_initialized) {
        _firstNameController.text = profile.firstName ?? '';
        _lastNameController.text = profile.lastName ?? '';
        _emailController.text = profile.email ?? '';
        _initialized = true;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ─────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFD4A843), Color(0xFFF5C518)],
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.backgroundDark
                                .withOpacity(0.15),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: AppColors.backgroundDark, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Edit Profile',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.backgroundDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Form ───────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Avatar
                Center(
                  child: profileAsync.when(
                    loading: () => const ShimmerWrap(
                      child: ShimmerCircle(radius: 44),
                    ),
                    error: (context, error) => const SizedBox.shrink(),
                    data: (profile) => Stack(
                      children: [
                        _avatarPath != null
                            ? CircleAvatar(
                                radius: 44,
                                backgroundImage:
                                    FileImage(File(_avatarPath!)),
                                backgroundColor: AppColors.primaryGold
                                    .withOpacity(0.15),
                              )
                            : (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                                ? CircleAvatar(
                                    radius: 44,
                                    backgroundImage: NetworkImage(ApiConstants.fullUrl(profile.avatarUrl!)),
                                    backgroundColor: AppColors.primaryGold
                                        .withOpacity(0.15),
                                  )
                                : CircleAvatar(
                                    radius: 44,
                                    backgroundColor: AppColors.primaryGold
                                        .withOpacity(0.15),
                                    child: Text(
                                      profile.initials,
                                      style:
                                          AppTextStyles.headlineLarge.copyWith(
                                        color: AppColors.primaryGold,
                                      ),
                                    ),
                                  ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _showAvatarOptions(context),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.backgroundDark, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt,
                                  size: 16,
                                  color: AppColors.backgroundDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // First Name
                _inputLabel('First Name'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _firstNameController,
                  hint: 'Enter first name',
                  inputFormatters: [
                    InputValidators.nameInputFormatter,
                    LengthLimitingTextInputFormatter(50),
                  ],
                ),
                const SizedBox(height: 16),

                // Last Name
                _inputLabel('Last Name'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _lastNameController,
                  hint: 'Enter last name',
                  inputFormatters: [
                    InputValidators.nameInputFormatter,
                    LengthLimitingTextInputFormatter(50),
                  ],
                ),
                const SizedBox(height: 16),

                // Email
                _inputLabel('Email'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _emailController,
                  hint: 'Enter email',
                  keyboardType: TextInputType.emailAddress,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(100),
                  ],
                ),
                const SizedBox(height: 16),

                // Phone (read-only)
                _inputLabel('Phone'),
                const SizedBox(height: 6),
                profileAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (context, error) => const SizedBox.shrink(),
                  data: (profile) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.inputDark.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.phone ?? 'Not set',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const Icon(Icons.lock_outline,
                            color: AppColors.textMuted, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Phone number cannot be changed',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.backgroundDark,
                      disabledBackgroundColor:
                          AppColors.primaryGold.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.backgroundDark),
                          )
                        : const Text('Save Changes',
                            style: AppTextStyles.button),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelLarge.copyWith(
        color: AppColors.textSecondary,
        fontSize: 13,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.inputDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGold),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _showAvatarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt,
                    color: AppColors.primaryGold),
                title: Text('Take Photo', style: AppTextStyles.bodyMedium),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: AppColors.primaryGold),
                title:
                    Text('Choose from Gallery', style: AppTextStyles.bodyMedium),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('Remove Photo',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _avatarPath = null);
                  _snackBar('Photo removed');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _avatarPath = picked.path);
        _snackBar('Photo updated');
      }
    } catch (e) {
      _snackBar(
          'Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}');
    }
  }

  void _snackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg), backgroundColor: AppColors.surfaceDark),
    );
  }

  Future<void> _saveProfile() async {
    if (!InputValidators.isValidName(_firstNameController.text)) {
      _snackBar('Please enter a valid first name');
      return;
    }
    if (!InputValidators.isValidName(_lastNameController.text)) {
      _snackBar('Please enter a valid last name');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final ds = ref.read(accountRemoteDatasourceProvider);

      // Upload avatar if user selected a new image
      if (_avatarPath != null) {
        await ds.uploadAvatar(_avatarPath!);
      }

      // Update profile fields
      final updates = <String, dynamic>{
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
      };
      final email = _emailController.text.trim();
      if (email.isNotEmpty) {
        updates['email'] = email;
      }

      await ds.updateProfile(updates);

      // Refresh the profile data so home screen picks up changes
      ref.invalidate(userProfileProvider);

      if (mounted) {
        _snackBar('Profile updated successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _snackBar('Failed to update profile: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
