import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/resume_flow.dart';
import '../../mockData/mock_opportunities.dart';
import '../../mockData/mock_resume.dart';
import '../../models/parsed_resume.dart';
import '../../models/profile_readiness.dart';
import '../../nav.dart';
import '../../services/apply_flow.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../widgets/back_chevron.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/expandable_text.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/pill_input.dart';
import '../../widgets/resume_ready_view.dart';
import '../../widgets/responsive_body.dart';

enum _Stage { input, review, success }

/// Mirrors frontend/app/college/resume.tsx (Resume).
class ResumeScreen extends StatefulWidget {
  /// Set when this screen was reached from an apply-gate on a specific
  /// opportunity — finishing the resume here submits that application
  /// automatically instead of dropping the user on a generic screen.
  final String? applyForOpportunityId;

  const ResumeScreen({super.key, this.applyForOpportunityId});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  _Stage _stage = _Stage.input;
  bool _parsing = false;
  String? _error;
  String? _pdfName;
  int? _pdfBytes;

  final _nameController = TextEditingController();
  String? _nameError;
  final _skillInputController = TextEditingController();
  List<String> _skills = [];
  List<ResumeEducation> _education = [];
  List<ResumeProject> _projects = [];
  bool _loading = false;

  // Someone who already has a resume filled in should land on a summary of
  // what's already there, not straight back into the build/upload flow —
  // that flow only makes sense as a first stop when nothing exists yet.
  // Callers that route here specifically because a resume is *missing*
  // (the apply gate, the onboarding redirect, the profile checklist) all
  // naturally skip the summary too, since `hasResume` is false for them.
  late bool _showSummary = context.read<AppState>().user?.hasResume ?? false;
  late final bool _hadSummary = _showSummary;

  @override
  void initState() {
    super.initState();
    // Hydrate the editable review-stage state from the existing resume so
    // that re-uploading a PDF from Summary mode actually triggers the
    // "Replace your current edits?" confirm — without this, _skills /
    // _education / _projects start empty here even for a user with a rich
    // quiz-built resume, and _analyze() silently overwrites it all with the
    // mock fixture.
    final resume = context.read<AppState>().user?.resume;
    if (resume != null) {
      _skills = List.of(resume.skills);
      _education = List.of(resume.education);
      _projects = List.of(resume.projects);
      _nameController.text = resume.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skillInputController.dispose();
    super.dispose();
  }

  static const _maxPdfBytes = 10 * 1024 * 1024;

  /// A real PDF's first bytes are always the literal ASCII "%PDF-" — a
  /// cheap, real check that a renamed non-PDF (extension alone can't catch)
  /// actually contains one.
  bool _looksLikePdf(List<int>? bytes) {
    const header = [0x25, 0x50, 0x44, 0x46, 0x2D]; // %PDF-
    if (bytes == null || bytes.length < header.length) return false;
    for (var i = 0; i < header.length; i++) {
      if (bytes[i] != header[i]) return false;
    }
    return true;
  }

  Future<void> _pickPdf() async {
    HapticFeedback.selectionClick();
    setState(() => _error = null);
    try {
      // file_picker 13.x: FilePicker.pickFiles is a direct static method
      // now (no more .platform), returns an empty list rather than a
      // nullable FilePickerResult on cancel, and PlatformFile.bytes/.size
      // became async readAsBytes()/length() — the old synchronous
      // fields are gone.
      final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf']);
      if (files.isEmpty) return;
      final file = files.first;
      final name = file.name.toLowerCase();
      if (!name.endsWith('.pdf')) {
        setState(() => _error = 'Please upload a PDF file.');
        return;
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > _maxPdfBytes) {
        setState(() => _error = 'That PDF is over 10MB — try a smaller file.');
        return;
      }
      if (!_looksLikePdf(bytes)) {
        setState(() => _error = "That doesn't look like a valid PDF file.");
        return;
      }
      setState(() {
        _pdfName = file.name;
        _pdfBytes = bytes.length;
        _error = null;
      });
      // Card is the upload CTA — parse as soon as a PDF is chosen.
      await _analyze();
    } catch (_) {
      if (mounted) setState(() => _error = 'Couldn’t open the file picker. Try again.');
    }
  }

  void _clearPdf() {
    HapticFeedback.selectionClick();
    setState(() {
      _pdfName = null;
      _pdfBytes = null;
      _error = null;
    });
  }

  String _prettySize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _analyze() async {
    if (_pdfName == null) {
      setState(() => _error = 'Upload your resume PDF first.');
      return;
    }
    // Re-analyzing (e.g. the user went review → back → picked a different
    // PDF) used to silently overwrite skills/education/projects even if
    // the user had already hand-edited them in the review stage — nothing
    // ever asked first. Only prompt when there's actually something to
    // lose; a first-time parse on an empty screen has nothing to confirm.
    if (_skills.isNotEmpty || _education.isNotEmpty || _projects.isNotEmpty) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Replace your current edits?'),
          content: const Text('Analyzing this file will overwrite the skills, education, and projects you already have here.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Replace')),
          ],
        ),
      );
      if (replace != true) return;
      if (!mounted) return;
    }
    final profileName = context.read<AppState>().user?.name;
    setState(() {
      _error = null;
      _parsing = true;
    });
    try {
      // Prototype: mock parse after PDF pick. Replace with real PDF → AI parse API.
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      final d = mockParsedResume;
      if (kResumeFlow == ResumeFlow.chat) {
        // Flow 2: the Resume Helper reads what was found, confirms it and
        // asks only about what is missing, instead of the review stage.
        final parsed = ParsedResume(
          name: (profileName != null && profileName.trim().isNotEmpty) ? profileName : d.name,
          education: d.education,
          skills: d.skills,
          projects: d.projects,
          links: d.links,
        );
        context.push(resumeBuildLocation(applyFor: widget.applyForOpportunityId), extra: parsed);
        return;
      }
      setState(() {
        _nameController.text = (profileName != null && profileName.trim().isNotEmpty) ? profileName : d.name;
        _skills = List.of(d.skills);
        _education = List.of(d.education);
        _projects = List.of(d.projects);
        _stage = _Stage.review;
      });
    } finally {
      if (mounted) setState(() => _parsing = false);
    }
  }

  void _manual() {
    final applyFor = widget.applyForOpportunityId;
    context.push(resumeBuildLocation(applyFor: applyFor));
  }

  bool get _postOnboarding => context.read<AppState>().user?.onboardingComplete == true;

  // Resume is now the last onboarding step (goals already happened), so
  // skipping it here means onboarding is done, not "on to the next thing".
  Future<void> _skipForNow() async {
    if (_postOnboarding) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/tabs');
      }
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AppState>().updateProfile((current) => current.copyWith(onboardingComplete: true));
      if (!mounted) return;
      context.go('/tabs');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _back() {
    if (_stage == _Stage.review) {
      setState(() => _stage = _Stage.input);
      return;
    }
    // Came here via "Edit details" or "Upload a new PDF" from the summary
    // — back should return there, not skip past it to whatever's under
    // this whole route.
    if (!_showSummary && _hadSummary) {
      setState(() => _showSummary = true);
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(_postOnboarding ? '/tabs' : '/college/goals');
    }
  }

  void _afterSave() {
    final applyFor = widget.applyForOpportunityId;
    if (applyFor != null) {
      // Resume just went from missing to saved — the application this
      // screen was opened for can now actually go through. Routes through
      // the same screening sheet the direct-apply path uses (instead of
      // silently auto-submitting with no note/answers) — the sheet's own
      // success flow handles confirmation and navigation from here.
      continueApplyAfterResume(context, applyFor);
      return;
    }
    // No pending application to submit — confirm the save with the same
    // success screen the guided builder ends on, then land on Home for
    // real (not a pop, which could leave the user on a stale screen).
    setState(() => _stage = _Stage.success);
  }

  void _addSkill() {
    final s = _skillInputController.text.trim();
    final alreadyAdded = _skills.any((existing) => existing.toLowerCase() == s.toLowerCase());
    if (s.isNotEmpty && !alreadyAdded) {
      setState(() => _skills = [..._skills, s]);
    }
    _skillInputController.clear();
  }

  Future<void> _save() async {
    // Was accepted silently — only ever masked by falling back to
    // user.name at PDF-export time and by the "Basic info" checklist item
    // only checking `resume != null`, not that a name was actually filled.
    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = 'Enter your name');
      return;
    }
    setState(() => _loading = true);
    try {
      final appState = context.read<AppState>();
      final wasOnboarding = !_postOnboarding;
      // TODO: replace with real API call (local mock)
      await appState.updateProfile((current) {
        final resume = ParsedResume(
          name: _nameController.text,
          skills: _skills,
          education: _education,
          projects: _projects,
          links: const [],
          // A PDF (re-)upload never collects these — they only come from
          // the guided quiz — so carry over whatever was already saved
          // instead of silently wiping them out.
          headline: current.resume?.headline,
          phone: current.resume?.phone,
          experienceLevel: current.resume?.experienceLevel,
          specializations: current.resume?.specializations ?? const [],
          summary: current.resume?.summary,
          workExperience: current.resume?.workExperience ?? const [],
          // Same reasoning as the fields above — a PDF (re-)upload never
          // touches these either, so re-uploading over a quiz-built resume
          // used to silently wipe out any certifications/portfolio link
          // that were already saved.
          certifications: current.resume?.certifications ?? const [],
          portfolioLink: current.resume?.portfolioLink,
          portfolioFileName: current.resume?.portfolioFileName,
        );
        return wasOnboarding ? current.copyWith(resume: resume, onboardingComplete: true) : current.copyWith(resume: resume);
      });
      if (!mounted) return;
      _afterSave();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmEdit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Edit your resume?', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.semibold)),
        content: Text(
          "You'll go through the resume builder to update your details.",
          style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontWeight: AppFontWeight.medium)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Yes, edit', style: AppTextStyles.body.copyWith(color: AppColors.blue, fontWeight: AppFontWeight.bold)),
          ),
        ],
      ),
    );
    // Straight into the guided quiz at step 0, not the old two-hop path
    // through _buildInput()'s PDF-vs-manual chooser — that choice only
    // makes sense when no resume exists yet; someone who explicitly asked
    // to start over already has one and just wants back into the quiz.
    if (confirmed == true && mounted) _goToStep(0);
  }

  @override
  Widget build(BuildContext context) {
    if (_stage == _Stage.success) {
      return ResumeReadyView(
        user: context.watch<AppState>().user,
        onDone: () => context.go('/tabs'),
      );
    }

    if (_showSummary) {
      return _buildSummaryScreen();
    }

    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isTablet = AppBreakpoints.isWide(context);

    return PopScope(
      // Without this, the system/browser back gesture pops the whole route
      // instead of returning from the review stage to the input stage, or
      // from the build flow back to the summary it was opened from.
      canPop: _stage == _Stage.input && !(!_showSummary && _hadSummary),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Column(
          children: [
            // A single ListView, not a fixed header + separately-scrolling
            // Expanded below it — a pinned header here left too little of
            // the fold visible, especially with TopNavBar also taking space
            // above it at desktop. The header is still deliberately NOT
            // wrapped in ResponsiveBody at the Container level — its
            // background is a true full-bleed banner — but its own text
            // gets the same ResponsiveBody(800) + padding as the form
            // below, so it aligns with it instead of hugging the true edge.
            // The Save/Skip footer stays a fixed sibling below this
            // ListView (a pinned bottom action bar is the expected pattern,
            // unlike a pinned header eating into the fold).
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isTablet ? AppColors.white : AppColors.blue,
                      border: isTablet ? const Border(bottom: BorderSide(color: AppColors.border, width: 1)) : null,
                    ),
                    child: ResponsiveBody(
                      maxWidth: isTablet ? 720 : AppBreakpoints.maxContentWidth,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BackChevron(color: isTablet ? AppColors.ink : AppColors.white, onPressed: _back),
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.md),
                              child: Text(
                                _postOnboarding
                                    ? (_stage == _Stage.input ? 'ALMOST READY TO APPLY' : 'LOOKS GOOD?')
                                    : (_stage == _Stage.input ? 'STEP 3 OF 3' : 'LOOKS GOOD?'),
                                style: AppTextStyles.caption.copyWith(color: isTablet ? AppColors.gray500 : AppColors.yellow, fontSize: 12, fontWeight: AppFontWeight.medium, letterSpacing: 1.2),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm),
                              child: Text(
                                _stage == _Stage.input ? 'Build your profile' : 'Review your profile',
                                style: AppTextStyles.h1.copyWith(color: isTablet ? AppColors.ink : AppColors.white, fontSize: 28, fontWeight: AppFontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ResponsiveBody(
                    maxWidth: isTablet ? 720 : AppBreakpoints.maxContentWidth,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxxl),
                      child: Column(
                        children: _stage == _Stage.input ? _buildInput() : _buildReview(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Both resume paths are now full-width tappable cards in the body
            // itself, so the input stage only needs a footer at all when
            // there's a skip option to offer.
            if (_stage == _Stage.review)
              ResponsiveBody(
                maxWidth: isTablet ? 720 : AppBreakpoints.maxContentWidth,
                child: Container(
                  padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, bottomInset + AppSpacing.md),
                  decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isTablet ? 400 : double.infinity),
                      child: PillButton(
                        label: _postOnboarding ? 'Save resume' : 'Save & Continue',
                        onPressed: _save,
                        loading: _loading,
                      ),
                    ),
                  ),
                ),
              )
            else if (!_postOnboarding)
              ResponsiveBody(
                maxWidth: isTablet ? 720 : AppBreakpoints.maxContentWidth,
                child: Container(
                  padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, bottomInset + AppSpacing.md),
                  decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isTablet ? 400 : double.infinity),
                      child: PillButton(
                        label: 'Skip for now',
                        variant: PillVariant.ghost,
                        onPressed: _parsing ? null : _skipForNow,
                        loading: _loading,
                        disabled: _parsing,
                      ),
                    ),
                  ),
                ),
              )
            else
              SizedBox(height: bottomInset + AppSpacing.md),
          ],
        ),
      ),
      ),
    );
  }

  void _goToStep(int step) {
    final applyFor = widget.applyForOpportunityId;
    final uri = Uri(path: '/college/resume/build', queryParameters: {
      'step': '$step',
      if (applyFor != null) 'applyFor': applyFor,
    });
    context.push(uri.toString());
  }

  Widget _buildSummaryScreen() {
    final user = context.watch<AppState>().user;
    final resume = user?.resume;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isTablet = AppBreakpoints.isWide(context);
    // Mirrors the 7 quiz steps in resume_builder_quiz_screen.dart exactly —
    // 'Fresher' is the sentinel that screen itself writes to
    // experienceLevel when the user explicitly answers "no experience"
    // (not left blank/skipped), so that counts as done too.
    final sections = [
      // Needs a real name, not just "the resume object exists" — filling
      // only Intro + Languages autosaves a ParsedResume, and `done:
      // resume != null` then showed "Basic info ✓" while `hasResume` (which
      // the apply gate checks) was still false because there's no
      // skills/education/projects yet.
      (title: 'Basic info', icon: Ionicons.person_outline, done: resume?.name.trim().isNotEmpty ?? false, step: 0),
      (title: 'Education', icon: Ionicons.school_outline, done: resume?.education.isNotEmpty ?? false, step: 1),
      (
        title: 'Experience',
        icon: Ionicons.briefcase_outline,
        done: (resume?.workExperience.isNotEmpty ?? false) || resume?.experienceLevel == 'Fresher',
        step: 2,
      ),
      (title: 'Certifications', icon: Ionicons.ribbon_outline, done: resume?.certifications.isNotEmpty ?? false, step: 3),
      (title: 'Skills', icon: Ionicons.code_slash_outline, done: resume?.skills.isNotEmpty ?? false, step: 4),
      (title: 'Languages', icon: Ionicons.globe_outline, done: (user?.languages ?? const []).isNotEmpty, step: 5),
      (title: 'Summary', icon: Ionicons.document_text_outline, done: resume?.summary?.trim().isNotEmpty ?? false, step: 6),
    ];

    return Scaffold(
      backgroundColor: AppColors.white,
      // A single ListView, not a fixed header + separately-scrolling
      // Expanded below it — a pinned header here left too little of the
      // fold visible, especially with TopNavBar also taking space above it
      // at desktop. The header is still deliberately NOT wrapped in
      // ResponsiveBody at the Container level — its background is a true
      // full-bleed banner — but its own text gets the same
      // ResponsiveBody(800) + padding as the content below it, so it
      // aligns with it instead of hugging the true edge. The Upload-new-PDF
      // footer stays a fixed sibling below the ListView (a pinned bottom
      // action bar is the expected pattern, unlike a pinned header).
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isTablet ? AppColors.white : AppColors.blue,
                    border: isTablet ? const Border(bottom: BorderSide(color: AppColors.border, width: 1)) : null,
                  ),
                  child: ResponsiveBody(
                    maxWidth: isTablet ? 720 : AppBreakpoints.maxContentWidth,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BackChevron(color: isTablet ? AppColors.ink : AppColors.white, fallbackRoute: '/tabs/profile'),
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: Text('Resume', style: AppTextStyles.h1.copyWith(color: isTablet ? AppColors.ink : AppColors.white, fontSize: 28, fontWeight: AppFontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ResponsiveBody(
                  maxWidth: isTablet ? 720 : AppBreakpoints.maxContentWidth,
                  child: resume == null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl).copyWith(top: AppSpacing.xxxl),
                          child: EmptyState(
                            icon: Ionicons.document_text_outline,
                            title: 'No resume saved yet',
                            subtitle: 'Build one from scratch or upload an existing PDF.',
                            buttonLabel: 'Build my resume',
                            onButtonTap: () => context.push(resumeBuildLocation()),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxxl),
                          child: Column(
                    // stretch (not the default centre): each summary section
                    // shrink-wrapped to its content and was centred, which is
                    // what centred Full name / Skills / Education on this page.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Complete your resume', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.medium)),
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xl),
                        child: _ResumeSectionChecklist(sections: sections, onTap: _goToStep),
                      ),
                      if (resume.name.trim().isNotEmpty) _SummarySection(label: 'Full name', child: Text(resume.name, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.medium))),
                      if (resume.summary?.trim().isNotEmpty ?? false)
                        _SummarySection(label: 'Summary', child: Text(resume.summary!, style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14, height: 1.4))),
                      if (resume.skills.isNotEmpty)
                        _SummarySection(
                          label: 'Skills',
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: resume.skills.map((s) => _ReadOnlyChip(label: s)).toList(),
                          ),
                        ),
                      if (resume.education.isNotEmpty)
                        _SummarySection(
                          label: 'Education',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: resume.education.map((e) => _SummaryCard(title: e.degree, subtitle: [e.institution, e.duration].where((s) => s.isNotEmpty).join(' • '))).toList(),
                          ),
                        ),
                      if (resume.workExperience.isNotEmpty)
                        _SummarySection(
                          label: 'Employment',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: resume.workExperience.map((w) => _SummaryCard(title: w.role, subtitle: [w.company, w.duration].where((s) => s.isNotEmpty).join(' • '))).toList(),
                          ),
                        ),
                      if (resume.certifications.isNotEmpty)
                        _SummarySection(
                          label: 'Certifications',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: resume.certifications
                                .map((c) => _SummaryCard(
                                      title: c.name,
                                      subtitle: [c.duration, if ((c.link ?? '').isNotEmpty) 'Certificate link added']
                                          .where((s) => s.isNotEmpty)
                                          .join(' • '),
                                    ))
                                .toList(),
                          ),
                        ),
                      if (resume.projects.isNotEmpty)
                        _SummarySection(
                          label: 'Projects',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: resume.projects.map((p) => _SummaryCard(title: p.title, subtitle: p.description)).toList(),
                          ),
                        ),
                      if (resume.portfolioLink?.trim().isNotEmpty ?? false)
                        _SummarySection(label: 'Portfolio', child: Text(resume.portfolioLink!, style: AppTextStyles.body.copyWith(color: AppColors.blue, fontSize: 14, fontWeight: AppFontWeight.medium))),
                    ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          ResponsiveBody(
            maxWidth: isTablet ? 720 : AppBreakpoints.maxContentWidth,
            child: Container(
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, bottomInset + AppSpacing.md),
            decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 400 : double.infinity),
                child: Column(
                  children: [
                    // A direct, unconfirmed second option — re-uploading a PDF
                    // is its own obviously-intentional action, not a multi-step
                    // edit that benefits from an "are you sure" gate.
                    PillButton(label: 'Upload a new PDF', variant: PillVariant.ghost, onPressed: () => setState(() => _showSummary = false)),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: GestureDetector(
                        onTap: _confirmEdit,
                        child: Text(
                          'Start over from the beginning',
                          style: AppTextStyles.label.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInput() {
    final hasPdf = _pdfName != null;
    final sizeLabel = _prettySize(_pdfBytes);

    // A reminder for "Not now" on the apply gate — don't show it if this
    // resume screen *is* that exact pending flow already (applyForOpportunityId
    // would be set to the same id in that case, and continueApplyAfterResume
    // is about to fire on save anyway).
    final pendingId = context.watch<AppState>().pendingApplyOpportunityId;
    final pendingOpportunity = pendingId != null && pendingId != widget.applyForOpportunityId ? getOpportunityById(pendingId) : null;

    return [
        if (pendingOpportunity != null) ...[
          GestureDetector(
            onTap: () {
              context.read<AppState>().setPendingApplyOpportunity(null);
              context.push('/opportunity/${pendingOpportunity.id}');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: Row(
                children: [
                  const Icon(Ionicons.briefcase_outline, size: 18, color: AppColors.blue),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Finish this to apply to ${pendingOpportunity.title}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium),
                    ),
                  ),
                  const Icon(Ionicons.chevron_forward, size: 16, color: AppColors.blue),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Ionicons.checkmark_circle, size: 18, color: AppColors.blue),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  noOrphan("Saved to your profile — no need to re-upload later."),
                  style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GestureDetector(
          onTap: _parsing ? null : _pickPdf,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border.all(color: hasPdf ? AppColors.blue : AppColors.border, width: 2),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              color: hasPdf ? AppColors.blueA10 : AppColors.white,
            ),
            child: Column(
              children: [
                Container(
                  width: 44 + AppSpacing.sm,
                  height: 44 + AppSpacing.sm,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hasPdf || _parsing ? AppColors.blue : AppColors.blueA10,
                    shape: BoxShape.circle,
                  ),
                  child: _parsing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : Icon(
                          hasPdf ? Ionicons.document : Ionicons.cloud_upload_outline,
                          size: 20 + AppSpacing.xs,
                          color: hasPdf ? AppColors.white : AppColors.blue,
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(
                    _parsing
                        ? 'Reading your resume…'
                        : hasPdf
                            ? 'Resume selected'
                            : 'Upload resume PDF',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold, fontSize: 14),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    noOrphan(_parsing
                        ? 'Extracting skills and experience with AI.'
                        : hasPdf
                            ? 'Tap again to choose a different PDF.'
                            : "PDF only — we'll extract the details with AI."),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium),
                  ),
                ),
                if (hasPdf && !_parsing)
                  Container(
                    margin: const EdgeInsets.only(top: AppSpacing.lg),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: AppShadows.card,
                    ),
                    child: Row(
                      children: [
                        const Icon(Ionicons.document_text_outline, size: 20, color: AppColors.blue),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _pdfName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.left,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: AppFontWeight.medium,
                                ),
                              ),
                              if (sizeLabel.isNotEmpty)
                                Text(
                                  sizeLabel,
                                  style: AppTextStyles.caption.copyWith(color: AppColors.gray500),
                                ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _clearPdf,
                          child: const Icon(Ionicons.close_circle, size: 20, color: AppColors.gray400),
                        ),
                      ],
                    ),
                  )
                else if (!hasPdf)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Text(
                      'Tap to choose a file',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.blue,
                        fontWeight: AppFontWeight.semibold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(color: AppColors.error, fontWeight: AppFontWeight.medium),
            ),
          ),
        // No PDF ready? This is a real, equally-good second option, not a
        // fallback — a user testing this without a resume file handy felt
        // stuck here because the only thing on screen was "upload a PDF",
        // with the manual path buried as a small caption below the fold.
        if (!hasPdf && !_parsing) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Row(
              children: [
                const Expanded(child: Divider(color: AppColors.border, height: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text('or', style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontWeight: AppFontWeight.medium)),
                ),
                const Expanded(child: Divider(color: AppColors.border, height: 1)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _manual,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                color: AppColors.blueA10,
                // AppShadows.soft, not .card — .card's shadow is tuned for
                // a white "identity" card floating on a plain page, and
                // reads as a heavy, muddy smear under a pale tinted panel
                // like this one instead of a clean lift. Matches the
                // lighter tier already used elsewhere for secondary/tinted
                // panels (e.g. HomeDashboardCards' own boost-tip card,
                // which uses no shadow at all).
                boxShadow: null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                    child: const Icon(Ionicons.chatbubbles_outline, size: 20, color: AppColors.blue),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(noOrphan("Don't have a resume? Build it here"), style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold, fontSize: 14)),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text('A few quick questions — about a minute', style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Ionicons.chevron_forward, size: 20, color: AppColors.gray400),
                ],
              ),
            ),
          ),
        ],
      ];
  }

  List<Widget> _buildReview() {
    return [
        Text('Full name', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.medium)),
        const SizedBox(height: AppSpacing.sm),
        PillInput(
          controller: _nameController,
          placeholder: 'Your name',
          icon: Ionicons.person_outline,
          error: _nameError,
          onChanged: (_) => setState(() {
            if (_nameError != null) _nameError = null;
          }),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: Text('Skills', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.medium)),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _skills
                .map((s) => GestureDetector(
                      onTap: () => setState(() => _skills = _skills.where((x) => x != s).toList()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.pill)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(s, style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
                            const SizedBox(width: AppSpacing.sm),
                            const Icon(Ionicons.close, size: 14, color: AppColors.blue),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: PillInput(
                  controller: _skillInputController,
                  placeholder: 'e.g. Python',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: _addSkill,
                child: Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                  child: const Icon(Ionicons.add, size: 24, color: AppColors.white),
                ),
              ),
            ],
          ),
        ),
        if (_education.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Text('Education', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.medium)),
          ),
          ..._education.map((e) => Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.xl)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.degree.isEmpty ? 'Degree' : e.degree, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.medium)),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        [e.institution, e.duration].where((s) => s.isNotEmpty).join(' • '),
                        style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
        ],
        if (_projects.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Text('Projects', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.medium)),
          ),
          ..._projects.map((p) => Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.xl)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title.isEmpty ? 'Project' : p.title, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.medium)),
                    if (p.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: ExpandableText(
                          text: p.description,
                          maxLines: 3,
                          style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              )),
        ],
      ];
  }
}

/// Per-section done/not-done rows — tapping one jumps straight into that
/// step of the guided quiz (`/college/resume/build?step=N`) instead of
/// forcing a walk through every earlier step to reach the one that was
/// actually skipped. Mirrors profile_screen.dart's own checklist-row look
/// (`_SectionCard`'s checkmark/empty-circle badge, row-list container with
/// dividers) so this reads as the same pattern, not a new one.
class _ResumeSectionChecklist extends StatelessWidget {
  final List<({String title, IconData icon, bool done, int step})> sections;
  final ValueChanged<int> onTap;
  const _ResumeSectionChecklist({required this.sections, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < sections.length; i++)
            GestureDetector(
              onTap: () => onTap(sections[i].step),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  border: i < sections.length - 1 ? const Border(bottom: BorderSide(color: AppColors.border, width: 1)) : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
                      child: Icon(sections[i].icon, size: 18, color: AppColors.blue),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(sections[i].title, style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.medium)),
                    ),
                    Icon(
                      sections[i].done ? Ionicons.checkmark_circle : Ionicons.ellipse_outline,
                      size: 16,
                      color: sections[i].done ? AppColors.success : AppColors.gray400,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Ionicons.chevron_forward, size: 16, color: AppColors.gray400),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final String label;
  final Widget child;
  const _SummarySection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label.copyWith(color: AppColors.gray500, fontSize: 12, fontWeight: AppFontWeight.medium)),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SummaryCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.isEmpty ? 'Untitled' : title, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.medium)),
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _ReadOnlyChip extends StatelessWidget {
  final String label;
  const _ReadOnlyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(label, style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
    );
  }
}
