import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:printing/printing.dart';

import '../models/user.dart';
import '../services/resume_pdf.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'pill_button.dart';

/// Success screen shown once a resume is saved to the profile — shared by
/// the guided quiz builder and the PDF-upload path so "your resume is
/// ready" looks and behaves the same regardless of how it got built.
/// Also the one place a real, downloadable PDF gets generated from
/// whatever's actually been saved.
class ResumeReadyView extends StatefulWidget {
  final User? user;
  final VoidCallback onDone;
  const ResumeReadyView({super.key, required this.user, required this.onDone});

  @override
  State<ResumeReadyView> createState() => _ResumeReadyViewState();
}

class _ResumeReadyViewState extends State<ResumeReadyView> {
  bool _downloading = false;

  String get _name {
    final resumeName = widget.user?.resume?.name.trim();
    if (resumeName != null && resumeName.isNotEmpty) return resumeName;
    final userName = widget.user?.name?.trim();
    return (userName != null && userName.isNotEmpty) ? userName : 'Your';
  }

  Future<void> _download() async {
    final user = widget.user;
    if (user == null || _downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await buildResumePdf(user);
      final safeName = _name.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(RegExp(r'\s+'), '_');
      await Printing.sharePdf(bytes: bytes, filename: '${safeName.isEmpty ? 'resume' : safeName}_resume.pdf');
    } catch (e) {
      debugPrint('Resume PDF generation failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text("Couldn't generate the PDF"),
          action: SnackBarAction(label: 'Retry', textColor: AppColors.brand, onPressed: _download),
          duration: const Duration(seconds: 4),
          // See sessions_screen.dart's own note on `persist`.
          persist: false,
        ));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = '$_name Resume';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle, boxShadow: AppShadows.brand),
                  child: const Icon(Ionicons.checkmark, size: 52, color: AppColors.ink),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Text('Your resume is ready!', style: AppTextStyles.h2.copyWith(color: AppColors.ink, fontSize: 22, fontWeight: AppFontWeight.semibold)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    "Saved to your profile — we'll attach it automatically every time you apply. No re-uploading.",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 14),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.xl),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.soft),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                        child: const Icon(Ionicons.document_text, size: 20, color: AppColors.blue),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body.copyWith(color: AppColors.ink, fontWeight: AppFontWeight.medium)),
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.xs),
                              child: Text('PDF · ready to download', style: AppTextStyles.caption.copyWith(color: AppColors.gray500)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: PillButton(
                    label: 'Download PDF',
                    variant: PillVariant.secondary,
                    icon: Ionicons.download_outline,
                    loading: _downloading,
                    onPressed: widget.user == null ? null : _download,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: PillButton(label: 'Done', onPressed: widget.onDone),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
