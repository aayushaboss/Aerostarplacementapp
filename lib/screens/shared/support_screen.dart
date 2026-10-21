import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../mockData/mock_support.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/shadows.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../utils/no_orphan.dart';
import '../../widgets/app_chip.dart';
import '../../widgets/app_page.dart';
import '../../widgets/back_chevron.dart';
import '../../widgets/responsive_body.dart';

/// FAQ + contact screen, reached from Profile → Support & Help. Mirrors the
/// mobile Naukri/Internshala pattern — a category-filtered, expandable FAQ
/// list plus a short contact block below, rather than a full desktop-style
/// help center with a page per question.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String? _activeCategoryId;
  final Set<String> _expandedQuestions = {};

  void _selectCategory(String? id) {
    HapticFeedback.selectionClick();
    setState(() => _activeCategoryId = id);
  }

  void _toggleExpanded(String question) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expandedQuestions.contains(question)) {
        _expandedQuestions.remove(question);
      } else {
        _expandedQuestions.add(question);
      }
    });
  }

  void _showStub(String label) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label — coming soon.')));
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final faqs = mockFaqs.where((f) => _activeCategoryId == null || f.categoryId == _activeCategoryId).toList();
    final isTablet = AppBreakpoints.isWide(context);

    if (isTablet) {
      BoxDecoration cardDecoration() => BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: AppColors.border));
      final faqCard = Container(
        decoration: cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < faqs.length; i++)
              _FaqTile(item: faqs[i], expanded: _expandedQuestions.contains(faqs[i].question), isLast: i == faqs.length - 1, onTap: () => _toggleExpanded(faqs[i].question)),
          ],
        ),
      );
      final contactCard = Container(
        decoration: cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: Text('Still need help?', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.medium)),
            ),
            const Divider(height: 1, color: AppColors.border),
            _ContactRow(icon: Ionicons.mail_outline, label: 'Email us', subtitle: 'support@aerostaredge.com', isLast: false, onTap: () => _showStub('Email us')),
            _ContactRow(icon: Ionicons.chatbubble_ellipses_outline, label: 'Chat with us', subtitle: 'Typically replies in a few minutes', isLast: false, onTap: () => _showStub('Chat with us')),
            _ContactRow(icon: Ionicons.document_text_outline, label: 'Raise a ticket', subtitle: 'Track a support request', isLast: true, onTap: () => _showStub('Raise a ticket')),
          ],
        ),
      );
      // One row on the web: it scrolls sideways if a narrow window can't fit every category.
      final chips = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            AppChip(label: 'All', selected: _activeCategoryId == null, onPressed: () => _selectCategory(null)),
            for (final c in mockFaqCategories) ...[const SizedBox(width: AppSpacing.sm), AppChip(label: c.label, selected: _activeCategoryId == c.id, onPressed: () => _selectCategory(c.id))],
          ],
        ),
      );
      final main = faqCard;
      return AppPage(
        backLabel: 'Profile',
        backFallback: '/tabs/profile',
        title: 'Support & Help',
        subtitle: "We're here to help with anything on Aerostar Edge.",
        scroll: AppBreakpoints.isExpanded(context) ? false : true,
        body: AppBreakpoints.isExpanded(context)
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [chips, const SizedBox(height: AppSpacing.lg), Expanded(child: TwoPane(main: main, side: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [contactCard, Padding(padding: const EdgeInsets.only(top: AppSpacing.lg), child: Center(child: Text('Aerostar Edge • v1.0.0', style: AppTextStyles.caption.copyWith(color: AppColors.gray400))))])))])
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [chips, const SizedBox(height: AppSpacing.lg), main, const SizedBox(height: AppSpacing.xl), contactCard]),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: ResponsiveBody(maxWidth: isTablet ? 1224 : AppBreakpoints.maxContentWidth, child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Plain white header, matching this screen's actual peers —
          // saved_screen.dart / recently_deleted_applications_screen.dart,
          // both reached from the same Profile-tab entry point with the
          // same list-of-items shape — instead of the blue "hub" header
          // this screen used to copy from bigger primary features
          // (resume_screen.dart/results_screen.dart), which read as
          // disproportionately large for what this page actually is.
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, topInset + AppSpacing.sm, AppSpacing.xl, 0),
            child: BackChevron(color: AppColors.ink, fallbackRoute: '/tabs/profile'),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Support & Help', textAlign: TextAlign.left, style: AppTextStyles.h1.copyWith(color: AppColors.ink)),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
                  child: Text(
                    "We're here to help with anything on Aerostar Edge.",
                    textAlign: TextAlign.left,
                    style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxxl),
                children: [
                  // One horizontally-scrolling row rather than a Wrap — the 5
                  // category labels wrapped to ~3 rows on a phone. Same
                  // ListView.separated(horizontal) shape the school home
                  // screen's cluster chips already use.
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: mockFaqCategories.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return AppChip(label: 'All', selected: _activeCategoryId == null, onPressed: () => _selectCategory(null));
                        }
                        final c = mockFaqCategories[i - 1];
                        return AppChip(label: c.label, selected: _activeCategoryId == c.id, onPressed: () => _selectCategory(c.id));
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // One shared card (radius + soft shadow) around every FAQ
                  // row, with plain dividers between them — the same
                  // "grouped card, not N floating cards" shape the contact
                  // block below already uses, instead of each of the 14
                  // FAQs carrying its own AppShadows.card + radius, which
                  // is what actually read as cluttered.
                  if (faqs.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.soft),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (var i = 0; i < faqs.length; i++)
                            _FaqTile(
                              item: faqs[i],
                              expanded: _expandedQuestions.contains(faqs[i].question),
                              isLast: i == faqs.length - 1,
                              onTap: () => _toggleExpanded(faqs[i].question),
                            ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md),
                    child: Text('Still need help?', style: AppTextStyles.h3.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.medium)),
                  ),
                  Container(
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.xl), boxShadow: AppShadows.soft),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _ContactRow(
                          icon: Ionicons.mail_outline,
                          label: 'Email us',
                          subtitle: 'support@aerostaredge.com',
                          isLast: false,
                          // UI only for now — stub pending a real mailto:/
                          // support-ticket integration (same pattern as
                          // booking_confirmed_screen.dart's
                          // _showCalendarSheet options).
                          onTap: () => _showStub('Email us'),
                        ),
                        _ContactRow(
                          icon: Ionicons.chatbubble_ellipses_outline,
                          label: 'Chat with us',
                          subtitle: 'Typically replies in a few minutes',
                          isLast: false,
                          onTap: () => _showStub('Chat with us'),
                        ),
                        _ContactRow(
                          icon: Ionicons.document_text_outline,
                          label: 'Raise a ticket',
                          subtitle: 'Track a support request',
                          isLast: true,
                          onTap: () => _showStub('Raise a ticket'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: Center(
                      child: Text('Aerostar Edge • v1.0.0', style: AppTextStyles.caption.copyWith(color: AppColors.gray400)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )),
      );
  }
}

class _FaqTile extends StatelessWidget {
  final FaqItem item;
  final bool expanded;
  final bool isLast;
  final VoidCallback onTap;
  const _FaqTile({required this.item, required this.expanded, required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // No own margin/decoration/shadow/radius — this now sits inside one
    // shared card (see the Container wrapping the whole FAQ list in
    // SupportScreen.build), same "grouped card, divided rows" shape
    // _ContactRow below already uses.
    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      noOrphan(item.question),
                      style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 14, fontWeight: AppFontWeight.medium, height: 1.35),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Ionicons.chevron_down, size: 18, color: AppColors.gray400),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    child: Text(
                      item.answer,
                      style: AppTextStyles.body.copyWith(color: AppColors.gray500, fontSize: 12, height: 1.45),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isLast;
  final VoidCallback onTap;
  const _ContactRow({required this.icon, required this.label, required this.subtitle, required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.blueA10, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: AppColors.blue),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppTextStyles.bodyLg.copyWith(color: AppColors.ink, fontSize: 16, fontWeight: AppFontWeight.medium)),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.gray500, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const Icon(Ionicons.chevron_forward, size: 18, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}
