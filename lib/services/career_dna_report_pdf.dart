import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../mockData/career_dna/career_dna_level1_data.dart';
import '../mockData/career_dna/career_dna_level2_data.dart';
import '../mockData/career_dna/career_dna_level3_data.dart';
import '../mockData/career_dna/career_dna_level4_data.dart';
import '../mockData/career_dna/career_dna_level_meta.dart';
import '../models/career_dna.dart';
import '../models/user.dart';
import '../utils/career_dna_narrative.dart' as narrative;

const _brand = PdfColor.fromInt(0xFF0A2FFF);
const _ink = PdfColor.fromInt(0xFF1C1C1E);
const _gray = PdfColor.fromInt(0xFF71717A);

/// Builds an actual downloadable Career Quiz report PDF — reuses the app's
/// own Poppins font files, mirroring resume_pdf.dart's structure/approach.
/// Renders a section per level that's actually been completed (any subset
/// of 1-5), plus a final-synthesis section once Level 5 is done — matching
/// career_dna_report_screen.dart's and career_dna_final_report_screen.dart's
/// own on-screen content exactly, so the PDF never contradicts the app.
Future<Uint8List> buildCareerDnaReportPdf(User user) async {
  final profile = user.careerDnaOrEmpty;
  final firstName = (user.name?.trim().isNotEmpty ?? false) ? user.name!.trim().split(' ').first : null;

  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins_400Regular.ttf'));
  final medium = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins_500Medium.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins_700Bold.ttf'));
  final extrabold = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins_800ExtraBold.ttf'));
  final fonts = _Fonts(regular: regular, medium: medium, bold: bold);

  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 40),
      build: (context) => [
        pw.Text('${(user.name?.trim().isNotEmpty ?? false) ? user.name : 'Your'} Career Quiz Report', style: pw.TextStyle(font: extrabold, fontSize: 20, color: _ink)),
        pw.SizedBox(height: 2),
        pw.Text('Aerostar Career Quiz', style: pw.TextStyle(font: medium, fontSize: 11, color: _brand)),
        pw.SizedBox(height: 18),
        if (profile.level1 != null) ..._level1Section(firstName, profile.level1!, fonts),
        if (profile.level2 != null) ..._level2Section(firstName, profile.level2!, fonts),
        if (profile.level3 != null) ..._level3Section(firstName, profile.level3!, fonts),
        if (profile.level4 != null) ..._level4Section(firstName, profile.level4!, fonts),
        if (profile.level5 != null) ..._level5Section(profile.level5!, fonts),
        if (!profile.allLevelsComplete) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            'Finish the remaining levels in the app to add more to this report.',
            style: pw.TextStyle(font: regular, fontSize: 9.5, color: _gray),
          ),
        ],
      ],
    ),
  );

  return doc.save();
}

/// Single-level Career Quiz PDF — same section content/styling as the
/// combined report's per-level sections above (reuses those exact private
/// builders), just one level, with its own header naming that level's
/// formal test name. Additive to, not a replacement of,
/// buildCareerDnaReportPdf — powers the new per-level "ready to download"
/// screen (career_dna_report_screen.dart), while the combined download
/// (post-payment report-ready screen, final-report screen) keeps using the
/// function above unchanged.
Future<Uint8List> buildCareerDnaLevelReportPdf(User user, int level) async {
  final profile = user.careerDnaOrEmpty;
  final firstName = (user.name?.trim().isNotEmpty ?? false) ? user.name!.trim().split(' ').first : null;

  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins_400Regular.ttf'));
  final medium = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins_500Medium.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins_700Bold.ttf'));
  final extrabold = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins_800ExtraBold.ttf'));
  final fonts = _Fonts(regular: regular, medium: medium, bold: bold);

  final meta = careerDnaLevelMeta.firstWhere((m) => m.level == level);
  final section = _levelSection(level, firstName, profile, fonts);

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 40),
      build: (context) => [
        pw.Text(
          '${(user.name?.trim().isNotEmpty ?? false) ? user.name : 'Your'} ${meta.title} — Career Quiz Report',
          style: pw.TextStyle(font: extrabold, fontSize: 20, color: _ink),
        ),
        pw.SizedBox(height: 2),
        pw.Text('Aerostar Career Quiz', style: pw.TextStyle(font: medium, fontSize: 11, color: _brand)),
        pw.SizedBox(height: 18),
        ...section,
      ],
    ),
  );
  return doc.save();
}

/// Dispatches to the right private section builder for a single level —
/// the empty-list fallback is defensive only (this is only ever called
/// once that level's result is confirmed non-null by the caller).
List<pw.Widget> _levelSection(int level, String? firstName, CareerDnaProfile profile, _Fonts fonts) {
  switch (level) {
    case 1:
      return profile.level1 != null ? _level1Section(firstName, profile.level1!, fonts) : const [];
    case 2:
      return profile.level2 != null ? _level2Section(firstName, profile.level2!, fonts) : const [];
    case 3:
      return profile.level3 != null ? _level3Section(firstName, profile.level3!, fonts) : const [];
    case 4:
      return profile.level4 != null ? _level4Section(firstName, profile.level4!, fonts) : const [];
    default:
      return const [];
  }
}

class _Fonts {
  final pw.Font regular;
  final pw.Font medium;
  final pw.Font bold;
  const _Fonts({required this.regular, required this.medium, required this.bold});
}

List<pw.Widget> _level1Section(String? name, CareerDnaLevel1Result r, _Fonts f) {
  final first = narrative.firstSentence(r.archetype.naturalStyle);
  final rest = r.archetype.naturalStyle.substring(first.length).trim();
  final (strengths, growing) = narrative.narrativeSentences(r.dimensionScores, careerDnaLevel1DimensionPhrases);
  return [
    _sectionHeader('Level 1 — Big Five (OCEAN)', f.bold),
    pw.Text(r.archetype.name, style: pw.TextStyle(font: f.bold, fontSize: 15, color: _ink)),
    pw.SizedBox(height: 4),
    pw.Text(first, style: pw.TextStyle(font: f.regular, fontSize: 10.5, color: _ink, lineSpacing: 2)),
    pw.SizedBox(height: 10),
    _heading(name, 'Personality Snapshot', f.medium),
    pw.SizedBox(height: 3),
    pw.Text('$rest $strengths', style: pw.TextStyle(font: f.regular, fontSize: 10.5, color: _ink, lineSpacing: 2)),
    pw.SizedBox(height: 6),
    pw.Text(growing, style: pw.TextStyle(font: f.regular, fontSize: 10.5, color: _ink, lineSpacing: 2)),
    pw.SizedBox(height: 6),
    pw.Text(
      '${r.archetype.growthAreaText} You could also thrive in places like ${narrative.joinList(r.archetype.environments)}.',
      style: pw.TextStyle(font: f.regular, fontSize: 10.5, color: _ink, lineSpacing: 1.5),
    ),
    pw.SizedBox(height: 18),
  ];
}

List<pw.Widget> _level2Section(String? name, CareerDnaLevel2Result r, _Fonts f) {
  final (strengths, growing) = narrative.narrativeSentences(r.dimensionScores, careerDnaLevel2DimensionPhrases);
  return [
    _sectionHeader('Level 2 — Situational Judgement Test', f.bold),
    pw.Text(r.headlineText, style: pw.TextStyle(font: f.bold, fontSize: 15, color: _ink)),
    pw.SizedBox(height: 4),
    pw.Text(careerDnaLevel2HeroSentence(r.headlineText), style: pw.TextStyle(font: f.regular, fontSize: 10.5, color: _ink, lineSpacing: 2)),
    pw.SizedBox(height: 10),
    _heading(name, 'Interest Snapshot', f.medium),
    pw.SizedBox(height: 3),
    pw.Text(strengths, style: pw.TextStyle(font: f.regular, fontSize: 10.5, color: _ink, lineSpacing: 2)),
    pw.SizedBox(height: 6),
    pw.Text(growing, style: pw.TextStyle(font: f.regular, fontSize: 10.5, color: _ink, lineSpacing: 2)),
    pw.SizedBox(height: 6),
    pw.Text('Worth exploring: ${r.careerExplorationChain.join(' -> ')}.', style: pw.TextStyle(font: f.regular, fontSize: 10.5, color: _ink, lineSpacing: 1.5)),
    pw.SizedBox(height: 18),
  ];
}

List<pw.Widget> _level3Section(String? name, CareerDnaLevel3Result r, _Fonts f) {
  final (strengths, growing) = narrative.narrativeSentences(r.dimensionScores, careerDnaLevel3DimensionPhrases);
  return [
    _sectionHeader('Level 3 — Hogan Personality Inventory Test', f.bold),
    pw.Text(r.profile.name, style: pw.TextStyle(font: f.bold, fontSize: 15, color: _ink)),
    pw.SizedBox(height: 4),
    pw.Text(r.profile.naturalStrength, style: pw.TextStyle(font: f.regular, fontSize: 10.5, color: _ink, lineSpacing: 2)),
    pw.SizedBox(height: 10),
    _heading(name, 'Teamwork Snapshot', f.medium),
    pw.SizedBox(height: 3),
    pw.Text(strengths, style: pw.TextStyle(font: f.regular, fontSize: 10.5, color: _ink, lineSpacing: 2)),
    pw.SizedBox(height: 6),
    pw.Text(growing, style: pw.TextStyle(font: f.regular, fontSize: 10.5, color: _ink, lineSpacing: 2)),
    pw.SizedBox(height: 6),
    pw.Text(
      '${r.profile.watchOut} You could also thrive in places like ${narrative.joinList(r.profile.environments)}.',
      style: pw.TextStyle(font: f.regular, fontSize: 10.5, color: _ink, lineSpacing: 1.5),
    ),
    pw.SizedBox(height: 18),
  ];
}

List<pw.Widget> _level4Section(String? name, CareerDnaLevel4Result r, _Fonts f) {
  final bandCopy = careerDnaWorkplaceReadinessBandCopy[r.band] ?? '';
  final (strengths, growing) = narrative.narrativeSentences(r.dimensionScores, careerDnaLevel4DimensionPhrases);
  return [
    _sectionHeader('Level 4 — DISC Assessment', f.bold),
    pw.Text(r.workStyleTitle, style: pw.TextStyle(font: f.bold, fontSize: 15, color: _ink)),
    pw.SizedBox(height: 4),
    pw.Text(r.workStyleText, style: pw.TextStyle(font: f.regular, fontSize: 10.5, color: _ink, lineSpacing: 2)),
    pw.SizedBox(height: 10),
    _heading(name, 'Workplace Snapshot', f.medium),
    pw.SizedBox(height: 3),
    pw.Text('$bandCopy $strengths', style: pw.TextStyle(font: f.regular, fontSize: 10.5, color: _ink, lineSpacing: 2)),
    pw.SizedBox(height: 6),
    pw.Text(growing, style: pw.TextStyle(font: f.regular, fontSize: 10.5, color: _ink, lineSpacing: 2)),
    pw.SizedBox(height: 6),
    pw.Text('${r.developmentAreaTitle} — ${r.developmentAreaText}', style: pw.TextStyle(font: f.regular, fontSize: 10.5, color: _ink, lineSpacing: 1.5)),
    pw.SizedBox(height: 18),
  ];
}

List<pw.Widget> _level5Section(CareerDnaLevel5Result r, _Fonts f) {
  return [
    _sectionHeader('Your Final Career DNA', f.bold),
    pw.Text(r.topDirections.first.name, style: pw.TextStyle(font: f.bold, fontSize: 15, color: _ink)),
    pw.SizedBox(height: 4),
    pw.Text(r.confidenceText, style: pw.TextStyle(font: f.regular, fontSize: 10.5, color: _ink, lineSpacing: 2)),
    pw.SizedBox(height: 10),
    pw.Text('TOP CAREER DIRECTIONS', style: pw.TextStyle(font: f.bold, fontSize: 10, color: _brand, letterSpacing: 1)),
    pw.SizedBox(height: 4),
    ...r.topDirections.map((d) => pw.Text('${d.name} — ${d.fitPercent}%', style: pw.TextStyle(font: f.regular, fontSize: 10, color: _ink))),
    pw.SizedBox(height: 10),
    pw.Text('TOP JOB ROLES', style: pw.TextStyle(font: f.bold, fontSize: 10, color: _brand, letterSpacing: 1)),
    pw.SizedBox(height: 4),
    pw.Text(r.topRoles.map((role) => role.name).join(', '), style: pw.TextStyle(font: f.regular, fontSize: 10, color: _ink)),
    pw.SizedBox(height: 10),
    pw.Text('CAREER STRENGTHS', style: pw.TextStyle(font: f.bold, fontSize: 10, color: _brand, letterSpacing: 1)),
    pw.SizedBox(height: 4),
    pw.Text(r.careerStrengths.join(' · '), style: pw.TextStyle(font: f.regular, fontSize: 10, color: _ink)),
    pw.SizedBox(height: 10),
    pw.Text('WORTH BUILDING ON', style: pw.TextStyle(font: f.bold, fontSize: 10, color: _brand, letterSpacing: 1)),
    pw.SizedBox(height: 4),
    pw.Text(r.developmentAreas.join(' · '), style: pw.TextStyle(font: f.regular, fontSize: 10, color: _ink)),
    pw.SizedBox(height: 10),
    pw.Text('RECOMMENDED NEXT STEPS', style: pw.TextStyle(font: f.bold, fontSize: 10, color: _brand, letterSpacing: 1)),
    pw.SizedBox(height: 4),
    pw.Text(r.nextSteps.join(' -> '), style: pw.TextStyle(font: f.regular, fontSize: 10, color: _ink, lineSpacing: 1.5)),
  ];
}

pw.Widget _heading(String? name, String noun, pw.Font medium) =>
    pw.Text(name != null ? "$name's $noun" : 'Your $noun', style: pw.TextStyle(font: medium, fontSize: 11.5, color: _ink));

pw.Widget _sectionHeader(String title, pw.Font bold) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title.toUpperCase(), style: pw.TextStyle(font: bold, fontSize: 11, color: _brand, letterSpacing: 1)),
        pw.SizedBox(height: 4),
        pw.Divider(color: _brand, thickness: 1.5),
        pw.SizedBox(height: 8),
      ],
    );
