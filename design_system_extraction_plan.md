# Extract Dashboard Design System

This plan outlines the extraction of hardcoded colors, typography, and gradients from the dashboard into centralized files so they can be reused across the app.

## Proposed Changes

### Core (Design System Files)

#### [MODIFY] `lib/src/core/app_colors.dart`
Add dashboard specific colors:
- Background: `Color(0xFFF9F9F9)` -> `AppColors.scaffoldGrey`
- Text Colors:
  - `Color(0xFF111111)` -> `AppColors.textPrimary`
  - `Color(0xFF494542)` -> `AppColors.textSecondary`
  - `Color(0xFF5E5956)` -> `AppColors.textTertiary`
  - `Color(0xFF8A8582)` -> `AppColors.textQuaternary`
- Accents:
  - `Color(0xFFE75B1B)`, `Color(0xFFE46C22)`, `Color(0xFFE06419)` -> `AppColors.orangeAccent` series
  - `Color(0xFF8F45F5)` -> `AppColors.purpleAccent`
  - `Color(0xFFD4A857)` -> `AppColors.goldAccent`
- Dark Surfaces:
  - `Color(0xFF2E2623)` -> `AppColors.darkSurface`
  - `Color(0xFF1E1816)` -> `AppColors.darkSurfaceVariant`

#### [NEW] `lib/src/core/app_typography.dart`
Extract `GoogleFonts` usages into reusable styles:
- `AppTypography.h1Playfair`: For titles like "Ready for today's drop?"
- `AppTypography.h2Inter`: For headers like "From your friends"
- `AppTypography.bodyInter`: For standard text
- `AppTypography.captionInter`: For small labels and tags

#### [NEW] `lib/src/core/app_gradients.dart`
Extract dashboard gradients:
- `growthDropCardBg`: `[Color(0xFFFFE8D6), Color(0xFFFFF1EB), Color(0xFFFDE8F1), Color(0xFFF3E5F5)]`
- `headerNameGradient`: `[Color(0xFFF36A21), Color(0xFFE6819E), Color(0xFFB64FD2)]`
- `headerPremiumGradient`: `[Color(0xFFFFF0B8), Color(0xFFFFD6C4), Color(0xFFF7B6D4)]`
- `socialDropPurple`, `socialDropYellow`, `socialDropPeach`, `socialDropLavender`

---

### Features (Refactoring)

#### [MODIFY] `lib/src/features/home/home_screen.dart`
- Replace `Color(0xFFF9F9F9)` with `AppColors.scaffoldGrey`
- Replace `GoogleFonts.playfairDisplay(...)` with `AppTypography.h1Playfair.copyWith(...)`

#### [MODIFY] `lib/src/features/home/widgets/growth_drop_card.dart`
- Replace hardcoded colors with `AppColors` tokens
- Replace `LinearGradient` arrays with `AppGradients` properties
- Replace `GoogleFonts.inter` with `AppTypography` constants

#### [MODIFY] `lib/src/features/home/widgets/social_drops_card.dart`
- Replace hardcoded colors with `AppColors`
- Replace hardcoded gradients with `AppGradients`

#### [MODIFY] `lib/src/features/home/widgets/home_header.dart`
- Replace text colors and gradient definitions with centralized design system tokens.

#### [MODIFY] All Other Feature Screens (`lib/src/features/`)
- Audit all other screens (e.g., Profile, Social, Books, Journal) for hardcoded `Color(...)`, `LinearGradient(...)`, and `GoogleFonts(...)` usages.
- Replace these hardcoded styles globally with the newly extracted `AppColors`, `AppGradients`, and `AppTypography` tokens to ensure complete design consistency across the app.
