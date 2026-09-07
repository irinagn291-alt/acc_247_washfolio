# Washfolio

Paint the year. Watch it bleed.

Washfolio is for people who want a year at a glance, not a chatty journal. Home is a 365-cell folio. Tap today, pick one of twelve named tones, and the stroke stays on that day. Consecutive days read as a wash, not a heatmap of chips.

## Architecture

Document-View. One `AlmanacFolio` is the year document — the single `ObservableObject` every view observes and never copies. `FolioCanvas`, `ToneWell`, and `WashSheet` bind to that document. Mutations live only on it: commit a `DayStroke` with neighbor-bleed, rewrite the twelve-tone palette, or change the bleed amount. The `UICollectionView` representable reads cell tones from the document and owns none of them.

This fits a year canvas: there is one folio, not a stack of screens with forked state.

## Neighbor-bleed wash

On commit, today's chosen tone lerps toward yesterday's stored tone when yesterday already has a `DayStroke`. The mix factor is the Settings bleed amount. An isolated day stays the pure picked tone. Consecutive bled days form a `WashRun`; a gap ends the run. Quiet streak is consecutive days ending today or yesterday — a gap restarts, with no broken-streak theatre. Analytics lists wash-run lengths, never a journal feed.

That lerp is why someone would pick this app: the year becomes a wash, not 365 chips.

## Art

Suminagashi floating-ink marble on damp rag paper, iron-gall black veins, rubric-red threads, almanac folio grain, quiet studio light, no text, no letters, no UI chrome.

| Image set | Prompt |
| --- | --- |
| `wfo_AppIcon` | Suminagashi floating-ink marble emblem filling the canvas edge to edge on rag paper, iron-gall veins and one rubric-red thread, no text, no letters, no rounded corners, no drop shadow, no alpha, subject inside the centre 80 percent |
| `wfo_Splash` | Tall rag-paper folio page with a quiet centre band, faint suminagashi wash at the margins, iron-gall and rubric-red veins, no text |
| `wfo_Onboarding1` | Closed almanac folio on rag paper, suminagashi marble on the cover, iron-gall and rubric red, no text |
| `wfo_Onboarding2` | A finger hovering over one cell of a year grid as a twelve-spoke ink well opens, suminagashi tones, rag paper, no text |
| `wfo_Onboarding3` | A finished year folio reading as one continuous ink wash, not a heatmap of chips, suminagashi marble, no text |
| `wfo_EmptyHome` | An empty year folio of blank rag-paper cells waiting for the first stroke, faint suminagashi mist, calm, no text |
| `wfo_EmptyList` | An empty wash-run sheet on rag paper, one unused rubric rule, no rows, no text |
| `wfo_CardBackdrop` | Low-contrast suminagashi marble on rag paper, pale iron-gall veins, quiet enough for ink text, no text |
| `wfo_ControlFace` | Face of a twelve-spoke radial ink well, almanac folio, iron-gall rim, rubric-red centre blot, no text |
| `wfo_TwistHero` | Two neighboring day cells whose inks bleed into one wash, suminagashi marble, rag paper, no text |
| `wfo_SuccessMark` | A small iron-gall ink blot committing a stroke, rubric-red fleck, rag paper, no text |
| `wfo_HeaderDecor` | Wide rubric rule and floating-ink marble band across rag paper, no text |

## How this is not a repeat

Not a food tracker: no Open Food Facts, no grams, no meal slots. Not a journal chrome clone: no Dashboard/Editor/Charts stack and no entry list. Not Moodling: there is no pet. Home is the year itself. The verb is paint-then-bleed. Typography is New York. Palette is rag paper, iron-gall, and rubric red (`#F4EBE0` `#E8D9C4` `#1A1510` `#9B2C28` `#7D6C58`).

## Build

```bash
cd Washfolio
xcodegen generate
xcodebuild -scheme Washfolio -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```
