# Implementation Plan: Case Study and Actionable Insights Screens

We need to add two new screens to the book reading experience (book flip screen): a "Case Study" screen and an "Actionable Insights" screen. These screens should appear immediately after the three lessons and before the final summary.

Please implement the following changes:

## 1. Update Domain Models
The backend AI generation prompts have already been updated in Supabase to include `caseStudy` (String) and `actionableInsights` (List of Strings) in the JSON payload. 

**`lib/src/domain/models/growth_drop.dart`**
- Add `final String? caseStudy;` and `final List<String>? actionableInsights;`.
- Update the constructor, `copyWith`, `toJson`, and `fromJson` methods to support these new fields safely.

**`lib/src/domain/models/social_drop.dart`**
- In `SocialDrop.fromJson`, extract `caseStudy` and `actionableInsights` from the nested `book_data` JSON.

## 2. Update Data Providers & Serialization
**`lib/src/providers/social_provider.dart`**
- In `saveDropToJournal`, update the manual `bookData` map to include `caseStudy` and `actionableInsights` when inserting the drop into the journal table.

**`lib/src/features/books/streak_complete_screen.dart`**
- In `_saveToJournal`, update the manual `recommended_books` map to include `caseStudy` and `actionableInsights`.
- In `_showFriendPicker`, update the manual mapping inside `sendBookFromJournal` to include the new fields.

## 3. Update the UI (`lib/src/features/books/book_flip_screen.dart`)
- **Dynamic Page List**: Change the static `_pageNames` list to a dynamic getter (e.g., `_getPageNames(GrowthDrop book)`) that only includes `'Case Study'` and `'Insights'` if `book.caseStudy != null` and `book.actionableInsights != null`. This ensures backwards compatibility for older books.
- **Update Page Progress Indicator**: Ensure the page progress dot indicator and `[current]/[total]` text dynamically use the length of the new dynamic page list instead of the old static `_pageNames.length`. Be careful with the syntax inside the `children` list.
- **Update `_nextPage` and Navigation**: Ensure the `_nextPage` logic and the "Next / Finish" button logic accurately check against the new dynamic page list length.
- **Update `_buildPageContent`**: Refactor the switch statement into a string-based check against the dynamic page names to render the correct pages.
- **Create `_CaseStudyPage` Widget**: Build a visually distinct page for the case study using `AppColors.xpKnowledge` or `AppColors.primary`. Display the case study text in a scrollable view. Use a psychology or lightbulb icon.
- **Create `_ActionableInsightsPage` Widget**: Build a visually distinct page for the actionable insights using `AppColors.warning` or `AppColors.xpInfluence`. Display the 3 insights as beautiful, separated cards with numbered circular badges. Use a bolt or action icon.

Please proceed to make these modifications across the codebase!
