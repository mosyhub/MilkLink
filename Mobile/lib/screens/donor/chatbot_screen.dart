import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/chatbot_service.dart';
import 'donor_registration_screen.dart';
import 'returning_donor_search_screen.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final String? action;
  final String? actionLabel;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.action,
    this.actionLabel,
  });
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: ChatbotService.milkBankIntro,
      isUser: false,
      time: DateTime.now(),
    ),
  ];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? presetText]) {
    final text = presetText ?? _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        time: DateTime.now(),
      ));
    });

    if (presetText == null) {
      _inputController.clear();
    }

    _scrollToBottom();

    // AI bot reply
    Future.delayed(const Duration(milliseconds: 400), () {
      final reply = ChatbotService.generateResponse(text);
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: reply['text'],
            isUser: false,
            time: DateTime.now(),
            action: reply['action'],
            actionLabel: reply['actionLabel'],
          ));
        });
        _scrollToBottom();
      }
    });
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

  void _handleAction(String? action) {
    if (action == 'REGISTER_DONOR') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DonorRegistrationScreen()),
      );
    } else if (action == 'SEARCH_DONOR') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReturningDonorSearchScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action "$action" opened in dashboard.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.softBlue,
              child: Icon(Icons.smart_toy, color: AppColors.primaryBlue, size: 20),
            ),
            SizedBox(width: 10),
            Text('MilkLink Assistant'),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Quick Questions Suggestions
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ActionChip(
                  label: const Text('How can I donate?', style: TextStyle(fontSize: 12)),
                  onPressed: () => _sendMessage('How can I donate breast milk?'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Returning Donor?', style: TextStyle(fontSize: 12)),
                  onPressed: () => _sendMessage('I am a returning donor, do I need to register?'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Storage guidelines', style: TextStyle(fontSize: 12)),
                  onPressed: () => _sendMessage('How do I store breast milk?'),
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('Required labs', style: TextStyle(fontSize: 12)),
                  onPressed: () => _sendMessage('What laboratory documents are required?'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(14),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[i];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: msg.isUser ? AppColors.primaryBlue : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.text,
                          style: TextStyle(
                            fontSize: 14,
                            color: msg.isUser ? Colors.white : AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                        if (msg.action != null && msg.actionLabel != null) ...[
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => _handleAction(msg.action),
                            icon: const Icon(Icons.arrow_forward, size: 14),
                            label: Text(
                              msg.actionLabel!,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: const InputDecoration(
                      hintText: 'Ask a question about donating or milk requests...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primaryBlue),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
