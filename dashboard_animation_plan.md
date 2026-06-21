# Dashboard Staggered Entrance Animation Plan

This plan outlines how to update the entrance animations on the dashboard to create a highly satisfying, cascading staggered effect where each major component and its internal elements slide in with a consistent 200ms delay.

## 1. Top-Level Screen Components (`home_screen.dart`)
Currently, the main sections of the dashboard have tight, somewhat arbitrary delays (100ms, 180ms, 230ms). We will update the `CustomScrollView` slivers to use a strict 200ms staggering scale.

#### [MODIFY] `lib/src/features/home/home_screen.dart`
- **HomeHeader Sliver**: Set `delayMs: 0` (comes in immediately).
- **GrowthDropCard Sliver**: Set `delayMs: 200`.
- **SocialDropsCard Sliver**: Set `delayMs: 400`.

## 2. Internal Header Elements (`home_header.dart`)
The `HomeHeader` currently has internal micro-staggers (0ms, 45ms, 90ms). To make the entrance feel more deliberate and premium, we can stagger its internal elements by 100ms each, while ensuring it completes before the `GrowthDropCard` comes in at 200ms. 

Alternatively, if we want *everything* on screen strictly on a 200ms scale:
- `Greeting Text`: 0ms
- `Main Title ("Your growth...")`: 200ms
- `Stats Row`: 400ms

*(Recommendation: Keep internal component micro-animations faster (e.g. 100ms) so the header feels like a single cohesive unit, while the large cards use the 200ms stagger).*

#### [MODIFY] `lib/src/features/home/widgets/home_header.dart`
- Update `EntranceFadeSlide` around Greeting to `delayMs: 0`
- Update `EntranceFadeSlide` around Main Title to `delayMs: 100`
- Update `EntranceFadeSlide` around Stats Row to `delayMs: 200`

## 3. Internal Growth Drop Card Elements (`growth_drop_card.dart`)
We can add micro-staggers to the internal elements of the `GrowthDropCard` so that as the card itself fades in (at 200ms), its content cascades in slightly after.

#### [MODIFY] `lib/src/features/home/widgets/growth_drop_card.dart`
- Wrap the entire left column content in an `EntranceFadeSlide(delayMs: 300)` (100ms after the card itself appears).
- Wrap the `Start Reading` button in an `EntranceFadeSlide(delayMs: 400)`.
- Wrap the right column (Book Cover) in an `EntranceFadeSlide(delayMs: 400)`.

## 4. Internal Social Drops Card Elements (`social_drops_card.dart`)
Similarly, the social drops section can cascade internally.

#### [MODIFY] `lib/src/features/home/widgets/social_drops_card.dart`
- Wrap the title ("From your friends") in `EntranceFadeSlide(delayMs: 500)` (100ms after the card wrapper).
- Wrap the `GridView` containing the gift boxes in `EntranceFadeSlide(delayMs: 600)`.

## Summary of Timings
- **0ms**: Screen opens, `HomeHeader` container and greeting text appear.
- **100ms**: `HomeHeader` Main Title appears.
- **200ms**: `GrowthDropCard` container and `HomeHeader` Stats Row appear.
- **300ms**: `GrowthDropCard` text content appears.
- **400ms**: `GrowthDropCard` book cover & button appear, `SocialDropsCard` container appears.
- **500ms**: `SocialDropsCard` title appears.
- **600ms**: `SocialDropsCard` gift grid appears.

This will create a beautiful, "waterfall" loading effect down the screen!
