import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/adaptive_sheet.dart';

/// Naukri's "Video Profile" — guidelines up front, then Record/Upload,
/// instead of a bare link field. A bottom sheet rather than its own route:
/// it's a single small edit surface reachable only from the Profile
/// screen's "Video profile" row, so pushing a whole page for it was more
/// ceremony than the task needs.
void showVideoProfileSheet(BuildContext context) {
  showAdaptiveSheet(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (sheetContext) => const _VideoProfileSheet(),
  );
}

class _VideoProfileSheet extends StatefulWidget {
  const _VideoProfileSheet();

  @override
  State<_VideoProfileSheet> createState() => _VideoProfileSheetState();
}

class _VideoProfileSheetState extends State<_VideoProfileSheet> {
  String? _videoIntroUrl;
  String? _videoIntroFileName;
  // Hydrated originals, kept separate from the mutable working values —
  // the only way to know whether there's actually something unsaved to
  // warn about before letting the sheet close.
  String? _originalVideoIntroUrl;
  String? _originalVideoIntroFileName;
  bool _hydrated = false;
  bool _loading = false;

  void _hydrate(User user) {
    if (_hydrated) return;
    _videoIntroUrl = user.videoIntroUrl;
    _videoIntroFileName = user.videoIntroFileName;
    _originalVideoIntroUrl = user.videoIntroUrl;
    _originalVideoIntroFileName = user.videoIntroFileName;
    _hydrated = true;
  }

  bool get _hasUnsavedChanges => _videoIntroUrl != _originalVideoIntroUrl || _videoIntroFileName != _originalVideoIntroFileName;

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final file = await ImagePicker().pickVideo(source: source, maxDuration: const Duration(seconds: 90));
      if (file == null) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _videoIntroUrl = file.path;
        _videoIntroFileName = file.name;
      });
    } catch (e) {
      // The null-return above already covers the real "user cancelled"
      // case per image_picker's own contract, so this catch is only ever
      // reached for a genuine failure — permission denied, no camera
      // available, a plugin error. Previously swallowed with zero feedback
      // on this screen's one and only function.
      debugPrint('VideoProfileSheet: pickVideo failed — $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(source == ImageSource.camera
              ? "Couldn't access your camera — try uploading a file instead."
              : "Couldn't open that file — try a different one."),
        ));
    }
  }

  Future<void> _attemptClose() async {
    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: Text('Discard this video?', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.semibold)),
        content: Text("It hasn't been saved yet.", style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Keep editing', style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontWeight: AppFontWeight.medium)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Discard', style: AppTextStyles.body.copyWith(color: AppColors.error, fontWeight: AppFontWeight.bold)),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  void _showVideoSourceSheet() {
    HapticFeedback.selectionClick();
    showAdaptiveSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Ionicons.videocam_outline, color: AppColors.blue),
              title: Text('Record a video', style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 16)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickVideo(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Ionicons.cloud_upload_outline, color: AppColors.blue),
              title: Text('Upload a video', style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 16)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickVideo(ImageSource.gallery);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _removeVideo() {
    HapticFeedback.selectionClick();
    setState(() {
      _videoIntroUrl = null;
      _videoIntroFileName = null;
    });
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final appState = context.read<AppState>();
      // Full reconstruction (not copyWith) — this sheet needs to clear
      // these fields back to null on "Remove", which copyWith's
      // merge-on-null semantics can't express.
      await appState.updateProfile((current) => User(
            id: current.id,
            identifier: current.identifier,
            name: current.name,
            city: current.city,
            segment: current.segment,
            currentClass: current.currentClass,
            board: current.board,
            college: current.college,
            course: current.course,
            semester: current.semester,
            fieldOfStudy: current.fieldOfStudy,
            goal: current.goal,
            roles: current.roles,
            photoUrl: current.photoUrl,
            resume: current.resume,
            aptitudeResults: current.aptitudeResults,
            preferences: current.preferences,
            languages: current.languages,
            itSkills: current.itSkills,
            videoIntroUrl: _videoIntroUrl,
            videoIntroFileName: _videoIntroFileName,
            differentlyAbled: current.differentlyAbled,
            differentlyAbledDetails: current.differentlyAbledDetails,
            onboardingComplete: current.onboardingComplete,
            aptitudeSkipped: current.aptitudeSkipped,
          ));
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      // Resolve the messenger before popping — same reasoning as the apply
      // flow's success sheet: this widget's own context is on its way out
      // once the sheet closes, so grab what we need from it first.
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Video profile saved.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _tips = [
    'Under 90 seconds, please.',
    'Good lighting and clear audio help.',
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    if (user == null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("You're signed out", style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 18, fontWeight: AppFontWeight.semibold)),
              const SizedBox(height: AppSpacing.sm),
              Text('Sign back in to edit your profile.', style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 12)),
              const SizedBox(height: AppSpacing.lg),
              PillButton(
                label: 'Sign in',
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/onboarding');
                },
              ),
            ],
          ),
        ),
      );
    }
    _hydrate(user);

    return PopScope(
      // A recorded/attached video previously vanished with zero warning
      // on any dismissal other than "Save changes" — tapping the scrim,
      // dragging the sheet down, or the "X" all popped it instantly. Now
      // only a genuinely unchanged sheet can close without a prompt.
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _attemptClose();
      },
      child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Container(
                width: AppSpacing.xxl,
                height: AppSpacing.xs,
                decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.lg, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Video profile', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 18, fontWeight: AppFontWeight.semibold)),
                  GestureDetector(
                    onTap: _attemptClose,
                    child: const Icon(Ionicons.close, size: 24, color: AppColors.gray400),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
                children: [
                  if (_videoIntroUrl != null)
                    _VideoAttachedCard(fileName: _videoIntroFileName ?? 'Video profile', onChange: _showVideoSourceSheet, onRemove: _removeVideo)
                  else
                    _VideoGuidelinesCard(tips: _tips, onTap: _showVideoSourceSheet),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, bottomInset + AppSpacing.md),
              child: PillButton(label: 'Save changes', onPressed: _save, loading: _loading),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _VideoGuidelinesCard extends StatelessWidget {
  final List<String> tips;
  final VoidCallback onTap;
  const _VideoGuidelinesCard({required this.tips, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Ionicons.videocam, size: 20, color: AppColors.gray500),
              const SizedBox(width: AppSpacing.sm),
              Text('Add a video profile', style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: tips
                  .map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.sm),
                              child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.gray400, shape: BoxShape.circle)),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: Text(noOrphan(t), style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 12, height: 1.3))),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: PillButton(label: 'Record or upload', icon: Ionicons.add_circle_outline, variant: PillVariant.secondary, compact: true, full: false, onPressed: onTap),
          ),
        ],
      ),
    );
  }
}

class _VideoAttachedCard extends StatelessWidget {
  final String fileName;
  final VoidCallback onChange;
  final VoidCallback onRemove;
  const _VideoAttachedCard({required this.fileName, required this.onChange, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      // Concentric with the inner icon box's own AppRadius.md corner
      // sitting AppSpacing.lg inside it, not an unrelated token.
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.md + AppSpacing.lg), boxShadow: AppShadows.card),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.blueA10, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: const Icon(Ionicons.play, size: 20, color: AppColors.blue),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.semibold)),
                const SizedBox(height: AppSpacing.xs),
                GestureDetector(
                  onTap: onChange,
                  child: Text('Change', style: AppTextStyles.caption.copyWith(color: AppColors.blue, fontSize: 12, fontWeight: AppFontWeight.medium)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.xs),
              child: Icon(Ionicons.trash_outline, size: 18, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
