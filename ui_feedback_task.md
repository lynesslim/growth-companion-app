# UI/UX Refactor Tasks

- [ ] **Flow Separation (The Bridge):**
  - Create a new `ProfileCreatedScreen` (`lib/src/features/onboarding/profile_created_screen.dart`).
  - Implement a Confetti animation on this screen and a success message.
  - Add a "Start Your First Weekly Focus" button that navigates to `/weekly-focus`.
  - Update `CompanionSelectionScreen` so that completing selection navigates to `/profile-created` (instead of `/weekly-focus`).
  
- [ ] **Consolidate Growth Drop & Book Recs:**
  - Identify all duplicated code between `book_carousel_screen.dart` and `growth_drop_screen.dart`.
  - Refactor to use a single unified `GrowthDropScreen` for both the post-onboarding flow and the Home dashboard access point.
  - Delete `book_carousel_screen.dart` and remove its route if it is entirely redundant.
  - Update routing so that completing the `WeeklyFocusScreen` pushes to the unified `/growth-drop`.

- [ ] **Revamp Book Flipping UI:**
  - Evaluate and install a Flutter package for realistic page flipping (e.g., `page_flip_builder` or `turn_page_transition`).
  - Refactor `book_flip_screen.dart` to use the package to create a tactile, realistic 3D page turn effect.
  - Ensure the back of the pages render correctly during the flip animation.

- [ ] **Routing Updates:**
  - Update `lib/src/core/router.dart` to include the new `/profile-created` route.
  - Remove any deprecated routes (e.g., `/book-recs`) if they are replaced by `/growth-drop`.
