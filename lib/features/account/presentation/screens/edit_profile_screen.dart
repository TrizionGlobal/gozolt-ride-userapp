import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import 'package:universal_io/io.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../providers/account_providers.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../auth/data/models/country_code.dart';
import '../../../auth/presentation/widgets/country_code_picker.dart';
import '../../../auth/presentation/widgets/phone_input_field.dart';
import '../../../../core/network/api_exception.dart';
import 'package:dio/dio.dart';
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  CountryCode _selectedCountry = supportedCountryCodes.first;
  String? _phoneError;
  bool _isLoading = false;
  bool _initialized = false;
  final _picker = ImagePicker();
  String? _avatarPath;
  bool _removeAvatar = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
        
        if (profile.phone != null && profile.phone!.isNotEmpty) {
          final phoneStr = profile.phone!;
          bool matched = false;
          // Sort by length descending to match +356 before +35 etc.
          final sortedCodes = List<CountryCode>.from(supportedCountryCodes)
            ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
            
          for (final country in sortedCodes) {
            if (phoneStr.startsWith(country.dialCode)) {
              _selectedCountry = country;
              _phoneController.text = phoneStr.substring(country.dialCode.length);
              matched = true;
              break;
            }
          }
          if (!matched) {
            _phoneController.text = phoneStr;
          }
        }
        
        _initialized = true;
      }
    });

    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, 8 + statusBarHeight, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFD4A843), Color(0xFFF5C518)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.backgroundDark.withOpacity(0.15),
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

          // ── Form ───────────────────────────────────
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                // Avatar
                Center(
                  child: Builder(
                    builder: (context) {
                      final profile = profileAsync.valueOrNull;
                      
                      if (profile == null && profileAsync.isLoading) {
                        return const ShimmerWrap(
                          child: ShimmerCircle(radius: 44),
                        );
                      }
                      
                      return Stack(
                        children: [
                          _avatarPath != null
                              ? CircleAvatar(
                                  radius: 44,
                                  backgroundImage:
                                      FileImage(File(_avatarPath!)),
                                  backgroundColor: AppColors.primaryGold
                                      .withOpacity(0.15),
                                )
                              : (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty && !_removeAvatar)
                                  ? ClipOval(
                                      child: Image.network(
                                        ApiConstants.fullUrl(profile.avatarUrl!),
                                        width: 88,
                                        height: 88,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(profile, 88),
                                      ),
                                    )
                                  : _buildAvatarPlaceholder(profile, 88),
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
                                      color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                ),
                                child: Icon(Icons.camera_alt,
                                    size: 16,
                                    color: Theme.of(context).scaffoldBackgroundColor),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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

                // Phone
                _inputLabel('Phone'),
                const SizedBox(height: 6),
                PhoneInputField(
                  controller: _phoneController,
                  selectedCountry: _selectedCountry,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.inputDark : Colors.grey[200],
                  onCountryTap: () {
                    CountryCodePicker.show(
                      context,
                      selected: _selectedCountry,
                      onSelected: (country) {
                        setState(() => _selectedCountry = country);
                      },
                    );
                  },
                  errorText: _phoneError,
                ),

                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                      disabledBackgroundColor:
                          AppColors.primaryGold.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).scaffoldBackgroundColor),
                          )
                        : Text('Save Changes',
                            style: AppTextStyles.button),
                  ),
                ),
              ]),
            ),
          ),
        ],
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
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
        fontSize: 13,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        hintStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.inputDark : Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGold),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _showAvatarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
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
                  color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
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
                  setState(() {
                    _avatarPath = null;
                    _removeAvatar = true;
                  });
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
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 50,
      );
      if (picked != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: picked.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Photo',
              toolbarColor: AppColors.primaryGold,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Photo',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );
        if (croppedFile != null) {
          final file = File(croppedFile.path);
          final fileSize = await file.length();
          if (fileSize > 5 * 1024 * 1024) {
            _snackBar('Image size must be less than 5MB', isError: true);
            return;
          }
          setState(() {
            _avatarPath = croppedFile.path;
            _removeAvatar = false;
          });
        }
      }
    } catch (e) {
      _snackBar(
          'Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}',
          isError: true);
    }
  }

  void _snackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!InputValidators.isValidName(_firstNameController.text)) {
      _snackBar('Please enter a valid first name', isError: true);
      return;
    }
    if (!InputValidators.isValidName(_lastNameController.text)) {
      _snackBar('Please enter a valid last name', isError: true);
      return;
    }
    
    final phoneDigits = _phoneController.text.trim();
    if (phoneDigits.isNotEmpty && (phoneDigits.length < 7 || phoneDigits.length > 12)) {
      setState(() => _phoneError = 'Please enter a valid phone number');
      _snackBar('Please enter a valid phone number', isError: true);
      return;
    } else {
      setState(() => _phoneError = null);
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final ds = ref.read(accountRemoteDatasourceProvider);

      // Handle avatar updates
      if (_removeAvatar) {
        await ds.deleteAvatar();
      } else if (_avatarPath != null) {
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
      
      if (phoneDigits.isNotEmpty) {
        updates['phone'] = '${_selectedCountry.dialCode}$phoneDigits';
      }

      await ds.updateProfile(updates);

      // Refresh the profile data so home screen picks up changes
      ref.invalidate(userProfileProvider);

      if (mounted) {
        _snackBar('Profile updated successfully');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Failed to update profile. Please try again.';
        if (e is ApiException) {
          msg = e.userMessage;
        } else if (e is DioException) {
          if (e.error is ApiException) {
            msg = (e.error as ApiException).userMessage;
          } else {
            msg = ApiException.fromDioException(e).userMessage;
          }
        } else {
          msg = e.toString();
        }
        _snackBar(msg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Widget _buildAvatarPlaceholder(dynamic profile, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryGold.withOpacity(0.15),
      ),
      child: Center(
        child: Text(
          profile?.initials ?? 'U',
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.primaryGold,
          ),
        ),
      ),
    );
  }
}
