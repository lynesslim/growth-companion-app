# Dashboard Redesign Implementation Plan

## Goal
Execute a premium, highly polished iOS-style redesign of the Home Screen (Dashboard) based on the provided UI prompt and reference image. The design features a warm ivory background, pastel gradients, bold typography mixed with elegant italic serifs, floating layered cards, and subtle 3D elements.

**CRITICAL NOTE FOR IMPLEMENTING AI**: You do not have access to the reference image. Follow the explicit widget structures (Stack, Row, Column, Positioned) defined below to ensure the layout matches the visual design exactly.

---

## Phase 1: Global Setup & Background
**Target Files**: `lib/src/core/app_colors.dart`, `lib/src/features/home/home_screen.dart`

**Instructions**:
1. **App Colors Update**:
   - Add the new background colors: `baseBackground` (`#FCFAF7`), `secondarySurface` (`#FFFDF9`).
2. **Screen Background**:
   - In `home_screen.dart`, update the main `Scaffold` or `CustomScrollView` background to use `baseBackground`.
   - **Layout**: Implement the "subtle ambient gradient" behind the upper section by wrapping the scroll view in a `Stack`, and placing a `Positioned` container at the top containing a `RadialGradient` (Top-left: `#FFF5E8`, Top-right: `#FDEFF6`, Center: `#FFFDF9`). Make sure it is purely for background warmth and ignores pointer events.

---

## Phase 2: Hero Header & Stats Row
**Target File**: `lib/src/features/home/widgets/home_header.dart`

**Instructions**:
1. **Header Layout Structure**:
   - Use a `Row` with `crossAxisAlignment: CrossAxisAlignment.start`.
   - The left side must be an `Expanded(child: Column(...))` for the Greeting and Headline.
   - The right side must be a `Column` for the Avatar and Streak Pill.
2. **Left Side (Greeting & Headline)**:
   - **Greeting**: "Good morning, [Name] 👋" in 15px, `#6E6A67`.
   - **Main Headline**: Two `Text` widgets in the column. 
     - "Your growth" (Bold Sans-serif, 38-42px, `#111111`, letter-spacing: -1.2px).
     - "starts today." (Playfair Display Italic, 40-44px, 500 weight). Wrap this text in a `ShaderMask` with a `LinearGradient` (`#F36A21` -> `#E6819E` -> `#B64FD2`).
3. **Right Side (Profile & Streak)**:
   - **Avatar**: 58-64px circle with a radial gradient (`#FFF0B8` -> `#FFD6C4` -> `#F7B6D4`). Center the user's initial (28px). Use a `Stack` to add a green online dot (`#39C96B`, white border) positioned at `bottom: 0, right: 0`.
   - **Streak Pill**: Place directly below the avatar. White background, 20px radius, soft shadow, text: "🔥 [X] days" (14px, 600 weight, `#E75B1B`).
4. **Growth Statistics Row (NEW Widget)**:
   - Create a horizontal `Row` of 4 small cards below the headline with 12-14px gaps.
   - **Inside Each Card (Layout)**: Use a `Column` with `crossAxisAlignment: CrossAxisAlignment.start`. Place the icon container at the top, a `Spacer()`, the large Statistic, and the Label at the bottom.
   - **Card Style**: Background `rgba(255,255,255, 0.72)`, border 1px white, 26px radius, light internal glow, subtle shadow. Height: 145px.
   - **Card Data**:
     1. Books Read (Icon Color: `#7C5CFF`, Bg: `#EEE8FF`)
     2. Minutes Today (Icon Color: `#F6B91C`, Bg: `#FFF5D8`)
     3. Streak Days (Icon Color: `#EC4F8C`, Bg: `#FFE7F1`)
     4. Growth Score (Icon Color: `#48B96A`, Bg: `#E9F8ED`)

---

## Phase 3: Today's Growth Drop Card
**Target File**: `lib/src/features/home/widgets/growth_drop_card.dart`

**Instructions**:
1. **Card Container (The Base)**:
   - High margin (24px horizontal), 34-38px radius, height ~540px.
   - **Gradient Background**: Blended pastel gradient (`#FFE0AE` -> `#FFDCCB` -> `#F7C5D8` -> `#F2D6EF`). Heavy shadow: `0 24px 50px rgba(96, 60, 45, 0.14)`.
   - **CRITICAL LAYOUT**: The entire card contents must be wrapped in a `Stack` to allow the AI Spark Button and 3D Book to float absolutely.
2. **Floating Elements (Positioned in Stack)**:
   - **AI Spark Button**: `Positioned(top: 28, right: 28)`. 48px circle, white 88% opacity, purple sparkle icon (`#8F45F5`).
   - **3D Book Visual (Right Side)**:
   - `Positioned(bottom: 28, right: -20)` (allow it to bleed off slightly). Add a `Transform` for slight 3D rotation (`rotateY(-0.1)`). Add a soft pink drop shadow underneath it.
   - Use `Image.asset('assets/images/book_mockup.png')` for the book image. Since the image has a white background, apply `colorBlendMode: BlendMode.multiply` to seamlessly blend it into the gradient card.
3. **Card Content (Positioned in Stack, Left Side)**:
   - `Positioned(left: 28, top: 28, bottom: 28, right: 150)`. This forces the text content to stay on the left half of the card, preventing overlap with the book.
   - Inside, use a `Column` with `crossAxisAlignment: CrossAxisAlignment.start`:
     - **Label**: "✦ TODAY'S GROWTH DROP" (`#E46C22`, 12px, 600 wt).
     - **Title**: "Atomic Habits" (30-34px, Bold, `#111111`).
     - **Category Pill**: "🎯 Habit Building", white 76% opacity, `#E06419` text.
     - **Description**: 16px, `#66615E`, max width 48% of card.
     - `Spacer()` to push the button down.
     - **Primary CTA Button**: `#2E2623` background, 60px height. Layout: `Row` with "Start Reading" on the left, and the Arrow Icon inside a semi-transparent white circle (`0.12` alpha) on the right.
     - **Social Proof**: `Row` of 3 overlapping circular friend avatars (use `Transform.translate` to overlap), followed by "12 friends read this" (13px, `#766F6B`).

---

## Phase 4: Friend Gift Cards
**Target File**: `lib/src/features/home/widgets/social_drops_card.dart`

**Instructions**:
1. **Section Header**:
   - `Row(mainAxisAlignment: MainAxisAlignment.spaceBetween)`.
   - Left: "From your friends" (18px, Bold, `#111111`). Right: "See all ›" Pill (white 80% opacity, 18px radius).
2. **Horizontally Scrollable Row**:
   - `SizedBox(height: 240)` containing a `ListView.builder(scrollDirection: Axis.horizontal)`. Use `PageScrollPhysics` or `BouncingScrollPhysics` for slight snapping.
3. **Card Design & Layout**:
   - Width: ~46% of screen.
   - **CRITICAL LAYOUT**: Use a `Stack` inside the card.
   - **Backgrounds**: Purple Card Mode (`#EEE6FF` -> `#B59CFF`) vs Yellow Card Mode (`#FFF3BF` -> `#FFD75E`).
   - **Text Content**: Wrap in `Positioned(left: 18, top: 18, bottom: 18)`. Use a `Column(crossAxisAlignment: start)`:
     - `Row` with Friend avatar + "A gift from [Name]".
     - `Spacer()`
     - Book Title + "by [Author]".
     - "New drop" Badge (semi-transparent white background).
   - **3D Gift Box Visual**: `Positioned(bottom: -10, right: -10)`. Use `Image.asset('assets/images/purple_gift.png')` for the purple card, and `Image.asset('assets/images/yellow_gift.png')` for the yellow card. Use `BlendMode.multiply` to blend the white backgrounds out.

---

## Phase 5: Floating Bottom Navigation
**Target File**: `lib/src/features/dashboard/dashboard_shell.dart`

**Instructions**:
1. **Nav Container**:
   - Verify it uses iOS 26 layout (inset capsule, frosted glass).
   - Background is `rgba(255, 255, 255, 0.82)` with a 24-30px backdrop blur.
2. **Active Tab Indicator Layout**:
   - The active tab must have a white raised capsule background (`rgba(255, 255, 255, 0.90)`).
   - Layout inside active tab: `Column(mainAxisSize: min)` with the Icon, Text (`#F06A19`), and a tiny orange dot (4px, `#F06A19`) below the label.
3. **Inactive Tabs**: Icon/Text color `#494542`.

---

## Phase 6: Typography System & Extra Sections
**Target Files**: `lib/src/core/app_typography.dart`, `lib/src/features/home/home_screen.dart`

**Instructions**:
1. **Typography System**:
   - Primary UI font: `Inter` or `SF Pro`. Editorial accent font: `Playfair Display Italic`.
   - Ensure sizes match specs: Hero headline (40-44px), Feature title (30-34px), Section title (18px), Card title (24-28px), Body (15-16px), Button (16px), Labels (12-14px).
2. **"Continue Your Journey" Section**:
   - Add below the Friend Gift Cards. Heading: "Continue your journey" (18px, Bold, `#111111`). Add a partially visible dummy card underneath it so it looks intentionally cropped by the floating bottom nav.

---

## Phase 7: Motion, Interaction, and Animation
**Target Files**: `lib/src/features/home/home_screen.dart` and related widgets

**Instructions**:
1. **Screen Entrance Animations**:
   - Animate elements in order: Greeting/Avatar -> Headline -> Stats cards -> Growth Drop -> Friend cards.
   - Animation properties: Opacity 0 -> 1, Translate Y 12px -> 0. Duration: 280-360ms, Stagger: 45-60ms, Curve: `easeOutCubic`.
2. **Growth Drop Card Interactions**:
   - On Press: Scale down to `0.985` over 100ms. Apply `HapticFeedback.lightImpact()`. The 3D Book Visual should move upward by 3-4px simultaneously.
3. **Primary CTA Interaction**:
   - On Press: Scale down to `0.97` over 90ms. The arrow circle inside the button should slide 3px to the right.
4. **Friend Gift Cards Interaction**:
   - On Press: Scale down to `0.98`, Gift box rotates `0°` -> `-3°` over 120ms.
5. **Bottom Navigation Indicator**:
   - The active pill indicator must slide smoothly between tabs over 260ms with an `easeOutCubic` curve. **Do NOT** use Android Material ripple effects (disable them globally).
