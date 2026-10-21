import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/parsed_resume.dart';
import '../models/user.dart';

const _brand = PdfColor.fromInt(0xFF0A2FFF);
const _brandSoft = PdfColor.fromInt(0x1A0A2FFF);
const _ink = PdfColor.fromInt(0xFF1C1C1E);
const _gray = PdfColor.fromInt(0xFF71717A);

/// Builds an actual downloadable resume PDF from the user's saved
/// [ParsedResume] — reuses the app's own Poppins font files so the
/// document matches the brand instead of falling back to a generic font.
Future<Uint8List> buildResumePdf(User user) async {
  final resume = user.resume;

  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins_400Regular.ttf'));
  final medium = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins_500Medium.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins_700Bold.ttf'));
  final extrabold = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins_800ExtraBold.ttf'));

  final doc = pw.Document();

  final contactParts = [
    if ((resume?.phone ?? '').isNotEmpty) resume!.phone!,
    if ((user.city ?? '').isNotEmpty) user.city!,
    if ((user.college ?? '').isNotEmpty) user.college!,
    user.identifier,
  ];

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 40),
      build: (context) => [
        pw.Text(
          (resume?.name.trim().isNotEmpty ?? false) ? resume!.name : (user.name ?? 'Resume'),
          style: pw.TextStyle(font: extrabold, fontSize: 22, color: _ink),
        ),
        if ((resume?.headline ?? '').isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(resume!.headline!, style: pw.TextStyle(font: medium, fontSize: 12, color: _brand)),
        ],
        pw.SizedBox(height: 4),
        pw.Text(contactParts.join('  ·  '), style: pw.TextStyle(font: regular, fontSize: 10, color: _gray)),
        pw.SizedBox(height: 18),
        if ((resume?.summary ?? '').isNotEmpty) ...[
          _sectionHeader('Summary', bold),
          pw.Text(resume!.summary!, style: pw.TextStyle(font: regular, fontSize: 10.5, color: _ink, lineSpacing: 2)),
          pw.SizedBox(height: 16),
        ],
        if ((resume?.workExperience ?? const []).isNotEmpty) ...[
          _sectionHeader('Experience', bold),
          ...resume!.workExperience.map((w) => _workEntry(w, bold, medium, regular)),
          pw.SizedBox(height: 16),
        ],
        if ((resume?.education ?? const []).isNotEmpty) ...[
          _sectionHeader('Education', bold),
          ...resume!.education.map((e) => _educationEntry(e, bold, regular)),
          pw.SizedBox(height: 16),
        ],
        if ((resume?.certifications ?? const []).isNotEmpty) ...[
          _sectionHeader('Certifications', bold),
          ...resume!.certifications.map((c) => _certificationEntry(c, bold, regular)),
          pw.SizedBox(height: 16),
        ],
        if ((resume?.skills ?? const []).isNotEmpty) ...[
          _sectionHeader('Skills', bold),
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: resume!.skills
                .map((s) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: _brandSoft,
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Text(s, style: pw.TextStyle(font: medium, fontSize: 9.5, color: _brand)),
                    ))
                .toList(),
          ),
          pw.SizedBox(height: 16),
        ],
        if ((resume?.projects ?? const []).isNotEmpty) ...[
          _sectionHeader('Projects', bold),
          ...resume!.projects.map((p) => _projectEntry(p, bold, regular)),
          pw.SizedBox(height: 16),
        ],
        if ((resume?.achievements ?? const []).isNotEmpty) ...[
          _sectionHeader('Achievements', bold),
          ...resume!.achievements.map(
            (a) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text('- $a', style: pw.TextStyle(font: regular, fontSize: 10, color: _ink)),
            ),
          ),
          pw.SizedBox(height: 16),
        ],
        if ((user.languages ?? const []).isNotEmpty) ...[
          _sectionHeader('Languages', bold),
          pw.Text(user.languages!.map((l) => l.name).join(', '), style: pw.TextStyle(font: regular, fontSize: 10, color: _ink)),
        ],
      ],
    ),
  );

  return doc.save();
}

pw.Widget _sectionHeader(String title, pw.Font bold) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title.toUpperCase(), style: pw.TextStyle(font: bold, fontSize: 11, color: _brand, letterSpacing: 1)),
        pw.SizedBox(height: 4),
        pw.Divider(color: _brand, thickness: 1.5),
        pw.SizedBox(height: 8),
      ],
    );

pw.Widget _workEntry(WorkExperience w, pw.Font bold, pw.Font medium, pw.Font regular) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${w.role} — ${w.company}', style: pw.TextStyle(font: bold, fontSize: 11, color: _ink)),
              if (w.duration.isNotEmpty) pw.Text(w.duration, style: pw.TextStyle(font: medium, fontSize: 9.5, color: _gray)),
            ],
          ),
          if (w.description.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(w.description, style: pw.TextStyle(font: regular, fontSize: 10, color: _ink, lineSpacing: 1.5)),
            ),
        ],
      ),
    );

pw.Widget _educationEntry(ResumeEducation e, pw.Font bold, pw.Font regular) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(e.degree.isEmpty ? 'Degree' : e.degree, style: pw.TextStyle(font: bold, fontSize: 11, color: _ink)),
          pw.Text(
            [e.institution, e.duration, if ((e.gpa ?? '').isNotEmpty) e.gpa!].where((s) => s.isNotEmpty).join(' · '),
            style: pw.TextStyle(font: regular, fontSize: 10, color: _gray),
          ),
        ],
      ),
    );

// The certificate image itself isn't embedded — image_picker only hands
// back a path, and nothing here re-reads/decodes it into PDF bytes today.
// Instead the PDF *acknowledges* an attached certificate on its own line
// rather than silently dropping every trace of it — a reader can then ask
// for proof. The link, if present, appears as a plain text line.
pw.Widget _certificationEntry(ResumeCertification c, pw.Font bold, pw.Font regular) {
  final meta = [
    c.duration,
    if ((c.link ?? '').isNotEmpty) c.link!,
    if ((c.imagePath ?? '').isNotEmpty) 'Certificate attached',
  ].where((s) => s.isNotEmpty).join(' · ');
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(c.name.isEmpty ? 'Certification' : c.name, style: pw.TextStyle(font: bold, fontSize: 11, color: _ink)),
        if (meta.isNotEmpty) pw.Text(meta, style: pw.TextStyle(font: regular, fontSize: 10, color: _gray)),
      ],
    ),
  );
}

pw.Widget _projectEntry(ResumeProject p, pw.Font bold, pw.Font regular) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(p.title.isEmpty ? 'Project' : p.title, style: pw.TextStyle(font: bold, fontSize: 11, color: _ink)),
          if (p.description.isNotEmpty)
            pw.Text(p.description, style: pw.TextStyle(font: regular, fontSize: 10, color: _gray)),
        ],
      ),
    );
