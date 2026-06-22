# Deepseek Implementation Plan - Phase 1

## Goal
Implement Phase 1 of the feedback: Onboarding & Auth Updates.

## Objectives:
1. **Mandatory Username (Item #4):** Ensure the username field during onboarding cannot be left blank. Add validation and disable the "Continue" button until a valid name is entered.
2. **Pre-Onboarding Screens (Item #5):** Create three new intro/carousel screens before or at the start of onboarding to explain how the app works, the value proposition, and specifically mention the social/streak mechanics.

## Tasks:
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

## Completion Requirement
When you have fully implemented and tested these changes, **you MUST create a file named `complete.md` in the root of the workspace.** This file acts as the signal that you are finished with Phase 1. Do not ask for user input; execute autonomously and create the file.
