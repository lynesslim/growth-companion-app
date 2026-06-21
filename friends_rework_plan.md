# Goal: Rework "Friends & Streaks" Page

This document outlines the extreme detail breakdown of the provided screenshot and the implementation plan to build the gorgeous new "Friends & Streaks" page. 

## Visual Assets Required

Before beginning the implementation, the following visual asset needs to be created and added to the `assets/images/` directory:

1. **`assets/images/3d_friends_illustration.webp`**: The 3D illustration shown on the right side of the highlight card (the two glossy 3D figures, one purple and one pink, with the yellow/purple sparkles above them). Make sure it has a transparent background.

*(Note: Avatar images and emojis can use standard network images / text emojis, so no extra local assets are needed for those).*

---

## Extreme Detail UI Breakdown

### 1. Scaffold & Background
- **Background Color**: Very light off-white/grey (e.g., `#FDFDFD` or `AppColors.scaffoldGrey`).
- **Ambient Glow**: A soft, radial gradient blur at the top right (behind the profile/add friend button) in a light pinkish-purple hue.

### 2. Header Section
- **Title Row**:
  - "Friends" in pure black, heavy sans-serif font (e.g., Inter, bold, ~34px).
  - "& Streaks" in an italic serif font (e.g., Playfair Display), colored with a linear gradient from Peach (`#FF8E8B`) to Lavender (`#9B72CB`).
- **Subtitle**: "Grow better, together. 💜" in mid-grey (`#8A8A8E`), regular weight, ~14px.
- **Top Right Button**: Circular FAB-style button (approx 48x48).
  - **Background**: Vibrant purple gradient (top-left to bottom-right, e.g., `#B088FF` to `#8A4FFF`).
  - **Icon**: White `person_add` icon.
  - **Shadow**: Soft, colored shadow matching the purple.

### 3. Search Bar
- **Shape**: Pill-shaped container (border radius 50).
- **Background**: Pure white (`#FFFFFF`) or very pale grey.
- **Shadow**: Extremely subtle, soft drop shadow (`color: Colors.black.withOpacity(0.03), blurRadius: 10`).
- **Content**: Left-aligned `search` icon (grey), placeholder text "Search by name or email..." (light grey, ~15px).

### 4. "Your closest streaks" Horizontal List
- **Header**: "Your closest streaks" (black, semibold, ~16px) and "View all >" (purple `#7B61FF`, medium, ~14px).
- **Scrollable List Items (Avatars)**:
  - **Avatar Ring**: A beautiful gradient border (thickness ~3px) with a small transparent gap between the border and the image. Gradient goes from Yellow/Orange to Pink/Purple.
  - **Image**: Circular avatar (approx 64x64).
  - **Streak Badge**: Overlaps the bottom center of the avatar. White pill shape, subtle drop shadow, containing a 🔥 emoji and the streak number (black, bold, ~11px).
  - **Name**: Below the avatar, centered (black, semibold, ~13px).
- **"View All" Item**:
  - Circular background matching avatar size. Color: Very pale lavender (`#F2E8FF`).
  - Icon: Purple group/people icon, with purple "12+" text below it inside the circle.
  - Name below: "View all" (black, semibold).

### 5. Highlight Card ("You and Sarah")
- **Container**: Large rounded rectangle (border radius ~24px).
- **Background Gradient**: A soft, milky glassmorphism gradient (diagonal from pale pink/white to pale lavender/peach).
- **Internal Layout**:
  - **Left Avatars**: Overlapping avatars. Back avatar (user) is slightly smaller/faded or just behind. Front avatar (friend) is prominent. A white pill streak badge (🔥 12) overlaps the bottom right.
  - **Text Info**: 
    - "You and Sarah are on a" (black, ~14px).
    - "12-day" (Gradient text matching the header).
    - "streak 🔥" (black).
    - Subtitle: "Keep inspiring each other." (grey, ~13px).
  - **Right Illustration**: The `3d_friends_illustration.webp` asset.
- **Bottom Button**: Full width pill button.
  - **Background**: Purple gradient (`#A88BEB` to `#7B61FF`).
  - **Text**: "Send today's Growth Drop" (white, semibold).
  - **Icon**: Right chevron (`Icons.chevron_right`).

### 6. "All friends" Vertical List
- **Header**: "All friends" (black, semibold, ~16px) and "Sort: Streak (High to Low) v" (grey, ~13px).
- **Container**: The list is housed in a white card with rounded top corners (`borderRadius: BorderRadius.vertical(top: Radius.circular(24))`), extending to the bottom.
- **List Items**:
  - **Avatar**: Circular (approx 48x48).
  - **Small Badge**: A standalone 🔥 emoji overlapping the bottom right of the avatar inside a white circle.
  - **Text Column**:
    - Name: Black, semibold, ~15px.
    - Streak count: "24-day streak" (Purple, ~13px).
    - Status: "Personal best!", "Active today" (Grey, ~13px).
  - **Trailing Widget (Two States)**:
    - *Has Streak*: Pill shape with very pale orange background (`#FFF0E5`). Contains 🔥 and number (black, bold). Followed by a right chevron.
    - *No Streak*: Pill shape with pale purple background (`#F2E8FF`). Purple text "Send drop". Followed by a right chevron.

---

## Proposed Implementation Plan

1. **Asset Integration**: Wait for the user to add `assets/images/3d_friends_illustration.webp`.
2. **Color & Typography Updates**: Add the new gradients (e.g., `AppGradients.streakText`, `AppGradients.avatarRing`) and semantic colors to `app_colors.dart` and `app_gradients.dart`.
3. **Component: Header & Search**: Build the top section with the custom RichText gradient and the pill-shaped search bar.
4. **Component: Closest Streaks**: Create a horizontal `ListView` with a custom `AvatarRing` widget and overlapping badges.
5. **Component: Highlight Card**: Build the soft gradient card with overlapping avatars, gradient text, the 3D asset, and the gradient CTA button.
6. **Component: All Friends List**: Build the vertical list with the unified white background, customized list tiles, and varying trailing badges based on streak status.
7. **Animation Integration**: Apply the `EntranceFadeSlide` staggering to these new components (200ms cascade) to match the dashboard.

## Open Questions for User
- Should the search bar actually filter the list below it, or is it just visual for now?
- For the overlapping avatars in the highlight card, does the current user data provide your own avatar URL, or should we use a local placeholder?
