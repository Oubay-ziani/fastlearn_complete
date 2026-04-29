import 'dart:typed_data';
// filepath: certificate_viewmodel.dart
import 'package:pdf/widgets.dart' as pw;
// Add other imports as needed (e.g., Firebase, ChangeNotifier)
// ...existing code...
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import '/core/constants/app_constants.dart';
import '/core/domain/entities.dart';
import '/core/data/models.dart';

// ═══════════════════════════════════════════════════════════
// CERTIFICATE VIEWMODEL — MVVM
// Implements: Enrollment.generateCertificate()
//             Certificate.download()
//             Student.downloadCertificate()
// ═══════════════════════════════════════════════════════════
class CertificateViewModel extends ChangeNotifier {
  final _db      = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _uuid    = const Uuid();

  List<CertificateEntity> _certificates = [];
  bool                    _isLoading    = false;
  String?                 _error;

  List<CertificateEntity> get certificates => _certificates;
  bool                    get isLoading    => _isLoading;
  String?                 get error        => _error;

  // ── Load user certificates ──
  Future<void> loadCertificates(String userId) async {
    _setLoading(true);
    final snap = await _db.collection(AppConstants.certificatesCol)
        .where('userId', isEqualTo: userId)
        .orderBy('issuedDate', descending: true)
        .get();
    _certificates = snap.docs.map((d) => CertificateModel.fromFirestore(d)).toList();
    _setLoading(false);
  }

  // ── GENERATE CERTIFICATE (Enrollment.generateCertificate) ──
  Future<CertificateEntity?> generateCertificate({
    required String userId,
    required String studentName,
    required String courseId,
    required String courseName,
  }) async {
    _setLoading(true);
    try {
      // Check if certificate already exists
      final existing = await _db.collection(AppConstants.certificatesCol)
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        _setLoading(false);
        return CertificateModel.fromFirestore(existing.docs.first);
      }

      // ...existing code...

// Generate PDF
final pdfBytes = await _buildCertificatePdf(studentName, courseName);

// Convert to Uint8List for Firebase Storage
final pdfUint8List = Uint8List.fromList(pdfBytes);

// Upload to Storage
final certId = _uuid.v4();
final ref = _storage.ref('${AppConstants.certsPath}/$certId.pdf');
await ref.putData(pdfUint8List);  // Use the converted list
final downloadUrl = await ref.getDownloadURL();

// ...existing code...

      // Save to Firestore
      final cert = CertificateModel(
        certificateId: certId,
        userId: userId,
        studentName: studentName,
        courseName: courseName,
        issuedDate: DateTime.now(),
        downloadUrl: downloadUrl,
      );
      final data = cert.toFirestore();
      data['courseId'] = courseId;
      await _db.collection(AppConstants.certificatesCol).doc(certId).set(data);

      _certificates = [cert, ..._certificates];
      _setLoading(false);
      return cert;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }

  // ── DOWNLOAD CERTIFICATE (Certificate.download, Student.downloadCertificate) ──
  Future<void> downloadCertificate(CertificateEntity cert) async {
    _setLoading(true);
    try {
      final pdfBytes = await _buildCertificatePdf(cert.studentName, cert.courseName);
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // ── Build professional PDF certificate ──
  Future<Uint8List> _buildCertificatePdf(String studentName, String courseName) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.openSansBold();
    final fontRegular = await PdfGoogleFonts.openSansRegular();

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (ctx) => pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.blue800, width: 8),
        ),
        padding: const pw.EdgeInsets.all(40),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text('CERTIFICATE OF COMPLETION',
              style: pw.TextStyle(font: font, fontSize: 28, color: PdfColors.blue800)),
            pw.SizedBox(height: 20),
            pw.Text('This is to certify that',
              style: pw.TextStyle(font: fontRegular, fontSize: 14, color: PdfColors.grey700)),
            pw.SizedBox(height: 16),
            pw.Text(studentName,
              style: pw.TextStyle(font: font, fontSize: 36, color: PdfColors.black)),
            pw.Divider(color: PdfColors.blue200, thickness: 1),
            pw.SizedBox(height: 16),
            pw.Text('has successfully completed',
              style: pw.TextStyle(font: fontRegular, fontSize: 14, color: PdfColors.grey700)),
            pw.SizedBox(height: 12),
            pw.Text(courseName,
              style: pw.TextStyle(font: font, fontSize: 22, color: PdfColors.blue900),
              textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 30),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Column(children: [
                pw.Text('Fast Learn', style: pw.TextStyle(font: font, fontSize: 16)),
                pw.SizedBox(height: 4),
                pw.Text('E-Learning Platform', style: pw.TextStyle(font: fontRegular, fontSize: 12, color: PdfColors.grey)),
              ]),
              pw.Column(children: [
                pw.Text('Date: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                  style: pw.TextStyle(font: fontRegular, fontSize: 12, color: PdfColors.grey)),
              ]),
            ]),
          ],
        ),
      ),
    ));
    return doc.save();
  }

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void clearError() { _error = null; notifyListeners(); }
}
