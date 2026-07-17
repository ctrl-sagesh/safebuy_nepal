import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart' as core_const;
import '../models/seller_model.dart';
import '../providers/language_provider.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../utils/app_strings.dart';
import '../utils/constants.dart';

class RegisterBusinessScreen extends ConsumerStatefulWidget {
  const RegisterBusinessScreen({super.key});

  @override
  ConsumerState<RegisterBusinessScreen> createState() =>
      _RegisterBusinessScreenState();
}

class _RegisterBusinessScreenState
    extends ConsumerState<RegisterBusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _showIntro = true;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tiktokCtrl = TextEditingController();
  final _instaCtrl = TextEditingController();
  final _fbCtrl = TextEditingController();
  String _businessType = BusinessTypes.list.first;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    _tiktokCtrl.dispose();
    _instaCtrl.dispose();
    _fbCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final lang = ref.read(languageProvider);
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang == 'ne'
                ? 'कृपया सर्तहरूमा सहमत हुनुहोस्'
                : 'Please agree to the terms to continue',
          ),
          backgroundColor: const Color(AppColors.highRisk),
        ),
      );
      return;
    }
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang == 'ne'
            ? 'नाम र फोन नम्बर आवश्यक छ'
            : 'Business name and phone are required')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authUser = FirebaseAuth.instance.currentUser;
      final seller = SellerModel(
        sellerId: 'seller_${const Uuid().v4()}',
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        tiktokHandle: _tiktokCtrl.text.trim().isEmpty
            ? null
            : _tiktokCtrl.text.trim().replaceAll('@', ''),
        instagramHandle: _instaCtrl.text.trim().isEmpty
            ? null
            : _instaCtrl.text.trim().replaceAll('@', ''),
        facebookHandle: _fbCtrl.text.trim().isEmpty ? null : _fbCtrl.text.trim(),
        trustScore: core_const.AppConstants.newSellerScore,
        trustVerdict: 'unverified',
        isVerified: authUser != null, // phone-OTP gives partial verification
        verifiedBadge: false,
        totalOrders: 0,
        reviewCount: 0,
        scamReportCount: 0,
        accountCreatedAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
        disputeResponseRate: 0.0,
        businessName: _nameCtrl.text.trim(),
        businessCategory: _businessType,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        linkedUserId: authUser?.uid,
        averageRating: 0.0,
        trustScoreHistory: [
          {
            'score': core_const.AppConstants.newSellerScore,
            'timestamp': Timestamp.now(),
          },
        ],
      );

      await ref.read(firestoreServiceProvider).registerSeller(seller);

      // Link to user document if signed in
      if (authUser != null) {
        await ref.read(firestoreServiceProvider).updateSeller(
          authUser.uid,
          {'linkedSellerId': seller.sellerId},
        );
      }

      AnalyticsService.logBusinessRegistered(_businessType);

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang == 'ne'
                ? 'दर्ता असफल: $e'
                : 'Registration failed: $e'),
            backgroundColor: const Color(AppColors.highRisk),
          ),
        );
      }
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(AppColors.trusted).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.store,
                  color: Color(AppColors.trusted), size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Registration Submitted!',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your business has been submitted for verification. We will review within 48 hours and assign your trust score.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(AppColors.textGrey), fontSize: 13),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final steps = [
      lang == 'ne' ? 'व्यवसाय' : 'Business',
      lang == 'ne' ? 'सोसल मिडिया' : 'Social',
      lang == 'ne' ? 'पुष्टि' : 'Confirm',
    ];

    if (_showIntro) return _buildIntro(lang);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('register_business', lang)
            .replaceAll('\n', ' ')),
        backgroundColor: const Color(AppColors.trusted),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildStepIndicator(steps),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: [
                  _buildStep1(lang),
                  _buildStep2(lang),
                  _buildStep3(lang),
                ][_currentStep],
              ),
            ),
            _buildBottomNav(lang),
          ],
        ),
      ),
    );
  }

  /// Motivation screen shown before the form: why register, what you
  /// get, and one clear action.
  Widget _buildIntro(String lang) {
    final ne = lang == 'ne';
    final benefits = [
      (
        Icons.handshake_outlined,
        const Color(AppColors.primary),
        ne ? 'खरिदारको विश्वास जित्नुहोस्' : 'Build Buyer Trust',
        ne
            ? 'प्रमाणित प्रोफाइलले तपाईं वास्तविक व्यवसाय हो भनी देखाउँछ'
            : 'Show buyers you are a legitimate business with a '
                'verified trust profile',
      ),
      (
        Icons.trending_up_rounded,
        const Color(AppColors.trusted),
        ne ? 'अरूभन्दा अगाडि देखिनुहोस्' : 'Stand Out',
        ne
            ? 'खोज परिणाम र सिफारिसहरूमा अप्रमाणित विक्रेताभन्दा माथि देखिनुहोस्'
            : 'Appear above unverified sellers in search results and '
                'community recommendations',
      ),
      (
        Icons.storefront_rounded,
        const Color(AppColors.accent),
        ne ? 'बिक्री बढाउनुहोस्' : 'Grow Sales',
        ne
            ? 'खरिदारहरू प्रमाणित विक्रेताबाट किन्न ३ गुणा बढी तयार हुन्छन्'
            : 'Buyers are 3x more likely to purchase from a verified '
                'seller',
      ),
    ];
    final gets = ne
        ? [
            'तपाईंको फोटो र QR सहितको SafeBuy प्रमाणीकरण कार्ड',
            'सार्वजनिक प्रोफाइलमा प्रमाणित ब्याज',
            'मासिक लिडरबोर्डमा स्थान पाउने योग्यता',
            'समीक्षा र उजुरी व्यवस्थापन ड्यासबोर्ड',
          ]
        : [
            'SafeBuy Verification Card with your photo and QR',
            'Verified badge on your public profile',
            'Monthly leaderboard eligibility',
            'Dashboard to manage reviews and complaints',
          ];

    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: AppBar(
        title: Text(ne ? 'प्रमाणित बन्नुहोस्' : 'Get SafeBuy Verified'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...benefits.map((b) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(AppColors.divider)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: b.$2.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(b.$1, color: b.$2, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.$3,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: Color(AppColors.textDark),
                                )),
                            const SizedBox(height: 3),
                            Text(b.$4,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: Color(AppColors.textGrey),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            Text(ne ? 'तपाईंले के पाउनुहुन्छ:' : 'What you will get:',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Color(AppColors.textDark),
                )),
            const SizedBox(height: 8),
            ...gets.map((g) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Color(AppColors.trusted), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(g,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(AppColors.textDark),
                            )),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () => setState(() => _showIntro = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(AppColors.trusted),
                ),
                child: Text(ne
                    ? 'निःशुल्क दर्ता सुरु गर्नुहोस्'
                    : 'Start Your Free Registration'),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              ne
                  ? 'लगभग १० मिनेट लाग्छ। कुनै शुल्क छैन। कहिल्यै।'
                  : 'Takes about 10 minutes. No payment required. Ever.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(AppColors.textGrey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(List<String> labels) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      color: const Color(AppColors.trusted).withValues(alpha: 0.05),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(AppColors.trusted)
                              : isActive
                                  ? const Color(AppColors.trusted)
                                  : Colors.grey.shade200,
                          shape: BoxShape.circle,
                          border: isActive
                              ? Border.all(
                                  color: const Color(AppColors.trusted),
                                  width: 2)
                              : null,
                        ),
                        child: Icon(
                          isDone ? Icons.check : Icons.circle,
                          color: isDone || isActive
                              ? Colors.white
                              : Colors.grey.shade400,
                          size: isDone ? 18 : 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.normal,
                          color: isActive
                              ? const Color(AppColors.trusted)
                              : const Color(AppColors.textGrey),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: isDone
                          ? const Color(AppColors.trusted)
                          : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          lang == 'ne' ? 'तपाईंको व्यवसायको बारेमा' : 'About Your Business',
          lang == 'ne'
              ? 'आफ्नो व्यवसायको विवरण भर्नुहोस्'
              : 'Fill in your business details',
        ),
        const SizedBox(height: 20),
        _field(
          controller: _nameCtrl,
          label: lang == 'ne' ? 'व्यवसायको नाम *' : 'Business Name *',
          hint: lang == 'ne' ? 'जस्तै: रमेश क्लथिङ' : 'e.g. Ramesh Clothing',
          icon: Icons.store,
          validator: (v) =>
              v!.isEmpty ? (lang == 'ne' ? 'नाम आवश्यक छ' : 'Required') : null,
        ),
        const SizedBox(height: 14),
        _field(
          controller: _phoneCtrl,
          label: lang == 'ne' ? 'फोन नम्बर *' : 'Phone Number *',
          hint: '98XXXXXXXX',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (v) =>
              v!.isEmpty ? (lang == 'ne' ? 'फोन आवश्यक छ' : 'Required') : null,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _businessType,
          isExpanded: true,
          menuMaxHeight: 300,
          dropdownColor: Colors.white,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w500,
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF666666)),
          decoration: InputDecoration(
            labelText: lang == 'ne' ? 'व्यवसायको प्रकार' : 'Business Type',
            prefixIcon:
                const Icon(Icons.category, color: Color(0xFF9E9E9E)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          items: BusinessTypes.list
              .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF1A1A1A),
                        )),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _businessType = v!),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _descCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText:
                lang == 'ne' ? 'व्यवसायको विवरण' : 'Business Description',
            hintText: lang == 'ne'
                ? 'तपाईंको व्यवसायको बारेमा लेख्नुहोस्...'
                : 'Describe your business briefly...',
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          lang == 'ne' ? 'सोसल मिडिया' : 'Social Media',
          lang == 'ne'
              ? 'तपाईंको प्लेटफर्म लिङ्कहरू थप्नुहोस्'
              : 'Add your platform links',
        ),
        const SizedBox(height: 20),
        _field(
          controller: _tiktokCtrl,
          label: 'TikTok Handle',
          hint: '@yourtiktok',
          icon: Icons.music_video,
        ),
        const SizedBox(height: 14),
        _field(
          controller: _instaCtrl,
          label: 'Instagram Handle',
          hint: '@yourinstagram',
          icon: Icons.photo_camera,
        ),
        const SizedBox(height: 14),
        _field(
          controller: _fbCtrl,
          label: 'Facebook Page',
          hint: 'facebook.com/yourpage',
          icon: Icons.facebook,
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(AppColors.primary).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(AppColors.primary).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Color(AppColors.primary), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lang == 'ne'
                      ? 'कम्तीमा एउटा सोसल मिडिया ह्यान्डल थप्नुहोस्।'
                      : 'Add at least one social media handle for verification.',
                  style: const TextStyle(
                      fontSize: 12, color: Color(AppColors.primary)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          lang == 'ne' ? 'समीक्षा र पुष्टि' : 'Review & Confirm',
          lang == 'ne'
              ? 'तपाईंको जानकारी जाँच गर्नुहोस्'
              : 'Check your information before submitting',
        ),
        const SizedBox(height: 20),
        _reviewCard(lang),
        const SizedBox(height: 16),
        _benefitsCard(lang),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
          child: Row(
            children: [
              Checkbox(
                value: _agreedToTerms,
                onChanged: (v) =>
                    setState(() => _agreedToTerms = v ?? false),
                activeColor: const Color(AppColors.trusted),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              Expanded(
                child: Text(
                  lang == 'ne'
                      ? 'म SafeBuy Nepal का सर्तहरू मान्छु र मेरो जानकारी सही छ।'
                      : 'I agree to SafeBuy Nepal\'s terms and confirm my information is accurate.',
                  style: const TextStyle(
                      fontSize: 13, color: Color(AppColors.textGrey)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewCard(String lang) {
    final items = [
      (lang == 'ne' ? 'व्यवसायको नाम' : 'Business Name',
          _nameCtrl.text.isEmpty ? '-' : _nameCtrl.text),
      (lang == 'ne' ? 'फोन नम्बर' : 'Phone Number',
          _phoneCtrl.text.isEmpty ? '-' : _phoneCtrl.text),
      (lang == 'ne' ? 'व्यवसायको प्रकार' : 'Business Type', _businessType),
      ('TikTok',
          _tiktokCtrl.text.isEmpty ? '-' : _tiktokCtrl.text),
      ('Instagram',
          _instaCtrl.text.isEmpty ? '-' : _instaCtrl.text),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang == 'ne' ? 'तपाईंको जानकारी' : 'Your Information',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        item.$1,
                        style: const TextStyle(
                            fontSize: 12, color: Color(AppColors.textGrey)),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.$2,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _benefitsCard(String lang) {
    final benefits = lang == 'ne'
        ? [
            'खरिदारहरूको विश्वास बढाउनुहोस्',
            'भेरिफाइड ब्याज पाउनुहोस्',
            'SafeBuy प्रोफाइल लिङ्क सेयर गर्नुहोस्',
            'धोखाधडी रिपोर्टबाट सुरक्षा',
          ]
        : [
            'Build buyer trust with a verified badge',
            'Get a SafeBuy trust score',
            'Share your profile link with buyers',
            'Protection against false fraud reports',
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(AppColors.trusted).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(AppColors.trusted).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars,
                  color: Color(AppColors.trusted), size: 18),
              const SizedBox(width: 8),
              Text(
                lang == 'ne' ? 'फाइदाहरू' : 'Benefits of Registering',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(AppColors.trusted)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...benefits.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Color(AppColors.trusted), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(b,
                            style: const TextStyle(fontSize: 12))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBottomNav(String lang) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                child: Text(
                  lang == 'ne' ? 'पछाडि' : 'Back',
                  style: const TextStyle(color: Color(AppColors.trusted)),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _currentStep < 2
                ? ElevatedButton(
                    onPressed: () {
                      if (_currentStep == 0) {
                        if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(lang == 'ne'
                                  ? 'नाम र फोन नम्बर भर्नुहोस्'
                                  : 'Please fill name and phone number'),
                              backgroundColor: const Color(AppColors.highRisk),
                            ),
                          );
                          return;
                        }
                      }
                      setState(() => _currentStep++);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppColors.trusted),
                    ),
                    child: Text(
                        lang == 'ne' ? 'अगाडि' : 'Continue'),
                  )
                : ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(AppColors.trusted),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(lang == 'ne' ? 'दर्ता गर्नुहोस्' : 'Register'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(
                color: Color(AppColors.textGrey), fontSize: 13)),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
