# iOS 26 Design Compliance Plan

## The Goal
Update the app's UI to comply with the official iOS 26 design guidelines, specifically implementing the "Liquid Glass" material and correct scroll edge effects for both the top and bottom navigation bars.

## Phase 1: Tab Bar (Bottom Nav)
**Target File**: `lib/src/features/dashboard/dashboard_shell.dart`

**Instructions for DeepSeek**:
1. **Apply Liquid Glass Material**: 
   - Locate the `Container` inside `_FloatingBottomNav`.
   - Wrap it with a `ClipRRect(borderRadius: BorderRadius.circular(34))`.
   - Inside the `ClipRRect`, wrap the `Container` with a `BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20))`.
   - Change the `Container`'s `color` from solid `AppColors.white` to `AppColors.white.withValues(alpha: 0.75)` to allow the blur to show through.
2. **Update Insets & Font Metrics**:
   - Change the margin of the Tab Bar to `EdgeInsets.only(left: 21, right: 21, bottom: 21)` to match the iOS 26 capsule standard.
   - In `_NavItem`, change the `fontSize` of the Text label from `10` to `11`.
3. **Add Scroll Edge Fade Effect**:
   - iOS 26 requires content scrolling behind the tab bar to fade out smoothly at the bottom edge.
   - In `_DashboardShellState`, wrap `widget.navigationShell` inside a `ShaderMask`.
   - Apply a vertical `LinearGradient`. The top 85% of the screen should be fully opaque (`Colors.black`), smoothly fading to transparent (`Colors.transparent`) at the bottom 15% to mask the list behind the tab bar.

## Phase 2: Nav Bar (Top Header)
**Target Files**: `lib/src/features/home/home_screen.dart` (and potentially `journal_screen.dart`, `social_screen.dart`, `profile_screen.dart`)

**Instructions for DeepSeek**:
1. **Floating Controls & Collapsing Titles**: 
   - Currently, headers like `HomeHeader` are placed inside a `SingleChildScrollView` and scroll entirely off-screen.
   - Refactor the page layouts to use `CustomScrollView` with Slivers instead.
   - Use `SliverAppBar` with `pinned: true` to keep the top navigation fixed while content scrolls beneath it.
   - Use `FlexibleSpaceBar` to implement the iOS 26 large-to-small title collapsing behavior.
2. **Top Liquid Glass**:
   - Set the `SliverAppBar`'s background to use a similar `ClipRRect` and `BackdropFilter` as the bottom tab bar.
   - The background color should be highly translucent (e.g., `AppColors.white.withValues(alpha: 0.6)`) to ensure the page content blurs beautifully as it passes under the top header.

## Phase 3: Global Typography
**Target File**: `lib/src/core/app_typography.dart` (and `app_theme.dart` for buttons)

**Instructions for DeepSeek**:
1. **Update Base Font Sizes**:
   - The app currently uses sizes that are exactly 1pt smaller than standard iOS native apps.
   - Update `bodyLarge` `fontSize` from `16` to `17`.
   - Update `bodyMedium` `fontSize` from `14` to `15`.
   - Update `bodySmall` `fontSize` from `12` to `13`.
2. **Update Button Font Sizes**:
   - In `app_theme.dart`, locate the `elevatedButtonTheme`.
   - Ensure the `textStyle` uses a `fontSize` of `17` instead of `16` to match the iOS 17pt standard for primary actions.
