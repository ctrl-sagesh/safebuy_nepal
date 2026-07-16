import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/seller_model.dart';
import '../core/agent_base.dart';
import '../core/agent_message.dart';
import '../core/agent_response.dart';
import 'safeguard_intent_classifier.dart';
import 'safeguard_knowledge_base.dart';

/// Agent 1: SafeGuard AI conversational assistant.
///
/// Classifies user intent, fetches live Firestore data for seller queries,
/// and returns context-aware bilingual responses.
class SafeguardAgent extends AgentBase {
  SafeguardAgent()
      : super(
          agentId: 'safeguard',
          agentName: 'Safety Assistant',
          agentDescription:
              'Conversational assistant for seller verification and fraud guidance',
        );

  @override
  Future<void> initialize() async {
    // Knowledge base is compile-time constant; nothing to load.
    isActive = true;
  }

  @override
  Future<AgentResponse> process(AgentMessage message) async {
    try {
      // Step 1: Classify intent
      final result = SafeguardIntentClassifier.classify(
        message.content,
        message.language,
      );

      // Step 2: If seller-specific, fetch live data
      if (result.intent == SafeguardIntent.askAboutSeller) {
        return await _handleSellerQuery(
          message,
          result.extractedPhone,
          result.extractedHandle,
        );
      }

      // Step 3: Look up static knowledge base
      final entry =
          SafeguardKnowledgeBase.knowledge[result.intent] ??
          SafeguardKnowledgeBase.knowledge[SafeguardIntent.unknown]!;

      final lang = message.language;
      return AgentResponse(
        text: lang == 'ne' ? entry.ne : entry.en,
        textNepali: entry.ne,
        type: entry.type,
        actions: entry.actions,
        agentId: agentId,
        requiresFollowUp: entry.followUp != null,
        followUpQuestion:
            lang == 'ne' ? (entry.followUpNe ?? '') : (entry.followUp ?? ''),
      );
    } catch (_) {
      // Never crash; return fallback.
      return _fallbackResponse(message.language);
    }
  }

  // ── Seller-specific query handler ────────────────────────────────

  Future<AgentResponse> _handleSellerQuery(
    AgentMessage message,
    String? phone,
    String? handle,
  ) async {
    SellerModel? seller;

    try {
      if (phone != null) {
        seller = await _findSellerByPhone(phone);
      }
      if (seller == null && handle != null) {
        seller = await _findSellerByHandle(handle);
      }
    } catch (_) {
      // Firestore error; fall through to "not found"
    }

    if (seller == null) {
      return _sellerNotFoundResponse(message);
    }

    return _buildSellerResponse(seller, message.language);
  }

  Future<SellerModel?> _findSellerByPhone(String phone) async {
    final snap = await FirebaseFirestore.instance
        .collection('sellers')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 5));
    if (snap.docs.isEmpty) return null;
    return SellerModel.fromFirestore(snap.docs.first);
  }

  Future<SellerModel?> _findSellerByHandle(String handle) async {
    final results = await Future.wait([
      FirebaseFirestore.instance
          .collection('sellers')
          .where('tiktokHandle', isEqualTo: handle)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5)),
      FirebaseFirestore.instance
          .collection('sellers')
          .where('instagramHandle', isEqualTo: handle)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5)),
    ]);
    final allDocs = [...results[0].docs, ...results[1].docs];
    if (allDocs.isEmpty) return null;
    return SellerModel.fromFirestore(allDocs.first);
  }

  AgentResponse _sellerNotFoundResponse(AgentMessage message) {
    final isNe = message.language == 'ne';
    return AgentResponse(
      text: isNe
          ? 'यो seller हाम्रो database मा भेटिएन। यसको मतलब:\n\n'
              '- अझै रिपोर्ट भएको छैन वा दर्ता भएको छैन\n'
              '- फोन नम्बरबाट खोज्न प्रयास गर्नुस्\n\n'
              'यदि यसले तपाईंलाई ठग्यो भने रिपोर्ट गर्नुस्।'
          : 'I could not find a seller with that information in our '
              'database. This could mean:\n\n'
              '- They have not been reported or registered yet\n'
              '- Try searching with their phone number instead\n\n'
              'If you were scammed by this seller, you can file a '
              'report and we will create their profile automatically.',
      textNepali: 'यो seller हाम्रो database मा भेटिएन।',
      type: ResponseType.text,
      actions: [
        AgentAction(
          label: 'Report This Seller',
          labelNe: 'यो Seller रिपोर्ट गर्नुस्',
          actionType: 'navigate',
          payload: {'route': '/report', 'prefill': message.content},
        ),
      ],
      agentId: agentId,
    );
  }

  AgentResponse _buildSellerResponse(SellerModel seller, String lang) {
    final isNe = lang == 'ne';
    final verdict = seller.trustVerdict;
    final verdictEmoji =
        verdict == 'trusted' ? '🟢' : verdict == 'unverified' ? '🟡' : '🔴';
    final verdictText = verdict == 'trusted'
        ? (isNe ? 'भरोसायोग्य' : 'TRUSTED')
        : verdict == 'unverified'
            ? (isNe ? 'अपरिचित' : 'UNVERIFIED')
            : (isNe ? 'उच्च जोखिम' : 'HIGH RISK');

    final name =
        seller.businessName?.isNotEmpty == true
            ? seller.businessName!
            : seller.name;

    final buf = StringBuffer();
    buf.writeln('$verdictEmoji $name\n');
    buf.writeln(
      'Trust Score: ${seller.trustScore.toStringAsFixed(0)}/100 $verdictText\n',
    );

    if (seller.scamReportCount > 0) {
      buf.writeln(
        isNe
            ? 'यो seller विरुद्ध ${seller.scamReportCount} ठगी रिपोर्ट छ।\n'
            : '${seller.scamReportCount} fraud report(s) filed against this seller.\n',
      );
    } else {
      buf.writeln(isNe ? 'कुनै ठगी रिपोर्ट छैन।\n' : 'No fraud reports on record.\n');
    }

    buf.writeln(
      isNe
          ? 'Reviews: ${seller.reviewCount}'
          : 'Reviews: ${seller.reviewCount} customer reviews',
    );
    buf.writeln(
      seller.isVerified
          ? (isNe ? 'Phone Verified' : 'Phone Verified')
          : (isNe ? 'Phone Not Verified' : 'Phone Not Verified'),
    );

    if (seller.tiktokHandle?.isNotEmpty == true) {
      buf.writeln(isNe ? 'TikTok Linked' : 'TikTok Linked');
    }

    buf.writeln();

    if (verdict == 'high_risk') {
      buf.write(
        isNe
            ? 'यो seller लाई पैसा नदिन कडा सिफारिश छ।'
            : 'We strongly recommend NOT paying this seller until you investigate further.',
      );
    } else if (verdict == 'trusted') {
      buf.write(
        isNe
            ? 'Community data अनुसार यो seller भरोसायोग्य देखिन्छ।'
            : 'This seller appears trustworthy based on community data.',
      );
    } else {
      buf.write(
        isNe
            ? 'पैसा तिर्नुअघि video call मार्फत सामान हेर्नुस्।'
            : 'Proceed with caution. Ask for video call proof before paying.',
      );
    }

    return AgentResponse(
      text: buf.toString(),
      textNepali: buf.toString(),
      type: ResponseType.sellerCard,
      data: {'seller': seller.toMap()},
      actions: [
        AgentAction(
          label: 'View Full Profile',
          labelNe: 'पूरा Profile हेर्नुस्',
          actionType: 'navigate',
          payload: {'route': '/seller/${seller.sellerId}'},
        ),
        if (verdict == 'high_risk' || seller.scamReportCount > 0)
          AgentAction(
            label: 'Report This Seller',
            labelNe: 'रिपोर्ट गर्नुस्',
            actionType: 'navigate',
            payload: {'route': '/report'},
          ),
      ],
      agentId: agentId,
    );
  }

  AgentResponse _fallbackResponse(String lang) {
    final entry = SafeguardKnowledgeBase.knowledge[SafeguardIntent.unknown]!;
    return AgentResponse(
      text: lang == 'ne' ? entry.ne : entry.en,
      textNepali: entry.ne,
      agentId: agentId,
    );
  }
}
