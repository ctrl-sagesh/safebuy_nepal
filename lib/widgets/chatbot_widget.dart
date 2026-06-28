import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';
import '../utils/constants.dart';

// ── Data ─────────────────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isBot;
  final DateTime time;
  _ChatMessage({required this.text, required this.isBot})
      : time = DateTime.now();
}

class _QA {
  final String en;
  final String ne;
  final String answerEn;
  final String answerNe;
  const _QA(this.en, this.ne, this.answerEn, this.answerNe);
}

const _qas = [
  _QA(
    '🔍 How to verify a seller?',
    '🔍 विक्रेता कसरी प्रमाणित गर्ने?',
    'Search the seller by their phone number, eSewa ID, or social media handle on the home screen. Their trust score and any community reports will appear instantly.',
    'गृहपृष्ठमा विक्रेताको फोन नम्बर, eSewa ID, वा सोसल मिडिया ह्यान्डल खोज्नुहोस्। उनीहरूको ट्रस्ट स्कोर र सामुदायिक रिपोर्टहरू तुरुन्त देखिनेछन्।',
  ),
  _QA(
    '⭐ What is a trust score?',
    '⭐ ट्रस्ट स्कोर के हो?',
    'Trust Score (0–100) is calculated from: Verification status (25 pts), Report history (35 pts), Community ratings (25 pts), Account maturity (15 pts). Scores above 80 are Trusted, below 50 are High Risk.',
    'ट्रस्ट स्कोर (०–१००) यसरी गणना गरिन्छ: प्रमाणीकरण स्थिति (२५ अंक), रिपोर्ट इतिहास (३५ अंक), समुदाय रेटिङ (२५ अंक), खाता परिपक्वता (१५ अंक)। ८० भन्दा माथि विश्वसनीय, ५० भन्दा तल उच्च जोखिम।',
  ),
  _QA(
    '🚨 How to report fraud?',
    '🚨 धोखाधडी कसरी रिपोर्ट गर्ने?',
    'Tap "Report Fraud" on the home screen or the Quick Actions section. Fill in the seller details, describe what happened, and upload screenshots as evidence. Reports are reviewed within 24 hours.',
    'गृहपृष्ठमा "धोखाधडी रिपोर्ट" थिच्नुहोस्। विक्रेताको विवरण भर्नुहोस्, के भयो त्यो लेख्नुहोस्, र प्रमाणका रूपमा स्क्रिनसट अपलोड गर्नुहोस्। रिपोर्ट २४ घण्टाभित्र समीक्षा गरिन्छ।',
  ),
  _QA(
    '⚠️ Common scams in Nepal',
    '⚠️ नेपालमा सामान्य घोटाला',
    'Common scams: 1) TikTok/Instagram sellers taking payment then disappearing. 2) Fake products sent instead of advertised ones. 3) Impersonation of trusted sellers. 4) Asking for advance payment via eSewa then blocking you.',
    'सामान्य घोटालाहरू: १) TikTok/Instagram विक्रेताले भुक्तानी लिएर हराउने। २) विज्ञापनको सट्टा नक्कली उत्पादन पठाउने। ३) विश्वसनीय विक्रेताको नक्कल गर्ने। ४) eSewa मार्फत अग्रिम भुक्तानी माग्ने र अवरुद्ध गर्ने।',
  ),
  _QA(
    '💳 eSewa/Khalti safety tips',
    '💳 eSewa/Khalti सुरक्षा सुझाव',
    'Safety tips: ✅ Always verify on SafeBuy before paying. ✅ Use "Goods & Services" not personal transfer. ✅ Never pay before seeing a product review. ✅ Check if seller has verified badge. ❌ Never share OTP with anyone.',
    'सुरक्षा सुझावहरू: ✅ भुक्तानी गर्नु अघि SafeBuy मा प्रमाणित गर्नुहोस्। ✅ व्यक्तिगत ट्रान्सफर होइन "सामान र सेवा" प्रयोग गर्नुहोस्। ✅ उत्पादन समीक्षा हेरेपछि मात्र भुक्तानी गर्नुहोस्। ❌ OTP कहिल्यै कसैसँग साझा नगर्नुहोस्।',
  ),
  _QA(
    '🏪 Register my business',
    '🏪 मेरो व्यवसाय दर्ता गर्ने',
    'Tap "Register Business" on the home screen. Fill in your business name, phone number, business type, and social media handles. After verification (48 hrs), you get a SafeBuy trust badge to share with buyers.',
    'गृहपृष्ठमा "व्यवसाय दर्ता" थिच्नुहोस्। आफ्नो व्यवसायको नाम, फोन नम्बर, व्यवसायको प्रकार, र सोसल मिडिया ह्यान्डलहरू भर्नुहोस्। प्रमाणीकरण पछि (४८ घण्टा), तपाईंले खरिदारहरूसँग साझा गर्न SafeBuy ट्रस्ट ब्याज पाउनुहुन्छ।',
  ),
];

// ── Provider ──────────────────────────────────────────────────────────────────

final _chatMessagesProvider =
    StateProvider<List<_ChatMessage>>((ref) => []);

// ── Widget ────────────────────────────────────────────────────────────────────

class ChatbotFAB extends ConsumerWidget {
  const ChatbotFAB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    return FloatingActionButton.extended(
      heroTag: 'chatbot_fab',
      onPressed: () => _openChat(context, lang),
      backgroundColor: const Color(AppColors.accent),
      foregroundColor: Colors.white,
      elevation: 6,
      icon: const Icon(Icons.support_agent, size: 22),
      label: Text(
        lang == 'ne' ? 'सहायता' : 'Help',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }

  void _openChat(BuildContext context, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChatSheet(lang: lang),
    );
  }
}

// ── Chat Sheet ────────────────────────────────────────────────────────────────

class _ChatSheet extends ConsumerStatefulWidget {
  final String lang;
  const _ChatSheet({required this.lang});

  @override
  ConsumerState<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends ConsumerState<_ChatSheet> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final msgs = ref.read(_chatMessagesProvider);
      if (msgs.isEmpty) {
        _addBotMessage(widget.lang == 'ne'
            ? 'नमस्ते! 👋 म SafeBuy Nepal को सहायक हुँ। तलका विषयहरूमध्ये एउटा छान्नुहोस् वा आफ्नो प्रश्न टाइप गर्नुहोस्।'
            : 'Hello! 👋 I\'m the SafeBuy Nepal assistant. Choose a topic below or type your question.');
      }
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _addBotMessage(String text) {
    ref
        .read(_chatMessagesProvider.notifier)
        .update((msgs) => [...msgs, _ChatMessage(text: text, isBot: true)]);
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    ref
        .read(_chatMessagesProvider.notifier)
        .update((msgs) => [...msgs, _ChatMessage(text: text, isBot: false)]);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleQuickReply(_QA qa) async {
    final question = widget.lang == 'ne' ? qa.ne : qa.en;
    _addUserMessage(question);
    setState(() => _isTyping = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _isTyping = false);
    _addBotMessage(widget.lang == 'ne' ? qa.answerNe : qa.answerEn);
  }

  Future<void> _handleTextInput() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    _addUserMessage(text);
    setState(() => _isTyping = true);
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() => _isTyping = false);

    // Simple keyword matching
    final lower = text.toLowerCase();
    _QA? match;
    if (lower.contains('verify') || lower.contains('search') || lower.contains('प्रमाणित') || lower.contains('खोज')) {
      match = _qas[0];
    } else if (lower.contains('trust') || lower.contains('score') || lower.contains('ट्रस्ट') || lower.contains('स्कोर')) {
      match = _qas[1];
    } else if (lower.contains('report') || lower.contains('fraud') || lower.contains('रिपोर्ट') || lower.contains('धोखा')) {
      match = _qas[2];
    } else if (lower.contains('scam') || lower.contains('घोटाला') || lower.contains('common')) {
      match = _qas[3];
    } else if (lower.contains('esewa') || lower.contains('khalti') || lower.contains('pay') || lower.contains('भुक्तानी')) {
      match = _qas[4];
    } else if (lower.contains('register') || lower.contains('business') || lower.contains('दर्ता') || lower.contains('व्यवसाय')) {
      match = _qas[5];
    }

    if (match != null) {
      _addBotMessage(widget.lang == 'ne' ? match.answerNe : match.answerEn);
    } else {
      _addBotMessage(widget.lang == 'ne'
          ? 'माफ गर्नुहोस्, मैले त्यो बुझ्न सकिनँ। कृपया तलका विकल्पहरूमध्ये एउटा छान्नुहोस् वा अर्को प्रश्न सोध्नुहोस्।'
          : 'Sorry, I didn\'t understand that. Please choose one of the options below or rephrase your question.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(_chatMessagesProvider);
    final lang = widget.lang;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(AppColors.background),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                    bottom: BorderSide(color: Color(AppColors.divider))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(AppColors.accent).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent,
                        color: Color(AppColors.accent), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang == 'ne'
                              ? 'SafeBuy सहायक'
                              : 'SafeBuy Assistant',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: Color(AppColors.trusted),
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              lang == 'ne' ? 'अनलाइन' : 'Online',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(AppColors.trusted)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      ref.read(_chatMessagesProvider.notifier).state = [];
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  ...messages.map((m) => _MessageBubble(
                        message: m,
                        lang: lang,
                      )),
                  if (_isTyping) _TypingIndicator(),
                  // Quick replies (always show at bottom)
                  const SizedBox(height: 12),
                  Text(
                    lang == 'ne' ? 'प्रश्नहरू:' : 'Quick questions:',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(AppColors.textGrey),
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _qas
                        .map((qa) => GestureDetector(
                              onTap: _isTyping ? null : () => _handleQuickReply(qa),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(AppColors.accent)
                                          .withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  lang == 'ne' ? qa.ne : qa.en,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(AppColors.textDark),
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Input
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                    top: BorderSide(color: Color(AppColors.divider))),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, -2))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      onSubmitted: (_) => _handleTextInput(),
                      decoration: InputDecoration(
                        hintText: lang == 'ne'
                            ? 'आफ्नो प्रश्न लेख्नुहोस्...'
                            : 'Type your question...',
                        hintStyle: const TextStyle(
                            fontSize: 13, color: Color(AppColors.textGrey)),
                        filled: true,
                        fillColor: const Color(AppColors.background),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                              color: Color(AppColors.accent), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _handleTextInput,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(AppColors.accent),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
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
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final String lang;
  const _MessageBubble({required this.message, required this.lang});

  @override
  Widget build(BuildContext context) {
    final isBot = message.isBot;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isBot) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(AppColors.accent),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isBot
                    ? Colors.white
                    : const Color(AppColors.primary),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isBot ? 4 : 16),
                  bottomRight: Radius.circular(isBot ? 16 : 4),
                ),
                border: isBot
                    ? Border.all(color: const Color(AppColors.divider))
                    : null,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 13,
                  color: isBot
                      ? const Color(AppColors.textDark)
                      : Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (!isBot) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Typing Indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      )..repeat(reverse: true, period: Duration(milliseconds: 800 + i * 160)),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(AppColors.accent),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.support_agent, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: const Color(AppColors.divider)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _controllers[i],
                  builder: (_, _) => Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        const Color(AppColors.textGrey).withValues(alpha: 0.3),
                        const Color(AppColors.accent),
                        _controllers[i].value,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
