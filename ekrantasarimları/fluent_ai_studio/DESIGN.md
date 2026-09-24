---
name: Fluent AI Studio
colors:
  surface: '#f4fafd'
  surface-dim: '#d4dbdd'
  surface-bright: '#f4fafd'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eef5f7'
  surface-container: '#e8eff1'
  surface-container-high: '#e2e9ec'
  surface-container-highest: '#dde4e6'
  on-surface: '#161d1f'
  on-surface-variant: '#474554'
  inverse-surface: '#2b3234'
  inverse-on-surface: '#ebf2f4'
  outline: '#787586'
  outline-variant: '#c8c4d7'
  surface-tint: '#5847d2'
  primary: '#5341cd'
  on-primary: '#ffffff'
  primary-container: '#6c5ce7'
  on-primary-container: '#faf6ff'
  inverse-primary: '#c6bfff'
  secondary: '#5952af'
  on-secondary: '#ffffff'
  secondary-container: '#a19afd'
  on-secondary-container: '#352c8a'
  tertiary: '#00664f'
  on-tertiary: '#ffffff'
  tertiary-container: '#008166'
  on-tertiary-container: '#defff1'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e4dfff'
  primary-fixed-dim: '#c6bfff'
  on-primary-fixed: '#160066'
  on-primary-fixed-variant: '#4029ba'
  secondary-fixed: '#e3dfff'
  secondary-fixed-dim: '#c5c0ff'
  on-secondary-fixed: '#140067'
  on-secondary-fixed-variant: '#413996'
  tertiary-fixed: '#63fbcf'
  tertiary-fixed-dim: '#3fdeb4'
  on-tertiary-fixed: '#002118'
  on-tertiary-fixed-variant: '#00513f'
  background: '#f4fafd'
  on-background: '#161d1f'
  surface-variant: '#dde4e6'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 30px
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 12px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-sm: 0.75rem
  margin: 1.25rem
  margin-mobile: 1.25rem
  margin-tablet: 2rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
  space-2xl: 2.5rem
---

## Brand & Style

The design system embodies an inviting, frictionless, and high-finish atmosphere tailored for modern language acquisition powered by artificial intelligence. Moving away from clinical or strictly gamified interfaces, this design system combines warm encouragement with sleek, contemporary intelligence. 

The visual style unites playful tactile minimalism with soft glassmorphic depth. It is characterized by luminous lavender gradients, gentle organic pastels (mint green, soft lemon, warm peach), generous border radii, and pill-shaped touchpoints. Interactions feel buoyant, responsive, and friendly, dismantling the anxiety typically associated with foreign language practice through cozy visual softness, ambient diffused drop-shadows, and spacious compositional breathing room.

## Colors

The color palette centers around a dynamic spectrum of vibrant royal violet and soothing pastel lavender, accented with optimistic natural hues for active states, micro-badges, and interactive cards.

- **Primary Violet (`#6C5CE7`)**: Used for key call-to-action buttons, active navigation indicators, and primary focus states.
- **Secondary Lavender (`#A29BFE`)**: Forms the ambient gradient atmosphere, supporting badges, and subtle highlighted surfaces.
- **Tertiary Mint (`#55EFC4`)**: Signals streaks, correct responses, AI voice readiness, and positive feedback loops.
- **Soft Butter Yellow (`#FFEAA7`)**: Serves as an auxiliary accent for milestones, vocabulary cards, and streak achievements.
- **Neutral Dark (`#2D3436`) & Muted Slate (`#636E72`)**: Establish crisp, high-legibility hierarchy for headlines and supportive reading body text without harsh contrast.
- **Canvas Base (`#F9F8FD`) & Card Surfaces (`#FFFFFF`)**: Ground the experience in luminous, pristine warmth with translucent variations (`rgba(255, 255, 255, 0.7)`) for glass layers.

## Typography

Typography relies entirely on **Plus Jakarta Sans**, offering a clean geometric construction softened by humanist curves. 

Headlines employ bold weights (`700` and `600`) to present questions, prompt titles, and user metrics with clarity and approachable warmth. Body text emphasizes comfortable eye flow across multilingual exercises, keeping line heights generous (`1.4`–`1.5` ratio). Labels and micro-badges use tight, uppercase or title-cased medium weights to guarantee rapid scanning without overpowering core instructional material.

## Layout & Spacing

Layouts adhere to an 8pt spatial grid optimized for high-density mobile viewports. Safe areas accommodate native iOS/Android system elements seamlessly. 

Screen layouts utilize a flexible single-column flow with multi-card split grids (2 columns) for feature dashboards and modular quiz options. Lateral canvas margins are locked at `1.25rem` (20px) on mobile displays, expanding to `2rem` (32px) on tablets. Dynamic vertical spacing prioritizes ergonomic thumbs: primary conversational inputs, microphone triggers, and bottom floating tabs are anchored strictly within reachable bottom boundaries, balanced by generous top status and greeting headers.

## Elevation & Depth

Visual hierarchy uses layered tonal planes and diffused luminous drop shadows rather than sharp structural borders:

- **Ambient Tinted Shadows**: Flat gray shadows are avoided. Instead, elevation layers employ ultra-soft, diffused shadows tinted with primary lavender (`rgba(108, 92, 231, 0.08)` to `rgba(108, 92, 231, 0.16)` with blur radii between `16px` and `32px`).
- **Translucent Glassmorphism**: Interactive floating bars, audio wave backdrops, and secondary filters leverage translucent white fills (`rgba(255, 255, 255, 0.72)`) paired with `backdrop-filter: blur(20px)` and a whisper-thin 1px border (`rgba(255, 255, 255, 0.6)`).
- **Surface Nesting**: Inactive cards settle directly on the tinted canvas, while active selection states and AI voice modules float with physical lift through elevated soft glows.

## Shapes

The shape system is friendly and pill-forward. Standard content containers, modular exercise blocks, and flashcards use an ultra-smooth radius of `24px` to `28px` (equivalent to `rounded-3xl`), eliminating harsh corners entirely. 

Action buttons, badges, chips, and navigational docks are fully capsule-shaped (`border-radius: 9999px`). Organic, fluid pill silhouettes are also integrated inside graphical accents and background visual blobs to emphasize a lightweight, welcoming atmosphere.

## Components

### Buttons
- **Primary Button**: Pill-shaped (`rounded-full`), full-width or inline, filled with solid `#6C5CE7` or a soft linear gradient (`#6C5CE7` to `#8072F6`). White text, semi-bold typography, with a gentle purple drop shadow.
- **Secondary / Option Button**: White or glassmorphic pill with a crisp 1px neutral/lavender hairline stroke (`#EDEAFE`). Hover/active states transition into a tinted pastel purple fill (`#F3F1FE`).
- **Icon Action Button**: Circular (`w-12 h-12`), elevated with an ambient purple blur, housing clean vector iconography (e.g., audio play, speak, swap).

### AI Interaction & Voice Floating Module
- Rounded card (`rounded-[28px]`) with a saturated lavender-violet gradient.
- Accommodates centered circular microphone buttons with ripple pulsing rings indicating active voice synthesis and listening mode.

### Floating Bottom Navigation Bar
- Pill-shaped floating dock anchored above the bottom safe area.
- Built using deep dark charcoal (`#1E1F24`) or translucent glass (`rgba(255, 255, 255, 0.85)`).
- Features minimal circular active indicator highlights behind active destination icons.

### Cards & Exercise Containers
- **Content Cards**: Solid white background, rounded at `28px`, padded with `1.25rem`, accented with soft tinted drop shadows.
- **Answer Selection Tiles**: Distinct rounded rectangles (`rounded-2xl`) with clear typography; selected answers gain a lavender border with subtle background tinting (`#F3F1FE`).

### Micro-Badges & Chips
- Fully rounded pills (`px-3 py-1`) sporting playful pastel tones (e.g., mint green for "Active", soft lavender for "In Progress").
- Typography set in extra-small bold (`label-sm`).

### Input Fields & Search Bars
- Full pill or `rounded-2xl` fields bathed in pure white or translucent gray (`rgba(0, 0, 0, 0.03)`).
- Subtle placeholder text with leading voice and search icon triggers.