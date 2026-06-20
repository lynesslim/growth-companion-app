# Implementation Plan - Social Streak and Send Limits

This plan describes how we will fix the streak double-increment bug and correctly disable the send icon on the social page for normal users who have hit their daily limit.

## User Review Required

> [!IMPORTANT]
> - Admins will remain completely unaffected: they can send unlimited drops/books daily, and their send buttons will not be disabled.
> - Normal users will have the send icon disabled directly on the friend list tile if they have already sent a book/drop to that friend today.

## Proposed Changes

### Social Provider

#### [MODIFY] [social_provider.dart](file:///Volumes/T7/Lyness/SAAS/Book%20App/lib/src/providers/social_provider.dart)
- Update both `sendDrop` and `sendBookFromJournal` to use a consistent and robust streak increment guard.
- Before incrementing, check if the current user already sent today (`myLastDate == today`). If yes, update `last_shared_date` but do not increment the streak value. This prevents double-incrementing if multiple drops/books are sent (e.g. by admins or via overlapping flows).

Specifically, in both methods, we will:
1. Fetch the streak record.
2. Determine `myLastDate` and `otherDate` based on who is user 1 or user 2.
3. If `myLastDate == today`, we update the corresponding date but **do not** increment the streak.
4. If `myLastDate != today` and `otherDate == today`, we increment the streak by 1.

---

### Social Screen

#### [MODIFY] [social_screen.dart](file:///Volumes/T7/Lyness/SAAS/Book%20App/lib/src/features/social/social_screen.dart)
- Update the friend list card trailing send button logic.
- Determine if the user has already sent a drop to that friend today:
  ```dart
  final alreadySent = socialState.sentTodayFriendIds.contains(friendId);
  final canSend = !alreadySent || socialState.isAdmin;
  ```
- Disable the `IconButton` (set `onPressed: null` and color to `AppColors.grey400` or a light grey) when `canSend` is false.

---

## Verification Plan

### Manual Verification
- Log in as a normal user, send a book to a friend, verify the send icon on the list tile becomes disabled (greyed out) and cannot be clicked.
- Log in as an admin, send a book to a friend, verify the send icon remains active and clickable.
- Verify the streak increments exactly once when both users exchange a drop today, even if they send multiple drops.
