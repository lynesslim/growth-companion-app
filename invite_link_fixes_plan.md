# Bug Fixes and Feature Plan: Social Sharing and Invite Links

## Goal Description
Fix duplicate friend insertions when clicking an invite link, prevent users from giving themselves blind boxes by clicking their own link, and allow users to share a specific book via WhatsApp such that new users signing up from the link receive that specific book rather than a generic blind box.

## User Review Required
> [!IMPORTANT]
> We will use the UUID approach. The shared link will include the `drop_id` (the UUID of the book). A new Supabase Postgres function `get_shared_book` has been created to bypass Row Level Security (RLS) and securely allow the new user to fetch the shared book data.

## Proposed Changes

### Core

#### [MODIFY] router.dart
- Update the `/invite` route definition to accept an optional `drop_id` query parameter.
- Pass this parameter down to the `InviteLandingScreen`.

### Features - Onboarding

#### [MODIFY] invite_landing_screen.dart
- Add a new `dropId` parameter to the widget.
- In `_unpack()`, if `dropId` is provided, save it to `SharedPreferences` under the key `shared_drop_id`.

### Features - Home

#### [MODIFY] home_screen.dart
- In `_processInvite()`:
  - Read both `sender_id` and `shared_drop_id` from SharedPreferences. Clear both keys.
  - Return early if `senderId == userId` (prevents self-referral and self-gift).
  - Before inserting a new row into the `friends` table, query the table using `maybeSingle()` to ensure a friend relationship doesn't already exist.
  - If `shared_drop_id` is present, fetch the book data via the newly created Supabase RPC: `await supabase.rpc('get_shared_book', params: {'drop_id': sharedDropId})`.
  - Insert the `social_drops` row with `book_data` set to the fetched book JSON (if present) instead of an empty `{}`.
  - Update the snackbar message dynamically depending on whether a specific book was received or a generic blind box.

### Features - Books

#### [MODIFY] streak_complete_screen.dart
- Update `_inviteViaWhatsApp` to construct the share link with the `drop_id` parameter.
- Append `&drop_id=${bookData.id}` to the deep link URI.

## Verification Plan

### Manual Verification
1. Sign in as User A. Send an invite link to User B via WhatsApp (general invite). Ensure User B receives a blind box and is added as a friend exactly once.
2. Sign in as User A. Click User A's own invite link. Verify that nothing happens (no self-friend added, no self-blind box).
3. Sign in as User A. Complete a streak/finish a book and share the specific book via WhatsApp. Sign in as User B, click the link, and verify User B receives the specific book shared by User A without needing AI generation.
