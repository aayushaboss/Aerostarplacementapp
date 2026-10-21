import 'dart:async';
import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../mockData/course_fields.dart';
import '../../mockData/mock_profile_options.dart';
import '../../models/language_entry.dart';
import '../../models/parsed_resume.dart';
import '../../models/user.dart';
import '../../services/apply_flow.dart';
import '../../state/app_state.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/autocomplete_field.dart';
import '../../widgets/date_picker_field.dart';
import '../../widgets/expandable_text.dart';
import '../../widgets/field_label.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/pill_input.dart';
import '../../widgets/resume_ready_view.dart';
import '../../widgets/responsive_body.dart';

/// Quick-pick chips shown above the Language step's search field — the
/// handful most students in this app's audience actually need one tap for;
/// anything else is a few keystrokes away in the search box right below.
const _quickLanguages = ['Hindi', 'English', 'Bengali', 'Tamil', 'Marathi'];

/// Adjacent-skill recommendations — adding a skill surfaces a few related
/// ones alongside it, the same "pick one, get more" pattern as the Goals
/// screen's interested-roles picker, instead of the suggestion list staying
/// static after the first tap.
const _relatedSkills = {
  'Python': ['Java', 'SQL', 'Data Structures', 'Git'],
  'Java': ['Python', 'Data Structures', 'SQL', 'Git'],
  'JavaScript': ['React', 'Git', 'SQL', 'Python'],
  'SQL': ['Python', 'Data Analysis', 'Excel', 'Data Structures'],
  'React': ['JavaScript', 'Git', 'UI Design', 'Prototyping'],
  'Git': ['Python', 'Java', 'JavaScript', 'Data Structures'],
  'C++': ['Data Structures', 'Java', 'Python', 'Git'],
  'Data Structures': ['Python', 'Java', 'C++', 'Git'],
  'Excel': ['Financial Analysis', 'PowerPoint', 'Data Analysis', 'Accounting'],
  'Financial Analysis': ['Excel', 'Accounting', 'Market Research', 'PowerPoint'],
  'PowerPoint': ['Excel', 'Communication', 'Public Speaking', 'Market Research'],
  'Market Research': ['Financial Analysis', 'Excel', 'Data Analysis', 'Communication'],
  'Accounting': ['Excel', 'Financial Analysis', 'Data Analysis', 'MS Office'],
  'Communication': ['Public Speaking', 'Teamwork', 'MS Office', 'Content Writing'],
  'Content Writing': ['Communication', 'Research', 'Social Media', 'Public Speaking'],
  'Research': ['Data Analysis', 'Report Writing', 'Communication', 'MS Office'],
  'MS Office': ['Excel', 'PowerPoint', 'Communication', 'Report Writing'],
  'Public Speaking': ['Communication', 'Content Writing', 'Teamwork', 'PowerPoint'],
  'Figma': ['Adobe XD', 'UI Design', 'Prototyping', 'Illustrator'],
  'Adobe XD': ['Figma', 'UI Design', 'Prototyping', 'Photoshop'],
  'Photoshop': ['Illustrator', 'Adobe XD', 'UI Design', 'Figma'],
  'Illustrator': ['Photoshop', 'Adobe XD', 'UI Design', 'Figma'],
  'UI Design': ['Figma', 'Adobe XD', 'Prototyping', 'Illustrator'],
  'Prototyping': ['Figma', 'UI Design', 'Adobe XD', 'Photoshop'],
  'Data Analysis': ['Excel', 'SQL', 'Research', 'Report Writing'],
  'Lab Techniques': ['Research', 'Data Analysis', 'Report Writing', 'MS Office'],
  'Report Writing': ['Research', 'MS Office', 'Data Analysis', 'Communication'],
  'Legal Research': ['Drafting', 'Case Analysis', 'Communication', 'MS Office'],
  'Drafting': ['Legal Research', 'Case Analysis', 'Communication', 'MS Office'],
  'Case Analysis': ['Legal Research', 'Drafting', 'Research', 'Communication'],
  'Clinical Skills': ['Patient Care', 'Research', 'Communication', 'Data Analysis'],
  'Patient Care': ['Clinical Skills', 'Communication', 'Research', 'Teamwork'],
  'Video Editing': ['Content Writing', 'Social Media', 'Journalism', 'Photoshop'],
  'Social Media': ['Content Writing', 'Video Editing', 'Journalism', 'Communication'],
  'Journalism': ['Content Writing', 'Social Media', 'Research', 'Communication'],
  'Customer Service': ['Communication', 'Operations', 'Event Management', 'Teamwork'],
  'Event Management': ['Customer Service', 'Operations', 'Communication', 'Teamwork'],
  'Operations': ['Event Management', 'Customer Service', 'Teamwork', 'Time Management'],
  'Problem Solving': ['Teamwork', 'Time Management', 'Communication', 'Research'],
  'Teamwork': ['Communication', 'Problem Solving', 'Time Management', 'Public Speaking'],
  'Time Management': ['Teamwork', 'Problem Solving', 'Operations', 'Communication'],
};

/// Reverses the `'$start'` / `'$start - $end'` / `'$start - Present'`
/// strings `_addEducation`/`_addWorkExperience` build, so tapping an
/// existing entry back into the form can re-populate the year picker
/// fields it came from. Falls back to all-nulls for anything that doesn't
/// match (e.g. an entry from the PDF-upload path, which never went through
/// this format) — the user just re-picks the years in that case.
({int? start, int? end, bool isCurrent}) _parseDurationRange(String duration) {
  final parts = duration.split('-').map((s) => s.trim()).toList();
  if (parts.isEmpty || parts.first.isEmpty) return (start: null, end: null, isCurrent: false);
  final start = int.tryParse(parts.first);
  if (parts.length == 1) return (start: start, end: null, isCurrent: false);
  if (parts[1].toLowerCase() == 'present') return (start: start, end: null, isCurrent: true);
  return (start: start, end: int.tryParse(parts[1]), isCurrent: false);
}

/// What a typed number in the education step's grade field means — CGPA is
/// out of 10, Percentage/Percentile are out of 100. Without this, a bare
/// number like "79" is ambiguous (79% vs 79th percentile vs a typo for a
/// CGPA), and nothing stops an out-of-range value like "799" from being
/// typed in the first place. See _gpaUnitMax/_composeGpa/_parseGpa below.
enum GpaUnit { cgpa, percentage, percentile }

double _gpaUnitMax(GpaUnit unit) => unit == GpaUnit.cgpa ? 10 : 100;

String _gpaPlaceholder(GpaUnit unit) => switch (unit) {
      GpaUnit.cgpa => 'e.g. 8.5',
      GpaUnit.percentage => 'e.g. 85',
      GpaUnit.percentile => 'e.g. 79',
    };

String _gpaUnitLabel(GpaUnit unit) => switch (unit) {
      GpaUnit.cgpa => 'CGPA',
      GpaUnit.percentage => 'Percentage',
      GpaUnit.percentile => 'Percentile',
    };

/// Appends the right suffix so the stored value is never just a bare,
/// ambiguous number — mirrors _parseDurationRange's "build a display string
/// once, parse it back on edit" approach.
String? _composeGpa(String rawValue, GpaUnit unit) {
  final v = rawValue.trim();
  if (v.isEmpty) return null;
  return switch (unit) {
    GpaUnit.cgpa => '$v CGPA',
    GpaUnit.percentage => '$v%',
    GpaUnit.percentile => '$v percentile',
  };
}

/// Reverses [_composeGpa] for editing an existing entry. Falls back to
/// treating the whole string as CGPA with no recognized suffix — covers a
/// PDF-parsed resume's freehand `gpa` value, which never went through this
/// flow in the first place.
({String value, GpaUnit unit}) _parseGpa(String raw) {
  final t = raw.trim();
  if (t.toUpperCase().endsWith('CGPA')) return (value: t.substring(0, t.length - 4).trim(), unit: GpaUnit.cgpa);
  if (t.endsWith('%')) return (value: t.substring(0, t.length - 1).trim(), unit: GpaUnit.percentage);
  if (t.toLowerCase().endsWith('percentile')) return (value: t.substring(0, t.length - 10).trim(), unit: GpaUnit.percentile);
  return (value: t, unit: GpaUnit.cgpa);
}

/// Validates a submitted grade value against the selected unit's range —
/// called once when "Add education"/"Save changes" is tapped, not on every
/// keystroke. An earlier version blocked out-of-range keystrokes live as
/// they were typed, which silently ate legitimate input (typing a second
/// digit onto a CGPA value, or a decimal point in some cases) with no
/// feedback — this validates on submit instead and surfaces a real error
/// message via PillInput's own `error` prop, so the field behaves like
/// plain text entry the rest of the time.
String? _gpaValidationError(String rawValue, GpaUnit unit) {
  final v = rawValue.trim();
  if (v.isEmpty) return null;
  final parsed = double.tryParse(v);
  final max = _gpaUnitMax(unit);
  if (parsed == null || parsed < 0 || parsed > max) {
    return 'Enter a value between 0 and ${max.toStringAsFixed(0)}';
  }
  return null;
}

const _monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _formatMonthYear(DateTime d) => '${_monthShort[d.month - 1]} ${d.year}';

/// Reverses _formatMonthYear-built duration strings for work experience —
/// same split-on-'-' shape as _parseDurationRange, but each side is a
/// "Mon YYYY" token instead of a bare year, since experience (unlike
/// education) can be as short as a few months. Falls back to all-nulls for
/// anything that doesn't match (e.g. a PDF-parsed entry, or an entry saved
/// before this format existed) — the user just re-picks the dates.
({DateTime? start, DateTime? end, bool isCurrent}) _parseMonthYearDurationRange(String duration) {
  DateTime? parseToken(String token) {
    final parts = token.trim().split(RegExp(r'\s+'));
    if (parts.length != 2) return null;
    final monthIndex = _monthShort.indexOf(parts[0]);
    final year = int.tryParse(parts[1]);
    if (monthIndex == -1 || year == null) return null;
    return DateTime(year, monthIndex + 1);
  }

  final parts = duration.split('-').map((s) => s.trim()).toList();
  if (parts.isEmpty || parts.first.isEmpty) return (start: null, end: null, isCurrent: false);
  final start = parseToken(parts.first);
  if (parts.length == 1) return (start: start, end: null, isCurrent: false);
  if (parts[1].toLowerCase() == 'present') return (start: start, end: null, isCurrent: true);
  return (start: start, end: parseToken(parts[1]), isCurrent: false);
}

const _buildingSteps = [
  'Structuring your experience…',
  'Formatting sections…',
  'Polishing the language…',
  'Almost done…',
];

/// One-question-at-a-time resume builder (mirrors the aptitude quiz's
/// tap-to-advance pattern) instead of one long form. Anything already
/// captured during onboarding (name, college, course, year) is shown once
/// as a read-only confirmation instead of being asked again, and the flow
/// ends by "generating" a resume doc so applying never blocks on an
/// incomplete profile mid-session.
class ResumeBuilderQuizScreen extends StatefulWidget {
  /// Set when this screen was reached from an apply-gate on a specific
  /// opportunity — finishing the build here submits that application
  /// automatically instead of dropping the user on a generic screen.
  final String? applyForOpportunityId;

  /// Which page to open on — set when reached from Profile's "Add details"
  /// menu for one specific section (work experience, skills, etc.) so
  /// jumping there doesn't mean re-clicking through the whole quiz first.
  final int initialStep;

  const ResumeBuilderQuizScreen({super.key, this.applyForOpportunityId, this.initialStep = 0});

  @override
  State<ResumeBuilderQuizScreen> createState() => _ResumeBuilderQuizScreenState();
}

enum _Phase { quiz, building, ready }

class _ResumeBuilderQuizScreenState extends State<ResumeBuilderQuizScreen> {
  static const _totalSteps = 7;

  late final PageController _pageController;
  int _index = 0;
  _Phase _phase = _Phase.quiz;
  int _buildingStep = 0;
  Timer? _buildingTimer;

  // Intro extras — headline + phone, appended to the existing read-only
  // confirmation instead of their own steps, to keep the total step count down.
  final _headlineController = TextEditingController();
  final _phoneController = TextEditingController();

  // Education — multi-entry, pre-seeded (in the *form*, not the list) from
  // onboarding's college/course so the first entry isn't typed from scratch.
  List<ResumeEducation> _educationEntries = [];
  final _eduInstitutionController = TextEditingController();
  final _eduDegreeController = TextEditingController();
  final _eduGpaController = TextEditingController();
  GpaUnit _eduGpaUnit = GpaUnit.cgpa;
  // Set only when "Add education"/"Save changes" is tapped with an
  // out-of-range grade value — see _gpaValidationError. Cleared as soon as
  // the field is edited again or the unit is switched.
  String? _eduGpaError;
  int? _eduStartYear;
  int? _eduEndYear;
  bool _eduCurrentlyStudying = false;
  // Which single question the add-a-new-entry flow is currently showing:
  // 0=Institution, 1=Degree, 2=Duration, 3=Grade. Reset to 0 every time an
  // entry is committed (or editing starts/ends), so a second entry always
  // starts fresh at the first question.
  int _eduQuestionIndex = 0;
  // Bumped every time _eduQuestionIndex resets to 0 (add/edit/cancel) —
  // captured by a scheduled auto-advance timer and re-checked when it
  // fires, so a timer scheduled for one entry can never fire against a
  // different entry that happens to land back on the same question index.
  int _eduDurationGeneration = 0;
  // Non-null while an existing entry is loaded into the form above for
  // editing — set on tapping a card, cleared on save/cancel. The tapped
  // entry is pulled out of _educationEntries while this is set (so it
  // doesn't show twice) and re-inserted at the same index on save/cancel.
  int? _editingEducationIndex;
  // The entry pulled out of the list while editing — restored on cancel.
  ResumeEducation? _editingEducationOriginal;

  // Experience — gated behind a yes/no question; "no" skips the detailed
  // form entirely instead of showing an empty multi-field form for freshers.
  bool? _hasWorkExperience;
  List<WorkExperience> _workExperience = [];
  final _expCompanyController = TextEditingController();
  final _expRoleController = TextEditingController();
  final _expDescController = TextEditingController();
  // Month + year, not just year — internships/short roles need finer
  // granularity than education's plain year-range does. Only the
  // year/month fields of these DateTimes are ever read.
  DateTime? _expStartDate;
  DateTime? _expEndDate;
  bool _expCurrentlyWorking = false;
  // Same purpose as _eduQuestionIndex: 0=Company, 1=Role, 2=Duration,
  // 3=Description.
  int _expQuestionIndex = 0;
  // See _eduDurationGeneration — same purpose.
  int _expDurationGeneration = 0;
  // Same editing pattern as education, see _editingEducationIndex.
  int? _editingExperienceIndex;
  WorkExperience? _editingExperienceOriginal;

  // Certifications — same yes/no gate + multi-entry shape as Experience.
  bool? _hasCertifications;
  List<ResumeCertification> _certifications = [];
  final _certNameController = TextEditingController();
  // No input for this anymore (certificate-link question removed — image
  // only) — carries a pre-existing entry's link through an edit/re-save
  // unchanged instead of silently dropping it. Always null for a
  // brand-new entry.
  String? _certExistingLink;
  DateTime? _certStartDate;
  DateTime? _certEndDate;
  bool _certOngoing = false;
  // Same purpose as _eduQuestionIndex: 0=Name, 1=Duration, 2=Image.
  int _certQuestionIndex = 0;
  // See _eduDurationGeneration — same purpose.
  int _certDurationGeneration = 0;
  int? _editingCertificationIndex;
  ResumeCertification? _editingCertificationOriginal;
  // Optional proof-of-certificate image — picked straight from the gallery
  // (no camera option, unlike the profile-photo picker: a certificate is
  // realistically always a screenshot/download, not a live photo).
  XFile? _certImageFile;
  String? _certImagePath;

  final _skillInputController = TextEditingController();
  List<String> _skills = [];
  // Never actually populated by any wired step (no UI ever asked for this)
  // — kept only so an existing resume's value round-trips through this
  // quiz's save/load instead of silently getting wiped.
  List<String> _specializations = [];
  // Set only when Continue is tapped on an empty Skills step — cleared as
  // soon as a skill is added. Same "block on submit, not while typing"
  // shape as _eduGpaError.
  String? _skillsError;

  List<LanguageEntry> _languages = [];
  String? _languagesError;

  final _summaryController = TextEditingController();
  String? _summaryError;
  // Which of the 2 phrasings per tier _summaryForVariant is currently on;
  // advances only on a genuine "Regenerate" tap (see _useSuggestedSummary).
  int _summaryVariant = 0;
  // The exact text the button last wrote into the field — as long as the
  // field still holds this verbatim, the button reads "Regenerate" and a
  // tap advances the variant; any hand-edit (even one character) makes
  // this stop matching, so the button reverts to "Tap to autofill" and a
  // tap starts the cycle over rather than clobbering what was typed.
  String? _lastGeneratedSummary;

  User? get _user => context.read<AppState>().user;
  bool get _postOnboarding => _user?.onboardingComplete == true;
  CourseField get _field => courseFieldFor(_user?.course);

  @override
  void initState() {
    super.initState();
    final start = widget.initialStep.clamp(0, _totalSteps - 1);
    _index = start;
    _pageController = PageController(initialPage: start);
    _hydrateFromExisting();
  }

  /// If a resume already exists (built here before, or PDF-uploaded), this
  /// screen doubles as its editor — reachable any time from the Profile
  /// tab, not just once during onboarding. Without this, revisiting always
  /// started from a blank quiz and silently overwrote whatever was there.
  void _hydrateFromExisting() {
    _languages = List.of(_user?.languages ?? const []);
    final resume = _user?.resume;
    if (resume == null) {
      _eduInstitutionController.text = _user?.college ?? '';
      _eduDegreeController.text = _user?.course ?? '';
      _eduQuestionIndex = _skipPrefilledEduQuestions();
      return;
    }
    _headlineController.text = resume.headline ?? '';
    _phoneController.text = resume.phone ?? '';
    _educationEntries = List.of(resume.education);
    if (_educationEntries.isEmpty) {
      _eduInstitutionController.text = _user?.college ?? '';
      _eduDegreeController.text = _user?.course ?? '';
      _eduQuestionIndex = _skipPrefilledEduQuestions();
    }
    _workExperience = List.of(resume.workExperience);
    _hasWorkExperience = _workExperience.isNotEmpty ? true : (resume.experienceLevel == 'Fresher' ? false : null);
    _certifications = List.of(resume.certifications);
    _hasCertifications = _certifications.isNotEmpty ? true : null;
    _skills = List.of(resume.skills);
    _specializations = List.of(resume.specializations);
    _summaryController.text = resume.summary ?? '';
  }

  // Institution/Degree are the only questions anywhere in this flow that
  // can already be known before the user answers anything — seeded above
  // from the profile's college/course, and only ever for a brand-new first
  // entry (every later entry starts with both controllers cleared). A
  // value that arrived this way shouldn't need "advancing through" as if
  // it were a question the user just answered — it's shown immediately,
  // grouped with any other already-known fields, and the one-at-a-time
  // flow starts from the first genuinely unanswered question instead.
  int _skipPrefilledEduQuestions() {
    if (_eduInstitutionController.text.trim().isEmpty) return 0;
    if (_eduDegreeController.text.trim().isEmpty) return 1;
    return 2;
  }

  @override
  void dispose() {
    _buildingTimer?.cancel();
    _pageController.dispose();
    _headlineController.dispose();
    _phoneController.dispose();
    _eduInstitutionController.dispose();
    _eduDegreeController.dispose();
    _eduGpaController.dispose();
    _expCompanyController.dispose();
    _expRoleController.dispose();
    _expDescController.dispose();
    _certNameController.dispose();
    _skillInputController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  // True from the moment a step change starts until a moment after it lands.
  // Every step's footer button sits in the same spot, so a double-tap or a late
  // tap on a laggy phone used to land on the *next* step's button and skip it
  // (the experience and certification gates, "Skip for now", ...).
  bool _navigating = false;

  Future<void> _goTo(int page) async {
    if (_navigating || page == _index || page < 0 || page >= _totalSteps) return;
    _navigating = true;
    try {
      await _goToUnguarded(page);
      // Let queued taps from the old screen drain before the new one listens.
      await Future<void>.delayed(const Duration(milliseconds: 250));
    } finally {
      _navigating = false;
    }
  }

  Future<void> _goToUnguarded(int page) async {
    // Leaving a step (Continue, Skip, or back) while an entry on that step
    // is mid-edit used to silently drop it — it stays pulled out of its
    // list forever since nothing re-inserts it. Auto-cancelling here (same
    // as tapping each step's own "Cancel" button) is the one place every
    // step transition passes through, so it catches every way of leaving,
    // not just the footer button.
    if (_editingEducationIndex != null) _cancelEditEducation();
    if (_editingExperienceIndex != null) _cancelEditWorkExperience();
    if (_editingCertificationIndex != null) _cancelEditCertification();
    await _pageController.animateToPage(page, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    if (!mounted) return;
    setState(() => _index = page);
    // Autosave on every step advance — abandoning the quiz partway (back
    // button, closing the tab) used to discard everything since nothing
    // persisted until the very last step. This reuses the same
    // `resume` field + `_hydrateFromExisting()` that already restores a
    // previously-*finished* resume, so a partial one restores the same way.
    unawaited(_saveDraft());
  }

  // A resume built from scratch stays a draft until the final step saves it;
  // editing one that was already finished must not demote it back to a draft.
  bool _isStillDraft(User current) => current.resume == null || current.resume!.isDraft;

  ParsedResume _resumeFromState({bool draft = false}) => ParsedResume(
        name: _user?.name ?? '',
        headline: _headlineController.text.trim().isEmpty ? null : _headlineController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        education: _educationEntries,
        skills: _skills,
        projects: const [],
        links: const [],
        experienceLevel: _hasWorkExperience == false ? 'Fresher' : null,
        specializations: _specializations,
        summary: _summaryController.text.trim().isEmpty ? null : _summaryController.text.trim(),
        workExperience: _workExperience,
        certifications: _certifications,
        isDraft: draft,
      );

  /// Whether there's genuinely something from *this* quiz worth saving —
  /// deliberately not the pre-seeded Education form text, since that comes
  /// from the profile the user already filled in, not from an answer given
  /// here. Autosaving before this is true would flip `hasResume` on from
  /// pre-existing profile data alone and make the router think the resume
  /// step is done while `onboardingComplete` is still false.
  bool get _hasDraftContent =>
      _skills.isNotEmpty ||
      _workExperience.isNotEmpty ||
      _certifications.isNotEmpty ||
      _educationEntries.isNotEmpty ||
      _languages.isNotEmpty ||
      _summaryController.text.trim().isNotEmpty ||
      _headlineController.text.trim().isNotEmpty ||
      _phoneController.text.trim().isNotEmpty;

  Future<void> _saveDraft() async {
    if (!mounted || !_hasDraftContent) return;
    try {
      await context.read<AppState>().updateProfile((current) => current.copyWith(resume: _resumeFromState(draft: _isStillDraft(current)), languages: _languages));
    } catch (e) {
      // Background autosave — the guard above keeps an oversized image
      // path from ever reaching here, so a failure at this point is
      // unexpected; fail quietly rather than interrupting the quiz with a
      // snackbar on every step. The real dead-end this used to cause was
      // at _finishBuilding, which does surface a failure to the user.
      debugPrint('ResumeBuilderQuizScreen: autosave failed — $e');
    }
  }

  void _back() {
    if (_index > 0) {
      _goTo(_index - 1);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(_postOnboarding ? '/tabs' : '/college/resume');
    }
  }

  void _addSkill() {
    final s = _skillInputController.text.trim();
    _addSkillValue(s);
    _skillInputController.clear();
  }

  void _addSkillValue(String s) {
    if (s.isEmpty) return;
    final alreadyAdded = _skills.any((existing) => existing.toLowerCase() == s.toLowerCase());
    if (alreadyAdded) {
      // Used to just clear the input with nothing added and no
      // explanation — looked like a UI glitch rather than "you already
      // added this."
      HapticFeedback.selectionClick();
      setState(() => _skillsError = 'Already added');
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _skills = [..._skills, s];
      _skillsError = null;
    });
  }

  void _continueFromSkills() {
    if (_skills.isEmpty) {
      HapticFeedback.selectionClick();
      setState(() => _skillsError = 'Add at least one skill to continue.');
      return;
    }
    _goTo(5);
  }

  bool get _eduDurationWasComplete => _eduStartYear != null && (_eduEndYear != null || _eduCurrentlyStudying);

  Future<void> _pickEduStartYear() async {
    final year = await showYearPickerSheet(context, minYear: 1990, maxYear: DateTime.now().year, initialYear: _eduStartYear, title: 'Start year');
    if (year == null) return;
    final wasComplete = _eduDurationWasComplete;
    setState(() {
      _eduStartYear = year;
      // End year is only ever valid within start..start+6 now — clear it if
      // picking a new start pushes the existing end outside that window in
      // either direction (previously only checked the "too early" side).
      if (_eduEndYear != null && (_eduEndYear! < year || _eduEndYear! > year + 6)) _eduEndYear = null;
    });
    _maybeAutoAdvanceEduDuration(wasComplete: wasComplete);
  }

  Future<void> _pickEduEndYear() async {
    final start = _eduStartYear;
    final year = await showYearPickerSheet(
      context,
      minYear: start ?? 1990,
      // Most degrees run 4-6 years — capping the wheel at start+6 instead of
      // "current year + 10" (which let a 2026 start scroll to an unrealistic
      // 2036) keeps every reachable value plausible.
      maxYear: (start ?? DateTime.now().year) + 6,
      // Defaults the wheel to start+4 (a typical degree length) instead of
      // landing on an arbitrary first entry — only when there's no existing
      // end year to preserve (e.g. editing a saved entry).
      initialYear: _eduEndYear ?? (start != null ? start + 4 : null),
      title: 'End year',
    );
    if (year == null) return;
    final wasComplete = _eduDurationWasComplete;
    setState(() => _eduEndYear = year);
    _maybeAutoAdvanceEduDuration(wasComplete: wasComplete);
  }

  void _setEduCurrentlyStudying(bool value) {
    HapticFeedback.selectionClick();
    final wasComplete = _eduDurationWasComplete;
    setState(() {
      _eduCurrentlyStudying = value;
      if (value) _eduEndYear = null;
    });
    _maybeAutoAdvanceEduDuration(wasComplete: wasComplete);
  }

  // Duration has no keyboard to submit — it's two date-picker sheets plus a
  // checkbox — so unlike every other question in this flow, nothing here
  // naturally signals "done." Auto-advances once the answer is actually
  // complete (a start plus either an end or "currently studying"), from
  // whichever of the three inputs above happens to complete it, so picking
  // them in any order still moves on. A short delay (matching the same
  // pattern already used for the yes/no gates in this file) lets the user
  // see their last tap register before the question changes under them;
  // re-checking the question index inside the callback guards against a
  // stale timer firing after the user has already moved past this question
  // some other way.
  //
  // [wasComplete] — true when the Duration answer was *already* complete
  // before this particular change (i.e. the user tapped the fact-row to
  // fix one field of an already-answered Duration, not answering it for
  // the first time). In that case we deliberately don't arm the timer:
  // re-editing one field of a complete answer would otherwise immediately
  // re-satisfy the completeness check and yank the user forward mid-
  // correction, before they get to the second field they meant to fix.
  void _maybeAutoAdvanceEduDuration({required bool wasComplete}) {
    if (_eduQuestionIndex != 2 || wasComplete) return;
    if (_eduStartYear == null || (_eduEndYear == null && !_eduCurrentlyStudying)) return;
    final generation = _eduDurationGeneration;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _eduQuestionIndex == 2 && generation == _eduDurationGeneration) setState(() => _eduQuestionIndex = 3);
    });
  }

  void _setEduGpaUnit(GpaUnit unit) {
    if (unit == _eduGpaUnit) return;
    HapticFeedback.selectionClick();
    setState(() {
      _eduGpaUnit = unit;
      // A value valid for the old unit (e.g. "85" as a Percentage) can be
      // out of range for the new one (85 > 10 for CGPA) — clearing avoids
      // silently carrying over a now-invalid number.
      _eduGpaController.clear();
      _eduGpaError = null;
    });
  }

  void _onEduGpaChanged(String _) {
    if (_eduGpaError != null) setState(() => _eduGpaError = null);
  }

  void _addEducation() {
    final institution = _eduInstitutionController.text.trim();
    final degree = _eduDegreeController.text.trim();
    final start = _eduStartYear;
    if (institution.isEmpty || degree.isEmpty || start == null) return;
    final gpaError = _gpaValidationError(_eduGpaController.text, _eduGpaUnit);
    if (gpaError != null) {
      setState(() => _eduGpaError = gpaError);
      return;
    }
    final duration = _eduCurrentlyStudying ? '$start - Present' : (_eduEndYear != null ? '$start - $_eduEndYear' : '$start');
    final entry = ResumeEducation(
      degree: degree,
      institution: institution,
      duration: duration,
      gpa: _composeGpa(_eduGpaController.text, _eduGpaUnit),
    );
    HapticFeedback.selectionClick();
    setState(() {
      final editingAt = _editingEducationIndex;
      if (editingAt != null) {
        _educationEntries = [..._educationEntries]..insert(editingAt.clamp(0, _educationEntries.length), entry);
        _editingEducationIndex = null;
        _editingEducationOriginal = null;
      } else {
        _educationEntries = [..._educationEntries, entry];
      }
      _eduInstitutionController.clear();
      _eduDegreeController.clear();
      _eduGpaController.clear();
      _eduGpaUnit = GpaUnit.cgpa;
      _eduGpaError = null;
      _eduStartYear = null;
      _eduEndYear = null;
      _eduCurrentlyStudying = false;
      _eduQuestionIndex = 0;
      _eduDurationGeneration++;
    });
  }

  void _removeEducation(ResumeEducation e) {
    HapticFeedback.selectionClick();
    setState(() => _educationEntries = _educationEntries.where((x) => x != e).toList());
  }

  /// Pulls an existing entry out of the list and back into the form above
  /// for editing — the list index is remembered so `_addEducation` can
  /// re-insert it in the same spot instead of appending it at the end.
  void _editEducation(int index) {
    // Capture the actual tapped entry before anything else touches the
    // list — cancelling an in-progress edit below re-inserts a different
    // entry ahead of this one, which would shift `index` out from under a
    // plain int lookup.
    final entry = _educationEntries[index];
    // Tapping a different card while another edit is already in progress
    // used to silently discard it — the in-progress entry was pulled out
    // of the list and never re-inserted once a second _editEducation
    // overwrote _editingEducationIndex/Original. Auto-cancelling (which
    // re-inserts the original, same as tapping "Cancel" would) first means
    // nothing is ever silently lost, just implicitly cancelled.
    if (_editingEducationIndex != null) _cancelEditEducation();
    index = _educationEntries.indexOf(entry);
    final parsed = _parseDurationRange(entry.duration);
    HapticFeedback.selectionClick();
    setState(() {
      _educationEntries = [..._educationEntries]..removeAt(index);
      _editingEducationIndex = index;
      _editingEducationOriginal = entry;
      _eduInstitutionController.text = entry.institution;
      _eduDegreeController.text = entry.degree;
      _eduGpaError = null;
      final gpa = entry.gpa;
      if (gpa == null || gpa.isEmpty) {
        _eduGpaController.clear();
        _eduGpaUnit = GpaUnit.cgpa;
      } else {
        final parsedGpa = _parseGpa(gpa);
        _eduGpaController.text = parsedGpa.value;
        _eduGpaUnit = parsedGpa.unit;
      }
      _eduStartYear = parsed.start;
      _eduEndYear = parsed.end;
      _eduCurrentlyStudying = parsed.isCurrent;
      _eduQuestionIndex = 0;
      _eduDurationGeneration++;
    });
  }

  void _cancelEditEducation() {
    final original = _editingEducationOriginal;
    final index = _editingEducationIndex;
    if (original == null || index == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _educationEntries = [..._educationEntries]..insert(index.clamp(0, _educationEntries.length), original);
      _editingEducationIndex = null;
      _editingEducationOriginal = null;
      _eduInstitutionController.clear();
      _eduDegreeController.clear();
      _eduGpaController.clear();
      _eduGpaUnit = GpaUnit.cgpa;
      _eduGpaError = null;
      _eduStartYear = null;
      _eduEndYear = null;
      _eduCurrentlyStudying = false;
      _eduQuestionIndex = 0;
      _eduDurationGeneration++;
    });
  }

  void _selectHasWorkExperience(bool value) {
    HapticFeedback.lightImpact();
    setState(() => _hasWorkExperience = value);
    // Same auto-advance as Certifications' "Not yet" (_selectHasCertifications
    // below) — "Not yet" has nothing further to fill in, so skip the extra
    // tap. Re-checks _hasWorkExperience so a fast follow-up tap on "Yes, I
    // do" cancels this.
    if (value == false) {
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted && _hasWorkExperience == false && _index == 2) _goTo(3);
      });
    }
  }

  bool get _expDurationWasComplete => _expStartDate != null && (_expEndDate != null || _expCurrentlyWorking);

  Future<void> _pickExpStartDate() async {
    // A start date can't be in the future either — the same real-world
    // constraint as the end date, just less obviously so.
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final picked = await showMonthYearPickerSheet(
      context,
      initialDate: _expStartDate,
      title: 'Start date',
      minYear: 1990,
      maxYear: now.year,
      maxDate: currentMonth,
    );
    if (picked == null) return;
    final start = DateTime(picked.year, picked.month);
    final wasComplete = _expDurationWasComplete;
    setState(() {
      _expStartDate = start;
      if (_expEndDate != null && _expEndDate!.isBefore(start)) _expEndDate = null;
    });
    _maybeAutoAdvanceExpDuration(wasComplete: wasComplete);
  }

  Future<void> _pickExpEndDate() async {
    final now = DateTime.now();
    final start = _expStartDate;
    final picked = await showMonthYearPickerSheet(
      context,
      initialDate: _expEndDate,
      title: 'End date',
      minYear: start?.year ?? 1990,
      maxYear: now.year,
      // minYear alone only floors the *year* wheel — within that year every
      // month was still pickable, so a start of Sep 2026 let the end land
      // on, say, Feb 2026 (before it). minDate floors the actual month too.
      minDate: start,
      maxDate: DateTime(now.year, now.month),
    );
    if (picked == null) return;
    final wasComplete = _expDurationWasComplete;
    setState(() => _expEndDate = DateTime(picked.year, picked.month));
    _maybeAutoAdvanceExpDuration(wasComplete: wasComplete);
  }

  void _setExpCurrentlyWorking(bool value) {
    HapticFeedback.selectionClick();
    final wasComplete = _expDurationWasComplete;
    setState(() {
      _expCurrentlyWorking = value;
      if (value) _expEndDate = null;
    });
    _maybeAutoAdvanceExpDuration(wasComplete: wasComplete);
  }

  // See _maybeAutoAdvanceEduDuration — same reasoning (including the
  // wasComplete/generation guards), target index 3 (Description) matches
  // this section's own _question switch.
  void _maybeAutoAdvanceExpDuration({required bool wasComplete}) {
    if (_expQuestionIndex != 2 || wasComplete) return;
    if (_expStartDate == null || (_expEndDate == null && !_expCurrentlyWorking)) return;
    final generation = _expDurationGeneration;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _expQuestionIndex == 2 && generation == _expDurationGeneration) setState(() => _expQuestionIndex = 3);
    });
  }

  void _addWorkExperience() {
    final company = _expCompanyController.text.trim();
    final role = _expRoleController.text.trim();
    final start = _expStartDate;
    if (company.isEmpty || role.isEmpty || start == null) return;
    final startLabel = _formatMonthYear(start);
    final duration = _expCurrentlyWorking ? '$startLabel - Present' : (_expEndDate != null ? '$startLabel - ${_formatMonthYear(_expEndDate!)}' : startLabel);
    final entry = WorkExperience(company: company, role: role, duration: duration, description: _expDescController.text.trim());
    HapticFeedback.selectionClick();
    setState(() {
      final editingAt = _editingExperienceIndex;
      if (editingAt != null) {
        _workExperience = [..._workExperience]..insert(editingAt.clamp(0, _workExperience.length), entry);
        _editingExperienceIndex = null;
        _editingExperienceOriginal = null;
      } else {
        _workExperience = [..._workExperience, entry];
      }
      _expCompanyController.clear();
      _expRoleController.clear();
      _expDescController.clear();
      _expStartDate = null;
      _expEndDate = null;
      _expCurrentlyWorking = false;
      _expQuestionIndex = 0;
      _expDurationGeneration++;
    });
  }

  void _removeWorkExperience(WorkExperience w) {
    HapticFeedback.selectionClick();
    setState(() => _workExperience = _workExperience.where((x) => x != w).toList());
  }

  void _editWorkExperience(int index) {
    // See _editEducation's own comment — same "capture entry, cancel any
    // in-progress edit first, re-resolve index" fix.
    final entry = _workExperience[index];
    if (_editingExperienceIndex != null) _cancelEditWorkExperience();
    index = _workExperience.indexOf(entry);
    final parsed = _parseMonthYearDurationRange(entry.duration);
    HapticFeedback.selectionClick();
    setState(() {
      _workExperience = [..._workExperience]..removeAt(index);
      _editingExperienceIndex = index;
      _editingExperienceOriginal = entry;
      _expCompanyController.text = entry.company;
      _expRoleController.text = entry.role;
      _expDescController.text = entry.description;
      _expStartDate = parsed.start;
      _expEndDate = parsed.end;
      _expCurrentlyWorking = parsed.isCurrent;
      _expQuestionIndex = 0;
      _expDurationGeneration++;
    });
  }

  void _cancelEditWorkExperience() {
    final original = _editingExperienceOriginal;
    final index = _editingExperienceIndex;
    if (original == null || index == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _workExperience = [..._workExperience]..insert(index.clamp(0, _workExperience.length), original);
      _editingExperienceIndex = null;
      _editingExperienceOriginal = null;
      _expCompanyController.clear();
      _expRoleController.clear();
      _expDescController.clear();
      _expStartDate = null;
      _expEndDate = null;
      _expCurrentlyWorking = false;
      _expQuestionIndex = 0;
      _expDurationGeneration++;
    });
  }

  void _selectHasCertifications(bool value) {
    HapticFeedback.lightImpact();
    setState(() => _hasCertifications = value);
    if (value == false) {
      // "Not yet" has nothing further to fill in — unlike "Yes, I do",
      // which needs the form to appear — so skip the extra tap and move on
      // automatically. A short delay, not instant: AppChip has no built-in
      // selection transition of its own (a plain Container rebuild), so
      // this isn't waiting on an animation — it's giving the user a beat to
      // see their tap actually register before the page slides away.
      // Re-checks _hasCertifications so a fast follow-up tap on "Yes, I do"
      // cancels this.
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted && _hasCertifications == false && _index == 3) _goTo(4);
      });
    }
  }

  bool get _certDurationWasComplete => _certStartDate != null && (_certEndDate != null || _certOngoing);

  Future<void> _pickCertStartDate() async {
    final now = DateTime.now();
    final picked = await showMonthYearPickerSheet(
      context,
      initialDate: _certStartDate,
      title: 'Start date',
      minYear: 1990,
      maxYear: now.year,
      maxDate: DateTime(now.year, now.month),
    );
    if (picked == null) return;
    final start = DateTime(picked.year, picked.month);
    final wasComplete = _certDurationWasComplete;
    setState(() {
      _certStartDate = start;
      if (_certEndDate != null && _certEndDate!.isBefore(start)) _certEndDate = null;
    });
    _maybeAutoAdvanceCertDuration(wasComplete: wasComplete);
  }

  Future<void> _pickCertEndDate() async {
    final now = DateTime.now();
    final start = _certStartDate;
    final picked = await showMonthYearPickerSheet(
      context,
      initialDate: _certEndDate,
      title: 'End date',
      minYear: start?.year ?? 1990,
      maxYear: now.year,
      // See _pickExpEndDate's comment — minYear alone doesn't stop an
      // earlier month within the same year as start; minDate does.
      minDate: start,
      maxDate: DateTime(now.year, now.month),
    );
    if (picked == null) return;
    final wasComplete = _certDurationWasComplete;
    setState(() => _certEndDate = DateTime(picked.year, picked.month));
    _maybeAutoAdvanceCertDuration(wasComplete: wasComplete);
  }

  void _setCertOngoing(bool value) {
    HapticFeedback.selectionClick();
    final wasComplete = _certDurationWasComplete;
    setState(() {
      _certOngoing = value;
      if (value) _certEndDate = null;
    });
    _maybeAutoAdvanceCertDuration(wasComplete: wasComplete);
  }

  // See _maybeAutoAdvanceEduDuration — same reasoning (including the
  // wasComplete/generation guards), target index 2 (certificate image)
  // matches this section's own _question switch.
  void _maybeAutoAdvanceCertDuration({required bool wasComplete}) {
    if (_certQuestionIndex != 1 || wasComplete) return;
    if (_certStartDate == null || (_certEndDate == null && !_certOngoing)) return;
    final generation = _certDurationGeneration;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _certQuestionIndex == 1 && generation == _certDurationGeneration) setState(() => _certQuestionIndex = 2);
    });
  }

  Future<void> _pickCertImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _certImageFile = file;
      _certImagePath = file.path;
    });
  }

  void _removeCertImage() {
    HapticFeedback.selectionClick();
    setState(() {
      _certImageFile = null;
      _certImagePath = null;
    });
  }

  void _addCertification() {
    final name = _certNameController.text.trim();
    final start = _certStartDate;
    if (name.isEmpty || start == null) return;
    final startLabel = _formatMonthYear(start);
    final duration = _certOngoing ? '$startLabel - Present' : (_certEndDate != null ? '$startLabel - ${_formatMonthYear(_certEndDate!)}' : startLabel);
    final entry = ResumeCertification(
      name: name,
      duration: duration,
      // No input for this anymore (link question removed) — a brand-new
      // entry never has one. Editing an *existing* entry that already had
      // a link (e.g. from an older draft) carries it through unchanged via
      // _certExistingLink rather than silently dropping it just because
      // this field was touched.
      link: _certExistingLink,
      // A picked file's path can come back as a full base64 data: URI on
      // web instead of a short blob: URL — persisting a large one blows
      // the browser's per-origin storage quota and silently breaks every
      // save from here on (see _saveDraft/_finishBuilding's own guards).
      // Same cap profile_edit_screen.dart already uses for its photo.
      imagePath: (_certImagePath != null && _certImagePath!.length > 20000) ? null : _certImagePath,
    );
    HapticFeedback.selectionClick();
    setState(() {
      final editingAt = _editingCertificationIndex;
      if (editingAt != null) {
        _certifications = [..._certifications]..insert(editingAt.clamp(0, _certifications.length), entry);
        _editingCertificationIndex = null;
        _editingCertificationOriginal = null;
      } else {
        _certifications = [..._certifications, entry];
      }
      _certNameController.clear();
      _certExistingLink = null;
      _certStartDate = null;
      _certEndDate = null;
      _certOngoing = false;
      _certImageFile = null;
      _certImagePath = null;
      _certQuestionIndex = 0;
      _certDurationGeneration++;
    });
  }

  void _removeCertification(ResumeCertification c) {
    HapticFeedback.selectionClick();
    setState(() => _certifications = _certifications.where((x) => x != c).toList());
  }

  void _editCertification(int index) {
    // See _editEducation's own comment — same fix.
    final entry = _certifications[index];
    if (_editingCertificationIndex != null) _cancelEditCertification();
    index = _certifications.indexOf(entry);
    final parsed = _parseMonthYearDurationRange(entry.duration);
    HapticFeedback.selectionClick();
    setState(() {
      _certifications = [..._certifications]..removeAt(index);
      _editingCertificationIndex = index;
      _editingCertificationOriginal = entry;
      _certNameController.text = entry.name;
      _certExistingLink = entry.link;
      _certStartDate = parsed.start;
      _certEndDate = parsed.end;
      _certOngoing = parsed.isCurrent;
      _certImagePath = entry.imagePath;
      _certImageFile = null;
      _certQuestionIndex = 0;
      _certDurationGeneration++;
    });
  }

  void _cancelEditCertification() {
    final original = _editingCertificationOriginal;
    final index = _editingCertificationIndex;
    if (original == null || index == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _certifications = [..._certifications]..insert(index.clamp(0, _certifications.length), original);
      _editingCertificationIndex = null;
      _editingCertificationOriginal = null;
      _certNameController.clear();
      _certExistingLink = null;
      _certStartDate = null;
      _certEndDate = null;
      _certOngoing = false;
      _certImageFile = null;
      _certImagePath = null;
      _certQuestionIndex = 0;
      _certDurationGeneration++;
    });
  }

  void _addLanguage(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final exists = _languages.any((l) => l.name.toLowerCase() == trimmed.toLowerCase());
    if (exists) return;
    HapticFeedback.selectionClick();
    setState(() {
      _languages = [..._languages, LanguageEntry(name: trimmed, proficiency: 'Intermediate')];
      _languagesError = null;
    });
  }

  void _removeLanguage(LanguageEntry l) {
    HapticFeedback.selectionClick();
    setState(() => _languages = _languages.where((x) => x != l).toList());
  }

  void _continueFromLanguages() {
    if (_languages.isEmpty) {
      HapticFeedback.selectionClick();
      setState(() => _languagesError = 'Add at least one language to continue.');
      return;
    }
    _goTo(6);
  }

  /// One resume-style sentence, not a fact dump — a blank text box is the
  /// single most intimidating part of writing a summary, so give people
  /// something to edit that already reads like a real opener, not
  /// something they'd need to rewrite from scratch anyway.
  String _oxfordJoin(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    if (items.length == 2) return '${items[0]} and ${items[1]}';
    return '${items.sublist(0, items.length - 1).join(', ')}, and ${items.last}';
  }

  /// A sentence-fragment opener, not a full sentence — the name is
  /// deliberately left out (it's redundant on an actual resume, already the
  /// page's own header) and this leads with qualification framed as
  /// identity ("X student at Y") rather than a bare "Pursuing X at Y."
  /// status line.
  String? get _qualificationPhrase {
    final course = _user?.course?.trim();
    final college = _user?.college?.trim();
    final hasCourse = course != null && course.isNotEmpty;
    final hasCollege = college != null && college.isNotEmpty;
    if (hasCourse && hasCollege) return '$course student at $college';
    if (hasCourse) return '$course student';
    if (hasCollege) return 'Student at $college';
    return null;
  }

  /// 2 differently-worded phrasings per tier, not the same clause reshuffled
  /// — a "Regenerate" tap needs to actually read as a different suggestion,
  /// not the identical sentence again.
  String _summaryForVariant(int variant) {
    final qualification = _qualificationPhrase;
    final skillsPhrase = _oxfordJoin(_skills.take(3).toList());
    final v = variant % 2;

    if (qualification != null && skillsPhrase.isNotEmpty) {
      return v == 0
          ? '$qualification with hands-on skills in $skillsPhrase, driven to deliver real, measurable impact.'
          : '$qualification, bringing hands-on experience in $skillsPhrase and a drive to deliver real results.';
    }
    if (qualification != null) {
      return v == 0
          ? '$qualification, eager to turn classroom learning into real-world impact.'
          : '$qualification, ready to bring energy and initiative to a real team.';
    }
    if (skillsPhrase.isNotEmpty) {
      return v == 0
          ? 'Motivated professional with hands-on skills in $skillsPhrase, driven to deliver real, measurable impact.'
          : 'Practical, hands-on professional skilled in $skillsPhrase, ready to make an immediate contribution.';
    }
    return v == 0
        ? 'Motivated and driven, eager to contribute meaningfully from day one.'
        : 'Driven and dependable, ready to learn fast and add value from day one.';
  }

  void _useSuggestedSummary() {
    HapticFeedback.selectionClick();
    // Only a genuine "Regenerate" tap (field still holds exactly what the
    // button wrote last time) advances the variant — a first-time autofill
    // always starts at variant 0, so nothing changes for anyone who's
    // never tapped this before.
    final isRegenerate = _lastGeneratedSummary != null && _summaryController.text == _lastGeneratedSummary;
    if (isRegenerate) _summaryVariant = (_summaryVariant + 1) % 2;
    final text = _summaryForVariant(_summaryVariant);
    _summaryController.text = text;
    _summaryController.selection = TextSelection.collapsed(offset: _summaryController.text.length);
    setState(() {
      _lastGeneratedSummary = text;
      _summaryError = null;
    });
  }

  void _onSummaryChanged(String _) {
    // Always rebuilds, not just when there's an error to clear — the
    // "Regenerate" vs "Tap to autofill" label depends on comparing the
    // field's live text to _lastGeneratedSummary on every keystroke, so a
    // hand-edit needs to flip that label back immediately, not only on
    // some other unrelated rebuild.
    setState(() {
      if (_summaryError != null) _summaryError = null;
    });
  }

  void _continueFromSummary() {
    if (_summaryController.text.trim().isEmpty) {
      HapticFeedback.selectionClick();
      setState(() => _summaryError = 'Write a short summary to continue.');
      return;
    }
    _startBuilding();
  }

  void _startBuilding() {
    setState(() => _phase = _Phase.building);
    _buildingTimer = Timer.periodic(const Duration(milliseconds: 450), (timer) {
      if (_buildingStep >= _buildingSteps.length - 1) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 500), _finishBuilding);
        return;
      }
      setState(() => _buildingStep++);
    });
  }

  Future<void> _finishBuilding() async {
    final wasOnboarding = !_postOnboarding;
    final resume = _resumeFromState();
    try {
      await context.read<AppState>().updateProfile((current) => (wasOnboarding
          ? current.copyWith(resume: resume, languages: _languages, onboardingComplete: true)
          : current.copyWith(resume: resume, languages: _languages)));
      if (!mounted) return;
      setState(() => _phase = _Phase.ready);
    } catch (e) {
      // There was no catch here before — a failed save (the same
      // storage-quota class of bug profile_edit_screen.dart is already
      // guarded against) left the user permanently stranded on
      // _BuildingView, which is deliberately unpoppable during this phase.
      // Land back on the quiz instead, where "Build my resume" is a real
      // retry, rather than a dead end with no way out but reloading.
      debugPrint('ResumeBuilderQuizScreen: finishBuilding failed — $e');
      if (!mounted) return;
      setState(() => _phase = _Phase.quiz);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text("Couldn't save your resume — try again."),
          action: SnackBarAction(label: 'Retry', textColor: AppColors.yellow, onPressed: _finishBuilding),
          duration: const Duration(seconds: 4),
          // See sessions_screen.dart's own note on `persist`.
          persist: false,
        ));
    }
  }

  // Resume is the last onboarding step (goals already happened before this
  // screen), so finishing here means straight home, not on to another step —
  // unless this build was started from an apply-gate, in which case the
  // application it was blocking can now actually be submitted. Deliberately
  // NOT a plain pop: this quiz is pushed on top of the resume-upload screen,
  // so popping once would land back on that now-stale intermediate screen
  // instead of home.
  void _done() {
    final applyFor = widget.applyForOpportunityId;
    if (applyFor != null) {
      // Same screening sheet the direct-apply path uses, not a silent
      // auto-submit with no note/answers — see apply_flow.dart's own doc
      // comment on continueApplyAfterResume for why.
      continueApplyAfterResume(context, applyFor);
      return;
    }
    context.go('/tabs');
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.building) {
      // Unlike every other phase, this one wasn't wrapped in a PopScope at
      // all — the system/browser back gesture could pop the route while
      // _finishBuilding()'s save is still in flight, racing a disposed
      // context. Blocked outright (not just intercepted): there's no
      // single "question" to step back to during this transitional phase
      // anyway.
      return PopScope(canPop: false, child: _BuildingView(stepLabel: _buildingSteps[_buildingStep]));
    }
    if (_phase == _Phase.ready) return ResumeReadyView(user: _user, onDone: _done);

    final topInset = MediaQuery.of(context).padding.top;
    final isTablet = AppBreakpoints.isWide(context);

    return PopScope(
      // The system/browser back gesture would otherwise pop this whole
      // route in one go, skipping however many questions are behind the
      // current one — intercept it and step back exactly one question,
      // same as the in-app chevron.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: ResponsiveBody(maxWidth: isTablet ? 720 : AppBreakpoints.maxContentWidth, child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(top: topInset + AppSpacing.sm, left: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.md),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _back,
                    child: const Icon(Ionicons.chevron_back, size: 44 - AppSpacing.lg, color: AppColors.ink),
                  ),
                  Expanded(
                    child: Text(
                      'Step ${_index + 1} of $_totalSteps',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLg.copyWith(color: AppColors.gray500, fontWeight: AppFontWeight.medium),
                    ),
                  ),
                  SizedBox(width: 44 - AppSpacing.lg),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm / 2),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: ((_index + 1) / _totalSteps).clamp(0.04, 1.0)),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: AppSpacing.sm - AppSpacing.xs / 2,
                    backgroundColor: AppColors.gray100,
                    valueColor: const AlwaysStoppedAnimation(AppColors.blue),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  if (_index != page) setState(() => _index = page);
                },
                children: [
                  _IntroStep(
                    user: _user,
                    headlineController: _headlineController,
                    phoneController: _phoneController,
                    onContinue: () => _goTo(1),
                  ),
                  _EducationStep(
                    entries: _educationEntries,
                    institutionController: _eduInstitutionController,
                    degreeController: _eduDegreeController,
                    gpaController: _eduGpaController,
                    gpaUnit: _eduGpaUnit,
                    onGpaUnitChanged: _setEduGpaUnit,
                    gpaError: _eduGpaError,
                    onGpaChanged: _onEduGpaChanged,
                    startYear: _eduStartYear,
                    endYear: _eduEndYear,
                    isCurrent: _eduCurrentlyStudying,
                    isEditing: _editingEducationIndex != null,
                    questionIndex: _eduQuestionIndex,
                    onQuestionIndexChanged: (i) => setState(() => _eduQuestionIndex = i),
                    onFieldChanged: () => setState(() {}),
                    onPickStart: _pickEduStartYear,
                    onPickEnd: _pickEduEndYear,
                    onCurrentChanged: _setEduCurrentlyStudying,
                    onAdd: _addEducation,
                    onRemove: _removeEducation,
                    onEdit: _editEducation,
                    onCancelEdit: _cancelEditEducation,
                    onContinue: () => _goTo(2),
                  ),
                  _ExperienceStep(
                    hasExperience: _hasWorkExperience,
                    onSelectHasExperience: _selectHasWorkExperience,
                    entries: _workExperience,
                    companyController: _expCompanyController,
                    roleController: _expRoleController,
                    descController: _expDescController,
                    startDate: _expStartDate,
                    endDate: _expEndDate,
                    isCurrent: _expCurrentlyWorking,
                    isEditing: _editingExperienceIndex != null,
                    questionIndex: _expQuestionIndex,
                    onQuestionIndexChanged: (i) => setState(() => _expQuestionIndex = i),
                    onFieldChanged: () => setState(() {}),
                    onPickStart: _pickExpStartDate,
                    onPickEnd: _pickExpEndDate,
                    onCurrentChanged: _setExpCurrentlyWorking,
                    onAdd: _addWorkExperience,
                    onRemove: _removeWorkExperience,
                    onEdit: _editWorkExperience,
                    onCancelEdit: _cancelEditWorkExperience,
                    onContinue: () => _goTo(3),
                  ),
                  _CertificationsStep(
                    hasCertifications: _hasCertifications,
                    onSelectHasCertifications: _selectHasCertifications,
                    entries: _certifications,
                    nameController: _certNameController,
                    startDate: _certStartDate,
                    endDate: _certEndDate,
                    isCurrent: _certOngoing,
                    isEditing: _editingCertificationIndex != null,
                    questionIndex: _certQuestionIndex,
                    onQuestionIndexChanged: (i) => setState(() => _certQuestionIndex = i),
                    onFieldChanged: () => setState(() {}),
                    imageFile: _certImageFile,
                    imagePath: _certImagePath,
                    onPickStart: _pickCertStartDate,
                    onPickEnd: _pickCertEndDate,
                    onCurrentChanged: _setCertOngoing,
                    onPickImage: _pickCertImage,
                    onRemoveImage: _removeCertImage,
                    onAdd: _addCertification,
                    onRemove: _removeCertification,
                    onEdit: _editCertification,
                    onCancelEdit: _cancelEditCertification,
                    onContinue: () => _goTo(4),
                  ),
                  _SkillsStep(
                    skills: _skills,
                    suggestions: skillSuggestionsByField[_field] ?? const [],
                    controller: _skillInputController,
                    onAdd: _addSkill,
                    onAddSuggestion: _addSkillValue,
                    onRemove: (s) => setState(() => _skills = _skills.where((x) => x != s).toList()),
                    error: _skillsError,
                    onContinue: _continueFromSkills,
                  ),
                  _LanguageStep(
                    languages: _languages,
                    onAddQuick: _addLanguage,
                    onAdd: _addLanguage,
                    onRemove: _removeLanguage,
                    error: _languagesError,
                    onContinue: _continueFromLanguages,
                  ),
                  _SummaryStep(
                    controller: _summaryController,
                    // "Regenerate" once the field still holds exactly what
                    // the button last generated; "Tap to autofill" for an
                    // empty field or one that's been hand-edited since.
                    label: _summaryController.text == _lastGeneratedSummary ? 'Regenerate' : 'Tap to autofill',
                    onUseSuggestion: _useSuggestedSummary,
                    onChanged: _onSummaryChanged,
                    error: _summaryError,
                    onContinue: _continueFromSummary,
                  ),
                ],
              ),
            ),
          ],
        )),
      ),
      ),
    );
  }
}

class _IntroStep extends StatelessWidget {
  final User? user;
  final TextEditingController headlineController;
  final TextEditingController phoneController;
  final VoidCallback onContinue;
  const _IntroStep({required this.user, required this.headlineController, required this.phoneController, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, String)>[
      (Ionicons.person_outline, 'Name', user?.name ?? '—'),
      if ((user?.college ?? '').isNotEmpty) (Ionicons.business_outline, 'College', user!.college!),
      if ((user?.course ?? '').isNotEmpty) (Ionicons.book_outline, 'Course', user!.course!),
      if ((user?.semester ?? '').isNotEmpty) (Ionicons.layers_outline, 'Semester', user!.semester!),
    ];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  noOrphan('Already got this from your profile'),
                  style: AppTextStyles.h1.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold, height: 1.25),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    noOrphan("No need to type it twice — you'll just answer a couple of quick ones."),
                    style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.lg)),
                    child: Column(
                      children: rows
                          .map((r) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                child: Row(
                                  children: [
                                    Icon(r.$1, size: 18, color: AppColors.blue),
                                    const SizedBox(width: AppSpacing.md),
                                    // 92, not the original 64 — "Semester"
                                    // (added for this row) doesn't fit 64
                                    // without wrapping, same issue already
                                    // hit and fixed for _FactRow's own
                                    // label column elsewhere in this file.
                                    SizedBox(
                                      width: 72,
                                      child: Text(r.$2, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
                                    ),
                                    Expanded(
                                      // Shrinks a long name/course to fit rather than
                                      // cutting it off ("Aayusha Pag…").
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          r.$3,
                                          textAlign: TextAlign.left,
                                          maxLines: 1,
                                          softWrap: false,
                                          style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    const Icon(Ionicons.checkmark_circle, size: 16, color: AppColors.success),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: GestureDetector(
                    onTap: () => context.push(Uri(
                      path: '/profile-edit',
                      queryParameters: {'returnTo': '/college/resume/build'},
                    ).toString()),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Ionicons.pencil_outline, size: 14, color: AppColors.blue),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Something wrong? Edit your profile',
                          style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium),
                        ),
                      ],
                    ),
                  ),
                ),
                const FieldLabel('Your role (optional)'),
                AutocompleteField(
                  value: headlineController.text,
                  controller: headlineController,
                  placeholder: 'e.g. Graphics Designer',
                  icon: Ionicons.briefcase_outline,
                  options: mockJobTitles,
                  onChanged: (_) {},
                ),
                const FieldLabel('Phone number (optional)', tight: true),
                PillInput(
                  controller: phoneController,
                  placeholder: 'e.g. 98765 43210',
                  icon: Ionicons.call_outline,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
          decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: AppBreakpoints.isWide(context) ? 400 : double.infinity),
              child: PillButton(label: 'Continue', onPressed: onContinue),
            ),
          ),
        ),
      ],
    );
  }
}

/// Start/end date picker shared by Education and Experience — two wheel
/// picks (same native scroll-wheel sheet used app-wide for dates) plus an
/// "in progress" checkbox that blanks the end date and shows "Present".
/// Takes pre-formatted display labels rather than raw year/date values —
/// Education formats a bare year ('2024'), Experience a month+year
/// ('Jan 2024') — so this stays one shared, purely presentational widget
/// instead of forking into two near-duplicates over that one difference.
class _YearRangeRow extends StatelessWidget {
  final String? startLabel;
  final String? endLabel;
  final bool isCurrent;
  final String currentLabel;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<bool> onCurrentChanged;

  const _YearRangeRow({
    required this.startLabel,
    required this.endLabel,
    required this.isCurrent,
    required this.currentLabel,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onCurrentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DatePickerField(value: startLabel, placeholder: 'Start date', icon: Ionicons.calendar_outline, onTap: onPickStart),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DatePickerField(
                value: isCurrent ? 'Present' : endLabel,
                placeholder: 'End date',
                icon: Ionicons.calendar_outline,
                onTap: onPickEnd,
                // Picking End before Start used to accept any year with no
                // bound (the picker's minDate/minYear had nothing to floor
                // against yet), then silently clear it the moment Start
                // was picked afterward and made the range invalid —
                // disabling End until Start exists removes that "why did
                // my answer vanish" moment entirely.
                disabled: startLabel == null,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: GestureDetector(
            onTap: () => onCurrentChanged(!isCurrent),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(isCurrent ? Ionicons.checkbox : Ionicons.square_outline, size: 20, color: isCurrent ? AppColors.blue : AppColors.gray400),
                const SizedBox(width: AppSpacing.sm),
                Text(currentLabel, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One "single question" layout shared by Education/Experience/
/// Certifications' add-a-new-entry flow — a label, the field itself, and a
/// fallback advance button that only appears once [canAdvance] is true. A
/// text field's primary way forward is still its own keyboard submit
/// (wired at each call site's `onSubmitted`) — but that only fires from an
/// actual keystroke, so a field that already has a valid answer without
/// the user ever having typed into it (pre-filled from the profile, or
/// simply not tapped) has no keyboard to submit at all. Without this
/// button that's a dead end: a filled field with no visible way forward.
/// Hidden while the field is empty, on purpose — an empty field's natural
/// next step really is "type something, then hit the keyboard's check,"
/// and a button sitting there too would just be visual noise competing
/// with that. The Duration question (no keyboard — it's date pickers)
/// still advances itself automatically once a complete answer exists (see
/// e.g. `_maybeAutoAdvanceEduDuration`); its own [canAdvance] here is
/// deliberately looser (just a start date) so this button still offers a
/// way forward even in the one case that auto-advance doesn't cover — a
/// start with no end and "currently" left unchecked. The last, optional
/// question in each section doesn't use this at all — its own field wires
/// the keyboard's submit action and an explicit checkmark button
/// (`_FinalQuestionRow`) directly to committing the entry, since there's
/// nothing further to advance to within the section.
class _QuestionScaffold extends StatelessWidget {
  final String label;
  final Widget field;
  final VoidCallback onAdvance;
  final bool canAdvance;

  const _QuestionScaffold({
    super.key,
    required this.label,
    required this.field,
    required this.onAdvance,
    required this.canAdvance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        field,
        if (canAdvance)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onAdvance,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                  child: const Icon(Ionicons.arrow_forward, size: 18, color: AppColors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Row shown below the last, optional question in each section's
/// add-a-new-entry flow (Education's Grade, Experience's Description,
/// Certifications' image). Every required question before it advances off
/// its own keyboard submit — this one can't rely on that the same way: an
/// empty answer is valid here (nothing to "submit"), and Experience's
/// Description is a genuine multi-line field where the keyboard's Enter
/// key correctly inserts a newline instead of firing a submit at all. A
/// plain "Skip" link alone left no obvious way to say "I typed something,
/// I'm done" — this pairs it with an explicit checkmark button. Both call
/// the same [onAdd]; the field being empty or filled doesn't change what
/// committing the entry means, so there's no separate "submit" handler to
/// wire — Skip and the checkmark are just two doors to the same action.
class _FinalQuestionRow extends StatelessWidget {
  final VoidCallback onAdd;
  const _FinalQuestionRow({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: onAdd,
            child: Text('Skip', style: AppTextStyles.body.copyWith(color: AppColors.gray400, fontSize: 14, fontWeight: AppFontWeight.medium)),
          ),
          const SizedBox(width: AppSpacing.xl),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
              child: const Icon(Ionicons.checkmark, size: 20, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// One "already known" fact — icon, label, value, trailing checkmark.
/// Exactly mirrors _IntroStep's own "Already got this from your profile"
/// rows, reused here so a value looks identical everywhere it's shown as
/// settled: a field the profile already supplied (Education's Institution/
/// Degree, when known) and a question just answered earlier in this
/// section's own one-at-a-time flow both render the same way. Several of
/// these stack inside one shared [_factBox], not one box per row.
///
/// Tappable (via [onTap]) to jump back and change the answer — the field's
/// own state (its controller, or the picked date) lives in the parent
/// regardless of which question is currently active, so re-showing it here
/// just makes it editable again without losing anything already entered
/// for questions after it.
class _FactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _FactRow({required this.icon, required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.blue),
            const SizedBox(width: AppSpacing.md),
            // 92, not _IntroStep's 64 — "Institution" and "Company" (used
            // here, unlike _IntroStep's shorter Name/College/Course/Year)
            // don't fit 64 without wrapping to a second line.
            SizedBox(width: 92, child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12))),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium, fontSize: 12),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (onTap != null) const Icon(Ionicons.pencil_outline, size: 14, color: AppColors.gray400) else const Icon(Ionicons.checkmark_circle, size: 16, color: AppColors.success),
          ],
        ),
      ),
    );
  }
}

/// Shared offWhite container for one or more [_FactRow]s — same shell
/// _IntroStep's profile-fact card uses. Empty when there's nothing known
/// yet, so a fresh question with no prior answers renders no stray box.
Widget _factBox(List<Widget> rows) {
  if (rows.isEmpty) return const SizedBox.shrink();
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
    decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.lg)),
    child: Column(children: rows),
  );
}

/// Multi-entry education — institution, degree, duration, and GPA/percentage.
/// Adding a new entry is one question at a time (Institution → Degree →
/// Duration → Grade); the last, optional question commits the entry on
/// either a keyboard submit or "Skip" — there's no separate "Add" button
/// anywhere in this flow. Editing an existing entry (tap its card) still
/// shows every field on one screen at once, unchanged — a deliberate,
/// smaller-blast-radius choice: editing is an occasional, deliberate
/// action where seeing everything at once for review is the better
/// experience, not something that needed the same redesign as first-time
/// entry.
class _EducationStep extends StatelessWidget {
  final List<ResumeEducation> entries;
  final TextEditingController institutionController;
  final TextEditingController degreeController;
  final TextEditingController gpaController;
  final GpaUnit gpaUnit;
  final ValueChanged<GpaUnit> onGpaUnitChanged;
  final String? gpaError;
  final ValueChanged<String> onGpaChanged;
  final int? startYear;
  final int? endYear;
  final bool isCurrent;
  final bool isEditing;
  final int questionIndex;
  final ValueChanged<int> onQuestionIndexChanged;
  final VoidCallback onFieldChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<bool> onCurrentChanged;
  final VoidCallback onAdd;
  final ValueChanged<ResumeEducation> onRemove;
  final ValueChanged<int> onEdit;
  final VoidCallback onCancelEdit;
  final VoidCallback onContinue;

  const _EducationStep({
    required this.entries,
    required this.institutionController,
    required this.degreeController,
    required this.gpaController,
    required this.gpaUnit,
    required this.onGpaUnitChanged,
    required this.gpaError,
    required this.onGpaChanged,
    required this.startYear,
    required this.endYear,
    required this.isCurrent,
    required this.isEditing,
    required this.questionIndex,
    required this.onQuestionIndexChanged,
    required this.onFieldChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onCurrentChanged,
    required this.onAdd,
    required this.onRemove,
    required this.onEdit,
    required this.onCancelEdit,
    required this.onContinue,
  });

  Widget _question(int index) {
    switch (index) {
      case 0:
        return _QuestionScaffold(
          key: const ValueKey('institution'),
          // Same wording as profile_edit_screen.dart and onboarding's
          // micro_profile_screen.dart use for this same field — was
          // "Institution" here, "College / University" there.
          label: 'College / University',
          field: AutocompleteField(
            value: institutionController.text,
            controller: institutionController,
            placeholder: 'e.g. BITS Goa',
            icon: Ionicons.business_outline,
            options: mockColleges,
            onChanged: (_) => onFieldChanged(),
            onSubmitted: (_) {
              if (institutionController.text.trim().isNotEmpty) onQuestionIndexChanged(1);
            },
          ),
          canAdvance: institutionController.text.trim().isNotEmpty,
          onAdvance: () => onQuestionIndexChanged(1),
        );
      case 1:
        return _QuestionScaffold(
          key: const ValueKey('degree'),
          label: 'Course / Degree',
          field: AutocompleteField(
            value: degreeController.text,
            controller: degreeController,
            placeholder: 'e.g. Bachelor of Design',
            icon: Ionicons.school_outline,
            options: mockCourses,
            onChanged: (_) => onFieldChanged(),
            onSubmitted: (_) {
              if (degreeController.text.trim().isNotEmpty) onQuestionIndexChanged(2);
            },
          ),
          canAdvance: degreeController.text.trim().isNotEmpty,
          onAdvance: () => onQuestionIndexChanged(2),
        );
      case 2:
        return _QuestionScaffold(
          key: const ValueKey('duration'),
          label: 'Duration',
          field: _YearRangeRow(
            startLabel: startYear?.toString(),
            endLabel: endYear?.toString(),
            isCurrent: isCurrent,
            currentLabel: 'Currently studying here',
            onPickStart: onPickStart,
            onPickEnd: onPickEnd,
            onCurrentChanged: onCurrentChanged,
          ),
          canAdvance: startYear != null,
          onAdvance: () => onQuestionIndexChanged(3),
        );
      default:
        return Column(
          key: const ValueKey('grade'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FieldLabel('Grade (optional)'),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: GpaUnit.values
                  .map((u) => AppChip(label: _gpaUnitLabel(u), selected: gpaUnit == u, onPressed: () => onGpaUnitChanged(u)))
                  .toList(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Pick whichever your institution uses',
                style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontSize: 12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: PillInput(
                controller: gpaController,
                placeholder: _gpaPlaceholder(gpaUnit),
                icon: Ionicons.ribbon_outline,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                error: gpaError,
                onChanged: onGpaChanged,
                // Typing a value then hitting the keyboard's own submit
                // commits the entry directly — same outcome as the
                // checkmark button below, just with the field filled in
                // first.
                onSubmitted: (_) => onAdd(),
                scrollIntoViewOnFocus: true,
              ),
            ),
            _FinalQuestionRow(onAdd: onAdd),
          ],
        );
    }
  }

  // Read-only fact row for a question index already passed (either
  // pre-filled from the profile or answered earlier in this flow) — see
  // _FactRow's own doc comment. Only ever called for indices strictly
  // before questionIndex, so 0/1/2 are the only cases that can occur (3,
  // Grade, is always the active question, never a past one).
  Widget _answeredRow(int index) {
    switch (index) {
      case 0:
        return _FactRow(icon: Ionicons.business_outline, label: 'College / University', value: institutionController.text, onTap: () => onQuestionIndexChanged(0));
      case 1:
        return _FactRow(icon: Ionicons.school_outline, label: 'Course / Degree', value: degreeController.text, onTap: () => onQuestionIndexChanged(1));
      default:
        final value = isCurrent ? '$startYear - Present' : (endYear != null ? '$startYear - $endYear' : '$startYear');
        return _FactRow(icon: Ionicons.calendar_outline, label: 'Duration', value: value, onTap: () => onQuestionIndexChanged(2));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  noOrphan('Your education'),
                  style: AppTextStyles.h1.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold, height: 1.25),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(noOrphan("We've filled in what we already know — just add the dates and grade."), style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (isEditing) ...[
                  const FieldLabel('College / University', tight: true),
                  AutocompleteField(value: institutionController.text, controller: institutionController, placeholder: 'e.g. BITS Goa', icon: Ionicons.business_outline, options: mockColleges, onChanged: (_) {}),
                  const FieldLabel('Course / Degree', tight: true),
                  AutocompleteField(value: degreeController.text, controller: degreeController, placeholder: 'e.g. Bachelor of Design', icon: Ionicons.school_outline, options: mockCourses, onChanged: (_) {}),
                  const FieldLabel('Duration', tight: true),
                  _YearRangeRow(
                    startLabel: startYear?.toString(),
                    endLabel: endYear?.toString(),
                    isCurrent: isCurrent,
                    currentLabel: 'Currently studying here',
                    onPickStart: onPickStart,
                    onPickEnd: onPickEnd,
                    onCurrentChanged: onCurrentChanged,
                  ),
                  const FieldLabel('Grade (optional)', tight: true),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: GpaUnit.values
                        .map((u) => AppChip(label: _gpaUnitLabel(u), selected: gpaUnit == u, onPressed: () => onGpaUnitChanged(u)))
                        .toList(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      'Pick whichever your institution uses',
                      style: AppTextStyles.caption.copyWith(color: AppColors.gray400, fontSize: 12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: PillInput(
                      controller: gpaController,
                      placeholder: _gpaPlaceholder(gpaUnit),
                      icon: Ionicons.ribbon_outline,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      error: gpaError,
                      onChanged: onGpaChanged,
                      scrollIntoViewOnFocus: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: PillButton(label: 'Save changes', variant: PillVariant.secondary, onPressed: onAdd),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        GestureDetector(
                          onTap: onCancelEdit,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.lg),
                            child: Text('Cancel', style: AppTextStyles.label.copyWith(color: AppColors.gray500, fontWeight: AppFontWeight.medium)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  _factBox([for (var i = 0; i < questionIndex; i++) _answeredRow(i)]),
                  if (questionIndex > 0) const SizedBox(height: AppSpacing.lg),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(animation), child: child),
                    ),
                    child: _question(questionIndex),
                  ),
                ],
                if (entries.isNotEmpty)
                  ...entries.asMap().entries.map((indexed) {
                    final i = indexed.key;
                    final e = indexed.value;
                    return Container(
                      margin: const EdgeInsets.only(top: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.lg)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onEdit(i),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.degree, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.medium)),
                                  Padding(
                                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                                    child: Text(
                                      [e.institution, e.duration, if (e.gpa != null && e.gpa!.isNotEmpty) e.gpa!].where((s) => s.isNotEmpty).join(' • '),
                                      style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => onRemove(e),
                            child: const Icon(Ionicons.close_circle, size: 20, color: AppColors.gray400),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
          decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: AppBreakpoints.isWide(context) ? 400 : double.infinity),
              child: PillButton(
                label: entries.isEmpty ? 'Skip for now' : 'Continue',
                variant: entries.isEmpty ? PillVariant.ghost : PillVariant.primary,
                onPressed: onContinue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Gated multi-entry work history — a fresher sees one yes/no question and
/// nothing else; picking "yes" reveals the same add/list/remove form shape
/// Education uses (company/role/duration/description instead of
/// institution/degree/duration/GPA), so the two sections ask the same way.
class _ExperienceStep extends StatelessWidget {
  final bool? hasExperience;
  final ValueChanged<bool> onSelectHasExperience;
  final List<WorkExperience> entries;
  final TextEditingController companyController;
  final TextEditingController roleController;
  final TextEditingController descController;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final bool isEditing;
  final int questionIndex;
  final ValueChanged<int> onQuestionIndexChanged;
  final VoidCallback onFieldChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<bool> onCurrentChanged;
  final VoidCallback onAdd;
  final ValueChanged<WorkExperience> onRemove;
  final ValueChanged<int> onEdit;
  final VoidCallback onCancelEdit;
  final VoidCallback onContinue;

  const _ExperienceStep({
    required this.hasExperience,
    required this.onSelectHasExperience,
    required this.entries,
    required this.companyController,
    required this.roleController,
    required this.descController,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    required this.isEditing,
    required this.questionIndex,
    required this.onQuestionIndexChanged,
    required this.onFieldChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onCurrentChanged,
    required this.onAdd,
    required this.onRemove,
    required this.onEdit,
    required this.onCancelEdit,
    required this.onContinue,
  });

  Widget _question(int index) {
    switch (index) {
      case 0:
        return _QuestionScaffold(
          key: const ValueKey('company'),
          label: 'Company',
          field: AutocompleteField(
            value: companyController.text,
            controller: companyController,
            placeholder: 'e.g. Microsoft',
            icon: Ionicons.business_outline,
            options: mockCompanyNames,
            onChanged: (_) => onFieldChanged(),
            onSubmitted: (_) {
              if (companyController.text.trim().isNotEmpty) onQuestionIndexChanged(1);
            },
          ),
          canAdvance: companyController.text.trim().isNotEmpty,
          onAdvance: () => onQuestionIndexChanged(1),
        );
      case 1:
        return _QuestionScaffold(
          key: const ValueKey('role'),
          label: 'Role',
          field: AutocompleteField(
            value: roleController.text,
            controller: roleController,
            placeholder: 'e.g. Software Intern',
            icon: Ionicons.person_outline,
            options: mockJobTitles,
            onChanged: (_) => onFieldChanged(),
            onSubmitted: (_) {
              if (roleController.text.trim().isNotEmpty) onQuestionIndexChanged(2);
            },
          ),
          canAdvance: roleController.text.trim().isNotEmpty,
          onAdvance: () => onQuestionIndexChanged(2),
        );
      case 2:
        return _QuestionScaffold(
          key: const ValueKey('duration'),
          label: 'Duration',
          field: _YearRangeRow(
            startLabel: startDate != null ? _formatMonthYear(startDate!) : null,
            endLabel: endDate != null ? _formatMonthYear(endDate!) : null,
            isCurrent: isCurrent,
            currentLabel: 'I currently work here',
            onPickStart: onPickStart,
            onPickEnd: onPickEnd,
            onCurrentChanged: onCurrentChanged,
          ),
          canAdvance: startDate != null,
          onAdvance: () => onQuestionIndexChanged(3),
        );
      default:
        return Column(
          key: const ValueKey('description'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FieldLabel('What did you do in this role? (optional)'),
            PillInput(
              controller: descController,
              placeholder: 'e.g. Shipped a feature used by 500+ customers',
              maxLength: 400,
              // Genuinely multi-line — Enter here correctly inserts a new
              // line rather than submitting, so onSubmitted's keyboard-only
              // trigger can't be this field's real "I'm done" signal the
              // way it is for every single-line question earlier in this
              // flow; the checkmark button below is the reliable one.
              maxLines: 4,
              minLines: 3,
              onSubmitted: (_) => onAdd(),
              scrollIntoViewOnFocus: true,
            ),
            _FinalQuestionRow(onAdd: onAdd),
          ],
        );
    }
  }

  // See _EducationStep._answeredRow — same purpose. Cases 0/1/2 are the
  // only ones that can occur (3, Description, is always the active
  // question, never a past one).
  Widget _answeredRow(int index) {
    switch (index) {
      case 0:
        return _FactRow(icon: Ionicons.business_outline, label: 'Company', value: companyController.text, onTap: () => onQuestionIndexChanged(0));
      case 1:
        return _FactRow(icon: Ionicons.person_outline, label: 'Role', value: roleController.text, onTap: () => onQuestionIndexChanged(1));
      default:
        final start = startDate;
        final startLabel = start != null ? _formatMonthYear(start) : '';
        final value = isCurrent ? '$startLabel - Present' : (endDate != null ? '$startLabel - ${_formatMonthYear(endDate!)}' : startLabel);
        return _FactRow(icon: Ionicons.calendar_outline, label: 'Duration', value: value, onTap: () => onQuestionIndexChanged(2));
    }
  }

  @override
  Widget build(BuildContext context) {
    final showForm = hasExperience == true;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  noOrphan('Do you have work experience?'),
                  style: AppTextStyles.h1.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold, height: 1.25),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(noOrphan('Internships count too.'), style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        // Disabled once entries exist — they're proof the
                        // answer is yes, and switching to "Not yet" would
                        // leave those same entries visibly listed under a
                        // contradictory answer instead of removing them.
                        child: AppChip(label: 'Not yet', selected: hasExperience == false, disabled: entries.isNotEmpty, onPressed: () => onSelectHasExperience(false)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppChip(label: 'Yes, I do', selected: hasExperience == true, onPressed: () => onSelectHasExperience(true)),
                      ),
                    ],
                  ),
                ),
                if (showForm) ...[
                  const SizedBox(height: AppSpacing.lg),
                  if (isEditing) ...[
                    const FieldLabel('Company', tight: true),
                    AutocompleteField(value: companyController.text, controller: companyController, placeholder: 'e.g. Microsoft', icon: Ionicons.business_outline, options: mockCompanyNames, onChanged: (_) {}),
                    const FieldLabel('Role', tight: true),
                    AutocompleteField(value: roleController.text, controller: roleController, placeholder: 'e.g. Software Intern', icon: Ionicons.person_outline, options: mockJobTitles, onChanged: (_) {}),
                    const FieldLabel('Duration', tight: true),
                    _YearRangeRow(
                      startLabel: startDate != null ? _formatMonthYear(startDate!) : null,
                      endLabel: endDate != null ? _formatMonthYear(endDate!) : null,
                      isCurrent: isCurrent,
                      currentLabel: 'I currently work here',
                      onPickStart: onPickStart,
                      onPickEnd: onPickEnd,
                      onCurrentChanged: onCurrentChanged,
                    ),
                    const FieldLabel('What did you do in this role? (optional)', tight: true),
                    PillInput(
                      controller: descController,
                      placeholder: 'e.g. Shipped a feature used by 500+ customers',
                      maxLength: 400,
                      maxLines: 4,
                      minLines: 3,
                      scrollIntoViewOnFocus: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                      child: Row(
                        children: [
                          Expanded(
                            child: PillButton(label: 'Save changes', variant: PillVariant.secondary, onPressed: onAdd),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          GestureDetector(
                            onTap: onCancelEdit,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.lg),
                              child: Text('Cancel', style: AppTextStyles.label.copyWith(color: AppColors.gray500, fontWeight: AppFontWeight.medium)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    _factBox([for (var i = 0; i < questionIndex; i++) _answeredRow(i)]),
                    if (questionIndex > 0) const SizedBox(height: AppSpacing.lg),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(animation), child: child),
                      ),
                      child: _question(questionIndex),
                    ),
                  ],
                ],
                if (entries.isNotEmpty)
                  ...entries.asMap().entries.map((indexed) {
                    final i = indexed.key;
                    final w = indexed.value;
                    return Container(
                      margin: const EdgeInsets.only(top: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.lg)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Only the identity block (role/company/
                                // duration) opens edit mode — the
                                // description below has its own "View
                                // more" tap target, which a single
                                // GestureDetector spanning the whole card
                                // would otherwise contend with.
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => onEdit(i),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${w.role} — ${w.company}',
                                        style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.medium),
                                      ),
                                      if (w.duration.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                                          child: Text(w.duration, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                ),
                                if (w.description.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                                    child: ExpandableText(
                                      text: w.description,
                                      maxLines: 3,
                                      style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => onRemove(w),
                            child: const Icon(Ionicons.close_circle, size: 20, color: AppColors.gray400),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
          decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: AppBreakpoints.isWide(context) ? 400 : double.infinity),
              child: PillButton(
                // "Yes, I do" + zero entries used to still read "Skip for
                // now" — the wording never checked the actual yes/no answer,
                // only the entry count.
                label: hasExperience == true && entries.isEmpty ? 'Add at least one' : (entries.isEmpty ? 'Skip for now' : 'Continue'),
                variant: entries.isEmpty && hasExperience != true ? PillVariant.ghost : PillVariant.primary,
                disabled: hasExperience == true && entries.isEmpty,
                onPressed: onContinue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Certifications / completed courses — mirrors _ExperienceStep's shape
/// (same yes/no gate, same date pickers, same skippable footer, same
/// entry-card layout). One optional certificate-specific field: an
/// uploaded image (no link field anymore — see [linkController]'s removal
/// note at the call site; a pre-existing entry's link, if any, still
/// displays on its card, just can't be set from here going forward).
class _CertificationsStep extends StatelessWidget {
  final bool? hasCertifications;
  final ValueChanged<bool> onSelectHasCertifications;
  final List<ResumeCertification> entries;
  final TextEditingController nameController;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final bool isEditing;
  final int questionIndex;
  final ValueChanged<int> onQuestionIndexChanged;
  final VoidCallback onFieldChanged;
  final XFile? imageFile;
  final String? imagePath;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<bool> onCurrentChanged;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final VoidCallback onAdd;
  final ValueChanged<ResumeCertification> onRemove;
  final ValueChanged<int> onEdit;
  final VoidCallback onCancelEdit;
  final VoidCallback onContinue;

  const _CertificationsStep({
    required this.hasCertifications,
    required this.onSelectHasCertifications,
    required this.entries,
    required this.nameController,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    required this.isEditing,
    required this.questionIndex,
    required this.onQuestionIndexChanged,
    required this.onFieldChanged,
    required this.imageFile,
    required this.imagePath,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onCurrentChanged,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onAdd,
    required this.onRemove,
    required this.onEdit,
    required this.onCancelEdit,
    required this.onContinue,
  });

  Widget _imagePreview() {
    if (imageFile != null) {
      return Image.file(File(imageFile!.path), width: 48, height: 48, fit: BoxFit.cover);
    }
    // imageFile is null whenever a pre-existing entry's image is being
    // shown without having been re-picked this session (e.g. re-opening
    // an entry to edit it — _editCertification sets imageFile back to
    // null and only imagePath survives).
    return Image.file(File(imagePath!), width: 48, height: 48, fit: BoxFit.cover);
  }

  Widget _imagePickerRow(bool hasImage) {
    return Row(
      children: [
        if (hasImage) ...[
          ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: _imagePreview()),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: GestureDetector(
            onTap: onPickImage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Ionicons.image_outline, size: 18, color: AppColors.gray500),
                  const SizedBox(width: AppSpacing.sm),
                  Text(hasImage ? 'Change image' : 'Upload image', style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14, fontWeight: AppFontWeight.medium)),
                ],
              ),
            ),
          ),
        ),
        if (hasImage) ...[
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onRemoveImage,
            child: const Icon(Ionicons.close_circle, size: 20, color: AppColors.gray400),
          ),
        ],
      ],
    );
  }

  Widget _question(int index, bool hasImage) {
    switch (index) {
      case 0:
        return _QuestionScaffold(
          key: const ValueKey('name'),
          label: 'Certification / course name',
          field: PillInput(
            controller: nameController,
            placeholder: 'e.g. Google UX Design Certificate',
            icon: Ionicons.ribbon_outline,
            onChanged: (_) => onFieldChanged(),
            onSubmitted: (_) {
              if (nameController.text.trim().isNotEmpty) onQuestionIndexChanged(1);
            },
          ),
          canAdvance: nameController.text.trim().isNotEmpty,
          onAdvance: () => onQuestionIndexChanged(1),
        );
      case 1:
        return _QuestionScaffold(
          key: const ValueKey('duration'),
          label: 'Duration',
          field: _YearRangeRow(
            startLabel: startDate != null ? _formatMonthYear(startDate!) : null,
            endLabel: endDate != null ? _formatMonthYear(endDate!) : null,
            isCurrent: isCurrent,
            currentLabel: 'Currently ongoing',
            onPickStart: onPickStart,
            onPickEnd: onPickEnd,
            onCurrentChanged: onCurrentChanged,
          ),
          canAdvance: startDate != null,
          onAdvance: () => onQuestionIndexChanged(2),
        );
      default:
        return Column(
          key: const ValueKey('image'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FieldLabel('Certificate image (optional)'),
            _imagePickerRow(hasImage),
            _FinalQuestionRow(onAdd: onAdd),
          ],
        );
    }
  }

  // See _EducationStep._answeredRow — same purpose. Cases 0/1 are the
  // only ones that can occur (2, the certificate image, is always the
  // active question, never a past one).
  Widget _answeredRow(int index) {
    switch (index) {
      case 0:
        // Shortened from the active question's own longer label
        // ("Certification / course name") — _FactRow's label column is
        // sized for short words like Step 1's Name/College/Course/Year.
        return _FactRow(icon: Ionicons.ribbon_outline, label: 'Name', value: nameController.text, onTap: () => onQuestionIndexChanged(0));
      default:
        final start = startDate;
        final startLabel = start != null ? _formatMonthYear(start) : '';
        final value = isCurrent ? '$startLabel - Present' : (endDate != null ? '$startLabel - ${_formatMonthYear(endDate!)}' : startLabel);
        return _FactRow(icon: Ionicons.calendar_outline, label: 'Duration', value: value, onTap: () => onQuestionIndexChanged(1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final showForm = hasCertifications == true;
    final hasImage = imageFile != null || (imagePath != null && imagePath!.isNotEmpty);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  noOrphan('Do you have any certifications?'),
                  style: AppTextStyles.h1.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold, height: 1.25),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(noOrphan('Online courses count too.'), style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        // See _ExperienceStep's own "Not yet" — same guard.
                        child: AppChip(label: 'Not yet', selected: hasCertifications == false, disabled: entries.isNotEmpty, onPressed: () => onSelectHasCertifications(false)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppChip(label: 'Yes, I do', selected: hasCertifications == true, onPressed: () => onSelectHasCertifications(true)),
                      ),
                    ],
                  ),
                ),
                if (showForm) ...[
                  const SizedBox(height: AppSpacing.lg),
                  if (isEditing) ...[
                    const FieldLabel('Certification / course name', tight: true),
                    PillInput(controller: nameController, placeholder: 'e.g. Google UX Design Certificate', icon: Ionicons.ribbon_outline),
                    const FieldLabel('Duration', tight: true),
                    _YearRangeRow(
                      startLabel: startDate != null ? _formatMonthYear(startDate!) : null,
                      endLabel: endDate != null ? _formatMonthYear(endDate!) : null,
                      isCurrent: isCurrent,
                      currentLabel: 'Currently ongoing',
                      onPickStart: onPickStart,
                      onPickEnd: onPickEnd,
                      onCurrentChanged: onCurrentChanged,
                    ),
                    const FieldLabel('Certificate image (optional)', tight: true),
                    _imagePickerRow(hasImage),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                      child: Row(
                        children: [
                          Expanded(
                            child: PillButton(label: 'Save changes', variant: PillVariant.secondary, onPressed: onAdd),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          GestureDetector(
                            onTap: onCancelEdit,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.lg),
                              child: Text('Cancel', style: AppTextStyles.label.copyWith(color: AppColors.gray500, fontWeight: AppFontWeight.medium)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    _factBox([for (var i = 0; i < questionIndex; i++) _answeredRow(i)]),
                    if (questionIndex > 0) const SizedBox(height: AppSpacing.lg),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(animation), child: child),
                      ),
                      child: _question(questionIndex, hasImage),
                    ),
                  ],
                ],
                if (entries.isNotEmpty)
                  ...entries.asMap().entries.map((indexed) {
                    final i = indexed.key;
                    final c = indexed.value;
                    return Container(
                      margin: const EdgeInsets.only(top: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.lg)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => onEdit(i),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.name, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.medium)),
                                      if (c.duration.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                                          child: Text(c.duration, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                ),
                                if ((c.link ?? '').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                                    child: Text('View certificate', style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
                                  ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => onRemove(c),
                            child: const Icon(Ionicons.close_circle, size: 20, color: AppColors.gray400),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
          decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: AppBreakpoints.isWide(context) ? 400 : double.infinity),
              child: PillButton(
                // See _ExperienceStep's own footer — same fix.
                label: hasCertifications == true && entries.isEmpty ? 'Add at least one' : (entries.isEmpty ? 'Skip for now' : 'Continue'),
                variant: entries.isEmpty && hasCertifications != true ? PillVariant.ghost : PillVariant.primary,
                disabled: hasCertifications == true && entries.isEmpty,
                onPressed: onContinue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SkillsStep extends StatelessWidget {
  final List<String> skills;
  final List<String> suggestions;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final ValueChanged<String> onAddSuggestion;
  final ValueChanged<String> onRemove;
  final String? error;
  final VoidCallback onContinue;

  const _SkillsStep({
    required this.skills,
    required this.suggestions,
    required this.controller,
    required this.onAdd,
    required this.onAddSuggestion,
    required this.onRemove,
    required this.error,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    // Each pick pulls in its related skills too, so the list grows with
    // relevant suggestions instead of staying static after the first tap.
    final relatedToSelected = skills.expand((s) => _relatedSkills[s] ?? const <String>[]);
    final remainingSuggestions = {...suggestions, ...relatedToSelected}.where((s) => !skills.contains(s)).toList();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  noOrphan("Add your skills"),
                  style: AppTextStyles.h1.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold, height: 1.25),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(noOrphan('Tap to add, or type your own.'), style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
                ),
                if (remainingSuggestions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: remainingSuggestions.map((s) => _SuggestionChip(label: s, onTap: () => onAddSuggestion(s))).toList(),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: PillInput(
                          controller: controller,
                          placeholder: 'Or type your own…',
                          // Every other free-text question in this flow
                          // wires the keyboard's own submit — this one
                          // didn't, so pressing Enter/Done silently did
                          // nothing and only the separate "+" button worked.
                          onSubmitted: (_) => onAdd(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: onAdd,
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
                if (skills.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: skills.map((s) => _RemovableChip(label: s, onTap: () => onRemove(s))).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
          decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: AppBreakpoints.isWide(context) ? 400 : double.infinity),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(error!, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.error)),
                    ),
                  PillButton(label: 'Continue', onPressed: onContinue),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Unselected "tap to add" suggestion chip — offWhite background, bordered,
/// leading + icon. Shared by Skills' and Languages' quick-pick rows so both
/// read as the same interaction: tap it here, watch it move to the
/// removable badge row below instead of just recoloring in place.
class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Ionicons.add, size: 14, color: AppColors.blue),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
          ],
        ),
      ),
    );
  }
}

/// Selected, removable badge — white with a 2px brand stroke, trailing × icon. Shared
/// by Skills' and Languages' "what you've added" row below the suggestions.
class _RemovableChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _RemovableChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.blue, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Ionicons.close, size: 14, color: AppColors.blue),
          ],
        ),
      ),
    );
  }
}

/// Quick-pick badges for the handful of languages most students need one
/// tap for, plus a search-suggest field (full mockLanguages list, free text
/// also accepted) for anything else — the same "chip row + type your own"
/// shape Skills already uses, so switching sections doesn't feel like a
/// different app.
class _LanguageStep extends StatelessWidget {
  final List<LanguageEntry> languages;
  final ValueChanged<String> onAddQuick;
  final ValueChanged<String> onAdd;
  final ValueChanged<LanguageEntry> onRemove;
  final String? error;
  final VoidCallback onContinue;

  const _LanguageStep({
    required this.languages,
    required this.onAddQuick,
    required this.onAdd,
    required this.onRemove,
    required this.error,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final selectedNames = languages.map((l) => l.name.toLowerCase()).toSet();
    // Same "drop out of suggestions, reappear as a removable badge below"
    // interaction as Skills' remainingSuggestions — a quick-pick language
    // that's already added has nothing left to do in this row.
    final remainingQuick = _quickLanguages.where((l) => !selectedNames.contains(l.toLowerCase())).toList();
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  noOrphan('Languages you know'),
                  style: AppTextStyles.h1.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold, height: 1.25),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(noOrphan('Tap to add, or search for more.'), style: AppTextStyles.body.copyWith(color: AppColors.gray500)),
                ),
                if (remainingQuick.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: remainingQuick.map((l) => _SuggestionChip(label: l, onTap: () => onAddQuick(l))).toList(),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: AutocompleteField(
                    value: '',
                    placeholder: 'Search any other language…',
                    icon: Ionicons.search_outline,
                    options: mockLanguages,
                    onChanged: (_) {},
                    onSelected: onAdd,
                    onSubmitted: onAdd,
                  ),
                ),
                if (languages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: languages.map((l) => _RemovableChip(label: l.name, onTap: () => onRemove(l))).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
          decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: AppBreakpoints.isWide(context) ? 400 : double.infinity),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(error!, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.error)),
                    ),
                  PillButton(label: 'Continue', onPressed: onContinue),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Last content step: a 2–3 sentence professional summary — the section
/// most resume guidance calls the highest-leverage part of the page, and
/// the one this builder had no equivalent of at all before. Offers a
/// generated starting point instead of a blank box, since that's the
/// biggest reason people skip writing one.
class _SummaryStep extends StatelessWidget {
  final TextEditingController controller;
  // 'Tap to autofill' or 'Regenerate' — computed by the parent from
  // whether the field still holds what the button last generated (see
  // _useSuggestedSummary), not decided in here.
  final String label;
  final VoidCallback onUseSuggestion;
  final ValueChanged<String> onChanged;
  final String? error;
  final VoidCallback onContinue;

  const _SummaryStep({
    required this.controller,
    required this.label,
    required this.onUseSuggestion,
    required this.onChanged,
    required this.error,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  noOrphan('Introduce yourself'),
                  style: AppTextStyles.h1.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.semibold, height: 1.25),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    noOrphan("Recruiters read this first — keep it short."),
                    style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.offWhite,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      maxLines: 5,
                      minLines: 5,
                      maxLength: 600,
                      style: AppTextStyles.bodyLg.copyWith(fontSize: 16, color: AppColors.ink, height: 1.4),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(AppSpacing.lg),
                        hintText: "e.g. B.Tech student at XYZ College with hands-on skills in Python, SQL, and Excel, driven to deliver real, measurable impact.",
                        hintStyle: AppTextStyles.body.copyWith(color: AppColors.gray400, height: 1.4),
                        border: InputBorder.none,
                        counterStyle: AppTextStyles.caption.copyWith(color: AppColors.gray400),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: GestureDetector(
                    onTap: onUseSuggestion,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        // A border is what separates this from a plain static
                        // tag — without one it read as an inert label instead
                        // of a button, so tapping it felt like an accident
                        // discovery rather than an obvious action.
                        border: Border.all(color: AppColors.blue, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Note: Ionicons in this bundled font version has no "sparkles"
                          // glyph — flash_outline is the established substitute elsewhere
                          // in this app (see value_slides_screen.dart's AI-Powered badge).
                          // Swaps to refresh_outline in the Regenerate state — this app's
                          // own established "do it again" glyph (see the Restore button
                          // on recently_deleted_applications_screen.dart), so the icon
                          // itself signals "do it again," not just the label text.
                          Icon(label == 'Regenerate' ? Ionicons.refresh_outline : Ionicons.flash_outline, size: 14, color: AppColors.blue),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            label,
                            style: AppTextStyles.label.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
          decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: AppBreakpoints.isWide(context) ? 400 : double.infinity),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(error!, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.error)),
                    ),
                  PillButton(label: 'Build my resume', onPressed: onContinue),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BuildingView extends StatelessWidget {
  final String stepLabel;
  const _BuildingView({required this.stepLabel});

  @override
  Widget build(BuildContext context) {
    final isTablet = AppBreakpoints.isWide(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.blue,
        body: ResponsiveBody(maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth, child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(color: AppColors.yellow, strokeWidth: 3),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: Text(
                    'Building your resume…',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h3.copyWith(color: AppColors.white, fontWeight: AppFontWeight.medium),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    stepLabel,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: AppColors.whiteA70),
                  ),
                ),
              ],
            ),
          ),
        )),
      ),
    );
  }
}
