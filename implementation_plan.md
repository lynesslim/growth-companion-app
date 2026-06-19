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
