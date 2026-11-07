import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../core/utils/pdf_generator.dart';
import '../../providers/group_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/savings_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _reportMonth = DateTime.now().month;
  int _reportYear = DateTime.now().year;
  bool _isGenerating = false;

  Future<void> _exportMonthlyReport() async {
    final group = ref.read(currentGroupProvider).value;
    final allSavings = ref.read(groupSavingsProvider).value ?? [];
    final allLoans = ref.read(groupLoansProvider).value ?? [];
    final members = ref.read(approvedMembersProvider).value ?? [];

    if (group == null) return;

    setState(() => _isGenerating = true);

    try {
      final monthlySavings = allSavings
          .where((s) => s.month == _reportMonth && s.year == _reportYear)
          .toList();

      final pdfBytes = await PdfGenerator.generateMonthlyReportPdf(
        group: group,
        month: _reportMonth,
        year: _reportYear,
        savings: monthlySavings,
        loans: allLoans,
        members: members,
      );

      final monthName = DateTimeExtensions.marathiMonths[_reportMonth - 1];
      await PdfGenerator.sharePdf(
        pdfBytes: pdfBytes,
        filename: 'Report_${group.name}_$monthName$_reportYear.pdf',
        text: '${group.name} - $monthName $_reportYear मासिक अहवाल',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('अहवाल तयार करताना त्रुटी: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _exportYearlyReport() async {
    final group = ref.read(currentGroupProvider).value;
    final allSavings = ref.read(groupSavingsProvider).value ?? [];
    final allLoans = ref.read(groupLoansProvider).value ?? [];

    if (group == null) return;
    setState(() => _isGenerating = true);

    try {
      final pdfBytes = await PdfGenerator.generateYearlyReportPdf(
        group: group,
        year: _reportYear,
        savings: allSavings,
        loans: allLoans,
      );

      await PdfGenerator.sharePdf(
        pdfBytes: pdfBytes,
        filename: 'Yearly_Report_${group.name}_$_reportYear.pdf',
        text: '${group.name} - $_reportYear वार्षिक अहवाल',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('वार्षिक अहवाल तयार करताना त्रुटी: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _exportLoanStatement() async {
    final group = ref.read(currentGroupProvider).value;
    final allLoans = ref.read(groupLoansProvider).value ?? [];

    if (group == null) return;
    setState(() => _isGenerating = true);

    try {
      final pdfBytes = await PdfGenerator.generateLoanStatementPdf(
        group: group,
        loans: allLoans,
      );

      await PdfGenerator.sharePdf(
        pdfBytes: pdfBytes,
        filename: 'Loan_Statement_${group.name}.pdf',
        text: '${group.name} - कर्ज विवरण पत्र',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('कर्ज विवरण तयार करताना त्रुटी: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthName = DateTimeExtensions.marathiMonths[_reportMonth - 1];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('अहवाल (Reports & PDF)'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Monthly Report Card
              _buildReportCard(
                title: 'मासिक संकलन व कर्ज अहवाल (Monthly Report)',
                subtitle: 'निवडलेल्या महिन्यातील संपूर्ण बचत संकलन आणि सक्रिय कर्जाचा तपशीलवार PDF अहवाल.',
                icon: Icons.calendar_month,
                color: AppColors.primary,
                trailingWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<int>(
                      value: _reportMonth,
                      items: List.generate(12, (index) {
                        return DropdownMenuItem(
                          value: index + 1,
                          child: Text(DateTimeExtensions.marathiMonths[index]),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) setState(() => _reportMonth = val);
                      },
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _reportYear,
                      items: [2024, 2025, 2026].map((y) {
                        return DropdownMenuItem(value: y, child: Text('$y'));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _reportYear = val);
                      },
                    ),
                  ],
                ),
                onDownload: _isGenerating ? null : _exportMonthlyReport,
                onShare: _isGenerating ? null : _exportMonthlyReport,
              ),
              const SizedBox(height: 16),

              // Yearly Report Card
              _buildReportCard(
                title: 'वार्षिक ताळेबंद अहवाल (Yearly Report)',
                subtitle: 'संपूर्ण वर्षातील एकूण बचत, कर्ज वाटप, परतफेड आणि बँक शिल्लक यांचा वार्षिक लेखाजोखा.',
                icon: Icons.receipt_long,
                color: AppColors.secondary,
                onDownload: _isGenerating ? null : _exportYearlyReport,
                onShare: _isGenerating ? null : _exportYearlyReport,
              ),
              const SizedBox(height: 16),

              // Loan Statement Card
              _buildReportCard(
                title: 'कर्ज विवरण पत्र (Loan Statement)',
                subtitle: 'गटातील सर्व सक्रिय आणि थकित कर्जांची सविस्तर स्थिती व व्याज हिशेब तक्ता.',
                icon: Icons.account_balance,
                color: const Color(0xFF1565C0),
                onDownload: _isGenerating ? null : _exportLoanStatement,
                onShare: _isGenerating ? null : _exportLoanStatement,
              ),
              const SizedBox(height: 16),

              // Attendance Report Card
              _buildReportCard(
                title: 'बैठक उपस्थिती अहवाल (Attendance Report)',
                subtitle: 'सर्व सदस्यांची वर्षभरातील बैठक उपस्थिती टक्केवारी आणि बैठकींचे इतिवृत्त नोंद.',
                icon: Icons.people_outline,
                color: Colors.teal,
                onDownload: _isGenerating ? null : _exportMonthlyReport,
                onShare: _isGenerating ? null : _exportMonthlyReport,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    Widget? trailingWidget,
    VoidCallback? onDownload,
    VoidCallback? onShare,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          if (trailingWidget != null) ...[
            const SizedBox(height: 10),
            trailingWidget,
          ],
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('PDF डाऊनलोड'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366), // WhatsApp green
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
