import '../core/agent_response.dart';
import 'safeguard_intent_classifier.dart';

/// A single knowledge base entry with bilingual content.
class KnowledgeEntry {
  const KnowledgeEntry({
    required this.en,
    required this.ne,
    this.type = ResponseType.text,
    this.actions = const [],
    this.followUp,
    this.followUpNe,
  });

  final String en;
  final String ne;
  final ResponseType type;
  final List<AgentAction> actions;
  final String? followUp;
  final String? followUpNe;
}

/// Static knowledge base for the SafeGuard AI agent.
/// Each intent maps to a bilingual response with optional follow-up.
class SafeguardKnowledgeBase {
  SafeguardKnowledgeBase._();

  static const Map<SafeguardIntent, KnowledgeEntry> knowledge = {
    // ── Greet ──────────────────────────────────────────────────────
    SafeguardIntent.greet: KnowledgeEntry(
      en: 'Namaste! I am your SafeBuy safety assistant. '
          'I can help you:\n\n'
          '- Verify if a seller is trustworthy\n'
          '- Guide you through reporting fraud\n'
          '- Explain how our trust scores work\n'
          '- Answer questions about online safety in Nepal\n\n'
          'What would you like to know?',
      ne: 'नमस्ते! म SafeBuy को सुरक्षा सहायक हुँ। '
          'म तपाईंलाई सहयोग गर्न सक्छु:\n\n'
          '- कुनै seller विश्वसनीय छ कि छैन जाँच्न\n'
          '- ठगी रिपोर्ट गर्ने तरिका सिकाउन\n'
          '- Trust Score कसरी काम गर्छ बुझाउन\n'
          '- Nepal मा online safety बारे प्रश्नहरू\n\n'
          'तपाईंलाई के जान्न मन छ?',
      followUp: 'Would you like to verify a seller right now? '
          'Just share their phone number or TikTok handle.',
      followUpNe: 'के तपाईं अहिले कुनै seller जाँच्न चाहनुहुन्छ? '
          'उनको फोन नम्बर वा TikTok handle पठाउनुस्।',
    ),

    // ── Trust Score ────────────────────────────────────────────────
    SafeguardIntent.askTrustScore: KnowledgeEntry(
      en: 'Our Trust Score (0-100) is calculated using 5 factors:\n\n'
          'Report Severity (40%) : How many fraud reports exist '
          'and how much money was lost. Recent reports count more.\n\n'
          'Verification Status (25%) : Did the seller verify their '
          'phone number? Are their social media accounts linked?\n\n'
          'Review Authenticity (20%) : Real customer reviews — '
          'fake and copy-pasted reviews are filtered out.\n\n'
          'Dispute Response (10%) : Does the seller respond to '
          'allegations? Fast responses = higher score.\n\n'
          'Account Age (5%) : New accounts start lower. Trust '
          'is built over time.\n\n'
          'Verdicts:\n'
          '80-100 = Trusted\n'
          '50-79 = Unverified\n'
          '0-49 = High Risk',
      ne: 'हाम्रो Trust Score (0-100) ५ कारकहरूमा आधारित छ:\n\n'
          'रिपोर्टको गम्भीरता (40%) : कति ठगी रिपोर्ट छन् '
          'र कति पैसा गुम्यो।\n\n'
          'Verification (25%) : Seller ले फोन verify गरेको छ '
          'कि छैन, social media linked छ कि छैन।\n\n'
          'Review (20%) : वास्तविक customer को review।\n\n'
          'Dispute Response (10%) : Seller ले आरोपको जवाफ '
          'दिन्छ कि दिँदैन।\n\n'
          'Account Age (5%) : नयाँ account मा score कम हुन्छ।\n\n'
          '80-100 = Trusted\n'
          '50-79 = Unverified\n'
          '0-49 = High Risk',
      type: ResponseType.steps,
    ),

    // ── How to Report ──────────────────────────────────────────────
    SafeguardIntent.askHowToReport: KnowledgeEntry(
      en: 'Here is how to file a fraud report on SafeBuy Nepal:\n\n'
          'Step 1 : Tap "Report Fraud" on the home screen\n\n'
          'Step 2 : Enter the seller\'s details:\n'
          '  - Phone number (most important)\n'
          '  - eSewa/Khalti ID if you have it\n'
          '  - Their TikTok or Instagram handle\n\n'
          'Step 3 : Describe what happened:\n'
          '  - How much did you lose? (in NPR)\n'
          '  - What type of fraud? (no delivery, fake product, etc.)\n'
          '  - Write at least 50 characters describing the incident\n\n'
          'Step 4 : Upload evidence:\n'
          '  - Screenshot of your payment receipt\n'
          '  - Screenshot of your chat with the seller\n\n'
          'Step 5 : Check the declaration box and submit\n\n'
          'The seller\'s trust score updates automatically within '
          'minutes of your report being submitted.',
      ne: 'SafeBuy Nepal मा ठगी रिपोर्ट कसरी गर्ने:\n\n'
          'Step 1 : Home screen मा "Report Fraud" थिच्नुस्\n\n'
          'Step 2 : Seller को जानकारी भर्नुस्:\n'
          '  - फोन नम्बर (सबैभन्दा महत्त्वपूर्ण)\n'
          '  - eSewa/Khalti ID भए दिनुस्\n'
          '  - TikTok वा Instagram handle\n\n'
          'Step 3 : के भयो लेख्नुस्:\n'
          '  - कति पैसा गुम्यो? (NPR मा)\n'
          '  - ठगीको प्रकार छान्नुस्\n'
          '  - कम्तीमा ५० अक्षरमा घटना वर्णन गर्नुस्\n\n'
          'Step 4 : प्रमाण upload गर्नुस्:\n'
          '  - Payment receipt को screenshot\n'
          '  - Seller सँगको chat को screenshot\n\n'
          'Step 5 : Declaration box check गरी submit गर्नुस्',
      type: ResponseType.steps,
      actions: [
        AgentAction(
          label: 'File a Report Now',
          labelNe: 'अहिले रिपोर्ट गर्नुस्',
          actionType: 'navigate',
          payload: {'route': '/report'},
        ),
      ],
    ),

    // ── How to Verify ──────────────────────────────────────────────
    SafeguardIntent.askHowToVerify: KnowledgeEntry(
      en: 'To verify a seller on SafeBuy Nepal:\n\n'
          'Step 1 : Open the Verify tab (magnifying glass icon)\n\n'
          'Step 2 : Enter the seller\'s identifier:\n'
          '  - Phone number (e.g. 9841234567)\n'
          '  - eSewa/Khalti ID\n'
          '  - TikTok or Instagram handle\n\n'
          'Step 3 : View results:\n'
          '  - Trust Score (0-100) with color-coded verdict\n'
          '  - Number of fraud reports filed\n'
          '  - Community reviews and ratings\n'
          '  - Verification status and account age\n\n'
          'Always check before sending money to any social media seller.',
      ne: 'SafeBuy Nepal मा seller जाँच्ने तरिका:\n\n'
          'Step 1 : Verify tab खोल्नुस् (magnifying glass icon)\n\n'
          'Step 2 : Seller को पहिचान भर्नुस्:\n'
          '  - फोन नम्बर (जस्तै 9841234567)\n'
          '  - eSewa/Khalti ID\n'
          '  - TikTok वा Instagram handle\n\n'
          'Step 3 : नतिजा हेर्नुस्:\n'
          '  - Trust Score (0-100) रंग सहित\n'
          '  - ठगी रिपोर्ट संख्या\n'
          '  - समुदायिक review र rating\n'
          '  - Verification status र account उमेर\n\n'
          'पैसा पठाउनु अघि सधैं seller जाँच गर्नुस्।',
      type: ResponseType.steps,
      actions: [
        AgentAction(
          label: 'Verify a Seller',
          labelNe: 'Seller जाँच्नुस्',
          actionType: 'navigate',
          payload: {'route': '/verify'},
        ),
      ],
    ),

    // ── How to Register ────────────────────────────────────────────
    SafeguardIntent.askHowToRegister: KnowledgeEntry(
      en: 'To register your business on SafeBuy Nepal:\n\n'
          'Step 1 : Go to Dashboard > "Register Business"\n\n'
          'Step 2 : Fill in your business details:\n'
          '  - Business name\n'
          '  - Your phone number\n'
          '  - Business category\n'
          '  - Social media handles (TikTok, Instagram, Facebook)\n\n'
          'Step 3 : Verify your phone number via OTP\n\n'
          'Step 4 : Optional: Upload PAN certificate for verified badge\n\n'
          'Benefits of registering:\n'
          '  - Get a SafeBuy profile buyers can check\n'
          '  - Respond to any reports filed against you\n'
          '  - Build trust score over time\n'
          '  - Verified badge shows you are a legitimate business',
      ne: 'SafeBuy Nepal मा व्यवसाय दर्ता गर्ने तरिका:\n\n'
          'Step 1 : Dashboard > "Register Business" मा जानुस्\n\n'
          'Step 2 : व्यवसायको जानकारी भर्नुस्:\n'
          '  - व्यवसायको नाम\n'
          '  - फोन नम्बर\n'
          '  - व्यवसाय श्रेणी\n'
          '  - Social media handle (TikTok, Instagram, Facebook)\n\n'
          'Step 3 : OTP बाट फोन verify गर्नुस्\n\n'
          'Step 4 : ऐच्छिक: PAN certificate upload गर्नुस्\n\n'
          'दर्ताका फाइदाहरू:\n'
          '  - SafeBuy profile पाउनुस्\n'
          '  - रिपोर्टको जवाफ दिन सक्नुस्\n'
          '  - समयसँगै trust score बढाउनुस्\n'
          '  - Verified badge ले वैधता देखाउँछ',
      type: ResponseType.steps,
      actions: [
        AgentAction(
          label: 'Register Business',
          labelNe: 'व्यवसाय दर्ता गर्नुस्',
          actionType: 'navigate',
          payload: {'route': '/register-business'},
        ),
      ],
    ),

    // ── Scam Types ─────────────────────────────────────────────────
    SafeguardIntent.askAboutScamTypes: KnowledgeEntry(
      en: 'The most common social commerce scams in Nepal:\n\n'
          'Non-Delivery (35% of reports)\n'
          'Seller collects payment then disappears. Most common on TikTok.\n\n'
          'Fake Products (28% of reports)\n'
          'Item delivered is completely different from advertised.\n\n'
          'Payment Fraud (20% of reports)\n'
          'Fake eSewa QR codes that send money to wrong account.\n\n'
          'Account Cloning (12% of reports)\n'
          'Scammer copies a legitimate seller\'s profile photos and name.\n\n'
          'Red flags to watch for:\n'
          '  - Account created less than 30 days ago\n'
          '  - Prices far below market rate\n'
          '  - Refuses to video call to show product\n'
          '  - Asks for full payment before shipping\n'
          '  - No reviews or only very recent reviews',
      ne: 'Nepal मा सबैभन्दा सामान्य social commerce ठगी:\n\n'
          'Non-Delivery (३५%)\n'
          'Seller पैसा लिएर गायब हुन्छ। TikTok मा धेरै।\n\n'
          'नक्कली सामान (२८%)\n'
          'मगाएको भन्दा फरक सामान आउँछ।\n\n'
          'Payment ठगी (२०%)\n'
          'नक्कली eSewa QR code बाट गलत ठाउँमा पैसा जान्छ।\n\n'
          'Account Clone (१२%)\n'
          'ठग्नेले असली seller को profile copy गर्छ।\n\n'
          'यी संकेत देखे सावधान हुनुस्:\n'
          '  - ३० दिनभन्दा कम पुरानो account\n'
          '  - बजार भाउभन्दा धेरै सस्तो मूल्य\n'
          '  - Video call गर्न मान्दैन\n'
          '  - पूरा पैसा अग्रिम माग्छ\n'
          '  - कुनै review छैन वा सबै नयाँ review',
    ),

    // ── About Platform ─────────────────────────────────────────────
    SafeguardIntent.askAboutPlatform: KnowledgeEntry(
      en: 'SafeBuy Nepal is a community-driven seller trust verification '
          'platform built to protect Nepali online buyers from social '
          'commerce fraud.\n\n'
          'Key features:\n'
          '  - Trust Score (0-100) for every seller based on 5 weighted factors\n'
          '  - Fraud reporting with evidence upload\n'
          '  - Community reviews with fake-review filtering\n'
          '  - A built-in safety assistant (that is me!)\n'
          '  - Fraud pattern detection that auto-alerts the community\n'
          '  - Bilingual support (English and Nepali)\n\n'
          'Built as a BSc thesis project for Ethical Hacking and Cybersecurity '
          'at Softwarica College / Coventry University.',
      ne: 'SafeBuy Nepal एक समुदाय-संचालित seller trust verification '
          'platform हो जसले नेपाली अनलाइन खरिदकर्ताहरूलाई social '
          'commerce ठगीबाट जोगाउँछ।\n\n'
          'मुख्य विशेषताहरू:\n'
          '  - हरेक seller को Trust Score (0-100)\n'
          '  - प्रमाण सहित ठगी रिपोर्ट\n'
          '  - नक्कली review हरू फिल्टर गरिएका सुरक्षित review\n'
          '  - सुरक्षा सहायक (त्यो म हुँ!)\n'
          '  - Fraud pattern detection जसले community लाई alert गर्छ\n'
          '  - English र Nepali दुवै भाषा\n\n'
          'Softwarica College / Coventry University को BSc thesis project।',
    ),

    // ── Evidence ───────────────────────────────────────────────────
    SafeguardIntent.askAboutEvidence: KnowledgeEntry(
      en: 'Always save this evidence IMMEDIATELY after being scammed:\n\n'
          'Payment Proof:\n'
          '  - eSewa or Khalti transaction receipt\n'
          '  - Bank transfer screenshot\n'
          '  - Note the transaction ID and date\n\n'
          'Communication Records:\n'
          '  - Screenshot ALL chat messages with the seller\n'
          '  - Save their phone number and social media handle\n'
          '  - Screenshot their profile page before they delete it\n\n'
          'Seller Identity:\n'
          '  - Their TikTok/Instagram profile URL\n'
          '  - Any product listings they posted\n'
          '  - Their eSewa or Khalti phone number\n\n'
          'Under Nepal\'s Electronic Transactions Act 2063, '
          'this evidence can support a formal complaint at the '
          'Cybercrime Bureau, Nepal Police.',
      ne: 'ठगी भएपछि तुरुन्त यी प्रमाण save गर्नुस्:\n\n'
          'Payment प्रमाण:\n'
          '  - eSewa वा Khalti transaction receipt\n'
          '  - Transaction ID र मिति नोट गर्नुस्\n\n'
          'Chat Record:\n'
          '  - Seller सँगको सबै chat screenshot गर्नुस्\n'
          '  - Seller को profile delete हुनुअघि screenshot गर्नुस्\n\n'
          'Seller को पहिचान:\n'
          '  - TikTok/Instagram profile URL\n'
          '  - eSewa वा Khalti नम्बर\n\n'
          'Nepal को ETA 2063 अनुसार यी प्रमाणले '
          'Cybercrime Bureau मा उजुरी दिन मद्दत गर्छ।',
      type: ResponseType.steps,
    ),

    // ── ETA / Legal ────────────────────────────────────────────────
    SafeguardIntent.askAboutETA: KnowledgeEntry(
      en: 'Nepal\'s Electronic Transactions Act 2063 (2008) is the '
          'primary law covering digital fraud:\n\n'
          'Section 47 : Computer Fraud\n'
          'Criminalizes unauthorized digital transactions and deception '
          'using electronic means. Penalty: up to 2 years imprisonment '
          'and NPR 200,000 fine.\n\n'
          'Section 48 : Electronic Fraud\n'
          'Specifically covers receiving payment without delivering '
          'goods or services. This directly applies to TikTok/Instagram '
          'seller scams.\n\n'
          'Where to complain:\n'
          '  - Cybercrime Investigation Bureau, Nepal Police\n'
          '  - Kathmandu: Naxal, Phone: 01-4412323\n\n'
          'A SafeBuy Nepal report preserves your evidence '
          'in a structured format that supports formal complaints.',
      ne: 'Nepal को Electronic Transactions Act 2063 digital '
          'ठगीको मुख्य कानून हो:\n\n'
          'Section 47 : Computer Fraud\n'
          'Electronic माध्यमबाट ठगी गरेमा: २ वर्षसम्म कैद '
          'र NPR २,००,००० जरिमाना।\n\n'
          'Section 48 : Electronic Fraud\n'
          'पैसा लिएर सामान नदिनु यही section अन्तर्गत पर्छ।\n\n'
          'उजुरी कहाँ दिने:\n'
          '  - Cybercrime Investigation Bureau, Nepal Police\n'
          '  - Kathmandu: Naxal, Phone: 01-4412323\n\n'
          'SafeBuy Nepal को रिपोर्टले तपाईंको प्रमाण '
          'structured तरिकामा सुरक्षित राख्छ।',
    ),

    // ── eSewa ──────────────────────────────────────────────────────
    SafeguardIntent.askAbouteSewa: KnowledgeEntry(
      en: 'Safety tips for eSewa/Khalti transactions:\n\n'
          'Before paying:\n'
          '  - Verify the seller\'s eSewa ID on SafeBuy first\n'
          '  - Never scan QR codes sent through chat messages\n'
          '  - Always double check the receiving name and number\n\n'
          'After paying:\n'
          '  - Screenshot the transaction confirmation immediately\n'
          '  - Note the transaction ID (you need this for disputes)\n'
          '  - If no delivery within promised time, contact eSewa support\n\n'
          'Common eSewa scams:\n'
          '  - Fake QR codes that look like eSewa but go to scammer\n'
          '  - "Payment failed" lie where seller claims not received\n'
          '  - Fake eSewa confirmation screenshots sent as "proof"\n\n'
          'If scammed via eSewa, report to eSewa: support@esewa.com.np '
          'and file a SafeBuy report.',
      ne: 'eSewa/Khalti transaction को सुरक्षा सुझाव:\n\n'
          'पैसा तिर्नु अघि:\n'
          '  - Seller को eSewa ID SafeBuy मा जाँच्नुस्\n'
          '  - Chat मा आएको QR code scan नगर्नुस्\n'
          '  - पाउने व्यक्तिको नाम र नम्बर जाँच्नुस्\n\n'
          'पैसा तिरेपछि:\n'
          '  - Transaction confirmation तुरुन्त screenshot गर्नुस्\n'
          '  - Transaction ID नोट गर्नुस्\n'
          '  - सामान नआए eSewa support मा सम्पर्क गर्नुस्\n\n'
          'सामान्य eSewa ठगी:\n'
          '  - नक्कली QR code जसबाट ठगकर्ताको खातामा पैसा जान्छ\n'
          '  - "Payment आएन" भनेर झुटो बोल्ने\n'
          '  - नक्कली eSewa confirmation screenshot पठाउने\n\n'
          'eSewa बाट ठगिए: support@esewa.com.np मा सम्पर्क गर्नुस्।',
    ),

    // ── TikTok ─────────────────────────────────────────────────────
    SafeguardIntent.askAboutTikTok: KnowledgeEntry(
      en: 'TikTok is the #1 platform for social commerce scams in Nepal.\n\n'
          'Why TikTok is risky:\n'
          '  - Viral videos create urgency ("limited stock!")\n'
          '  - Easy to create fake accounts with stolen content\n'
          '  - Comments can be filtered to hide negative feedback\n'
          '  - No built-in buyer protection like established e-commerce\n\n'
          'How to buy safely from TikTok sellers:\n'
          '  - ALWAYS check the seller on SafeBuy before paying\n'
          '  - Ask for a video call showing the actual product\n'
          '  - Insist on COD (Cash on Delivery) when possible\n'
          '  - Never send full payment via eSewa/Khalti upfront\n'
          '  - Check their TikTok account age and follower quality\n'
          '  - Look for saved review videos from real customers\n\n'
          'If something feels wrong, trust your instinct and do not pay.',
      ne: 'TikTok Nepal मा social commerce ठगीको #1 platform हो।\n\n'
          'TikTok किन जोखिमपूर्ण:\n'
          '  - Viral video ले "limited stock!" भनेर हतार गराउँछ\n'
          '  - चोरेको content ले नक्कली account बनाउन सजिलो\n'
          '  - नकारात्मक comment filter गर्न सकिन्छ\n'
          '  - E-commerce जस्तो buyer protection छैन\n\n'
          'TikTok seller बाट सुरक्षित किन्ने तरिका:\n'
          '  - पैसा तिर्नु अघि सधैं SafeBuy मा seller जाँच्नुस्\n'
          '  - वास्तविक सामान देखाउन video call माग्नुस्\n'
          '  - सकेसम्म COD (Cash on Delivery) गर्नुस्\n'
          '  - eSewa/Khalti बाट अग्रिम पूरा पैसा नपठाउनुस्\n'
          '  - TikTok account को उमेर र follower quality जाँच्नुस्\n\n'
          'शंका लागे पैसा नतिर्नुस्।',
    ),

    // ── Refund ─────────────────────────────────────────────────────
    SafeguardIntent.askAboutRefund: KnowledgeEntry(
      en: 'Steps to try getting your money back after a scam:\n\n'
          'Step 1 : Contact the seller directly\n'
          '  Ask for a refund politely but firmly. Screenshot everything.\n\n'
          'Step 2 : Contact your payment provider\n'
          '  - eSewa: support@esewa.com.np or in-app help\n'
          '  - Khalti: support@khalti.com\n'
          '  - Bank transfer: visit your bank branch with proof\n\n'
          'Step 3 : File a report on SafeBuy Nepal\n'
          '  This creates a public record and alerts other buyers.\n\n'
          'Step 4 : File a complaint with Nepal Police\n'
          '  - Cybercrime Bureau: Naxal, Kathmandu\n'
          '  - Phone: 01-4412323\n'
          '  - Bring all evidence (payment proof, chat screenshots)\n\n'
          'Important: Act quickly. The sooner you report, the better '
          'the chance of recovery. eSewa/Khalti can sometimes freeze '
          'the scammer\'s account if reported within 24 hours.',
      ne: 'ठगी पछि पैसा फिर्ता पाउने प्रयास:\n\n'
          'Step 1 : Seller लाई सिधै सम्पर्क गर्नुस्\n'
          '  शिष्ट तर दृढतापूर्वक refund माग्नुस्।\n\n'
          'Step 2 : Payment provider लाई सम्पर्क गर्नुस्\n'
          '  - eSewa: support@esewa.com.np\n'
          '  - Khalti: support@khalti.com\n'
          '  - Bank transfer: प्रमाण लिएर bank जानुस्\n\n'
          'Step 3 : SafeBuy Nepal मा रिपोर्ट गर्नुस्\n'
          '  यसले अरू खरिदकर्ताहरूलाई alert गर्छ।\n\n'
          'Step 4 : Nepal Police मा उजुरी दिनुस्\n'
          '  - Cybercrime Bureau: Naxal, Kathmandu\n'
          '  - Phone: 01-4412323\n'
          '  - सबै प्रमाण लैजानुस्\n\n'
          'छिटो रिपोर्ट गर्नुस्। eSewa/Khalti ले २४ घण्टा भित्र '
          'ठगकर्ताको खाता freeze गर्न सक्छ।',
      type: ResponseType.steps,
    ),

    // ── Seller Defense ─────────────────────────────────────────────
    SafeguardIntent.sellerDefense: KnowledgeEntry(
      en: 'If you are a seller and believe a report is false, '
          'here is what you can do:\n\n'
          'Step 1 : Go to your Business Dashboard\n'
          '  Tap "Disputes" to see all reports against you\n\n'
          'Step 2 : Respond to the report\n'
          '  Write your side of the story clearly and honestly\n\n'
          'Step 3 : Provide proof of refund\n'
          '  If you already refunded the buyer, upload your '
          'payment confirmation\n\n'
          'Step 4 : Flag as false if the report is fabricated\n'
          '  Select a reason and submit. Our admin team reviews '
          'flagged reports within 48 hours\n\n'
          'Responding quickly increases your Dispute Response '
          'Rate which directly improves your trust score.',
      ne: 'यदि तपाईं seller हुनुहुन्छ र रिपोर्ट गलत छ भन्ने '
          'लाग्छ भने:\n\n'
          'Step 1 : Business Dashboard खोल्नुस्\n'
          '  "Disputes" मा तपाईंका विरुद्धका रिपोर्ट हेर्नुस्\n\n'
          'Step 2 : रिपोर्टको जवाफ दिनुस्\n'
          '  आफ्नो पक्षको कुरा स्पष्ट र इमान्दारीसाथ लेख्नुस्\n\n'
          'Step 3 : Refund को प्रमाण दिनुस्\n'
          '  पैसा फिर्ता गरिसक्नुभएको छ भने screenshot upload '
          'गर्नुस्\n\n'
          'Step 4 : गलत रिपोर्ट flag गर्नुस्\n'
          '  कारण चुनेर submit गर्नुस्। Admin ले ४८ घण्टामा '
          'हेर्छन्\n\n'
          'छिटो जवाफ दिँदा तपाईंको Trust Score बढ्छ।',
      type: ResponseType.steps,
      actions: [
        AgentAction(
          label: 'Go to Disputes',
          labelNe: 'Disputes हेर्नुस्',
          actionType: 'navigate',
          payload: {'route': '/dashboard/disputes'},
        ),
      ],
    ),

    // ── Report Help ────────────────────────────────────────────────
    SafeguardIntent.reportHelp: KnowledgeEntry(
      en: 'I can see you need help. Here are the most common things '
          'people ask me:\n\n'
          '- "Check a seller" : I will look up any seller by phone or handle\n'
          '- "How to report" : Step-by-step guide to file fraud report\n'
          '- "What is trust score" : How we calculate seller trustworthiness\n'
          '- "Common scams" : Learn what scam types exist in Nepal\n'
          '- "My rights" : Nepal\'s ETA 2063 and how to file police complaint\n'
          '- "Get refund" : Steps to recover money after being scammed\n\n'
          'Just type your question naturally and I will do my best to help!',
      ne: 'म तपाईंलाई सहयोग गर्छु। मान्छेहरूले सबैभन्दा धेरै सोध्ने '
          'प्रश्नहरू:\n\n'
          '- "Seller जाँच" : फोन वा handle बाट seller खोज्छु\n'
          '- "कसरी रिपोर्ट गर्ने" : ठगी रिपोर्ट गर्ने step-by-step guide\n'
          '- "Trust score के हो" : Seller को भरोसा कसरी गणना हुन्छ\n'
          '- "ठगीका प्रकार" : Nepal मा कस्ता ठगी हुन्छन्\n'
          '- "मेरो अधिकार" : ETA 2063 र प्रहरी उजुरी\n'
          '- "पैसा फिर्ता" : ठगी पछि पैसा फिर्ता पाउने तरिका\n\n'
          'आफ्नो प्रश्न सहज रूपमा लेख्नुस्, म सहयोग गर्छु!',
    ),

    // ── Unknown ────────────────────────────────────────────────────
    SafeguardIntent.unknown: KnowledgeEntry(
      en: 'I am not sure I understood that. Here are things I can '
          'help you with:\n\n'
          '- Search and verify a seller\n'
          '- File a fraud report\n'
          '- Understand trust scores\n'
          '- Learn about common scams\n'
          '- Know your legal rights under Nepal\'s ETA\n'
          '- Register your business\n\n'
          'Try asking me something like: '
          '"How do I check if a seller is safe?" '
          'or "What is a trust score?"',
      ne: 'मैले बुझिनँ। म यी विषयमा सहयोग गर्न सक्छु:\n\n'
          '- Seller जाँच्ने तरिका\n'
          '- ठगी रिपोर्ट गर्ने तरिका\n'
          '- Trust Score बारे जानकारी\n'
          '- सामान्य ठगीका तरिका\n'
          '- ETA 2063 अन्तर्गत तपाईंको अधिकार\n'
          '- व्यवसाय दर्ता गर्ने तरिका',
    ),
  };
}
