import 'package:universal_io/io.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/providers/dio_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../core/widgets/gozolt_button.dart';
import '../../data/models/complete_profile_request.dart';
import '../../data/models/country_code.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../../../../core/providers/storage_provider.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _homeAddressController = TextEditingController();
  final _cityController = TextEditingController();

  String _selectedLanguage = 'en';
  String _selectedCountry = 'Malta';
  bool _termsAccepted = false;
  bool _marketingConsent = false;
  File? _profileImage;

  bool get _isFormFilled =>
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty &&
      _cityController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _homeAddressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _onContinue() {
    HapticFeedback.mediumImpact();
    if (!_termsAccepted) {
      _showTermsDialog();
      return;
    }
    if (!_isFormFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in your name and city.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!InputValidators.isValidName(_firstNameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid first name.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!InputValidators.isValidName(_lastNameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid last name.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    

    final request = CompleteProfileRequest(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      language: _selectedLanguage,
      country: _getCountryCode(_selectedCountry),
      city: _cityController.text.trim(),
      homeAddress: _homeAddressController.text.trim().isNotEmpty
          ? _homeAddressController.text.trim()
          : null,
      termsAccepted: _termsAccepted,
      marketingConsent: _marketingConsent,
    );

    ref.read(authProvider.notifier).completeProfile(request);
  }

  void _onSkip() {
    if (!_termsAccepted) {
      _showTermsDialog();
      return;
    }
    context.goNamed(RouteNames.home);
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text(
          'Accept Terms',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'You must accept the Terms of Service & Privacy Policy to continue.',
          style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'OK',
              style: AppTextStyles.titleSmall.copyWith(color: AppColors.primaryGold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
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
              Text('Choose Photo', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt,
                    color: AppColors.primaryGold),
                title: Text('Take a Photo',
                    style: AppTextStyles.bodyMedium),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: AppColors.primaryGold),
                title: Text('Choose from Gallery',
                    style: AppTextStyles.bodyMedium),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _profileImage = File(picked.path));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access camera/gallery'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _uploadAvatarAndGoHome() async {
    if (_profileImage != null) {
      try {
        final dio = ref.read(dioProvider);
        final formData = FormData.fromMap({
          'avatar': await MultipartFile.fromFile(
            _profileImage!.path,
            filename: 'avatar.jpg',
          ),
        });
        await dio.post('/users/me/avatar', data: formData);
      } catch (e) {
        // Silently fail - avatar upload is not critical
        debugPrint('Avatar upload failed: $e');
      }
    }
    if (mounted) {
      context.goNamed(RouteNames.home);
    }
  }

  String _getCountryCode(String countryName) {
    final match = supportedCountryCodes.where((c) => c.name == countryName);
    if (match.isNotEmpty) {
      return match.first.code;
    }
    return 'MT'; // fallback
  }

  void _showCountryPicker() {
    final countries = supportedCountryCodes
        .map((c) => c.name)
        .toSet()
        .toList()
      ..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CountrySearchSheet(
        countries: countries,
        selected: _selectedCountry,
        onSelect: (country) {
          setState(() => _selectedCountry = country);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        _uploadAvatarAndGoHome();
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ── Scrollable content ─────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // ── Avatar with camera ─────────────────────
                    _buildAvatarPlaceholder(),

                    const SizedBox(height: 24),

                    // ── Title ────────────────────────────────
                    Text(
                      'Complete Profile',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Personalize your luxury experience',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── First Name ───────────────────────────
                    _buildTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      icon: Icons.person_outline,
                      inputFormatters: [
                        InputValidators.nameInputFormatter,
                        LengthLimitingTextInputFormatter(50),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Last Name ────────────────────────────
                    _buildTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      icon: Icons.person_outline,
                      inputFormatters: [
                        InputValidators.nameInputFormatter,
                        LengthLimitingTextInputFormatter(50),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Language Toggle ──────────────────────
                    _buildLanguageToggle(),

                    const SizedBox(height: 24),

                    // ── Country Selector ─────────────────────
                    GestureDetector(
                      onTap: _showCountryPicker,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _selectedCountry,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.keyboard_arrow_down,
                                color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── City (manual input) ──────────────────
                    _buildTextField(
                      controller: _cityController,
                      label: 'Enter your City',
                      icon: Icons.location_city_outlined,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(100),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Home Address ─────────────────────────
                    _buildTextField(
                      controller: _homeAddressController,
                      label: 'Home Address',
                      icon: Icons.home_outlined,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(200),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── GDPR Checkboxes ──────────────────────
                    _buildTermsCheckbox(),
                    const SizedBox(height: 12),
                    _buildMarketingCheckbox(),

                    const SizedBox(height: 32),

                    // ── Continue button ──────────────────────
                    GozoltButton(
                      label: 'Continue',
                      width: double.infinity,
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _onContinue,
                    ),

                    const SizedBox(height: 16),

                    // ── Skip for now ─────────────────────────
                    GestureDetector(
                      onTap: isLoading ? null : _onSkip,
                      child: Text(
                        'Skip for now',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return GestureDetector(
      onTap: _pickProfileImage,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.inputDark : Colors.grey[200],
              border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark, width: 2),
              image: _profileImage != null
                  ? DecorationImage(
                      image: FileImage(_profileImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _profileImage == null
                ? Icon(
                    Icons.person,
                    size: 48,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGold,
              ),
              child: Icon(
                Icons.camera_alt,
                size: 16,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      inputFormatters: inputFormatters,
      style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight, size: 20),
        filled: true,
        fillColor: Theme.of(context).cardTheme.color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREFERRED LANGUAGE',
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _buildLangOption('English', 'en'),
              _buildLangOption('Maltese', 'mt'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLangOption(String label, String value) {
    final isSelected = _selectedLanguage == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedLanguage = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGold : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.titleSmall.copyWith(
              color: isSelected ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _termsAccepted = !_termsAccepted);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCheckbox(_termsAccepted),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => context.pushNamed(RouteNames.terms),
                      child: Text(
                        'Terms of Service',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryGold,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primaryGold,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' & '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => context.pushNamed(RouteNames.privacyPolicy),
                      child: Text(
                        'Privacy Policy',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryGold,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primaryGold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketingCheckbox() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _marketingConsent = !_marketingConsent);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCheckbox(_marketingConsent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'I consent to receive marketing updates and GDPR-related notifications',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(bool checked) {
    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: checked ? AppColors.primaryGold : Colors.transparent,
        border: Border.all(
          color: checked ? AppColors.primaryGold : (Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
          width: 1.5,
        ),
      ),
      child: checked
          ? Icon(Icons.check, size: 16, color: Theme.of(context).scaffoldBackgroundColor)
          : null,
    );
  }
}

// ── Country Search Sheet ─────────────────────────────────
class _CountrySearchSheet extends StatefulWidget {
  final List<String> countries;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CountrySearchSheet({
    required this.countries,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<_CountrySearchSheet> createState() => _CountrySearchSheetState();
}

class _CountrySearchSheetState extends State<_CountrySearchSheet> {
  final _searchController = TextEditingController();
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.countries;
  }

  void _search(String query) {
    if (query.isEmpty) {
      setState(() => _filtered = widget.countries);
      return;
    }
    setState(() {
      _filtered = widget.countries
          .where((c) => c.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _search,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight),
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textMuted),
                  prefixIcon: Icon(Icons.search,
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                  filled: true,
                  fillColor: Theme.of(context).cardTheme.color,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final country = _filtered[index];
                  final isSelected = country == widget.selected;
                  final match = supportedCountryCodes
                      .where((c) => c.name == country);
                  final flag = match.isNotEmpty ? match.first.flag : '';

                  return ListTile(
                    leading: Text(flag,
                        style: const TextStyle(fontSize: 24)),
                    title: Text(
                      country,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected
                            ? AppColors.primaryGold
                            : (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : AppColors.textPrimaryLight),
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check,
                            color: AppColors.primaryGold, size: 20)
                        : null,
                    onTap: () => widget.onSelect(country),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
