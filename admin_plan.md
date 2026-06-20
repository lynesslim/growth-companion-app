# Admin Status Implementation Plan

We will introduce an "Admin" status to the application. Admin users will be granted two special privileges:
1. They can send an unlimited number of blind boxes/books to friends per day (bypassing the 1-per-day restriction).
2. They will see a "Regenerate" button on their daily drop, allowing them to instantly generate a new daily drop on demand.

## Proposed Changes

### 1. Database Schema Update
We need to track admin status in the database.
- Run a SQL command via Supabase MCP:
  ```sql
  ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT false;
  ```

### 2. Update User Model
**File:** `lib/src/domain/models/user.dart`
- [MODIFY] Add `final bool isAdmin;` to the `User` class.
- [MODIFY] Update the constructor, `copyWith`, `toJson`, `fromJson`, `==`, and `hashCode` to properly serialize and track the new `isAdmin` field (mapped to `is_admin` in JSON).

### 3. Admin Power 1: Unrestricted Sending
**File:** `lib/src/providers/social_provider.dart`
- [MODIFY] In the `sendDrop(String friendId)` function, check if the current user is an admin (`user.isAdmin`).
- [MODIFY] Currently, the code checks if `existingDrop != null` and throws a "You already sent a drop to this friend today!" exception. We will bypass this exception if the user is an admin, allowing the backend to successfully insert multiple `social_drops` records.

### 4. Admin Power 2: Regenerate Daily Drop
**File:** `lib/src/features/home/widgets/growth_drop_card.dart`
- [MODIFY] In the `build` method, access the current `user` from `userProvider`.
- [MODIFY] If a daily drop already exists (`drop != null`) and `user.isAdmin == true`, render a new "Regenerate Drop (Admin)" button below the "Open Now" or "Start Reading" buttons.
- [MODIFY] The button will re-trigger the existing `_generateToday()` function. Because our previous update specifically fetches the daily drop using `.order('created_at', ascending: false).limit(1)`, the newly generated drop will automatically overwrite the old one on the dashboard seamlessly.

## Verification Plan
### Manual Verification
1. I will execute the `ALTER TABLE` SQL command to add the `is_admin` column.
2. I will manually update your specific user profile via SQL to set `is_admin = true` so you can test it immediately.
3. Open the app, and view your daily drop. Verify that a "Regenerate Drop (Admin)" button appears. Click it and verify a new drop replaces the old one.
4. Go to the Social tab and send a blind box to a friend. 
5. Send a second blind box to the exact same friend on the same day. Verify that it succeeds without throwing the usual 1-per-day limit error.
