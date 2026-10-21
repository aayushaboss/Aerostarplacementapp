# Spacing system — 8pt grid

This app's spacing is governed by one file: [`lib/theme/spacing.dart`](lib/theme/spacing.dart). Every padding, margin, and gap in the codebase should reference `AppSpacing`, never a raw number.

## The scale

| Token | Value | Use for |
|---|---|---|
| `AppSpacing.xs` | 4px | Hairline nudges only — a 2-4px optical adjustment under a label/baseline, a tiny icon-to-text gap. The one half-step off the strict grid; anything smaller than this genuinely doesn't need its own token. |
| `AppSpacing.sm` | 8px | Gap between **closely-related items** — a title and its subtitle directly beneath it, an icon and the label next to it, chip/pill internal padding. |
| `AppSpacing.md` | 16px | Gap between **distinct elements within one block** — two stacked cards' fields, a form field's own internal padding, the space before a Continue button. |
| `AppSpacing.lg` | 24px | Gap between **sub-sections** — a card's outer padding, the space between a section heading and its content. |
| `AppSpacing.xl` | 32px | A screen's **outer horizontal margin** (the standard left/right inset almost every screen uses), and the gap **between major sections** on a scrolling page. |
| `AppSpacing.xxl` | 48px | Larger hero/banner spacing — rare, used where a screen needs a bigger visual break than `xl` gives (e.g. stacked with other tokens for a bottom safe-area clearance above a fixed action bar). |
| `AppSpacing.xxxl` | 64px | The largest step — bottom-of-scroll clearance above a page, a hero section's own top/bottom breathing room. |

**Radii are separate and unaffected** — `AppRadius` (same file) still uses its own scale (`sm`/`md`/`lg`/`xl`/`pill`) and was **not** part of this pass; corner radius, icon sizes, avatar/card dimensions, font sizes, shadow blur, and animation durations are deliberately out of scope for the spacing grid (see "What this doesn't cover" below).

## Vertical-rhythm convention

When placing a gap between two things, ask what relationship they have:

1. **Same idea, two lines** (title + subtitle, label + value) → `sm`
2. **Different fields in one block** (icon + label, two rows in a card) → `md`
3. **Different blocks in one section** (a card's outer padding, heading → content) → `lg`
4. **Different sections on a screen** → `xl`
5. **Screen-level breathing room** (top-of-hero, bottom-of-scroll clearance) → `xxl` / `xxxl`

This isn't enforced by the compiler — it's a convention to keep new spacing decisions consistent with what's already in the app. When in doubt, look at a sibling screen doing the same kind of layout and match its token, not its pixel value.

## Composing values

Some places need a value that isn't a single token — a safe-area inset plus a fixed clearance, for example. Compose it from tokens rather than writing a raw number:

```dart
// A bottom-bar clearance of 120px, composed from tokens:
padding: EdgeInsets.only(bottom: AppSpacing.xxxl + AppSpacing.xxl + AppSpacing.sm + bottomInset),
```

If no combination of tokens lands close enough to what a design needs, that's a signal the design itself should be revisited to fit the grid — not a reason to fall back to a raw number.

## Fixed-size components: watch for overflow

A handful of cards/lanes in this app use a **fixed height** so that several cards line up identically in a horizontal-scrolling row (e.g. `OpportunityCarouselCard`, `_CourseCard`). Because their *internal* padding comes from `AppSpacing`, whenever the scale itself changes, those fixed heights need to be re-derived — a bigger token value inside a container whose outer size didn't grow to match will overflow (Flutter's yellow/black overflow stripes, or a "RenderFlex overflowed by Npx" console error).

If you ever need to change `AppSpacing`'s values again, grep for `height: ` near `AppSpacing`/`AppShadows.cardBuffer` usage and re-check each fixed-size card's content still fits — don't just trust that a token-level change is risk-free everywhere.

## What this doesn't cover

Per the scope agreed for this pass, the following are **not** tokenized here and may still contain literal numbers — this is intentional, not an oversight:
- Icon sizes (`Icon(..., size: 18)`)
- Avatar/circle/card fixed dimensions (`width: 44`, `height: 262`)
- Corner radii (`AppRadius`, unchanged)
- Font sizes (`AppTextStyles`, unchanged)
- Shadow blur/offset (`AppShadows`, unchanged)
- Animation durations
- `lib/services/resume_pdf.dart` and `lib/services/career_dna_report_pdf.dart` — PDF export uses print points, a different medium with its own already-established layout constants; not part of the on-screen UI grid.
- `lib/screens/dev/style_guide_screen.dart` — dev-only reference screen, never ships in a release build.

## Responsive breakpoints

Mobile+tablet only (no web/desktop target). [`lib/theme/breakpoints.dart`](lib/theme/breakpoints.dart) defines two tiers:

| Tier | Width |
|---|---|
| `AppBreakpoint.mobile` | < 600px |
| `AppBreakpoint.tablet` | >= 600px |

This app is phone-first — built and pixel-checked at ~375px, with [`ResponsiveBody`](lib/widgets/responsive_body.dart) capping wider screens at a comfortable reading width (`AppBreakpoints.maxContentWidth`, 520px, or a wider per-screen `maxWidth`) rather than stretching a phone-tuned layout edge-to-edge. `AppBreakpoints.spacing(context, base)` and `AppBreakpoints.fontSize(context, base)` give a gentle upscale (spacing +50%, font +15% at tablet) for the handful of screens that already branch on width (the 1-vs-2-column screens: Applications, Saved, Courses search results, Opportunity list). These helpers are additive — not retrofitted across every screen in the app, which would be a much larger layout redesign than this pass covered.

## Adding a new spacing value

Don't. If none of the seven tokens fit, compose two of them (see above) before reaching for a new constant. A spacing system with 20 near-duplicate values isn't a system.
