# UI/UX Refactor Plan (PM Review)

## Senior PM Analysis: The Current Flow Issues
1. **Conflating Setup with Core Loop**: Currently, the initial Onboarding (Profile Setup + Companion Selection) flows directly into the Weekly Focus (the recurring core loop) without any break. This causes cognitive overload and makes the setup process feel endless.
2. **Duplicated Features**: The "Book Recommendations" shown during onboarding and the "Growth Drop" accessible from the Home screen are functionally identical concepts but built as two different features/UI flows. They need to be consolidated.
3. **Underwhelming Book Flip**: The current "flip" animation in `book_flip_screen.dart` uses a basic 2D rotation matrix (`rotateY`). It looks like a card turning slightly sideways, rather than a realistic 3D page flip.
4. **Missing Celebration/Bridge**: When a user finishes the heavy lift of setting up their profile, they deserve a dopamine hit (celebration) before being asked to do more work (setting a weekly goal).

## Proposed Corrections & Flow Changes

### 1. Separate Onboarding from the Weekly Routine
- **Stage 1 (One-off Setup)**: `OnboardingScreen` -> `CompanionSelectionScreen`.
- **The Bridge (New)**: Once the companion is selected, navigate to a new `ProfileCreatedScreen`. This screen will feature Confetti, a celebratory message ("Your Sanctuary is Ready"), and a clear Call-to-Action button: "Start Your First Weekly Focus".
- **Stage 2 (Recurring Core Loop)**: Tapping that button brings them to the `WeeklyFocusScreen`, which acts as the start of their recurring journey, rather than a continuation of setup.

### 2. Consolidate Growth Drop & Book Recommendations
- Delete the redundant `/book-recs` flow if it differs from the `GrowthDropScreen`. 
- Unify them into a single `GrowthDropScreen` that handles the weekly book recommendations. Whether the user accesses it right after setting their weekly focus, or by tapping the card on the Home dashboard, they should see the exact same beautifully designed feature.

### 3. Revamp the Book Flipping UI
- Replace the custom `rotateY` tween in `book_flip_screen.dart` with a proper page-flipping package (e.g., `page_flip_builder` or `turn_page_transition`). 
- If using a package is not desired, we must significantly upgrade the matrix transformation to include a 3D perspective fold, a shadow gradient that moves with the page turn, and a proper back-page rendering to simulate a real book.

## Open Questions for DeepSeek Execution
> [!IMPORTANT]
> - Should we install a community package like `page_flip_builder` for the book flip, or write a complex bespoke Matrix4 animation? (Recommendation: Use a package for maximum realism and stability).
