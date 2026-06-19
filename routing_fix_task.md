# Routing Fix Tasks

- [ ] Add `GoRoute` for `/growth-drop` mapping to `GrowthDropScreen()` in `lib/src/core/router.dart`.
- [ ] Add `GoRoute` for `/quest/:id` mapping to `QuestDetailScreen()` in `lib/src/core/router.dart`.
- [ ] Parse `id` parameter in the `/quest/:id` route and pass it to `QuestDetailScreen(questId: id)`.
- [ ] Verify that `context.push('/quest/1')` in `quest_log_card.dart` successfully navigates to the correct page.
- [ ] Verify that `context.push('/growth-drop')` in `growth_drop_card.dart` successfully navigates to the correct page.
