# Feedback Implementation Plan

This document outlines the phased implementation plan for the 10 feedback items. It is structured into logical phases so that it can be executed sequentially by the developer agent (`opencode`).

## Phase 1: Onboarding & Auth Updates

### Objectives:
1. **Mandatory Username (Item #4):** Ensure the username field during onboarding cannot be left blank. Add validation and disable the "Continue" button until a valid name is entered.
2. **Pre-Onboarding Screens (Item #5):** Create three new intro/carousel screens before or at the start of onboarding to explain how the app works, the value proposition, and specifically mention the social/streak mechanics.

### Tasks for Deepseek:
- Locate the onboarding screen where the username is entered and add form validation.
- Create a new `PreOnboardingScreen` containing a `PageView` with 3 instructional slides. Please use the following copy and visual guidelines:
  - **Slide 1 (Core Value):** 
    - Title: "Read Smarter, Every Day"
    - Subtitle: "Get curated book summaries delivered daily. Grow your mind without the time commitment."
    - Visual: A clean, modern placeholder (e.g., an open book or lightbulb icon) using the app's primary gradient.
  - **Slide 2 (How it Works):**
    - Title: "Your Daily Drop"
    - Subtitle: "A new actionable insight awaits you each day. Read, reflect, and apply it to your life."
    - Visual: A calendar or "gift drop" style icon.
  - **Slide 3 (Social Streaks):**
    - Title: "Grow Together"
    - Subtitle: "Send books to your friends and maintain daily reading streaks. Stay consistent and hold each other accountable!"
    - Visual: A fire emoji (🔥) or two people icons to represent social streaks.
- Ensure the UI matches the app's modern aesthetics (use `AppColors` and `AppTypography`).
- Update the app router / main flow to show the pre-onboarding screen to new users before reaching the username/auth screen.

---

## Phase 2: Home Page & Dashboard UI Enhancements

### Objectives:
1. **Next Book Timer (Item #1):** In the dashboard's Today's Drop container, if the drop is completed, display a countdown timer: "Your next book is available in [x] hours [x] min". The countdown should target midnight (or the daily refresh time).
2. **Horizontal Gifts Received (Item #8):** Refactor the "Gifts received by friends" section on the Home Page to use a horizontal scroll (`ListView.horizontal`) instead of taking up the full vertical space.
3. **Send to Friends Carousel (Item #9):** Add a new horizontally scrolling list on the Home Page displaying the user's friends. 
   - Title: "Send a book to your friends".
   - Behavior: Hide the section completely if the user has no friends added.
   - Design: It must look identical to the "closest streaks" horizontal carousel on the Friends screen (e.g., using the custom gradient avatar rings, streak badges, and matching typography).

### Tasks for Deepseek:
- Update `TodayDropCard` (or similar widget) to calculate time until the next drop and use a `Timer` to rebuild the text.
- Modify `SocialDropsCard` or the home screen body to format received gifts into a horizontal list.
- Fetch the user's friends in the Home Screen provider/logic and conditionally render a new horizontal `ListView` of friend avatars. Extract the avatar list item widget from `friends_screen.dart` into a shared component if it isn't already, so the Home Screen carousel perfectly matches the Friends Screen carousel.

---

## Phase 3: Social & Streak Logic Adjustments

### Objectives:
1. **Post-Reading Modal (Item #10):** When the user returns to the Home Page after completing Today's Drop, automatically pop up a modal. It must only appear **once a day** upon completion. The modal should encourage sending a book/blindbox to maintain streaks and include a button linking to the Friends Page.
2. **Update Share Text (Item #2):** Locate the share/invite text logic and append: *"Read more books & stay consistent with friends today!"*
3. **Streak Expiration Logic (Item #3):** Update the streak calculation logic. Streaks should reset to zero (or disappear) if there is no mutual interaction (sending gift/book/blindbox) within a rolling 24-hour window.

### Tasks for Deepseek:
- Add a check in the Home Page's initialization or build logic (e.g., using `SharedPreferences` or state) to see if Today's Drop was just completed and the modal hasn't been shown yet today. Show the custom `AlertDialog` or `BottomSheet` there.
- Search for the share string and append the new sentence.
- Review the `Friend` model and `SocialProvider` (or backend Edge Function if calculated on server). Ensure streaks validate `last_interaction_date`.

---

## Phase 4: Content Generation (Covers & Takeaways)

### Objectives:
1. **Fix Missing Key Takeaways (Item #7):** Investigate the AI generation pipeline (e.g., Supabase edge functions or backend prompt) to ensure Key Takeaways are reliably structured and parsed. Add fallbacks or stricter JSON output rules to the LLM prompt.
2. **AI SVG Book Covers (Item #6):** Explore ways to generate visual book covers based on the actual book's dominant color. If using SVGs, dynamically inject color codes based on book metadata.

### Tasks for Deepseek:
- Review the prompt inside the `generate-social-drop` (or related generation) edge function. Update it to strictly enforce the inclusion of Key Takeaways.
- Refactor the book cover UI widget to dynamically construct an SVG or gradient background using the book's specific color palette.

---

## Instructions for Opencode Loop Execution

To execute this plan using our loop system, the Project Manager (Antigravity) will:
1. Generate a specific `deepseek_implementation_plan.md` for the current Phase.
2. Trigger the `opencode` agent to execute it and instruct it to write `complete.md` when done.
3. Wait for `complete.md` to appear.
4. **QA Review:** Thoroughly inspect the modified codebase to verify code quality, ensure best practices, and confirm that all requirements for the phase are 100% met. 
   - If the implementation is lacking, trigger `opencode` again with specific feedback and corrections.
   - If the implementation passes the quality check, verify with the user, delete `complete.md`, and move to the next Phase.
