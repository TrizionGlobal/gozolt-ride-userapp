import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../auth/data/models/country_code.dart';
import '../../../auth/presentation/widgets/country_code_picker.dart';
import '../../../auth/presentation/widgets/phone_input_field.dart';
import '../../data/datasources/account_remote_datasource.dart';
import '../providers/account_providers.dart';

class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends ConsumerState<EmergencyContactsScreen> {
  List<Map<String, String>> _contacts = [];
  bool _isAdding = false;
  int? _editingIndex;
  CountryCode _selectedCountry = supportedCountryCodes.firstWhere((c) => c.code == 'MT', orElse: () => supportedCountryCodes.first);
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _snackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _callNumber(String number) async {
    final cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse("tel:$cleanNumber");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        // canLaunchUrl returns false on iOS Simulators because there is no Phone app.
        // We attempt to launch anyway just in case, but catch the result.
        final launched = await launchUrl(url);
        if (!launched) {
          _snackBar('Could not launch dialer. (Testing on a simulator?)', isError: true);
        }
      }
    } catch (e) {
      _snackBar('Could not launch dialer for $number', isError: true);
    }
  }

  Future<void> _saveContactList(List<Map<String, String>> newList, {bool showSuccess = true}) async {
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final ds = ref.read(accountRemoteDatasourceProvider);
      final updates = <String, dynamic>{
        'emergencyContacts': newList,
      };

      await ds.updateProfile(updates);

      // Refresh the profile data
      ref.invalidate(userProfileProvider);

      if (mounted) {
        if (showSuccess) _snackBar('Emergency contacts updated successfully');
        setState(() {
          _contacts = newList;
          _isAdding = false;
          _editingIndex = null;
        });
      }
    } catch (e) {
      if (mounted) {
        _snackBar('Failed to update contacts: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSaveClicked() {
    final name = _nameController.text.trim();
    final phoneDigits = _phoneController.text.trim();
    final phone = phoneDigits.isNotEmpty ? '${_selectedCountry.dialCode} $phoneDigits' : '';
    
    if (name.isEmpty && phone.isEmpty) {
      setState(() {
        _isAdding = false;
        _editingIndex = null;
      });
      return;
    }

    final newList = List<Map<String, String>>.from(_contacts);
    if (_editingIndex != null) {
      newList[_editingIndex!] = {'name': name, 'phone': phone};
    } else {
      newList.add({'name': name, 'phone': phone});
    }
    
    _saveContactList(newList);
  }

  void _onDeleteClicked(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Contact', style: AppTextStyles.headlineSmall),
        content: Text('Are you sure you want to delete this emergency contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final newList = List<Map<String, String>>.from(_contacts);
              newList.removeAt(index);
              _saveContactList(newList, showSuccess: false);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _inputLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelSmall.copyWith(
        color: Theme.of(context).brightness == Brightness.dark 
            ? AppColors.textSecondary 
            : AppColors.textSecondaryLight,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildMaltaNumberCard(String name, String number, String sub, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
      ),
      child: ListTile(
        onTap: () => _callNumber(number),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.error, size: 24),
        ),
        title: Text(name, style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(sub, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text(number, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryGold)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.call, color: AppColors.success),
          onPressed: () => _callNumber(number),
        ),
      ),
    );
  }

  Widget _buildSavedContactCard(int index, Map<String, String> contact) {
    final name = contact['name'] ?? '';
    final phone = contact['phone'] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryGold.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: AppColors.primaryGold, size: 24),
        ),
        title: Text(name, style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(phone, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 20),
              onPressed: () {
                String p = phone;
                CountryCode c = supportedCountryCodes.firstWhere((c) => p.startsWith(c.dialCode), orElse: () => supportedCountryCodes.firstWhere((c) => c.code == 'MT'));
                if (p.startsWith(c.dialCode)) {
                  p = p.substring(c.dialCode.length).trim();
                }
                setState(() {
                  _isAdding = false;
                  _editingIndex = index;
                  _nameController.text = name;
                  _phoneController.text = p;
                  _selectedCountry = c;
                });
                _scrollToBottom();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              onPressed: () => _onDeleteClicked(index),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
        data: (profile) {
          if (!_initialized) {
            if (profile.emergencyContacts != null && profile.emergencyContacts!.isNotEmpty) {
              _contacts = profile.emergencyContacts!.map((e) => {
                'name': e['name']?.toString() ?? '',
                'phone': e['phone']?.toString() ?? ''
              }).toList();
            }
            _initialized = true;
          }

          final showInputFields = _isAdding || _editingIndex != null;

          return CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
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
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
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
                              child: const Icon(Icons.arrow_back, color: AppColors.backgroundDark, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Emergency Contacts',
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

              // ── Content ────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: AppColors.primaryGold, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Your safety is our priority. These numbers will be easily accessible during an active ride.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? AppColors.textSecondary 
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Malta Emergency Numbers ──────────────────────
                Text(
                  'Malta Emergency Numbers',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? AppColors.textPrimary 
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMaltaNumberCard('General Emergency', '112', 'Police, Fire, Ambulance', Icons.local_police),
                _buildMaltaNumberCard('Medical Guidance', '1400', 'Non-emergency health helpline', Icons.local_hospital),
                _buildMaltaNumberCard('Police', '2122 4001', 'Non-emergency', Icons.shield),
                
                const SizedBox(height: 32),

                // ── Personal Contacts ──────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Contacts',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? AppColors.textPrimary 
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You can add up to 3 contacts',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_contacts.length < 3 && !showInputFields)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isAdding = true;
                            _editingIndex = null;
                            _nameController.clear();
                            _phoneController.clear();
                            _selectedCountry = supportedCountryCodes.firstWhere((c) => c.code == 'MT', orElse: () => supportedCountryCodes.first);
                          });
                          _scrollToBottom();
                        },
                        icon: const Icon(Icons.add, size: 18, color: AppColors.primaryGold),
                        label: Text('Add New contact', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryGold)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Saved Contacts List
                if (!showInputFields || _editingIndex != null)
                  ...List.generate(_contacts.length, (index) {
                    if (_editingIndex == index) return const SizedBox.shrink(); // Hide the card if editing it
                    return _buildSavedContactCard(index, _contacts[index]);
                  }),

                // Input Fields
                if (showInputFields) ...[
                  if (_contacts.isNotEmpty && _editingIndex == null) 
                    const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.backgroundDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _editingIndex != null ? 'Edit Contact' : 'New Contact',
                              style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isAdding = false;
                                  _editingIndex = null;
                                });
                              },
                              child: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _inputLabel('Name'),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _nameController,
                          hint: 'Enter contact name',
                          inputFormatters: [LengthLimitingTextInputFormatter(50)],
                        ),
                        const SizedBox(height: 16),
                        _inputLabel('Mobile number'),
                        const SizedBox(height: 6),
                        PhoneInputField(
                          controller: _phoneController,
                          selectedCountry: _selectedCountry,
                          onCountryTap: () {
                            CountryCodePicker.show(
                              context,
                              selected: _selectedCountry,
                              onSelected: (code) {
                                setState(() {
                                  _selectedCountry = code;
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Save button
                if (showInputFields)
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onSaveClicked,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Save Changes',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
                const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
