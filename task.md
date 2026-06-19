# Task List: Daily Growth Companion App

## Phase 1: Foundation & Architecture
- [x] Initialize new Flutter project
- [x] Set up clean architecture folders (`lib/src/...`)
- [x] Install core dependencies (riverpod, go_router, freezed, google_fonts, vibration, rive)
- [x] Configure GoRouter for declarative navigation
- [x] Implement Design System (ThemeData, colors, typography)
- [x] Set up Haptic Feedback utilities

## Phase 2: MVP Features - Interactive Flow
- [x] **Design System Updates:**
  - [x] Update `app_colors.dart` to new warm/airy palette
  - [x] Update `app_typography.dart` (Add Lora/Playfair for headers)
- [x] **One-Off Onboarding (`lib/src/features/onboarding/`):**
  - [x] Build 5-6 personal question screens
  - [x] Build Companion Selection screen (Pokemon-style)
- [x] **Weekly Focus (`lib/src/features/focus/`):**
  - [x] Build Weekly Focus intent & struggle screen
- [x] **Interactive Book Recommendations (`lib/src/features/books/`):**
  - [x] Build 3-book swipe/carousel container
  - [x] Implement custom page-flip for the 6-page interactive book
  - [x] Book Pages: Cover, Summary, Lesson 1-3, First Chapter
  - [x] Build Confetti Congrats screen upon completing the books

## Phase 3: Core Infrastructure (State & Data Layer)
- [x] Add `freezed_annotation`, `json_annotation` to dependencies, and `build_runner`, `freezed`, `json_serializable` to dev_dependencies
- [x] Create Freezed data models in `lib/src/domain/models/`:
  - `User` (id, name, currentXp, level, currentStreak, selectedCompanionId, onboardingProfile)
  - `WeeklyGoal` (id, userId, focusArea, status, startDate, endDate)
  - `Companion` (id, name, type, description, assetPath)
  - `GrowthDrop` (id, date, focusArea, recommendedBooks)
  - `Quest` (id, title, xpReward, isCompleted, type)
- [x] Run `dart run build_runner build -d` to generate Freezed files
- [x] Define Repository classes in `lib/src/data/repositories/`:
  - `AuthRepository` (mock login/logout)
  - `UserRepository` (mock get profile, update XP)
  - `CompanionRepository` (mock available companions)
  - `TasksRepository` (mock daily quests, mark complete)
- [x] Wire up Riverpod providers in `lib/src/providers/` and connect to the static UI

## Phase 4: Backend & AI Integration (Real Data)

## Phase 4.5: User Authentication
- [x] Implement Auth strategy (Email/Password)
- [x] Refactor `auth_provider.dart` to use Supabase `onAuthStateChange` stream
- [x] Add `redirect` logic to `router.dart` for authenticated vs unauthenticated states
- [x] Create UI: `lib/src/features/auth/login_screen.dart`
- [x] Add `supabase_flutter` to dependencies
- [x] Initialize Supabase in `main.dart` with URL and Anon Key
- [x] Define database schemas in Supabase dashboard (Users, Companions, Tasks, Daily Recommendations)
- [x] Update Repositories (`AuthRepository`, `UserRepository`, `TasksRepository`) to use `Supabase.instance.client`
- [x] Delete `Mock*Repository` files and Repository Interfaces (Ponytail Rule)
- [ ] Integrate OpenAI for Growth Drop generation
- [ ] Implement gamification engine (XP logic)

## Phase 5: Monetization & Analytics (Future)
- [ ] Integrate RevenueCat
- [ ] Build Paywall screen
- [ ] Integrate PostHog / Firebase Analytics

---

## Ponytail Codebase Audit

- [x] **Stage 1: The Foundation Layer**
  - [x] Review `lib/src/core/` for boilerplate — clean
  - [x] Review `lib/src/utils/` for trivial wrappers — removed redundant `.taskComplete()`, `.swipe()` from HapticUtils
  - [x] Review `lib/src/providers/` for bloated state management — kept, reasonable for Riverpod pattern

- [x] **Stage 2: The Data & Domain Layer**
  - [x] Review `lib/src/data/` — collapsed abstract+mock repos into concrete classes (YAGNI on interfaces until Phase 4)
  - [x] Review `lib/src/domain/` — kept Freezed models (already generated, working, churn to remove)
  - [x] Review `lib/src/services/` — N/A (no services/ dir existed)

- [x] **Stage 3: The UI Layer**
  - [x] Review `lib/src/features/` — clean
  - [x] Review `lib/src/common_widgets/` — deleted unused `GlassCard`

- [x] **Stage 4: Dependencies**
  - [x] Review `pubspec.yaml` — removed `rive` (unused), `cupertino_icons` (unused template default)

- [x] **Verification**
  - [x] Run `flutter analyze` — no issues
  - [ ] Run `flutter test` — only default placeholder test exists
  - [ ] Manual app build verification
