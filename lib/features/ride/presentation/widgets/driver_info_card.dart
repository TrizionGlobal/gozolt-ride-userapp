import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/driver_info.dart';
import '../../data/models/vehicle_type.dart';

class DriverInfoCard extends StatelessWidget {
  final DriverInfo driverInfo;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final String pickupAddress;
  final String dropoffAddress;
  final String paymentMethod;

  const DriverInfoCard({
    super.key,
    required this.driverInfo,
    required this.onCall,
    required this.onMessage,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Driver & Vehicle Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with Rating
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    driverInfo.avatarUrl != null && driverInfo.avatarUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              driverInfo.avatarUrl!,
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholder(54, AppTextStyles.titleLarge.copyWith(color: AppColors.primaryGold)),
                            ),
                          )
                        : _buildPlaceholder(54, AppTextStyles.titleLarge.copyWith(color: AppColors.primaryGold)),
                    Positioned(
                      bottom: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              driverInfo.rating.toStringAsFixed(2),
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.star, size: 10, color: AppColors.primaryGold),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Driver Name & Car Plate
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverInfo.name,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${driverInfo.vehicleColor} ${driverInfo.vehicleDescription}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.inputDark : Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          driverInfo.formattedPlate,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Vehicle Image
                Image.asset(
                  _getVehicleAsset(driverInfo.vehicleType),
                  width: 70,
                  height: 40,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 70, height: 40),
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onMessage,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.inputDark : Colors.grey[200],
                        border: Border.all(color: isDark ? Colors.transparent : Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Message',
                            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onCall,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.inputDark : Colors.grey[200],
                      border: Border.all(color: isDark ? Colors.transparent : Colors.grey[300]!),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _showDriverProfile(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.inputDark : Colors.grey[200],
                      border: Border.all(color: isDark ? Colors.transparent : Colors.grey[300]!),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_outline, size: 22),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          Divider(
            height: 1, 
            thickness: 1, 
            color: Theme.of(context).dividerTheme.color ?? AppColors.borderLight.withOpacity(0.5)
          ),
          
          // Trip Details Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline icons
                Column(
                  children: [
                    const SizedBox(height: 6),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: AppColors.primaryGold, size: 14),
                    ),
                    Container(
                      width: 2,
                      height: 24,
                      color: Theme.of(context).dividerTheme.color ?? AppColors.borderLight,
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: Colors.grey, size: 14),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Location & Payment
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pickup',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pickupAddress.isNotEmpty ? pickupAddress : 'Meet at the pickup point',
                                  style: AppTextStyles.titleSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Payment Method Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.payments_outlined, color: Colors.green, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  paymentMethod.toUpperCase(),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: Colors.green, 
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Drop-off',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dropoffAddress.isNotEmpty ? dropoffAddress : 'Destination',
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getVehicleAsset(String? vehicleType) {
    return VehicleType.fromApi(vehicleType ?? '').iconPath;
  }

  void _showDriverProfile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.only(top: 12, bottom: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                'Driver details',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: Theme.of(context).dividerTheme.color ?? AppColors.borderLight.withOpacity(0.5), height: 1),
              const SizedBox(height: 20),

              // Avatar with Rating Badge
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  driverInfo.avatarUrl != null && driverInfo.avatarUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            driverInfo.avatarUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholderRect(60, AppTextStyles.headlineMedium.copyWith(color: AppColors.primaryGold)),
                          ),
                        )
                      : _buildPlaceholderRect(60, AppTextStyles.headlineMedium.copyWith(color: AppColors.primaryGold)),
                  Positioned(
                    bottom: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 12, color: AppColors.primaryGold),
                          const SizedBox(width: 2),
                          Text(
                            driverInfo.rating.toStringAsFixed(2),
                            style: AppTextStyles.labelSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Plate Number
              Text(
                driverInfo.formattedPlate,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),

              // Subtitle
              Text(
                '${driverInfo.name} · ${driverInfo.vehicleColor} ${driverInfo.vehicleDescription}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          onMessage();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.inputDark : Colors.grey[200],
                            border: Border.all(color: isDark ? Colors.transparent : Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded, size: 18, color: isDark ? Colors.white : Colors.black),
                              const SizedBox(width: 8),
                              Text(
                                'Send a message',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        onCall();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.inputDark : Colors.grey[200],
                          border: Border.all(color: isDark ? Colors.transparent : Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Icon(Icons.phone_rounded, size: 20, color: isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: Theme.of(context).dividerTheme.color ?? AppColors.borderLight.withOpacity(0.5), height: 1),

              // List Tiles
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primaryGold, size: 20),
                ),
                title: Text('Spotlight', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'Have your screen shine a colour to help your driver find you.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                    fontSize: 11,
                  ),
                ),
                onTap: () => _showSpotlight(context),
                trailing: GestureDetector(
                  onTap: () => _showSpotlight(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.inputDark : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Try it',
                      style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              Divider(color: Theme.of(context).dividerTheme.color ?? AppColors.borderLight.withOpacity(0.5), height: 1),
              
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.inputDark : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline_rounded, size: 20),
                ),
                title: Text('Driver profile', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'Get to know ${driverInfo.name.split(' ').first}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                    fontSize: 11,
                  ),
                ),
                trailing: Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                onTap: () => _showFullDriverProfile(context),
              ),

              const SizedBox(height: 16),
              // Close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.cardDark : Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text('Close', style: AppTextStyles.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSpotlight(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: const Color(0xFFE91E63), // Bright pink color
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.white, size: 80),
                    const SizedBox(height: 24),
                    Text(
                      'Hold your phone up\nso your driver can see you.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullDriverProfile(BuildContext context) {
    Navigator.pop(context); // Close the current bottom sheet
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.inputDark : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_rounded, size: 22),
                          ),
                        ),
                        // Drag Handle
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                        // Placeholder to keep the drag handle perfectly centered
                        const SizedBox(width: 38), 
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Large Avatar
                  driverInfo.avatarUrl != null && driverInfo.avatarUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            driverInfo.avatarUrl!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(120, AppTextStyles.displayLarge.copyWith(color: AppColors.primaryGold)),
                          ),
                        )
                      : _buildPlaceholder(120, AppTextStyles.displayLarge.copyWith(color: AppColors.primaryGold)),
                  const SizedBox(height: 16),
                  Text(
                    driverInfo.name,
                    style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  
                  // Stats row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn('★ ${driverInfo.rating.toStringAsFixed(2)}', 'Rating', isDark),
                        _buildStatColumn(driverInfo.totalRides.toString(), 'Trips', isDark),
                        _buildStatColumn(driverInfo.memberSince ?? '1', 'Years', isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Divider(color: Theme.of(context).dividerTheme.color ?? AppColors.borderLight.withOpacity(0.5), height: 1),
                  
                  // Compliments/Details
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('About ${driverInfo.name.split(' ').first}', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildProfileDetailRow(Icons.language, 'Speaks English and Maltese', isDark),
                        const SizedBox(height: 16),
                        _buildProfileDetailRow(Icons.thumb_up_alt_outlined, 'Top rated for excellent service', isDark),
                        const SizedBox(height: 16),
                        _buildProfileDetailRow(Icons.directions_car_outlined, 'Drives a ${driverInfo.vehicleColor} ${driverInfo.vehicleDescription}', isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight)),
      ],
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Text(text, style: AppTextStyles.bodyMedium),
        ),
      ],
    );
  }

  Widget _profileRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.bodyMedium
                .copyWith(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight)),
        Text(value,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildPlaceholder(double size, TextStyle style) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryGold.withOpacity(0.15),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          driverInfo.name.isNotEmpty ? driverInfo.name[0].toUpperCase() : 'D',
          style: style,
        ),
      ),
    );
  }

  Widget _buildPlaceholderRect(double size, TextStyle style) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          driverInfo.name.isNotEmpty ? driverInfo.name[0].toUpperCase() : 'D',
          style: style,
        ),
      ),
    );
  }
}
