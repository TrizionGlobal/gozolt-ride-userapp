import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/chat_message.dart';
import '../providers/active_ride_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  static const _quickReplies = [
    'Where are you?',
    'I am at the location',
    'On my way',
    'Please wait',
    'Thank you',
  ];

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(activeRideProvider);
    final rideId = rideState.ride?.id ?? '';
    final messages = ref.watch(chatMessagesProvider(rideId));
    final driver = rideState.driverInfo;

    // Auto-scroll when new messages arrive
    ref.listen(chatMessagesProvider(rideId), (prev, next) {
      if ((prev?.length ?? 0) < next.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardTheme.color,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color ?? AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Driver avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGold.withOpacity(0.15),
              ),
              child: Center(
                child: Text(
                  driver?.name.isNotEmpty == true
                      ? driver!.name[0].toUpperCase()
                      : 'D',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.primaryGold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver?.name ?? 'Driver',
                    style: AppTextStyles.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${driver?.vehicleDescription ?? ''} \u2022 ${driver?.formattedPlate ?? ''}',
                    style: AppTextStyles.labelSmall.copyWith(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: AppColors.primaryGold),
            onPressed: () async {
              final phone = driver?.phone;
              if (phone != null && phone.isNotEmpty) {
                final uri = Uri.parse('tel:$phone');
                try {
                  final launched = await launchUrl(uri);
                  if (launched) return;
                } catch (_) {
                  // Ignore and fallback
                }
              }
              if (mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Calling ${driver?.name ?? "driver"}...'),
                    backgroundColor: AppColors.primaryGold,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48,
                            color: AppColors.textMuted.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Send a message to your driver',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (_, index) =>
                        _ChatBubble(message: messages[index]),
                  ),
          ),

          // Quick replies
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickReplies
                    .map((msg) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () {
                              _messageController.text = msg;
                              _sendMessage();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardTheme.color,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primaryGold
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                msg,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: AppTextStyles.bodyMedium,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: 3,
                      minLines: 1,
                      maxLength: 500,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textMuted),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.inputDark : Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGold,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.send,
                        color: Theme.of(context).scaffoldBackgroundColor,
                        size: 20,
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

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();

    final rideId = ref.read(activeRideProvider).ride?.id ?? '';
    ref.read(chatMessagesProvider(rideId).notifier).sendMessage(text);
    _messageController.clear();
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // Driver avatar
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardDark,
                border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppColors.borderDark),
              ),
              child: const Icon(Icons.person, size: 16, color: AppColors.textMuted),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primaryGold : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isUser
                          ? Theme.of(context).scaffoldBackgroundColor
                          : (Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isUser
                              ? Colors.black54
                              : AppColors.textMuted,
                        ),
                      ),
                      if (message.isSending) ...[
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: isUser
                                ? Colors.black54
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                      if (message.hasFailed) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.error_outline,
                            size: 12, color: AppColors.error),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }
}
