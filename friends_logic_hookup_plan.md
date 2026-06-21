# DeepSeek Rework Plan: Hooking Up the Logic in FriendsScreen

The UI for `friends_screen.dart` looks fantastic and perfectly matches the screenshot. However, the interactive logic and data hookups from the original `social_screen.dart` are missing and need to be integrated into this new UI.

Please implement the following changes in `lib/src/features/social/friends_screen.dart`:

## 1. Search Bar Logic & Search Results
Currently, the search bar is purely visual. 
- The parent `FriendsScreen` has already been converted to a `ConsumerStatefulWidget` and handles the `_searchController` and `_onSearchChanged` logic.
- **Task**: Render the search results! If `socialState.isSearching` is true, show a `CircularProgressIndicator`. If `socialState.searchResults` is not empty, iterate through them and render the `_buildSearchResult(u, userId)` widget directly beneath the search bar.
- **Note**: You will need to bring over the `_buildSearchResult` helper method from the old `social_screen.dart` and ensure it uses the new clean UI styling.

## 2. Restore Pending Requests
The "Pending Requests" section was completely removed because it wasn't visible in the screenshot.
- **Task**: Re-insert the Pending Requests section just above the "Your closest streaks" section.
- If `socialState.pendingRequests.isNotEmpty`, display the "Pending Requests" header and render each request using the `_buildPendingRequest(req)` helper method from the old `social_screen.dart`.
- Make sure the accept/decline buttons are hooked up to `ref.read(socialProvider.notifier).acceptFriendRequest(req.id)` and `declineFriendRequest`.

## 3. Hook Up "Send Growth Drop" Buttons
Currently, these buttons are dead ends (`onTap: () {}`).
- **Highlight Card Task**: Inside `_HighlightCard`, the "Send today's Growth Drop" button needs to trigger:
  ```dart
  ref.read(socialProvider.notifier).sendDrop(friendId);
  ```
- **All Friends List Task**: In `_FriendTile`, the trailing badge "Send drop" is just a static container. Wrap it in a `GestureDetector` or `InkWell` and trigger the same `sendDrop(friendId)` logic when tapped.
- Ensure that if `alreadySent` is true (check `socialState.sentTodayFriendIds.contains(friendId)`), the send button is disabled or grayed out.

## 4. Friend Profile Navigation
Currently, tapping a friend's avatar does nothing.
- **Task**: In `_StreakAvatarItem` and `_FriendTile`, wrap the entire card/avatar in a `CardPress` or `GestureDetector`.
- **Action**: On tap, navigate to the friend's profile using:
  ```dart
  context.push('/friend-profile', extra: friendData);
  ```

## Summary
Do not change the aesthetics or layout of the new UI. Your goal is simply to bridge the missing `onTap` events, restore the Search Results rendering, and restore the Pending Requests rendering using the methods from the old `social_screen.dart`.
