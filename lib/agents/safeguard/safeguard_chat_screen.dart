import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/language_provider.dart';
import '../core/agent_message.dart';
import '../core/agent_response.dart';
import '../core/agent_registry.dart';

// ── Chat message UI model ──────────────────────────────────────────

class _ChatBubble {
  _ChatBubble({
    required this.text,
    required this.isUser,
    this.type = ResponseType.text,
    this.actions = const [],
    this.followUp,
    DateTime? time,
  }) : time = time ?? DateTime.now();

  final String text;
  final bool isUser;
  final ResponseType type;
  final List<AgentAction> actions;
  final String? followUp;
  final DateTime time;
}

// ── Screen ─────────────────────────────────────────────────────────

class SafeguardChatScreen extends ConsumerStatefulWidget {
  const SafeguardChatScreen({super.key});

  @override
  ConsumerState<SafeguardChatScreen> createState() =>
      _SafeguardChatScreenState();
}

class _SafeguardChatScreenState extends ConsumerState<SafeguardChatScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages = <_ChatBubble>[];
  bool _isTyping = false;
  bool _showSuggestions = true;

  static const _suggestionsEn = [
    'Verify a seller',
    'How to report fraud',
    'Common scams',
    'My legal rights',
    'What is trust score',
  ];
  static const _suggestionsNe = [
    'Seller जाँच्नुस्',
    'कसरी रिपोर्ट गर्ने',
    'सामान्य ठगी',
    'मेरो अधिकार',
    'Trust score के हो',
  ];

  @override
  void initState() {
    super.initState();
    // Send greeting on open
    Future.microtask(() => _sendToAgent('hello', silent: true));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Core logic ───────────────────────────────────────────────────

  Future<void> _sendToAgent(String text, {bool silent = false}) async {
    final lang = ref.read(languageProvider);

    if (!silent) {
      setState(() {
        _messages.add(_ChatBubble(text: text, isUser: true));
        _showSuggestions = false;
      });
    }

    setState(() => _isTyping = true);
    _scrollToBottom();

    // Realistic delay
    await Future.delayed(const Duration(milliseconds: 350));

    final agent = AgentRegistry().safeguard;
    final response = await agent.process(
      AgentMessage(
        content: text,
        userId: FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        language: lang,
      ),
    );

    if (!mounted) return;

    setState(() {
      _isTyping = false;
      _messages.add(
        _ChatBubble(
          text: response.text,
          isUser: false,
          type: response.type,
          actions: response.actions,
          followUp:
              response.requiresFollowUp ? response.followUpQuestion : null,
        ),
      );
    });
    _scrollToBottom();
  }

  void _onSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _sendToAgent(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isNe = lang == 'ne';

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: _buildAppBar(isNe),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: const Color(0xFF0D1F3C),
            child: Text(
              isNe
                  ? 'Online  |  तुरुन्त जवाफ  |  बाहिर डाटा पठाइँदैन'
                  : 'Online  |  Instant answers  |  No data sent externally',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF546E7A),
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessage(_messages[i], isNe)
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .slideY(begin: 0.1);
              },
            ),
          ),

          // Suggestions
          if (_showSuggestions) _buildSuggestions(isNe),

          // Input
          _buildInput(isNe),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isNe) {
    return AppBar(
      backgroundColor: const Color(0xFF0D1F3C),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Color(0xFF42A5F5),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Safety Assistant',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                isNe
                    ? 'सुरक्षित किनमेलबारे जवाफ पाउनुहोस्'
                    : 'Answers about safe online shopping',
                style: const TextStyle(
                  color: Color(0xFF64B5F6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Language toggle
        TextButton(
          onPressed: () {
            final current = ref.read(languageProvider);
            ref.read(languageProvider.notifier).setLanguage(
                current == 'en' ? 'ne' : 'en');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              ref.watch(languageProvider) == 'en' ? 'NE' : 'EN',
              style: const TextStyle(
                color: Color(0xFF64B5F6),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Message bubble ───────────────────────────────────────────────

  Widget _buildMessage(_ChatBubble msg, bool isNe) {
    if (msg.isUser) return _buildUserBubble(msg);
    return _buildAgentBubble(msg, isNe);
  }

  Widget _buildUserBubble(_ChatBubble msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFF1565C0),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          msg.text,
          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
        ),
      ),
    );
  }

  Widget _buildAgentBubble(_ChatBubble msg, bool isNe) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Color(0xFF42A5F5),
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _bubbleColor(msg.type),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: _textColor(msg.type),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                // Action buttons
                if (msg.actions.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: msg.actions.map((a) {
                      return _buildActionButton(a, isNe);
                    }).toList(),
                  ),
                // Follow-up
                if (msg.followUp != null && msg.followUp!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      msg.followUp!,
                      style: const TextStyle(
                        color: Color(0xFF64B5F6),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Color(0xFF455A64),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _bubbleColor(ResponseType type) {
    switch (type) {
      case ResponseType.alert:
        return const Color(0xFF3E2723);
      case ResponseType.milestone:
        return const Color(0xFF1B5E20).withValues(alpha: 0.3);
      case ResponseType.sellerCard:
        return const Color(0xFF0D2137);
      default:
        return const Color(0xFF132741);
    }
  }

  Color _textColor(ResponseType type) {
    switch (type) {
      case ResponseType.alert:
        return const Color(0xFFFFCC80);
      default:
        return const Color(0xFFE0E0E0);
    }
  }

  Widget _buildActionButton(AgentAction action, bool isNe) {
    return Material(
      color: const Color(0xFF1565C0).withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _handleAction(action),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            isNe ? action.labelNe : action.label,
            style: const TextStyle(
              color: Color(0xFF42A5F5),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _handleAction(AgentAction action) {
    if (action.actionType == 'navigate') {
      final route = action.payload['route'] as String?;
      if (route != null) {
        Navigator.of(context).pushNamed(route);
      }
    } else if (action.actionType == 'search') {
      final query = action.payload['query'] as String? ?? '';
      _controller.text = query;
      _onSend();
    }
  }

  // ── Typing indicator ─────────────────────────────────────────────

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 36, bottom: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: const Icon(Icons.circle, size: 8, color: Color(0xFF42A5F5))
                  .animate(onPlay: (c) => c.repeat())
                  .scaleXY(begin: 0.7, end: 1.0, duration: 500.ms)
                  .then(delay: (i * 150).ms),
            );
          }),
        ),
      ),
    );
  }

  // ── Suggestion chips ─────────────────────────────────────────────

  Widget _buildSuggestions(bool isNe) {
    final suggestions = isNe ? _suggestionsNe : _suggestionsEn;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: suggestions.map((s) {
          return Material(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _sendToAgent(s),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Text(
                  s,
                  style: const TextStyle(
                    color: Color(0xFF90CAF9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Input bar ────────────────────────────────────────────────────

  Widget _buildInput(bool isNe) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1F3C),
        border: Border(top: BorderSide(color: Color(0xFF1A2F4A))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _onSend(),
              decoration: InputDecoration(
                hintText: isNe
                    ? 'Seller safety बारे सोध्नुहोस्...'
                    : 'Ask anything about seller safety...',
                hintStyle: const TextStyle(
                  color: Color(0xFF546E7A),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFF1565C0),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _onSend,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
