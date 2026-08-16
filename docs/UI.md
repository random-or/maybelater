# MaybeLater — UI Specification

## Visual Direction

Dark.
Minimal.
Technical.
Professional.
Fast.

The app should feel like a serious utility rather than a generic Material demo.

## Palette

```dart
background    = Color(0xFF09090E);
surface       = Color(0xFF111118);
surfaceHigh   = Color(0xFF1A1A27);
border        = Color(0xFF1E1E2E);

accent        = Color(0xFF7C3AED);
accentLight   = Color(0xFF8B5CF6);
accentGlow    = Color(0x337C3AED);

textPrimary   = Color(0xFFE2E8F0);
textSecondary = Color(0xFF94A3B8);
textMuted     = Color(0xFF475569);

success       = Color(0xFF10B981);
warning       = Color(0xFFF59E0B);
danger        = Color(0xFFEF4444);
```

Do not make every element purple.

## Typography

Primary UI font:

Inter.

OCR/technical text:

JetBrains Mono.

Suggested:

- display: 24px / 700
- title: 18px / 600
- body: 14px / 400
- caption: 12px / 400
- OCR: 13px / 400

Bundle required fonts for offline behavior.

## Home

Show:

- library count from database
- search entry
- recent screenshots
- collections
- bottom navigation

Never show fake counts.

## Gallery

Default 3-column grid.

Requirements:

- thumbnails only
- lazy loading
- multi-select
- long press selection
- sorting
- favorites
- delete

Support grid density changes where practical.

## Search

Search should be the most polished screen.

Opening search should feel instant.

Show recent searches when empty.

Results should appear as the user types.

## Detail

Show:

- full image
- zoom
- favorite
- share
- collection
- tags
- OCR
- metadata
- delete

OCR must be selectable/copyable.

## Import

Show:

- selection actions
- progress
- completed count
- failed count
- remaining count
- pause/resume/cancel where supported
- retry failures
- background status

## Cleaner

Tinder-like swipe behavior:

left = trash
right = keep

Requirements:

- card follows finger
- subtle rotation
- haptic feedback
- small preload stack
- OCR snippet
- progress

Trash must be recoverable.

## Settings

Include:

- appearance
- grid size
- sorting
- OCR settings where supported
- import behavior
- trash
- storage
- notifications
- privacy
- about

## Empty States

Always explain what the user can do next.

## Errors

Show human-readable messages.

Never expose stack traces in normal UI.

## Animation

Use approximately 150–300ms for micro-interactions.

Animations must not delay interaction.

Avoid animation overload.

## Accessibility

Use:

- adequate contrast
- semantic labels
- reasonable touch targets
- screen-reader labels
- information not conveyed by color alone
