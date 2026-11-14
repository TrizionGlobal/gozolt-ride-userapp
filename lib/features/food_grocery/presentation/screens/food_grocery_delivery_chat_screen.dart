import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
 
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/food_grocery_chat_provider.dart';
 
class FoodGroceryDeliveryChatArguments {
  const FoodGroceryDeliveryChatArguments({
    required this.orderId,
    required this.partnerName,
    required this.partnerPhone,
  });
 
  final String orderId;
  final String partnerName;
  final String? partnerPhone;
}
 
class FoodGroceryDeliveryChatScreen extends ConsumerStatefulWidget {
  const FoodGroceryDeliveryChatScreen({
    required this.orderId,
    required this.partnerName,
    required this.partnerPhone,
    super.key,
  });
 
  final String orderId;
  final String partnerName;
  final String? partnerPhone;
 
  @override
  ConsumerState<FoodGroceryDeliveryChatScreen> createState() =>
      _FoodGroceryDeliveryChatScreenState();
}
 
class _FoodGroceryDeliveryChatScreenState
    extends ConsumerState<FoodGroceryDeliveryChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
 
  static const List<String> _quickReplies = [
    'Where are you?',
    'I am at the location',
    'Please call when you arrive',
    'Leave it at the door',
    'Thank you',
  ];
 
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
 
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
 
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }
 
  void _sendMessage([String? quickReply]) {
    final message = quickReply ?? _messageController.text;
 
    if (message.trim().isEmpty) {
      return;
    }
 
    ref
        .read(
          foodGroceryChatProvider(widget.orderId).notifier,
        )
        .sendCustomerMessage(message);
 
    _messageController.clear();
    _scrollToBottom();
  }
 
  Future<void> _callDeliveryPartner() async {
    final phone = widget.partnerPhone?.trim();
 
    if (phone == null || phone.isEmpty) {
      _showError(
        'The delivery partner’s phone number is not available.',
      );
      return;
    }
 
    final uri = Uri(
      scheme: 'tel',
      path: phone,
    );
 
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
 
      if (!launched && mounted) {
        _showError('Unable to open the phone app.');
      }
    } catch (_) {
      if (mounted) {
        _showError('Unable to open the phone app.');
      }
    }
  }
 
  void _showError(String message) {
    if (!mounted) {
      return;
    }
 
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.error,
        ),
      );
  }
 
  String _formatTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
 
    return '$hour:$minute';
  }
 
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
 
    final messages = ref.watch(
      foodGroceryChatProvider(widget.orderId),
    );
 
    ref.listen<List<FoodGroceryChatMessage>>(
      foodGroceryChatProvider(widget.orderId),
      (previous, next) {
        if ((previous?.length ?? 0) < next.length) {
          _scrollToBottom();
        }
      },
    );
 
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: AppColors.primaryGold.withValues(alpha: 0.16),
              child: Text(
                widget.partnerName.trim().isEmpty
                    ? 'D'
                    : widget.partnerName.trim()[0].toUpperCase(),
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.primaryGoldDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.partnerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Order ID: ${widget.orderId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Call delivery partner',
            onPressed: _callDeliveryPartner,
            icon: const Icon(
              Icons.call_outlined,
              color: AppColors.primaryGoldDark,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 9,
            ),
            color: AppColors.primaryGold.withValues(alpha: 0.10),
            child: Text(
              'Only share information needed to complete this delivery.',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      18,
                      16,
                      18,
                    ),
                    itemCount: messages.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 10);
                    },
                    itemBuilder: (context, index) {
                      final message = messages[index];
 
                      return _MessageBubble(
                        message: message,
                        formattedTime: _formatTime(message.sentAt),
                        isDark: isDark,
                      );
                    },
                  ),
          ),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 5,
              ),
              itemCount: _quickReplies.length,
              separatorBuilder: (context, index) {
                return const SizedBox(width: 8);
              },
              itemBuilder: (context, index) {
                final reply = _quickReplies[index];
 
                return ActionChip(
                  label: Text(reply),
                  onPressed: () {
                    _sendMessage(reply);
                  },
                  backgroundColor: isDark ? AppColors.cardDark : Colors.white,
                  side: BorderSide(
                    color: AppColors.primaryGold.withValues(alpha: 0.65),
                  ),
                  labelStyle: AppTextStyles.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                border: Border(
                  top: BorderSide(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.inputDark
                            : AppColors.backgroundLight,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) {
                        _sendMessage();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.primaryGold,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Send message',
                      onPressed: _sendMessage,
                      icon: const Icon(
                        Icons.send_rounded,
                        color: AppColors.backgroundDark,
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
}
 
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.formattedTime,
    required this.isDark,
  });
 
  final FoodGroceryChatMessage message;
  final String formattedTime;
  final bool isDark;
 
  @override
  Widget build(BuildContext context) {
    final isCustomer = message.isFromCustomer;
 
    return Align(
      alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 10, 13, 7),
          decoration: BoxDecoration(
            color: isCustomer
                ? AppColors.primaryGold
                : isDark
                    ? AppColors.cardDark
                    : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(15),
              topRight: const Radius.circular(15),
              bottomLeft: Radius.circular(isCustomer ? 15 : 4),
              bottomRight: Radius.circular(isCustomer ? 4 : 15),
            ),
            border: isCustomer
                ? null
                : Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isCustomer
                      ? AppColors.backgroundDark
                      : isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formattedTime,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isCustomer
                      ? AppColors.backgroundDark.withValues(alpha: 0.65)
                      : isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 