import 'package:intl/intl.dart';
import '../models/seller_model.dart';
import '../models/report_model.dart';

/// SafeBuy Nepal — Cyber Bureau Auto-Escalation
///
/// When a seller accumulates enough verified fraud reports / losses, the
/// platform auto-prepares the official Nepali complaint petition (निवेदन)
/// addressed to the Cyber Bureau, Nepal Police — ready for an admin to submit.
abstract final class CyberBureauService {
  // ── Escalation thresholds ──────────────────────────────────────────────────
  static const int minReports = 5;
  static const double minTotalLoss = 50000; // NPR
  static const double criticalScore = 25;

  /// Decides whether a seller's case warrants escalation to the Cyber Bureau.
  static bool shouldEscalate(SellerModel seller, List<ReportModel> reports) {
    final valid =
        reports.where((r) => r.status != 'flagged_false').toList();
    final totalLoss = valid.fold<double>(0, (s, r) => s + r.amountLost);
    if (valid.length >= minReports) return true;
    if (totalLoss >= minTotalLoss) return true;
    if (seller.trustScore < criticalScore && valid.length >= 3) return true;
    return false;
  }

  /// Human-readable reason the case crossed the threshold.
  static String escalationReason(
      SellerModel seller, List<ReportModel> reports) {
    final valid =
        reports.where((r) => r.status != 'flagged_false').toList();
    final totalLoss = valid.fold<double>(0, (s, r) => s + r.amountLost);
    final reasons = <String>[];
    if (valid.length >= minReports) {
      reasons.add('${valid.length} verified reports (≥ $minReports)');
    }
    if (totalLoss >= minTotalLoss) {
      reasons.add('NPR ${_money(totalLoss)} total loss (≥ NPR ${_money(minTotalLoss)})');
    }
    if (seller.trustScore < criticalScore && valid.length >= 3) {
      reasons.add('critical trust score ${seller.trustScore.toStringAsFixed(0)}');
    }
    return reasons.isEmpty ? 'Below threshold' : reasons.join(' • ');
  }

  /// Generates the formal bilingual निवेदन (petition) letter text.
  static String generateNivedan(
    SellerModel seller,
    List<ReportModel> reports,
  ) {
    final valid = reports.where((r) => r.status != 'flagged_false').toList()
      ..sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
    final totalLoss = valid.fold<double>(0, (s, r) => s + r.amountLost);
    final dateFmt = DateFormat('yyyy-MM-dd');
    final today = dateFmt.format(DateTime.now());

    // Identifiers
    final handles = <String>[];
    if ((seller.tiktokHandle ?? '').isNotEmpty) {
      handles.add('TikTok: @${seller.tiktokHandle}');
    }
    if ((seller.instagramHandle ?? '').isNotEmpty) {
      handles.add('Instagram: @${seller.instagramHandle}');
    }
    if ((seller.facebookHandle ?? '').isNotEmpty) {
      handles.add('Facebook: ${seller.facebookHandle}');
    }
    final handlesStr = handles.isEmpty ? 'उपलब्ध छैन' : handles.join(', ');
    final esewa = (seller.esewaId ?? '').isNotEmpty ? seller.esewaId! : 'उपलब्ध छैन';

    // Incident summary
    final typeCounts = <String, int>{};
    for (final r in valid) {
      typeCounts[r.incidentType] = (typeCounts[r.incidentType] ?? 0) + 1;
    }
    final typeSummary = typeCounts.entries
        .map((e) => '${_incidentNe(e.key)} (${e.value})')
        .join(', ');

    final period = valid.isEmpty
        ? today
        : '${dateFmt.format(valid.first.submittedAt)} देखि ${dateFmt.format(valid.last.submittedAt)}';

    // Report reference list
    final refList = valid
        .map((r) =>
            '   • ${r.reportId} | ${_incidentNe(r.incidentType)} | रु ${_money(r.amountLost)} | ${dateFmt.format(r.incidentDate)}')
        .join('\n');

    final buffer = StringBuffer();

    // ── Nepali petition ──────────────────────────────────────────────────────
    buffer.writeln('मिति: $today');
    buffer.writeln();
    buffer.writeln('श्रीमान् प्रमुखज्यू,');
    buffer.writeln('साइबर ब्यूरो, नेपाल प्रहरी');
    buffer.writeln('भोटाहिटी, काठमाडौं');
    buffer.writeln();
    buffer.writeln('विषय: अनलाइन खरिद-बिक्रीमा भएको ठगी सम्बन्धी उजुरी।');
    buffer.writeln();
    buffer.writeln('महोदय,');
    buffer.writeln(
        'उपर्युक्त सम्बन्धमा, SafeBuy Nepal सामुदायिक प्लेटफर्ममा दर्ता भएका प्रमाणित '
        'उजुरीहरूका आधारमा, तपसिलमा उल्लिखित विक्रेताविरुद्ध सामाजिक सञ्जालमार्फत '
        'भएको अनलाइन ठगीका सम्बन्धमा आवश्यक अनुसन्धान एवं कानुनी कारबाहीका लागि '
        'यो निवेदन पेस गर्दछु।');
    buffer.writeln();
    buffer.writeln('तपसिल (विक्रेता विवरण):');
    buffer.writeln('   • नाम/व्यवसाय: ${seller.name}');
    buffer.writeln('   • फोन नम्बर: ${seller.phone}');
    buffer.writeln('   • eSewa/Khalti ID: $esewa');
    buffer.writeln('   • सामाजिक सञ्जाल: $handlesStr');
    buffer.writeln();
    buffer.writeln('उजुरीको सारांश:');
    buffer.writeln('   • कुल प्रमाणित उजुरी संख्या: ${valid.length}');
    buffer.writeln('   • कुल दाबी गरिएको आर्थिक हानि: रु ${_money(totalLoss)}');
    buffer.writeln('   • ठगीका प्रकारहरू: $typeSummary');
    buffer.writeln('   • घटना अवधि: $period');
    buffer.writeln('   • SafeBuy ट्रस्ट स्कोर: ${seller.trustScore.toStringAsFixed(0)}/100 (उच्च जोखिम)');
    buffer.writeln();
    buffer.writeln('सम्बन्धित उजुरी सन्दर्भ नम्बरहरू:');
    buffer.writeln(refList.isEmpty ? '   • उपलब्ध छैन' : refList);
    buffer.writeln();

    // Evidence section
    final withEvidence = valid
        .where((r) =>
            (r.paymentScreenshotUrl?.isNotEmpty ?? false) ||
            (r.chatScreenshotUrl?.isNotEmpty ?? false))
        .toList();
    final evidenceLines = withEvidence.map((r) {
      final parts = <String>[];
      if (r.paymentScreenshotUrl?.isNotEmpty ?? false) {
        parts.add('भुक्तानी स्क्रिनसट');
      }
      if (r.chatScreenshotUrl?.isNotEmpty ?? false) {
        parts.add('च्याट स्क्रिनसट');
      }
      return '   • ${r.reportId}: ${parts.join(", ")}';
    }).join('\n');
    buffer.writeln(
        'संलग्न प्रमाण (Evidence on file): ${withEvidence.length} वटा रिपोर्टमा स्क्रिनसट');
    buffer.writeln(
        evidenceLines.isEmpty ? '   • स्क्रिनसट उपलब्ध छैन' : evidenceLines);
    buffer.writeln();
    buffer.writeln(
        'उपर्युक्त विवरणसहितका स्क्रिनसट, भुक्तानी प्रमाण लगायतका कागजातहरू '
        'SafeBuy Nepal प्लेटफर्ममा सुरक्षित रूपमा संग्रहित छन् र अनुरोध भएमा '
        'उपलब्ध गराइनेछ। उजुरीकर्ताहरूको पहिचान गोप्य राखिएको छ।');
    buffer.writeln();
    buffer.writeln(
        'अतः, माथि उल्लिखित विक्रेताविरुद्ध प्रचलित कानुनबमोजिम आवश्यक '
        'अनुसन्धान गरी पीडितहरूलाई न्याय दिलाई थप ठगीबाट आम उपभोक्तालाई '
        'जोगाइदिनुहुन सादर अनुरोध गर्दछु।');
    buffer.writeln();
    buffer.writeln('निवेदक,');
    buffer.writeln('SafeBuy Nepal (सामुदायिक उपभोक्ता संरक्षण प्लेटफर्म)');
    buffer.writeln('इमेल: report@safebuynepal.com');
    buffer.writeln();
    buffer.writeln('─────────────────────────────────────────────');
    buffer.writeln('ENGLISH SUMMARY (for reference)');
    buffer.writeln('─────────────────────────────────────────────');
    buffer.writeln('Date: $today');
    buffer.writeln('To: Chief, Cyber Bureau, Nepal Police, Bhotahiti, Kathmandu');
    buffer.writeln('Subject: Complaint regarding online marketplace fraud.');
    buffer.writeln();
    buffer.writeln(
        'On behalf of the SafeBuy Nepal community, we submit this petition '
        'against the seller below based on verified fraud reports, and request '
        'investigation and lawful action.');
    buffer.writeln();
    buffer.writeln('Seller: ${seller.name}  |  Phone: ${seller.phone}');
    buffer.writeln('eSewa/Khalti: $esewa');
    buffer.writeln('Social: ${handles.isEmpty ? "N/A" : handles.join(", ")}');
    buffer.writeln('Verified reports: ${valid.length}  |  '
        'Total claimed loss: NPR ${_money(totalLoss)}');
    buffer.writeln('Trust score: ${seller.trustScore.toStringAsFixed(0)}/100 (high risk)');
    buffer.writeln('Period: $period');
    buffer.writeln();
    buffer.writeln('Reporter identities are kept confidential. Evidence '
        '(screenshots, payment proofs) is stored securely and available on request.');

    return buffer.toString();
  }

  /// All evidence image URLs across the seller's valid reports, for the
  /// admin to review before approving the letter.
  static List<EvidenceItem> collectEvidence(List<ReportModel> reports) {
    final items = <EvidenceItem>[];
    for (final r in reports.where((r) => r.status != 'flagged_false')) {
      if (r.paymentScreenshotUrl?.isNotEmpty ?? false) {
        items.add(EvidenceItem(
            reportId: r.reportId,
            label: 'Payment',
            url: r.paymentScreenshotUrl!));
      }
      if (r.chatScreenshotUrl?.isNotEmpty ?? false) {
        items.add(EvidenceItem(
            reportId: r.reportId, label: 'Chat', url: r.chatScreenshotUrl!));
      }
    }
    return items;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  static String _money(double v) =>
      NumberFormat('#,##0', 'en_US').format(v);

  static String _incidentNe(String type) {
    switch (type) {
      case 'no_delivery':
        return 'सामान डेलिभरी नभएको';
      case 'wrong_item':
        return 'गलत सामान';
      case 'fake_product':
        return 'नक्कली सामान';
      case 'payment_issue':
        return 'भुक्तानी ठगी';
      case 'impersonation':
        return 'नक्कली पहिचान';
      default:
        return 'अन्य';
    }
  }
}

/// A single piece of evidence attached to an escalation.
class EvidenceItem {
  final String reportId;
  final String label; // Payment | Chat
  final String url;
  const EvidenceItem({
    required this.reportId,
    required this.label,
    required this.url,
  });

  bool get isLocalFile => !url.startsWith('http');
}
