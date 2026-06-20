# Fix Daily Drop Modal & Journal Save Logic

The daily drop modal keeps reappearing because the app never actually marks the daily drop as "read" after you finish it. Additionally, the journal currently displays all generated drops by default, rather than only the ones explicitly saved.

## Proposed Changes

### Database Schema Updates
To separate books you've merely "read" from books you've "saved" to your journal:
- Run a SQL command to add an `is_saved BOOLEAN DEFAULT FALSE` column to the `growth_drops` table.
- Update the `count_user_drops` RPC to count only books where `is_saved = true`.

### 1. `lib/src/domain/models/growth_drop.dart`
- [MODIFY] Add `isSaved` boolean field to the `GrowthDrop` model. Update `copyWith`, `toJson`, and `fromJson`.

### 2. `lib/src/providers/growth_drop_provider.dart`
- [MODIFY] Update the `fromSupabase` factory to parse the new `is_saved` column from the database.
- [MODIFY] Add a `saveToJournal()` method to `GrowthDropNotifier` to update `is_saved = true` in the database.

### 3. `lib/src/providers/journal_provider.dart`
- [MODIFY] Update the query to include `.eq('is_saved', true)` so the Journal screen only shows explicitly saved books.

### 4. `lib/src/features/books/book_flip_screen.dart`
- [MODIFY] In the `_onPageChanged` or `_finishReading` method, when the user reaches the end of the book, automatically trigger the existing (but currently unused) `markAsRead()` function for the daily drop. This guarantees the modal will stop showing up on the home screen.

### 5. `lib/src/features/books/streak_complete_screen.dart`
- [MODIFY] Remove the `if (widget.book!.giftedBy != null)` condition wrapping the "Save to Journal" button so it appears for all books (daily drops and friend drops).
- [MODIFY] Update the `_saveToJournal` function:
  - If it's a **Daily Drop** (has an existing ID in `growth_drops`): Update the row to `is_saved = true`.
  - If it's a **Friend Drop** (from `social_drops`): Insert a new row into `growth_drops` with `is_saved = true` (this preserves the current behavior while adopting the new column).

## Verification Plan
### Manual Verification
1. Open the app and generate/view a daily drop.
2. Read to the last page. Return to the home screen and verify the modal no longer reappears.
3. Finish a daily drop and verify the "Save to Journal" button is present on the completion screen.
4. Click "Save to Journal" and verify the book appears in the Journal tab.
5. Finish a drop but DO NOT click "Save to Journal", and verify it does NOT appear in the Journal tab.
