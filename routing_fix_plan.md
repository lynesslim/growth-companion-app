# Routing & Navigation Fix Plan

## Problem Statement
During manual testing, several navigation links are broken and trigger a "Page not found" error. This is because the UI components are trying to navigate to routes that do not exist in the `GoRouter` configuration in `lib/src/core/router.dart`. 

## Proposed Changes

### 1. Update `lib/src/core/router.dart`
Add the missing routes to the router configuration:
- Add a route for `/growth-drop` that points to `GrowthDropScreen`.
- Add a route for `/quest/:id` that points to `QuestDetailScreen` (and parse the `id` from `pathParameters`).

### 2. Verify all `context.push` and `context.go` calls
Ensure that all navigation calls in the features directory match the configured routes exactly.
- `QuestLogCard`: calls `context.push('/quest/${quest.id}')` -> ensure `/quest/:id` handles this correctly.
- `GrowthDropCard`: calls `context.push('/growth-drop')` -> ensure `/growth-drop` handles this correctly.

## Verification Plan
1. Launch the app and navigate to the Home Dashboard.
2. Tap on the Growth Drop card -> verify it opens the `GrowthDropScreen`.
3. Tap on a Quest card -> verify it opens the `QuestDetailScreen`.
