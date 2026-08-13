import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/popup_helper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/language_toggle.dart';
import '../../../../models/report_model.dart';
import '../../../../models/seller_model.dart';
import '../../../../providers/language_provider.dart';
import '../../../../services/firestore_service.dart';
import '../../../../services/storage_service.dart';
import '../../../kyc/kyc_draft.dart' show KycUploadZone, pickKycImage;

/// 3-step incident report: seller info → incident details → evidence.
class IncidentReportScreen extends ConsumerStatefulWidget {
  const IncidentReportScreen({
    super.key,
    this.sellerId,
    this.prefillPhone,
  });

  final String? sellerId;
  final String? prefillPhone;

  @override
  ConsumerState<IncidentReportScreen> createState() =>
      _IncidentReportScreenState();
}

class _IncidentReportScreenState
    extends ConsumerState<IncidentReportScreen> {
  int _step = 0;

  /// Current UI language ('en' | 'ne'); refreshed at the top of build().
  String _lang = 'en';
  String _t(String en, String ne) => _lang == 'ne' ? ne : en;

  /// Localized label for an incident-type key.
  String _incidentLabel(String key) {
    switch (key) {
      case 'no_delivery':
        return _t('Item Not Delivered', 'सामान प्राप्त भएन');
      case 'wrong_item':
        return _t('Wrong Item Sent', 'गलत सामान पठाइयो');
      case 'fake_product':
        return _t('Fake / Counterfeit', 'नक्कली सामान');
      case 'payment_issue':
        return _t('Paid, No Response', 'तिरें, जवाफ आएन');
      default:
        return key;
    }
  }

  // Step 1
  final _phone = TextEditingController();
  final _esewa = TextEditingController();
  final _handle = TextEditingController();
  String _platform = 'TikTok';
  SellerModel? _matchedSeller;
  String? _phoneError;

  // Step 2
  final _amount = TextEditingController();
  String? _incidentType;
  DateTime _incidentDate = DateTime.now();
  final _description = TextEditingController();
  bool _declared = false;
  String? _amountError;

  // Step 3
  File? _paymentShot;
  File? _chatShot;
  bool _submitting = false;

  static const _platforms = [
    'TikTok',
    'Instagram',
    'Facebook',
    'WhatsApp',
    'Viber',
    'Other'
  ];

  static const _incidentTypes = [
    ('no_delivery', '📦', 'Item Not Delivered'),
    ('wrong_item', '🔄', 'Wrong Item Sent'),
    ('fake_product', '🏷️', 'Fake / Counterfeit'),
    ('payment_issue', '💳', 'Paid, No Response'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.prefillPhone != null) {
      _phone.text = widget.prefillPhone!;
    }
    if (widget.sellerId != null) _lookupSeller();
  }

  Future<void> _lookupSeller() async {
    try {
      final s = await ref
          .read(firestoreServiceProvider)
          .getSellerById(widget.sellerId!);
      if (mounted && s != null) {
        setState(() {
          _matchedSeller = s;
          if (_phone.text.isEmpty) _phone.text = s.phone;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _phone.dispose();
    _esewa.dispose();
    _handle.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  // ── Step navigation with validation ─────────────────────────────────────────

  void _next() {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      final hasIdentifier = _phone.text.trim().isNotEmpty ||
          _esewa.text.trim().isNotEmpty ||
          _handle.text.trim().isNotEmpty;
      if (!hasIdentifier) {
        PopupHelper.showWarning(
            context,
            _t(
                'Please enter at least one seller identifier '
                    '(phone, eSewa ID, or social handle)',
                'कृपया विक्रेताको कम्तीमा एउटा पहिचान हाल्नुहोस् '
                    '(फोन, eSewa आईडी, वा सोशल ह्यान्डल)'));
        return;
      }
      if (_phone.text.trim().isNotEmpty) {
        final err = Validators.nepaliPhone(_phone.text);
        if (err != null) {
          setState(() => _phoneError = _t(
              'Enter a valid Nepal phone number (97XXXXXXXX or 98XXXXXXXX)',
              'मान्य नेपाली फोन नम्बर हाल्नुहोस् (97XXXXXXXX वा 98XXXXXXXX)'));
          PopupHelper.showError(
              context,
              _t('Please fix the phone number to continue.',
                  'अगाडि बढ्न फोन नम्बर मिलाउनुहोस्।'));
          return;
        }
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      final amount = double.tryParse(_amount.text.trim());
      if (amount == null || amount < 0) {
        setState(() => _amountError = _t(
            'Enter the amount in NPR, or 0 if you did not pay',
            'रकम NPR मा हाल्नुहोस्, वा नतिरेको भए ० हाल्नुहोस्'));
        PopupHelper.showWarning(
            context,
            _t('Please enter the amount lost (0 if you did not pay)',
                'गुमेको रकम हाल्नुहोस् (नतिरेको भए ०)'));
        return;
      }
      if (_incidentType == null) {
        PopupHelper.showWarning(
            context,
            _t('Please select the type of incident',
                'घटनाको प्रकार छान्नुहोस्'));
        return;
      }
      final desc = _description.text.trim();
      if (desc.length < 50) {
        PopupHelper.showWarning(
            context,
            _t(
                'Please describe the incident in at least 50 characters '
                    '(${desc.length}/50)',
                'घटनालाई कम्तीमा ५० अक्षरमा वर्णन गर्नुहोस् '
                    '(${desc.length}/50)'));
        return;
      }
      if (!_declared) {
        PopupHelper.showWarning(
            context,
            _t('Please confirm your declaration to continue',
                'अगाडि बढ्न आफ्नो घोषणा पुष्टि गर्नुहोस्'));
        return;
      }
      setState(() => _step = 2);
    }
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      PopupHelper.showAuthGateBottomSheet(context);
      return;
    }

    setState(() => _submitting = true);
    final fs = ref.read(firestoreServiceProvider);

    try {
      // Resolve / create seller record.
      String sellerId = _matchedSeller?.sellerId ?? '';
      if (sellerId.isEmpty && _phone.text.trim().isNotEmpty) {
        final found = await fs.searchSeller(_phone.text.trim());
        sellerId = found?.sellerId ?? '';
      }

      // Rate limit.
      if (sellerId.isNotEmpty) {
        final allowed =
            await fs.checkReportRateLimit(user.uid, sellerId);
        if (!allowed) {
          if (!mounted) return;
          final nextDate = DateFormat('dd MMM')
              .format(DateTime.now().add(const Duration(days: 7)));
          PopupHelper.showWarning(
              context,
              _t(
                  'You have already submitted 3 reports against this '
                      'seller this week. You can submit again on $nextDate.',
                  'तपाईंले यस हप्ता यो विक्रेताविरुद्ध ३ उजुरी पेस '
                      'गरिसक्नुभयो। $nextDate मा फेरि पेस गर्न सक्नुहुन्छ।'));
          setState(() => _submitting = false);
          return;
        }
      }

      if (!mounted) return;
      PopupHelper.showLoadingDialog(
          context, _t('Uploading evidence...', 'प्रमाण अपलोड हुँदै...'));

      final reportDraftId = const Uuid().v4();
      String? paymentUrl;
      String? chatUrl;
      try {
        if (_paymentShot != null) {
          paymentUrl = await StorageService.uploadEvidence(
            file: _paymentShot!,
            reportId: reportDraftId,
            evidenceType: 'payment',
            userId: user.uid,
          );
        }
        if (_chatShot != null) {
          chatUrl = await StorageService.uploadEvidence(
            file: _chatShot!,
            reportId: reportDraftId,
            evidenceType: 'chat',
            userId: user.uid,
          );
        }
      } catch (_) {
        if (!mounted) return;
        PopupHelper.hideLoadingDialog(context);
        PopupHelper.showError(
            context,
            _t(
                'Evidence upload failed. Please check your connection '
                    'and try again.',
                'प्रमाण अपलोड असफल भयो। इन्टरनेट जाँची फेरि प्रयास '
                    'गर्नुहोस्।'));
        setState(() => _submitting = false);
        return;
      }

      final report = ReportModel(
        reportId: '',
        reporterId: user.uid,
        sellerId: sellerId,
        sellerPhone: _phone.text.trim(),
        sellerEsewaId:
            _esewa.text.trim().isEmpty ? null : _esewa.text.trim(),
        sellerSocialHandle: _handle.text.trim().isEmpty
            ? null
            : Validators.stripAtPrefix(_handle.text.trim()),
        platform: _platform,
        incidentType: _incidentType!,
        amountLost: double.parse(_amount.text.trim()),
        description: Validators.sanitize(_description.text),
        incidentDate: _incidentDate,
        paymentScreenshotUrl: paymentUrl,
        chatScreenshotUrl: chatUrl,
        submittedAt: DateTime.now(),
        status: 'pending',
        reporterDeclaration: true,
      );

      final reportId = await fs.submitReport(report);

      if (!mounted) return;
      PopupHelper.hideLoadingDialog(context);
      Navigator.pushReplacementNamed(context, '/report/success',
          arguments: {
            'reportId': reportId,
            'sellerId': sellerId,
          });
    } catch (_) {
      if (!mounted) return;
      PopupHelper.hideLoadingDialog(context);
      PopupHelper.showError(
          context,
          _t(
              'Report submission failed. Your evidence has been saved. '
                  'Please try again.',
              'उजुरी पेस असफल भयो। तपाईंको प्रमाण सुरक्षित छ। फेरि '
                  'प्रयास गर्नुहोस्।'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        title: Text(_t('Report a Fraud', 'ठगी उजुरी गर्नुहोस्')),
        actions: const [LanguageToggle()],
      ),
      body: Column(
        children: [
          // 3-step progress
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: List.generate(3, (i) {
                final labels = [
                  _t('Seller', 'विक्रेता'),
                  _t('Incident', 'घटना'),
                  _t('Evidence', 'प्रमाण'),
                ];
                final done = i < _step;
                final active = i == _step;
                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 250),
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: done
                                    ? AppColors.trusted
                                    : active
                                        ? AppColors.primary
                                        : AppColors.grey200,
                              ),
                              alignment: Alignment.center,
                              child: done
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 16)
                                  : Text('${i + 1}',
                                      style: GoogleFonts.poppins(
                                        color: active
                                            ? Colors.white
                                            : AppColors.grey500,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      )),
                            ),
                            const SizedBox(height: 3),
                            Text(labels[i],
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                )),
                          ],
                        ),
                      ),
                      if (i < 2)
                        Expanded(
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.only(bottom: 15),
                            color: done
                                ? AppColors.trusted
                                : AppColors.grey200,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: [_step1(), _step2(), _step3()][_step],
            ),
          ),

          // Bottom bar
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.paddingOf(context).bottom + 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border:
                  Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step--),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 50)),
                      child: Text(_t('Back', 'पछाडि')),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: _submitting
                            ? null
                            : (_step < 2 ? _next : _submit),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: Text(_step < 2
                            ? _t('Continue', 'जारी राख्नुहोस्')
                            : _t('Submit Report', 'उजुरी पेस गर्नुहोस्')),
                      ),
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

  Widget _step1() {
    return ListView(
      key: const ValueKey(0),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        // Supportive intro — the user has just been scammed.
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  _t('Were you scammed by a social media seller?',
                      'सोशल मिडिया विक्रेताले ठगेको हो?'),
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary900,
                  )),
              const SizedBox(height: 5),
              Text(
                _t(
                    'Your report helps protect thousands of future buyers. '
                        'It takes about 3 minutes to complete. Your identity '
                        'is never shown publicly.',
                    'तपाईंको उजुरीले हजारौं भावी ग्राहकलाई जोगाउँछ। पूरा '
                        'गर्न करिब ३ मिनेट लाग्छ। तपाईंको पहिचान सार्वजनिक '
                        'कहिल्यै देखाइँदैन।'),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),

        if (_matchedSeller != null)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary100),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary50,
                  child: Text(
                    _matchedSeller!.displayName.isNotEmpty
                        ? _matchedSeller!.displayName[0]
                        : '?',
                    style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_matchedSeller!.displayName,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5)),
                      Text(
                          _t('Found in SafeBuy database',
                              'SafeBuy डाटाबेसमा भेटियो'),
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.trusted)),
                    ],
                  ),
                ),
                const Icon(Icons.verified_rounded,
                    color: AppColors.trusted, size: 20),
              ],
            ),
          ),

        Text(_t('Tell us about the seller', 'विक्रेताबारे बताउनुहोस्'),
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
            _t(
                'Enter any information you have about the seller. '
                    'Even one detail helps.',
                'विक्रेताबारे तपाईंसँग भएको जुनसुकै जानकारी हाल्नुहोस्। '
                    'एउटै विवरण भए पनि मद्दत गर्छ।'),
            style: GoogleFonts.inter(
                fontSize: 12.5, color: AppColors.textSecondary)),
        const SizedBox(height: 16),

        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: _t('Their phone number or eSewa number',
                'उनीहरूको फोन नम्बर वा eSewa नम्बर'),
            hintText: '98XXXXXXXX',
            helperText: _t('This is the most important identifier',
                'यो सबैभन्दा महत्त्वपूर्ण पहिचान हो'),
            counterText: '',
            prefixIcon: const Icon(Icons.phone_outlined),
            errorText: _phoneError,
            errorMaxLines: 2,
          ),
          onChanged: (_) {
            if (_phoneError != null) setState(() => _phoneError = null);
          },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _esewa,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText:
                _t('eSewa / Khalti ID (optional)', 'eSewa / Khalti आईडी (वैकल्पिक)'),
            prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _handle,
          decoration: InputDecoration(
            labelText: _t('Their TikTok or Instagram handle (optional)',
                'उनीहरूको TikTok वा Instagram ह्यान्डल (वैकल्पिक)'),
            hintText: '@username',
            prefixIcon: const Icon(Icons.alternate_email_rounded),
          ),
        ),
        const SizedBox(height: 16),

        Text(_t('Where did you find them?', 'उनीहरूलाई कहाँ भेट्नुभयो?'),
            style: GoogleFonts.poppins(
                fontSize: 13.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _platforms.map((p) {
            final selected = _platform == p;
            return InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _platform = p);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.borderLight),
                ),
                child: Text(p,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : AppColors.textSecondary,
                    )),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _step2() {
    return ListView(
      key: const ValueKey(1),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        Text(_t('What happened?', 'के भयो?'),
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),

        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText:
                _t('How much did you lose? (NPR) *', 'कति गुमाउनुभयो? (NPR) *'),
            helperText: _t('Enter 0 if you cancelled before paying',
                'तिर्नुअघि रद्द गर्नुभएको भए ० हाल्नुहोस्'),
            prefixIcon: const Icon(Icons.payments_outlined),
            errorText: _amountError,
          ),
          onChanged: (v) {
            final parsed = double.tryParse(v);
            if (_amountError != null &&
                parsed != null &&
                parsed >= 0) {
              setState(() => _amountError = null);
            }
          },
        ),
        const SizedBox(height: 16),

        Text(_t('Incident Type *', 'घटनाको प्रकार *'),
            style: GoogleFonts.poppins(
                fontSize: 13.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: _incidentTypes.map((it) {
            final (key, emoji, _) = it;
            final label = _incidentLabel(key);
            final selected = _incidentType == key;
            return InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _incidentType = key);
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary50 : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.borderLight,
                    width: selected ? 1.8 : 1.1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(label,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          )),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Date picker
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _incidentDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              if (picked.isAfter(DateTime.now())) {
                if (mounted) {
                  PopupHelper.showWarning(
                      context,
                      _t('Incident date cannot be in the future',
                          'घटनाको मिति भविष्यमा हुन सक्दैन'));
                }
                return;
              }
              setState(() => _incidentDate = picked);
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: _t('Date of Incident', 'घटनाको मिति'),
              prefixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            child: Text(
              DateFormat('dd MMMM yyyy').format(_incidentDate),
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _description,
          maxLines: 5,
          maxLength: 1000,
          decoration: InputDecoration(
            labelText: _t('Describe what happened *', 'के भयो वर्णन गर्नुहोस् *'),
            alignLabelWithHint: true,
            hintText: _t(
                'Tell us the full story. What did you order? '
                    'What did you pay? What happened after?',
                'पूरा कुरा बताउनुहोस्। के अर्डर गर्नुभयो? कति तिर्नुभयो? '
                    'त्यसपछि के भयो?'),
            helperText: _t(
                'More detail helps our team verify your report faster',
                'बढी विवरणले हाम्रो टोलीलाई उजुरी छिटो जाँच्न मद्दत गर्छ'),
            helperMaxLines: 2,
            counterText:
                '${_description.text.trim().length}/50 ${_t('minimum', 'न्यूनतम')}',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),

        CheckboxListTile(
          value: _declared,
          onChanged: (v) => setState(() => _declared = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.primary,
          title: Text(
            _t(
                'I confirm this report is truthful and based on my genuine '
                    'personal experience.',
                'म यो उजुरी सत्य र मेरो वास्तविक व्यक्तिगत अनुभवमा आधारित '
                    'भएको पुष्टि गर्छु।'),
            style: GoogleFonts.inter(fontSize: 12.5, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _step3() {
    // (level, label, color) — level drives the explanation text below.
    final quality = _paymentShot != null && _chatShot != null
        ? ('strong', _t('Strong evidence', 'बलियो प्रमाण'), AppColors.trusted)
        : _paymentShot != null || _chatShot != null
            ? (
                'partial',
                _t('Partial evidence', 'आंशिक प्रमाण'),
                AppColors.unverified
              )
            : ('none', _t('No evidence', 'प्रमाण छैन'), AppColors.highRisk);

    return ListView(
      key: const ValueKey(2),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        Text(
            _t('Evidence makes your report stronger',
                'प्रमाणले तपाईंको उजुरी बलियो बनाउँछ'),
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
            _t(
                'Screenshots help verify your report faster. Both are '
                    'optional but strongly recommended.',
                'स्क्रिनसटले उजुरी छिटो जाँच्न मद्दत गर्छ। दुवै वैकल्पिक '
                    'हुन् तर कडा रूपमा सिफारिस गरिन्छ।'),
            style: GoogleFonts.inter(
                fontSize: 12.5, color: AppColors.textSecondary)),
        const SizedBox(height: 16),

        Text(_t('Payment screenshot', 'भुक्तानी स्क्रिनसट'),
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        KycUploadZone(
          label: _t('Your eSewa or Khalti receipt',
              'तपाईंको eSewa वा Khalti रसिद'),
          icon: Icons.receipt_long_outlined,
          file: _paymentShot,
          onPick: () async {
            final f = await pickKycImage(context,
                source: ImageSource.gallery);
            if (f != null) setState(() => _paymentShot = f);
          },
          onRemove: () => setState(() => _paymentShot = null),
          height: 120,
        ),
        const SizedBox(height: 14),

        Text(_t('Chat screenshot', 'च्याट स्क्रिनसट'),
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        KycUploadZone(
          label: _t('Your conversation with the seller',
              'विक्रेतासँगको तपाईंको कुराकानी'),
          icon: Icons.chat_outlined,
          file: _chatShot,
          onPick: () async {
            final f = await pickKycImage(context,
                source: ImageSource.gallery);
            if (f != null) setState(() => _chatShot = f);
          },
          onRemove: () => setState(() => _chatShot = null),
          height: 120,
        ),
        const SizedBox(height: 16),

        // Evidence quality indicator
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: quality.$3.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: quality.$3.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Text('🛡️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_t('Evidence Check', 'प्रमाण जाँच')}: ${quality.$2}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: quality.$3,
                        )),
                    Text(
                      quality.$1 == 'strong'
                          ? _t(
                              'Both payment and chat proof attached. This report carries full weight.',
                              'भुक्तानी र च्याट दुवै प्रमाण संलग्न छन्। यो उजुरीको पूरा महत्त्व छ।')
                          : quality.$1 == 'partial'
                              ? _t(
                                  'One screenshot attached. Adding both makes your report stronger.',
                                  'एउटा स्क्रिनसट संलग्न छ। दुवै थप्दा उजुरी बलियो हुन्छ।')
                              : _t(
                                  'No evidence attached. Reports without evidence carry much less weight.',
                                  'कुनै प्रमाण संलग्न छैन। प्रमाणविनाको उजुरीको महत्त्व धेरै कम हुन्छ।'),
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Why evidence matters
        _WhyEvidenceMatters(lang: _lang),
      ],
    );
  }
}

/// Expandable info card: how structured evidence supports formal
/// complaints under Nepal's Electronic Transactions Act (ETA 2063).
class _WhyEvidenceMatters extends StatelessWidget {
  const _WhyEvidenceMatters({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context) {
    String t(String en, String ne) => lang == 'ne' ? ne : en;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Theme(
        data: Theme.of(context)
            .copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          title: Text(t('Why evidence matters', 'प्रमाण किन महत्त्वपूर्ण'),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              )),
          children: [
            Text(
              t(
                  'Online fraud is punishable under Nepal\'s Electronic '
                      'Transactions Act (ETA 2063). If this seller is reported '
                      'by multiple buyers, your screenshots become part of a '
                      'structured evidence file that supports a formal '
                      'complaint to the Cyber Bureau, making action against '
                      'the scammer far more likely.',
                  'अनलाइन ठगी नेपालको विद्युतीय कारोबार ऐन (ETA 2063) '
                      'अन्तर्गत दण्डनीय छ। यदि यो विक्रेतालाई धेरै ग्राहकले '
                      'उजुरी गरे, तपाईंको स्क्रिनसट साइबर ब्युरोमा औपचारिक '
                      'उजुरीलाई सहयोग गर्ने संरचित प्रमाण फाइलको भाग बन्छ, '
                      'जसले ठगविरुद्ध कारबाही धेरै सम्भव बनाउँछ।'),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
