import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/group_model.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/saving_model.dart';
import '../../data/models/user_model.dart';
import '../extensions/date_extensions.dart';

class PdfGenerator {
  /// Generates Monthly Savings & Loan Report PDF and prompts print/save or share
  static Future<Uint8List> generateMonthlyReportPdf({
    required GroupModel group,
    required int month,
    required int year,
    required List<SavingModel> savings,
    required List<LoanModel> loans,
    required List<UserModel> members,
  }) async {
    final pdf = pw.Document();

    final monthName = DateTimeExtensions.marathiMonths[month - 1];
    final totalSavings = savings.fold(0.0, (sum, s) => sum + s.totalPaid);
    final activeLoans = loans.where((l) => l.status == LoanStatus.active).toList();
    final totalLoans = activeLoans.fold(0.0, (sum, l) => sum + l.outstandingPrincipal);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${group.name} - मासिक अहवाल',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('गाव: ${group.village} | महिना: $monthName $year'),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Summary Stats Box
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('एकूण जमा बचत', style: const pw.TextStyle(fontSize: 12)),
                      pw.Text('Rs. ${totalSavings.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('सक्रिय कर्ज मुद्दल', style: const pw.TextStyle(fontSize: 12)),
                      pw.Text('Rs. ${totalLoans.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Savings Table
            pw.Text('मासिक बचत संकलन विवरण',
                style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['अ.क्र.', 'सदस्याचे नाव', 'बचत (Rs.)', 'दंड (Rs.)', 'एकूण (Rs.)', 'दिनांक'],
              data: List.generate(savings.length, (index) {
                final s = savings[index];
                return [
                  '${index + 1}',
                  s.memberName,
                  s.amount.toStringAsFixed(2),
                  s.lateFee.toStringAsFixed(2),
                  s.totalPaid.toStringAsFixed(2),
                  s.paidAt.toFormattedDate(),
                ];
              }),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2E7D32)),
              cellAlignment: pw.Alignment.centerLeft,
            ),

            pw.SizedBox(height: 30),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('अध्यक्षाची स्वाक्षरी: ________________'),
                pw.Text('उपाध्यक्षाची स्वाक्षरी: ________________'),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Generates Member Passbook PDF
  static Future<Uint8List> generatePassbookPdf({
    required UserModel member,
    required GroupModel group,
    required List<SavingModel> savings,
    required List<LoanModel> memberLoans,
  }) async {
    final pdf = pw.Document();
    final totalSavings = savings.fold(0.0, (sum, s) => sum + s.totalPaid);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('सदस्य पासबुक (Member Passbook)',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('गट: ${group.name} | गाव: ${group.village}'),
                  pw.Text('सदस्याचे नाव: ${member.name} | मोबाईल: ${member.phone}'),
                  pw.Text('आधार क्रमांक: XXXX-XXXX-${member.aadhaarLast4}'),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text('एकूण जमा बचत: Rs. ${totalSavings.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF2E7D32))),
            pw.SizedBox(height: 16),
            pw.Text('बचत इतिहास', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['महिना', 'वर्ष', 'रक्कम (Rs.)', 'पावती दिनांक'],
              data: savings.map((s) {
                final monthName = s.month >= 1 && s.month <= 12
                    ? DateTimeExtensions.marathiMonths[s.month - 1]
                    : '${s.month}';
                return [
                  monthName,
                  '${s.year}',
                  s.totalPaid.toStringAsFixed(2),
                  s.paidAt.toFormattedDate(),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF6A1B9A)),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Generates Yearly Summary Report PDF
  static Future<Uint8List> generateYearlyReportPdf({
    required GroupModel group,
    required int year,
    required List<SavingModel> savings,
    required List<LoanModel> loans,
  }) async {
    final pdf = pw.Document();
    final totalSavingsYear = savings.where((s) => s.year == year).fold(0.0, (sum, s) => sum + s.totalPaid);
    final totalInterestYear = loans.fold(0.0, (sum, l) => sum + l.totalInterestPaid);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${group.name} - वार्षिक ताळेबंद अहवाल ($year)',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('गाव: ${group.village} | वित्तीय वर्ष: $year'),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('वर्षभरातील एकूण बचत', style: const pw.TextStyle(fontSize: 12)),
                      pw.Text('Rs. ${totalSavingsYear.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('मिळालेले एकूण व्याज', style: const pw.TextStyle(fontSize: 12)),
                      pw.Text('Rs. ${totalInterestYear.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('महिनानिहाय वार्षिक सारांश', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['महिना', 'जमा बचत (Rs.)', 'नोंदणीकृत पावत्या'],
              data: List.generate(12, (index) {
                final month = index + 1;
                final monthSavings = savings.where((s) => s.year == year && s.month == month).toList();
                final sum = monthSavings.fold(0.0, (s, item) => s + item.totalPaid);
                return [
                  DateTimeExtensions.marathiMonths[index],
                  sum.toStringAsFixed(2),
                  '${monthSavings.length} सदस्य',
                ];
              }),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2E7D32)),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Generates Loan Statement PDF per member or across group
  static Future<Uint8List> generateLoanStatementPdf({
    required GroupModel group,
    required List<LoanModel> loans,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${group.name} - कर्ज विवरण पत्र',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('गाव: ${group.village} | व्याज दर: ${group.settings.interestRate}% प्रति महिना (घटत्या मुद्दलावर)'),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: ['सदस्य', 'मुद्दल (Rs.)', 'बाकी मुद्दल (Rs.)', 'व्याज भरले (Rs.)', 'स्थिती'],
              data: loans.map((l) {
                return [
                  l.memberName,
                  l.amount.toStringAsFixed(2),
                  l.outstandingPrincipal.toStringAsFixed(2),
                  l.totalInterestPaid.toStringAsFixed(2),
                  l.status.name.toUpperCase(),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1565C0)),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Share PDF to WhatsApp or any external app
  static Future<void> sharePdf({
    required Uint8List pdfBytes,
    required String filename,
    required String text,
  }) async {
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: filename,
    );
  }
}

