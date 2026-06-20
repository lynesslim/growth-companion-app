# Fix Invite User Flow

The current invite link flow forces users to sign up immediately before showing them any context, and the background logic for generating the social drop relies on an edge function that actually expects an existing drop. 

We will adjust the flow to show the blindbox first, require signup to "open" it, and then handle all friendship and drop logic silently when they land on the dashboard.

## Proposed Changes

### 1. Update Router Authentication Logic
**File:** `lib/src/core/router.dart`
- [MODIFY] Update the `redirect` function to explicitly allow the `/invite` path even if the user is not authenticated.
- [MODIFY] Update the `/invite` GoRoute to render a new `InviteLandingScreen` instead of immediately redirecting to `/onboarding`.

### 2. Create Invite Landing Screen
**File:** `lib/src/features/onboarding/invite_landing_screen.dart` (New File)
- [NEW] Create a screen visually similar to the current blind box screen.
- [NEW] UI: "A friend sent you a mystery book tailored to your goals. Tap to open!" with 3 selectable boxes.
- [NEW] Logic on tap:
  - Save the `sender_id` to `SharedPreferences`.
  - Check if the user is currently logged in.
  - If logged in -> `context.go('/')` (Home dashboard).
  - If not logged in -> `context.go('/login')` (Login/Signup).

### 3. Handle Post-Signup / Dashboard Logic
**File:** `lib/src/features/home/home_screen.dart`
- [MODIFY] In `initState` or `addPostFrameCallback`, check `SharedPreferences` for `sender_id`.
- [MODIFY] If `sender_id` exists:
  - Remove it from `SharedPreferences` to prevent looping.
  - Automatically insert a row into the `friends` table: `user_id_1: sender_id`, `user_id_2: current_user_id`, `status: 'accepted'`.
  - Automatically insert a row into the `social_drops` table: `sender_id: sender_id`, `recipient_id: current_user_id`, `is_opened: false`, `drop_date: today`.
  - Invalidate the `socialProvider` so the UI updates to show the unopened blind box on the dashboard.
  - Show a snackbar: "You've received a blind box from your friend!"

### 4. Update Onboarding Routing
**File:** `lib/src/features/onboarding/onboarding_screen.dart`
- [MODIFY] In Steps 10 and 11, remove the old logic that checks for `sender_id` and redirects to `/blind-box`.
- [MODIFY] Change the routing so that completing onboarding redirects the user to `/` (Home dashboard), which will automatically trigger the invite processing logic built in Step 3.

### 5. Cleanup
**File:** `lib/src/features/onboarding/blind_box_screen.dart`
- [DELETE] Remove the old `BlindBoxScreen` as it is replaced entirely by the new flow.

## Verification Plan
### Manual Verification
1. Log out of the app.
2. Open a URL formatted like `/#/invite?sender=TEST_ID`.
3. Verify that you see the `InviteLandingScreen` without being forced to log in.
4. Tap a box, verify it redirects to the Login screen.
5. Sign up, complete onboarding, and verify that upon landing on the Home screen:
   - You are automatically friends with `TEST_ID`.
   - An unopened blind box from `TEST_ID` appears in your "Gifted for you" section.
