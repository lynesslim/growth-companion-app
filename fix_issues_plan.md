# Fix Invite Blindbox, Remove Weekly Focus & Redesign Landing Screen

We will address the three requested issues:
1. Ensure the invited user actually receives the blindbox on the dashboard.
2. Completely remove the "Weekly Focus" requirement from the app, allowing users to generate drops immediately.
3. Redesign the `InviteLandingScreen` to use a single emoji box, an "Unpack" button, and confetti.

## Proposed Changes

### 1. Fix Invite Blindbox Not Showing
**File:** `lib/src/features/home/home_screen.dart`
- **Issue Analysis:** The database table `social_drops` requires `book_data` to be non-null (`JSONB NOT NULL`), but our silent insertion in `_processInvite()` omitted it, causing a silent database error.
- [MODIFY] Update the `insert` logic in `_processInvite` to include `'book_data': {}` so the insertion succeeds and the blindbox appears on the dashboard.

### 2. Remove Weekly Focus
**File:** `lib/src/features/home/widgets/growth_drop_card.dart`
- [MODIFY] Remove all references to `currentWeeklyGoalProvider`.
- [MODIFY] In `_generateToday()`, remove the check `if (goal == null)` and the snackbar prompting the user to set a weekly focus.
- [MODIFY] Update the `body` sent to the edge function to only rely on `user!.id`.
- [MODIFY] In the `build()` method, remove the UI prompting the user to go to `/weekly-focus`. Ensure the "Generate Today's Drop" button is shown unconditionally when no drop exists for the day.

**File:** `lib/src/core/router.dart`
- [MODIFY] Remove the `/weekly-focus` route.
- [MODIFY] Remove `/weekly-focus` from the `onboardingRoutes` list.

**File:** `lib/src/features/profile/profile_screen.dart`
- [MODIFY] Remove the "Weekly Focus" section and the button navigating to `/weekly-focus` from the profile page.

**File Cleanup:**
- [DELETE] `lib/src/features/weekly_focus/weekly_focus_screen.dart` (or the folder).
- [DELETE] `lib/src/domain/models/weekly_goal.dart` and `lib/src/providers/weekly_goal_provider.dart` (if they exist).

### 3. Redesign Invite Landing Screen
**File:** `lib/src/features/onboarding/invite_landing_screen.dart`
- [MODIFY] Convert `InviteLandingScreen` to a `StatefulWidget` to manage a `ConfettiController`.
- [MODIFY] Add a `ConfettiWidget` at the top center of the screen so confetti rains down.
- [MODIFY] Replace the grid of 3 boxes with a single large Emoji `📦` (`Text('\u{1F4E6}', style: TextStyle(fontSize: 80))`).
- [MODIFY] Add a prominent button labeled "Unpack the blindbox".
- [MODIFY] When clicked, play the confetti animation, wait ~2 seconds, and then execute the login/redirect logic.

## Verification Plan
### Manual Verification
1. **Invite Logic:** Open an invite link (`/#/invite?sender=...`), tap "Unpack the blindbox", view the confetti, sign up as a new user, and verify the blindbox appears successfully on the home dashboard.
2. **Weekly Focus Removed:** As a new user (or existing user), verify that the dashboard immediately allows you to "Generate Today's Drop" without ever being prompted to set a weekly focus. Verify the Weekly Focus screen is no longer accessible anywhere in the app.
3. **Invite UI:** Verify the landing screen features the single emoji box and the confetti animation works perfectly before redirecting.
