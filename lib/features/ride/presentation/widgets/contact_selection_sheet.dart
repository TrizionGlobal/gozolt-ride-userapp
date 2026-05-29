import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

enum ContactSelectionMode { call, whatsapp }

class ContactSelectionSheet extends StatefulWidget {
  final ContactSelectionMode mode;
  final String locationMessage; // Used for WhatsApp mode
  final List<dynamic>? emergencyContacts;

  const ContactSelectionSheet({
    super.key,
    required this.mode,
    this.locationMessage = '',
    this.emergencyContacts,
  });

  @override
  State<ContactSelectionSheet> createState() => _ContactSelectionSheetState();
}

class _ContactSelectionSheetState extends State<ContactSelectionSheet> {
  List<Contact>? _contacts;
  List<Contact>? _filteredContacts;
  bool _permissionDenied = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchContacts() async {
    final status = await ph.Permission.contacts.request();
    if (status == ph.PermissionStatus.granted) {
      final contacts = await FlutterContacts.getAll(properties: {ContactProperty.phone});
      
      // Filter out contacts without phones
      final contactsWithPhone = contacts.where((c) => c.phones.isNotEmpty).toList();
      
      // Sort alphabetically
      contactsWithPhone.sort((a, b) => (a.displayName ?? '').compareTo(b.displayName ?? ''));
      
      if (mounted) {
        setState(() {
          _contacts = contactsWithPhone;
          _filteredContacts = contactsWithPhone;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _permissionDenied = true;
        });
      }
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    if (_contacts != null) {
      setState(() {
        _filteredContacts = _contacts!.where((c) {
          return (c.displayName ?? '').toLowerCase().contains(query);
        }).toList();
      });
    }
  }

  Future<void> _handleContactSelect(Contact contact) async {
    HapticFeedback.lightImpact();
    
    if (contact.phones.isEmpty) return;
    
    // Clean up phone number
    String rawPhone = contact.phones.first.number;
    String cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');

    if (widget.mode == ContactSelectionMode.call) {
      final url = Uri.parse("tel:$cleanPhone");
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch dialer for ${contact.displayName}.')),
          );
        }
      }
    } else if (widget.mode == ContactSelectionMode.whatsapp) {
      // Remove leading '+' if present, WhatsApp requires just digits
      String waPhone = cleanPhone.startsWith('+') ? cleanPhone.substring(1) : cleanPhone;
      
      // Fallback if the user doesn't have a country code, add a default or let it fail gracefully
      final encodedMsg = Uri.encodeComponent(widget.locationMessage);
      final waUrl = Uri.parse("whatsapp://send?phone=$waPhone&text=$encodedMsg");
      
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WhatsApp is not installed on your device.')),
          );
        }
      }
    }
    
    if (mounted) Navigator.pop(context);
  }

  Future<void> _handleEmergencyContactSelect(dynamic emergencyContact) async {
    HapticFeedback.lightImpact();
    final phone = emergencyContact['phone'] as String? ?? '';
    if (phone.isEmpty) return;
    
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    if (widget.mode == ContactSelectionMode.call) {
      final url = Uri.parse("tel:$cleanPhone");
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch dialer for ${emergencyContact['name']}.')),
          );
        }
      }
    } else if (widget.mode == ContactSelectionMode.whatsapp) {
      String waPhone = cleanPhone.startsWith('+') ? cleanPhone.substring(1) : cleanPhone;
      final encodedMsg = Uri.encodeComponent(widget.locationMessage);
      final waUrl = Uri.parse("whatsapp://send?phone=$waPhone&text=$encodedMsg");
      
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WhatsApp is not installed on your device.')),
          );
        }
      }
    }
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  widget.mode == ContactSelectionMode.call 
                      ? Icons.local_phone_rounded 
                      : Icons.share_rounded,
                  color: widget.mode == ContactSelectionMode.call 
                      ? AppColors.error 
                      : AppColors.primaryGold,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.mode == ContactSelectionMode.call 
                      ? 'Select Contact to Call' 
                      : 'Share via WhatsApp',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Search bar
          if (!_permissionDenied)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight),
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  hintStyle: TextStyle(color: isDark ? AppColors.textMuted : AppColors.textMutedLight),
                  prefixIcon: Icon(Icons.search, color: isDark ? AppColors.textMuted : AppColors.textMutedLight),
                  filled: true,
                  fillColor: isDark ? AppColors.inputDark : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            
          const SizedBox(height: 12),
          
          // List
          Expanded(
            child: _buildBody(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (widget.emergencyContacts != null && widget.emergencyContacts!.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Emergency Contacts',
                style: AppTextStyles.labelLarge.copyWith(
                  color: widget.mode == ContactSelectionMode.call ? AppColors.error : AppColors.primaryGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final ec = widget.emergencyContacts![index];
                final name = ec['name'] as String? ?? 'Unknown';
                final phone = ec['phone'] as String? ?? '';
                return ListTile(
                  onTap: () => _handleEmergencyContactSelect(ec),
                  leading: CircleAvatar(
                    backgroundColor: widget.mode == ContactSelectionMode.call 
                        ? AppColors.error.withOpacity(0.15)
                        : AppColors.primaryGold.withOpacity(0.15),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: widget.mode == ContactSelectionMode.call 
                            ? AppColors.error
                            : AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    phone,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                    ),
                  ),
                  trailing: Icon(
                    widget.mode == ContactSelectionMode.call ? Icons.call : Icons.send,
                    color: widget.mode == ContactSelectionMode.call 
                        ? AppColors.error
                        : AppColors.primaryGold,
                    size: 20,
                  ),
                );
              },
              childCount: widget.emergencyContacts!.length,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'All Contacts',
                style: AppTextStyles.labelLarge.copyWith(
                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        
        if (_permissionDenied)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.perm_contact_calendar_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'Contacts Permission Required',
                      style: AppTextStyles.titleMedium.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please enable contacts access in your device settings to select a contact.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => ph.openAppSettings(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: AppColors.backgroundDark,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                      ),
                      child: const Text('Open Settings'),
                    )
                  ],
                ),
              ),
            ),
          )
        else if (_filteredContacts == null)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold),
            ),
          )
        else if (_filteredContacts!.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'No contacts found',
                style: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
              ),
            ),
          )
        else
        SliverPadding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final contact = _filteredContacts![index];
                final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
                
                return ListTile(
                  onTap: () => _handleContactSelect(contact),
                  leading: CircleAvatar(
                    backgroundColor: widget.mode == ContactSelectionMode.call 
                        ? AppColors.error.withOpacity(0.15)
                        : AppColors.primaryGold.withOpacity(0.15),
                    child: Text(
                      (contact.displayName ?? '').isNotEmpty ? contact.displayName![0].toUpperCase() : '?',
                      style: TextStyle(
                        color: widget.mode == ContactSelectionMode.call 
                            ? AppColors.error
                            : AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    contact.displayName ?? 'Unknown',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    phone,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                    ),
                  ),
                  trailing: Icon(
                    widget.mode == ContactSelectionMode.call ? Icons.call : Icons.send,
                    color: widget.mode == ContactSelectionMode.call 
                        ? AppColors.error
                        : AppColors.primaryGold,
                    size: 20,
                  ),
                );
              },
              childCount: _filteredContacts!.length,
            ),
          ),
        ),
      ],
    );
  }
}
