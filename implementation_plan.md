# Implementation Plan: Daily Growth Companion App

This document outlines the comprehensive technical and execution plan for bringing the Daily Growth Companion App to life using Flutter, ensuring a premium, native-feeling experience on both iOS and Android.

## Technical Stack Decisions
- **Framework:** Flutter (targeting iOS and Android natively)
- **State Management:** Riverpod
- **Backend & Database:** Supabase (Initial phase will use **local mocking** for UI development)
- **AI Integration:** OpenAI
- **Animations:** Rive (for interactive companion states)
- **Monetization:** RevenueCat (Future Phase)
- **Analytics:** PostHog or Firebase Analytics (Future Phase)

## Proposed Changes

### Phase 1: Foundation & Architecture

- **Project Initialization:**
  - Create a new Flutter project.
  - Configure iOS and Android specific settings (bundle IDs, permissions).
- **Architecture Setup:**
  - Implement a clean architecture structure (`lib/src/features`, `lib/src/common_widgets`, `lib/src/utils`, `lib/src/services`).
  - Set up **Riverpod** for state management and dependency injection.
  - Set up **GoRouter** for declarative navigation.
- **Design System & Native Feel:**
  - Implement a custom `ThemeData` (Dark/Light mode support).
  - Integrate `vibration` or `haptic_feedback` packages for rich native haptics on button presses, task completions, and companion interactions.
  - Setup unified text styles using modern typography (e.g., Google Fonts like Inter or Outfit).

### Phase 2: MVP Features - Interactive Flow (Current Phase)

**Design System Updates (Based on UI Reference):**
- **Color Palette:** Shift to a warm, airy off-white background (`#FCF9F5`) to match the "Sanctuary" feel. Update primary colors to soft purples (`#9E82F0`) and pink gradients.
- **Typography:** Introduce an elegant Serif font (e.g., `Playfair Display` or `Lora`) for major headings to give a premium, calming vibe. Retain a clean Sans-Serif (`Inter`) for readability in body text.

**Feature Implementation Breakdown (New Flow):**

1. **One-Off Onboarding (`lib/src/features/onboarding/`)**
   - **Personal Questionnaire:** Build a beautiful sequence of 5-6 personal questions to understand the user's goals and struggles.
   - **Companion Selection:** Create a "Pokemon-style" selection screen where users choose their digital zen companion. High visual polish, utilizing gradients and subtle floating animations.

2. **Weekly Focus (`lib/src/features/focus/`)**
   - After onboarding (or beginning of a new week), present a flow asking about the user's focus for the week and their current personal struggles. This sets the context for the recommendations.

3. **Book Recommendations Experience (`lib/src/features/books/`)**
   - Present 3 recommended books based on the weekly focus.
   - **Interactive Page Flip UI:** For each book, build a highly polished, award-winning 6-page interactive book experience featuring realistic/stylized page-flip animations.
   - The 6 pages for each book will strictly be:
     1. Cover + Description
     2. Summary based on the user's profile
     3. Lesson 01
     4. Lesson 02
     5. Lesson 03
     6. The chapter to first read

## Open Questions for Phase 2
> [!IMPORTANT]
> 1. **Page Flip Animation:** To achieve "award-winning" page flips, we can either use a highly polished community package (like `page_flip_builder` or `turn_page_transition`) customized to perfection, or build a bespoke 3D/Matrix4 transformation animation from scratch. Should we start with a custom-tuned package for speed, or go fully bespoke?
> 2. **Navigation after Books:** Once the user flips through the 3 books, where do they land? Do they arrive at the Dashboard shown in the previous UI image?

### Phase 3: Core Infrastructure (State & Data Layer)

- **Dependencies:**
  - Add `freezed_annotation`, `json_annotation` to `dependencies`.
  - Add `build_runner`, `freezed`, `json_serializable` to `dev_dependencies`.
- **Data Models (`lib/src/domain/models/`):**
  - Create Freezed/JsonSerializable data classes:
    - `User`: id, name, currentXp, level, currentStreak, selectedCompanionId, **onboardingProfile** (e.g., goals, challenges, interests).
    - `WeeklyGoal`: id, userId, focusArea, status, startDate, endDate.
    - `Companion`: id, name, type, description, assetPath.
    - `GrowthDrop`: id, date, focusArea, recommendedBooks (list of book objects/ids).
    - `Quest` (Task): id, title, xpReward, isCompleted, type (e.g., daily, weekly).
- **Mocked Data Layer (`lib/src/data/repositories/`):**
  - Create interfaces and local in-memory Mock Repositories:
    - `AuthRepository`: login, logout, getCurrentUser.
    - `UserRepository`: getUserProfile, updateXp.
    - `CompanionRepository`: getAvailableCompanions, getCompanionById.
    - `TasksRepository`: getDailyQuests, completeQuest.
- **State Wiring (`lib/src/providers/`):**
  - Wire up the static UI to Riverpod providers for dynamic state updates (e.g., watching a `questsProvider` to update the UI when a quest is marked complete, and updating `userProvider` to reflect XP gains).

### Phase 4: Backend & AI Integration (Real Data)

> [!IMPORTANT]
> **Open Questions for Phase 4 (Supabase):**
> 1. Do you already have a Supabase project created, or do you need me to provide the SQL schema so you can run it in your Supabase SQL editor first?
> 2. Should we start with Anonymous Authentication for onboarding, or force an Email/Password login upfront?

- **Supabase Integration (Ponytail Mode):**
  - [NEW] Install the `supabase_flutter` dependency.
  - [MODIFY] Initialize Supabase globally in `main.dart`.
  - [MODIFY] Update `AuthRepository`, `UserRepository`, and `TasksRepository` to use `Supabase.instance.client` directly.
  - [DELETE] Remove all `Mock*Repository` files. Under Ponytail rules ("deletion over addition"), we delete code we no longer use.
  - [DELETE] Remove Repository Interfaces (e.g., `abstract class IUserRepository`), *unless* you specifically plan to switch out Supabase for something else in the near future (YAGNI).
  - Define database schemas (Users, Companions, Tasks, Daily Recommendations).
- **OpenAI Service Integration:**
  - Implement the OpenAI service to generate personalized Growth Drops and Actions.
- **Gamification Engine:**
  - Implement server-side or robust client-side logic for XP calculation, leveling up, and streak maintenance.

### Phase 4.5: User Authentication

- **Auth Strategy (Confirmed):**
  - Use **Traditional Email/Password Login**.
- **Refactor Auth State:**
  - Replace the complex `StateNotifierProvider` in `auth_provider.dart` with a simple Riverpod `StreamProvider` that listens directly to `Supabase.instance.client.auth.onAuthStateChange`. This delegates all session management to the Supabase library ("let the library do the work" rule).
- **GoRouter Integration:**
  - Add a `redirect` callback in `router.dart` that watches the new auth stream.
  - If a user is not authenticated, redirect them to the `/login` screen.
- **Login/Signup UI:**
  - Create a new, minimal, cleanly-designed `LoginScreen` in `lib/src/features/auth/login_screen.dart`.
  - Wire it up to Supabase's `signInWithPassword` and `signUp`.

### Phase 4.6: Fix Onboarding Reroute Bug (Completed)

> [!IMPORTANT]
> **Root Cause of the Rerouting Bug:**
> 1. `userProvider` only fetches your profile *once* when the app starts. If you are not logged in yet, it fails and permanently caches an `AsyncError`.
> 2. When you finally log in, `authStateProvider` updates, but `userProvider` doesn't know you logged in, so it never retries fetching your profile!
> 3. The Router's `redirect` function checks `userState.valueOrNull`. Because it's stuck in an error state, it returns `null`. The router assumes `null` means "You don't have a profile, go to onboarding!"
> 4. Additionally, `GoRouter` is only listening to `authStateProvider`, meaning when `userProvider` *does* eventually load, the router is never notified to take you to the Dashboard.

- **Proposed Fix (UserProvider):**
  - Update `userProvider` to `ref.listen` to `authStateProvider`. Whenever your authentication state changes to "logged in", it will automatically trigger a fresh profile fetch from the database.
- **Proposed Fix (Router Logic):**
  - Update `RouterNotifier` in `router.dart` to listen to BOTH `authStateProvider` and `userProvider`. This guarantees the router will re-evaluate your destination the millisecond your profile finishes loading, correctly dropping you into the Dashboard (`/`).

### Phase 4.7: Fix Companion UUID Crash (Completed)

> [!IMPORTANT]
> **Root Cause of the Companion Crash:**
> During Companion Selection, the app uses **mocked** companions with string IDs like `"companion_1"`. When you choose one, the app attempts to save it to your Supabase `profiles` table. However, Supabase strictly expects a **valid UUID** for `selected_companion_id`. This type mismatch causes a silent database crash, throwing your `userProvider` into an Error state. Because it is in an error state, the router assumes you don't have a profile and traps you in the Onboarding loop!

- **Proposed Fix (Companion Integration):**
  - Connect `CompanionRepository` directly to the `companions` table in Supabase.
  - Remove the mock strings. Fetch the real companions (Lumina, Terra, Zephyr) generated by our database schema.
  - This ensures a valid UUID is passed when you choose a companion, completing the Onboarding flow cleanly.

### Phase 4.8: Supabase Data Integrity & Mock Removal Audit (Completed)

> [!WARNING]
> Several core features of the app are currently running on placeholder (mock) data from early UI prototyping. We need to purge these to prevent any more type mismatch crashes.

- **Proposed Fix (Tasks & Quests):**
  - `TasksRepository` is completely mocked. We will rewrite it to execute real CRUD operations against the `quests` table in Supabase.
- **Proposed Fix (Weekly Goals):**
  - Ensure the `weekly_goal_provider` reads and writes exclusively to the `weekly_goals` table.
- **Proposed Fix (Growth Drops):**
  - The `growth_drop_provider` currently returns a hardcoded Cal Newport book. We will connect this to the `growth_drops` table (and eventually power it with OpenAI in Phase 4.9).
- **Execution Strategy:**
  - I will systematically go through `lib/src/data/repositories` and `lib/src/providers` to remove any `Future.delayed` mock calls, replacing them with strongly-typed `Supabase.instance.client` queries.

### Phase 4.9: OpenAI Integration (Generating Dynamic Growth Drops)

> [!IMPORTANT]
> **OpenAI Edge Function Architecture:**
> We will completely remove the hardcoded `book_data.dart` and replace it with a dynamic, AI-powered Growth Drop engine. When the user finishes the Weekly Focus screen, the app will call a Supabase Edge Function to generate the week's book.

## User Review Required
**Edge Function Generation Strategy:** Since the goal is **1 book per day** based on the Weekly Focus, the most reliable and scalable way to build this is:
1. **Sunday/Monday:** User sets their Weekly Focus (`intent` and `struggle`).
2. **Daily Login:** Every day when the user opens the app, it checks if a Growth Drop exists for *today*.
3. **On-Demand Generation:** If none exists, it calls the OpenAI Edge Function to instantly generate **1 personalized book** and **micro-action quests** for that specific day, guided by the active Weekly Focus.

*Are you approved to proceed with this daily, on-demand AI generation approach?*

- **Proposed Fix (Supabase Edge Function):**
  - Create a new table `ai_prompts` in Supabase with a row for `growth_drop_prompt`. This allows you to edit the exact GPT prompt at any time without deploying code.
  - Create a Supabase Edge Function (`generate-growth-drop`) written in Deno.
  - The function will read your prompt from `ai_prompts`, inject the user's `onboarding_profile`, `weekly_intent`, and `weekly_struggle`.
  - It will call the OpenAI API (GPT-4o) and ask it to generate: 1 Book Title, Author, Summary, 3 Lessons, and **3 Micro-Action Quests**.
  - The function will save the JSON result directly into the user's `growth_drops` table for the current `drop_date`.
- **Proposed Fix (Flutter UI):**
  - Update `growth_drop_provider.dart` to fetch the Growth Drop for `DateTime.now()`. If it's missing, show a loading state and trigger the Edge Function.
  - Update `book_flip_screen.dart` and `action_plans_screen.dart` to read directly from this daily Growth Drop.
  - Ensure the "Add to Quests" button reliably triggers the GPT-generated micro-actions.

### Phase 5: Monetization & Analytics

- **RevenueCat Integration:**
  - Setup `purchases_flutter`.
  - Build the Paywall screen.
  - Implement logic to gate premium features.
- **Analytics & Tracking:**
  - Integrate PostHog or Firebase Analytics.
  - Track core events: `onboarding_completed`, `growth_drop_opened`, `task_completed`.

## Verification Plan

### Automated Tests
- Write unit tests for core business logic (XP calculation, streak logic).
- Write widget tests for critical UI components (Task cards, Onboarding flow).

### Manual Verification & iOS Simulator Testing
To launch the app on an iOS simulator and test the new UI:
1. Ensure Xcode is installed on your Mac.
2. In your terminal, run `open -a Simulator` to start an iOS simulator.
3. Once the simulator is running, navigate to your project directory in terminal.
4. Run `flutter run` and select the iOS simulator from the list of available devices.
- Test haptics and animations on physical iOS and Android devices (note: haptics don't always trigger in simulators).
- Verify native navigation feel (swipe back on iOS, back button handling on Android).
- End-to-end testing of the onboarding -> daily drop -> task completion loop using mock data.

---

## Ponytail Codebase Audit Plan

> **Note:** This section was added to track the staged audit for over-engineering using the Ponytail rules ("lazy senior dev" mode).

### Stage 1: The Foundation Layer
*Target:* `lib/src/core/`, `lib/src/utils/`, `lib/src/providers/`
* **Core & Utils**: Look for "utility" functions that just wrap standard Dart library methods. Replace them with inline native calls.
* **Providers**: Check for bloated state management or deeply nested providers that could be simplified.

### Stage 2: The Data & Domain Layer
*Target:* `lib/src/data/`, `lib/src/domain/`, `lib/src/services/`
* **Data / Domain**: Eliminate "pass-through" repositories or interfaces (YAGNI). 
* **Services**: Remove custom wrappers around standard platform features or installed dependencies.

### Stage 3: The UI Layer
*Target:* `lib/src/features/`, `lib/src/common_widgets/`
* **Features**: Strip out unnecessary wrapper widgets. If a standard Flutter widget does the job, use it directly.
* **Common Widgets**: Delete custom widgets that re-implement native platform behaviors. Simplify widget trees.

### Stage 4: Dependencies
*Target:* `pubspec.yaml`
* **Dependencies**: Review installed packages. Remove unused or trivially replaceable packages.

---

### Phase 4.10: Dashboard UX Refactor & Empty States

> [!IMPORTANT]
> **User Review Required:** Please review these proposed UX changes to the dashboard empty states. Do you approve the messaging?

**Issues Identified:**
1. **Growth Drop Card Empty State:** In the Dashboard, it shows blank text when there's no drop.
2. **Quest Log Card Empty State:** Shows a progress bar and "0 of 0 quests completed" when no quests exist.
3. **Obsolete Screens:** `growth_drop_screen.dart` is a legacy file that was replaced by `book_flip_screen.dart`, but it hasn't been deleted yet.

**Execution Strategy:**
- **[MODIFY] `growth_drop_card.dart`:** If `drop.valueOrNull == null`, render a beautiful Empty State with a "Ready for your next drop?" title and a "Set Weekly Focus" button that routes to `/weekly-focus`. If not null, update the button to route to `/book` instead of the old `/growth-drop`.
- **[MODIFY] `quest_log_card.dart`:** If `quests.isEmpty`, hide the progress bar and show an empty state message: "Read your daily book drop to discover and add new micro-actions."
- **[DELETE] `growth_drop_screen.dart`:** Completely remove this legacy screen.
- **[MODIFY] `router.dart`:** Remove the obsolete `/growth-drop` route.

---

### Phase 4.11: Weekly Goal Persistence

> [!IMPORTANT]
> **User Review Required:** Do you approve the architecture for saving and re-using the Weekly Goal so users only set it once a week?

**Issues Identified:**
1. **Goal Amnesia:** The `WeeklyFocusScreen` currently sends the user's `intent` and `struggle` directly to the AI Edge Function without saving them. Thus, the app forgets the goal the next day.
2. **Repetitive UI:** Users are forced to re-enter their intent and struggle every single day to generate a new book.

**Execution Strategy:**
- **[DATABASE] Modify `weekly_goals` table:** Add `intent` and `struggle` columns to the `weekly_goals` table in Supabase so we can store the two-part focus properly.
- **[MODIFY] `WeeklyFocusScreen`:** When the user completes the flow, it will now save a new `WeeklyGoal` to the database using `TasksRepository.setWeeklyGoal()`.
- **[MODIFY] `GrowthDropCard` Empty States:** 
  - If the user has **no active Weekly Goal**, show the "Set Weekly Focus" button (routes to `/weekly-focus`).
  - If the user **has an active Weekly Goal** but no drop for today, show a "Generate Today's Drop" button. Clicking this will trigger the Edge Function automatically using the saved `intent` and `struggle` without making them fill out the form again!

---

### Phase 4.12: Growth Drop Read State & Action Plan UI Improvements

**Goal:** Track whether a user has already read today's Growth Drop and completed the action plan selection.
1. The dashboard button should change from "Start" to "Review Drop".
2. The Action Plans screen should visually indicate which quests have already been added to their daily quests and prevent re-adding them.

**Execution Strategy:**
- **[DATABASE] Modify `growth_drops` table:** Run a SQL migration to add an `is_read` column (BOOLEAN DEFAULT FALSE).
- **[MODIFY] `lib/src/domain/models/growth_drop.dart`:** Add `final bool isRead;` and update JSON serialization/`copyWith`.
- **[MODIFY] `lib/src/providers/growth_drop_provider.dart`:** Refactor `growthDropProvider` to an `AsyncNotifierProvider` (`GrowthDropNotifier`). Parse the `is_read` column, and add a `markAsRead()` method that updates Supabase and local state.
- **[MODIFY] `lib/src/features/home/widgets/growth_drop_card.dart`:** If `drop.valueOrNull!.isRead` is `true`, change the button text from "Start" to "Review Drop" and update the icon.
- **[MODIFY] `lib/src/features/books/action_plans_screen.dart`:**
  - Watch `dailyQuestsProvider` and compare quest descriptions.
  - Disable toggling for already added items, and style them to look "completed" (e.g. permanent green checkmark).
  - On "Continue", call `markAsRead()`.
  - If no new items are selected but the user already added quests previously, change the button text to "Return to Dashboard".

---

### Phase 4.13: Fix Persistence of Growth Drop Read State (Completed)

**Goal:** Ensure that when a user completes a Growth Drop, the `is_read` state correctly persists across app restarts.

**Issues Identified:**
The `growth_drops` table in Supabase has Row-Level Security (RLS) enabled. While there is a policy allowing users to `SELECT` (view) their own growth drops, there is no policy allowing them to `UPDATE` their drops. Because of this, the `markAsRead()` method's database update call fails silently, causing the UI to revert from "Review Drop" back to "Start" the next time the data is fetched.

**Proposed Changes:**
- **[DATABASE] Add RLS UPDATE Policy:** Run a SQL migration to create an `UPDATE` policy for the `growth_drops` table, allowing users to update rows where they are the owner (`auth.uid() = user_id`).
```sql
CREATE POLICY "Users update own growth drops" 
ON growth_drops FOR UPDATE 
USING (auth.uid() = user_id);
```

---

### Phase 4.14: Journal Page (Library of Books)

**Goal:** The Journal page should record all the books the user has received so far. It will display the covers of the books in a beautiful grid layout.

**Open Questions:**
None. We will pass the specific `GrowthDrop` object via routing so the user can re-read past books.

**Proposed Changes:**

- **[NEW] `lib/src/providers/journal_provider.dart`:**
  - Create a new `AsyncNotifierProvider` (`JournalNotifier`) that fetches *all* `growth_drops` for the current user from Supabase, ordered by `drop_date` descending.

- **[MODIFY] `lib/src/features/journal/journal_screen.dart`:**
  - Replace the static Empty State with a dynamic `GridView.builder`.
  - Watch `journalProvider`. If empty, show a nice empty state.
  - Render a "Book Cover" for each item. The cover will mimic the aesthetic of the `_CoverPage` in `BookFlipScreen`: a stylized container with a gradient, book icon, title, and author.
  - Wrap each cover in a `GestureDetector` that routes to `/book` and passes the specific `GrowthDrop` object.

- **[MODIFY] `lib/src/core/router.dart`:**
  - Update the `/book` route to accept an optional `GrowthDrop` via `state.extra`.
  - Update the `/action-plans` route to accept an optional `GrowthDrop` via `state.extra`.

- **[MODIFY] `lib/src/features/books/book_flip_screen.dart` & `action_plans_screen.dart`:**
  - Accept an optional `GrowthDrop? book` parameter in the constructor.
  - If `widget.book` is provided, render the UI using that past book immediately instead of watching `growthDropProvider` (which only fetches today's drop).
  - Pass the specific `GrowthDrop` to `/action-plans` when reaching the end of the book.

---

### Phase 4.15: Profile Screen UI/UX Overhaul (Duolingo Inspired)

**Goal:** Transform the basic Profile tab into a highly engaging, gamified dashboard similar to Duolingo, focusing on user identity, statistics, and achievements.

**Proposed UI/UX Changes:**

1. **Header Section (Identity & Settings):**
   - Top-right "Settings" gear icon (for Logout and preferences).
   - Prominent Avatar: Instead of just initials, display a large, beautifully styled avatar circle. If they have a companion, show a small companion badge overlapping the avatar.
   - Name and a subtle "Explorer" or "Growth Seeker" subtitle.

2. **Gamified Statistics Grid:**
   - Replace the basic list rows with a 2x2 grid of stylish cards (similar to Duolingo's stat boxes), featuring colorful icons and bold numbers:
     - 🔥 **Current Streak:** (Orange/Red styling)
     - ⚡ **Total XP:** (Yellow/Gold styling)
     - 📚 **Books Finished:** (Purple styling - derived from `journalProvider` from Phase 4.14)
     - ✅ **Level:** (Blue styling - showing their current rank/level).

3. **Weekly Focus Section:**
   - A dedicated card showing their active `WeeklyGoal` (Intent).
   - An "Edit" button allowing them to jump back into the `/weekly-focus` flow to recalibrate their goals whenever they want.

4. **Achievements / Badges (Gamification):**
   - A section titled "Achievements".
   - A visually appealing grid of stylized circular badges.
   - MVP Badges (visually locked/unlocked based on current stats):
     - *First Drop:* Unlocked when Books Finished >= 1.
     - *On Fire:* Unlocked when Streak >= 3.
     - *Action Taker:* Unlocked when XP >= 50.
   - Locked badges will be greyscale with a lock icon. Unlocked badges will be fully colored with a glowing effect.

**Execution Strategy:**
- **[MODIFY] `lib/src/features/profile/profile_screen.dart`:** Completely rewrite the UI. Introduce a `_StatCard` widget for the 2x2 grid. Add the `_AchievementsSection` with badge logic. Add an `AppBar` with a settings icon.
- **[NEW] `lib/src/features/profile/settings_screen.dart`:** A simple settings page with a "Log Out" button (calling `Supabase.instance.client.auth.signOut()`).
- **[MODIFY] `lib/src/core/router.dart`:** Add a route for `/settings`.

---

### Phase 4.16: Fix Journal Routing and Read State Bugs

**Goal:** Fix the edge cases that occur when revisiting a past book via the Journal. Re-reading an old book should not trigger the Onboarding Congrats screen, nor should it incorrectly mark *today's* drop as read.

**Proposed Changes:**
- **[MODIFY] `lib/src/features/books/action_plans_screen.dart`:**
  - Detect if the user is viewing a past book (`widget.book != null`).
  - In `_continue()`: 
    - If viewing a past book, **skip** calling `ref.read(growthDropProvider.notifier).markAsRead()`. This prevents the bug where reading a past book incorrectly marks today's new drop as read.
    - Instead of routing to `/congrats` (which is designed for the onboarding flow), return the user to the journal (`context.go('/journal')`).
    - If they successfully added *new* quests from the past book, show a simple success `SnackBar` ("Action plans added to your quests!") before navigating.

---

### Phase 4.17: Fix Weekly Focus Edit Button

**Goal:** Enable users to successfully edit their Weekly Focus from the Profile screen.

**Issues Identified:**
Currently, when a user clicks "Edit" on the Weekly Focus card in their Profile, the app appears to do nothing. This is because `/weekly-focus` is listed in the `strictOnboardingRoutes` array inside `router.dart`. The router actively intercepts the navigation and redirects fully onboarded users back to the Home screen (`/`), treating the screen as strictly locked to new users only.

**Proposed Changes:**
- **[MODIFY] `lib/src/core/router.dart`:**
  - Remove `'/weekly-focus'` from the `strictOnboardingRoutes` list.
  - This minimal change will allow onboarded users to re-access the screen to update their focus and generate a fresh book, while still correctly protecting other onboarding routes (like `/companion-select`).

---

# Phase 5: Complete Onboarding Overhaul (Headway-Style)

**Goal:** Replace the current onboarding sequence with a comprehensive, Headway-inspired 12-screen flow tailored for Gen Z. The design will be clean, minimal, and warm, utilizing a `PageView` for smooth transitions. Additionally, we will completely strip out the Companion system from the app.

## Proposed Changes

### 1. Strip the Companion System
- **[DELETE] `lib/src/features/onboarding/companion_selection_screen.dart`**, **`lib/src/providers/companion_provider.dart`**, and **`lib/src/domain/models/companion.dart`**.
- **[MODIFY] `lib/src/domain/models/user.dart`**: Remove `selectedCompanionId` and `companionState`. Update `fromJson`/`toJson` accordingly.
- **[MODIFY] `lib/src/features/profile/profile_screen.dart`**: Remove the companion badge overlapping the avatar.
- **[MODIFY] `supabase/functions/generate-growth-drop/index.ts`** (if applicable): Ensure the AI generation prompt no longer relies on a specific companion persona, defaulting to a consistent, encouraging tone.

### 2. Unified Onboarding State & Architecture
- **[MODIFY] `lib/src/features/onboarding/onboarding_screen.dart`:** 
  - Completely rewrite the screen.
  - Implement a `PageView` with `NeverScrollableScrollPhysics` so progress is strictly controlled by "Continue" buttons.
  - Maintain a local state object to collect: `name`, `age`, `goals`, `interests`, `readingTime`, `readingMoments`, `motivationAnswers`, and `reminders`.
  - Add an animated top progress bar that updates as the user moves through screens 2–9.

### 3. UI Components & Visual System
- **[NEW] `lib/src/features/onboarding/widgets/onboarding_widgets.dart`:**
  - `SelectionCard`: A reusable card for Age, Goals, and Reading Moments (supports single or multi-select with colored borders, soft tinted backgrounds, and checkmarks).
  - `TopicPill`: Pill-shaped buttons for the "Areas of Interest" screen.
  - `QuoteCard`: A large colored card for the Motivation statements.
  - `OnboardingLayout`: A scaffold wrapper with a fixed bottom "Continue" button to keep actions within thumb reach.

### 4. Screen Breakdown
- **Screen 1 (Welcome):** Illustration, Headline, "Get started" button.
- **Screen 2 (Name):** Text input field.
- **Screen 3 (Age):** Single-select `SelectionCard`s.
- **Screen 4 (Goals):** Multi-select `SelectionCard`s.
- **Screen 5 (Interests):** Multi-select `TopicPill`s.
- **Screen 6 (Time):** Multi-select options, displaying dynamic estimated results (e.g., "About 20 useful ideas every week").
- **Screen 7 (Moment):** Multi-select `SelectionCard`s.
- **Screen 8 (Motivation):** A nested sub-state showing 3 sequential quote statements with ❌/✅ buttons.
- **Screen 9 (Reminders):** Toggle options (Native permission request triggers *only* on "Continue").
- **Screen 10 (Loading):** Animated loading screen simulating AI personalization. Submits the gathered data (JSON) to the `users` table and triggers the `generate-growth-drop` Edge Function.
- **Screen 11 (Plan):** Displays the personalized plan and recommended books.
- **Screen 12 (First Session):** Directs the user immediately to `/book` to view the newly generated drop.

### 5. Routing Updates
- **[MODIFY] `lib/src/core/router.dart`:**
  - Because `OnboardingScreen` now encapsulates the *entire* flow, remove `/profile-created`, `/companion-select`, and `/weekly-focus` from the mandatory strict onboarding routes and rely solely on `/onboarding`.

---

# Phase 6: Book Reading Overhaul & Action Plan Removal

**Goal:** Provide deeper, more structured book lessons, replace the "First Chapter" concept with a cohesive summary, and completely strip the Action Plans / Quests system from the app, capping off reading sessions with a streak-based motivation screen.

## Proposed Changes

### 1. Data Model & AI Prompt Updates
- **[MODIFY] `supabase/functions/generate-growth-drop/index.ts` (or relevant prompt config):**
  - Alter the system prompt to return `what_its_about` as 3 specific bullet points explaining why it is recommended for the user.
  - Instruct the AI to write deeper `lessons` (300-400 words each), explicitly citing the chapter number and title for each.
  - Replace the `first_chapter` JSON output with a `summary` containing 3 bullet points summarizing the lessons and their application.
  - Remove all instructions related to generating `quests` and `daily_actions`.
- **[MODIFY] `lib/src/domain/models/growth_drop.dart`:**
  - Remove `quests`, `dailyAction`, `dailyActionDuration`, and `firstChapter`.
  - Add `finalSummary` (or reuse an existing summary field appropriately). Update `fromJson` / `toJson`.
- **[MODIFY] `lib/src/providers/growth_drop_provider.dart`:**
  - Update `fromSupabase()` parsing logic to match the new AI JSON schema.

### 2. Complete Removal of Action Plans
- **[DELETE]** `lib/src/features/books/action_plans_screen.dart`
- **[DELETE]** `lib/src/features/growth/quest_detail_screen.dart`
- **[DELETE]** `lib/src/providers/quests_provider.dart`
- **[DELETE]** `lib/src/data/repositories/tasks_repository.dart`
- **[DELETE]** `lib/src/domain/models/quest.dart`
- **[MODIFY] `lib/src/features/dashboard/dashboard_shell.dart`:** Ensure any bottom navigation items referencing Quests/Action Plans are fully removed.
- **[MODIFY] `lib/src/core/router.dart`:** Remove `/action-plans` and `/quest/:id` routes.

### 3. Book Reading UI Overhaul
- **[MODIFY] `lib/src/features/books/book_flip_screen.dart`:**
  - **What It's About Page:** Update the UI to render the 3 bullet points clearly instead of a single text block.
  - **Lesson Pages:** Ensure the layout uses a `SingleChildScrollView` (or an elegant scrolling text container) to gracefully handle 300-400 words without cutoff. Ensure Chapter citations are visually distinct (e.g., bolded).
  - **Summary Page:** Replace the `_FirstChapterPage` with a new `_SummaryPage` that renders the 3 final bullet points.
  - **Navigation Logic:** In `_nextPage()`, when the user finishes the last page (Summary), route to `/streak` instead of the deleted Action Plans screen.

### 4. Streak Completion Screen
- **[NEW] `lib/src/features/books/streak_complete_screen.dart`:**
  - A celebratory screen triggered at the end of a reading session.
  - Pulls the user's current streak from `userProvider` (e.g., "Day 4").
  - Displays warm words of encouragement (e.g., "You're building an incredible habit. See you tomorrow!").
  - Includes a primary button to "Return to Home".
- **[MODIFY] `lib/src/core/router.dart`:** Add the `/streak` route pointing to this new screen.



---

# Phase 7: Social Sharing & Gamified Streaks (Snapchat Style)

**Goal:** Drive virality and daily retention by allowing users to invite friends via WhatsApp, resulting in a reciprocal, gamified "Blind Box" book-drop ritual that maintains a social streak.

## Proposed Changes

### 1. Database Schema Updates
- **[DATABASE] `friends` table:**
  - `user_id_1` (UUID), `user_id_2` (UUID), `status` (pending/accepted), `created_at`.
- **[DATABASE] `social_streaks` table:**
  - `user_id_1`, `user_id_2`, `current_streak` (INT), `last_shared_date_1` (DATE), `last_shared_date_2` (DATE).
- **[DATABASE] `social_drops` table:**
  - `id` (UUID), `sender_id` (UUID), `recipient_id` (UUID), `drop_date` (DATE), `book_data` (JSONB), `is_opened` (BOOLEAN).

### 2. Deep Linking & Invites
- **[NEW] `share_plus` Integration:** Add a "Share with Friends" button in the Profile or Home screen that generates a unique referral link (e.g., `app://invite?sender=[USER_ID]`).
- **[MODIFY] `lib/src/core/router.dart`:** Set up deep link handling. If the app is opened via an invite link, store the `sender_id` locally using `SharedPreferences`.

### 3. Onboarding "Blind Box" Experience
- **[MODIFY] `OnboardingScreen` (Screen 10 & 11):**
  - If a `sender_id` was detected, after normal onboarding, route the user to a **Blind Box Selection Screen**.
  - Display 3 stylized "Blind Boxes", labeled dynamically based on the user's selected goals (e.g., "Box of Finances", "Box of Relationships", "Box of Productivity").
  - Tapping a box triggers the AI to immediately generate their first personalized book drop, credited as "Sent by [Sender Name]".
  - Create the reciprocal `friends` relationship in the database automatically.

### 4. Daily Social Drop (The Snapchat Streak Loop)
- **[NEW] `generate-social-drop` Edge Function:**
  - A new Supabase Edge Function specifically for social sharing.
  - **Inputs:** `sender_id`, `recipient_id`.
  - **Logic:** Fetches the *recipient's* onboarding profile. Uses the AI to generate a highly personalized book for the recipient. Saves it to `social_drops` with `sender_id` attached.
- **[NEW] `lib/src/features/social/social_screen.dart`:**
  - A new primary tab for "Friends".
  - Displays a list of friends and the current 🔥 Streak count.
  - **Action 1 (Send):** "Tap to send a Blind Box". Triggers the `generate-social-drop` Edge Function. The sender doesn't choose the book; the AI tailors it for the friend.
  - **Action 2 (Receive):** "Tap to open your Blind Box". Opens the `BookFlipScreen` to read the book sent by the friend.
  - Streaks increment when both users exchange a blind box within a 24-hour window.

### 5. UI/UX Considerations
- Beautiful, physics-based "shaking" animations when tapping a blind box to open it (using Flutter's implicit animations or Rive).
- The `BookFlipScreen` will show a special banner: "Gifted by [Friend Name]" when reading a social drop.

---

# Phase 8: Robust Social Network & Journal Integration

**Goal:** Evolve the social feature into a true network. Users can search for friends by email/username, send friend requests, send specific books from their journal (or AI blind boxes), and optionally save received drops to their own journal. Received drops are also moved to the main Dashboard.

## Proposed Changes

### Database & RPC Updates
#### 1. [NEW] Supabase RPC `search_users`
Create a `SECURITY DEFINER` Postgres function. It will securely search `auth.users` for an exact email match, AND `public.profiles` for username matches (using `ILIKE`). It will return a list of sanitized `User` profiles (ID, Name, XP, Level) so the app can display search results.

#### 2. Friend Requests Logic
- Update the `friends` table usage. When "Add Friend" is tapped, insert a record with `status = 'pending'`.
- The recipient can view pending requests and hit "Accept", updating the status to `accepted`.

### Flutter UI Updates

#### 3. Social Search & Friend Requests (`social_screen.dart`)
- **Search Bar:** Add a search bar at the top of the Social tab to query emails/usernames.
- **Search Results:** Display matching profiles. Tapping one opens a bottom sheet with their basic stats and an "Add Friend" button.
- **Pending Requests Section:** Show incoming friend requests with "Accept" and "Decline" buttons.

#### 4. Dashboard Integration (`home_screen.dart` & `social_drops_section.dart`)
- Move the "Unopened Blind Boxes/Books" queue out of the Social Tab and place it natively on the `HomeScreen` directly beneath "Today's Drop".

#### 5. Sending Books vs Blind Boxes
- **Social Tab Action:** When tapping the "Send" icon next to a friend, show a modal: "Send Blindbox (AI)" or "Send from Journal".
- **Journal Integration:** If "Send from Journal" is selected, open a picker showing their past `growth_drops`. 
- **Book Details Page:** Add a "Share with Friend" button directly inside a user's own Journal entries.

#### 6. Saving to Journal (`book_flip_screen.dart` / `congrats_screen.dart`)
- When a user finishes reading a Social Drop (whether it was a blindbox or a journal share), show a new button: **"Save to my Journal"**.
- Tapping this takes the `bookData` payload from the `social_drop` and permanently inserts it into the user's personal `growth_drops` table.

## User Review Required
Please review the updated Phase 8 plan above. Once approved, I'll dive in and begin executing!

## Open Questions
> [!IMPORTANT]
> 1. **Deep Linking Infrastructure:** Do you want to use Firebase Dynamic Links (deprecated soon but still functional), Supabase Deep Links, or a service like Branch.io to ensure the WhatsApp invite link reliably survives the App Store installation process? (Supabase Deep links are easiest if we keep the stack consolidated).
> 2. **Daily Drop Conflict:** If a user receives 3 social drops from 3 different friends in one day, does this replace their standard daily "Growth Drop", or do they get to read all 4 books that day?
