# Washfolio — Build Specification

> Portfolio app 45, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Paint the year. Watch it bleed.

| Field | Value |
| --- | --- |
| Product name | Washfolio |
| Bundle identifier | `com.washfolio.year` |
| Domain | https://washfolio.pro |
| Contact URL | https://washfolio.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Light |
| Asset prefix | `wfo_` |
| User-Agent | `Washfolio/1.0 (iOS; +https://washfolio.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
5. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
6. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
7. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Washfolio -destination 'generic/platform=iOS' build`.
8. **Nothing may echo another app in this batch** in naming, layout or visuals.
9. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

Paint the year one stroke at a time.

### 2.1 User flow

1. Open the year canvas: 365 cells, today marked, empty cells blank
2. Tap today's cell; an in-place radial well of twelve tones opens on the canvas
3. Pick a tone and commit; the stroke stays on that cell
4. If yesterday has a stroke, today's committed tone blends toward it so the year reads as a wash
5. Open analytics as a sheet to read wash-runs and the quiet streak
6. Change the twelve-tone palette or the bleed amount in Settings

### 2.2 Essential behaviour

- 365-cell year canvas is home; there is no entry list and no tab bar
- One MoodStroke per local day, keyed by ordinal day of year
- Twelve tones chosen from an in-place radial well
- Neighbor-bleed on commit: lerp toward yesterday's tone when it exists; an isolated day stays pure
- Quiet streak: consecutive days ending today or yesterday; a gap restarts with no broken-streak theatre
- Analytics read wash-run lengths, not a journal feed
- Local only; no account, no social, no remote catalog

---

## 3. Uniqueness assignment for Washfolio

| Axis | Assigned value |
| --- | --- |
| Architecture | **Document-View (one year document, views observe it)** |
| UI approach | **SwiftUI hosting a UICollectionView compositional representable for the 365-cell year** |
| Naming convention | **Almanac lexicon** |
| File organization | **By document role (YearDocument, Stroke, Wash, Well)** |
| Dependency strategy | **None (zero external dependencies)** |
| Design direction | **Almanac folio (rag paper, rubric red, iron-gall)** |
| Typography | **New York** |
| Navigation pattern | **Locked-canvas chrome (tone well overlays the year; sheets only for analytics and settings)** |
| AI art style | **Suminagashi floating-ink marble** |
| Functional twist | **Neighbor-bleed wash (commit blends toward yesterday)** |
| Persistence | **UserDefaults + Codable snapshot** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — year_mood_canvas

**Core** — Paint the year one stroke at a time.

**Audience** — People who want a year at a glance, not a chatty journal.

**User flow**

1. Open the year canvas: 365 cells, today marked, empty cells blank
2. Tap today's cell; an in-place radial well of twelve tones opens on the canvas
3. Pick a tone and commit; the stroke stays on that cell
4. If yesterday has a stroke, today's committed tone blends toward it so the year reads as a wash
5. Open analytics as a sheet to read wash-runs and the quiet streak
6. Change the twelve-tone palette or the bleed amount in Settings

**Essential features**

- 365-cell year canvas is home; there is no entry list and no tab bar
- One MoodStroke per local day, keyed by ordinal day of year
- Twelve tones chosen from an in-place radial well
- Neighbor-bleed on commit: lerp toward yesterday's tone when it exists; an isolated day stays pure
- Quiet streak: consecutive days ending today or yesterday; a gap restarts with no broken-streak theatre
- Analytics read wash-run lengths, not a journal feed
- Local only; no account, no social, no remote catalog

**Twist** — Neighbor-bleed wash. Committing today's tone mixes it toward yesterday so consecutive days form a continuous wash; an isolated day stays pure. Analytics count wash-runs, not chips.

**Why this is not a repeat** — Not a food_tracker: no Open Food Facts, no grams, no meal slots, no barcode. Not Clickface: no desk calculator and no target face. Not Moodling: there is no pet. Not a daily_card: home is not a flip, it is the year itself. Not a journal_chrome clone: there is no Dashboard/Editor/Charts stack and no list of entries. The new verb is paint-then-bleed — unit-testable lerp on commit — so the year is a wash, not a 365-chip heatmap.

### 3.0a Craft from the shipped portfolio

These rules come from apps that already shipped. Follow them. Do not copy their type names or layouts.

**Ship these. They are what made the real apps feel finished.**

- Home **is** the mechanic (canvas, rings, tower, wheel, matrix, dial, board, console). A tab plus a list of records is a clone.
- One persisted verb on home. Unit-test that verb. A decorative Game / Aura / Circuit / Nest / Sweep tab is filler — do not ship one.
- Every primary list has an empty state: generated art, one headline, one line, one CTA. Blank `List` fails.
- Simulator seed only, once, behind a versioned key. Never seed on a device.
- Contact URL on Settings (or Goals). App Review looks for it.
- Offline: if the product needs a catalog, a local shelf must catch empty/fail search. A spinner forever fails.
- Denied camera (when used) explains the state and routes to Settings. Silent no-op fails.
- Numbers go through `NumberFormatter`. Day edges use `Calendar.current.startOfDay`.
- One haptic on a successful commit, none on navigation.
- VoiceOver labels on every icon-only control. Colour is never the only signal.

**Review screenshots (21AUG App02–09)**

The running app, not `ImageRenderer`. One launch argument, three keys:

- `-ReviewScreen today` — home after onboarding (often a no-op)
- `-ReviewScreen log` — log / statement / planner
- `-ReviewScreen goals` — goals / targets / profile

Read `ProcessInfo.processInfo.arguments` **once**, **after** onboarding is done.
If onboarding is still showing, the hook never fires.

Companion (Simulator only):

- Seed one demo day behind a versioned key (`{prefix}.demo.v1`).
- Mark onboarding complete in the same seed so the hook is reachable.
- `#if targetEnvironment(simulator)`. Never seed on a device.
- Seed fills the primary surface (four slot posts from the local shelf).

Driver (outside the app): build → install on iPhone and iPad → launch with the
argument → wait until the UI settles → `xcrun simctl io <udid> screenshot`.
Name files `{App}-{today|log|goals}.png`. Pick any available simulator UDID.

**Family `year_mood_canvas`**
- Home: 365-cell year canvas. Tap today → radial tone picker → one stroke.
- Invariant (unit-test this): One MoodEntry per startOfDay. Quiet streak = consecutive days ending today or yesterday; a gap restarts, no broken-streak theatre. 12 tones.
- Empty: The year is empty. The first stroke is yours.
- Fake that fails: A heatmap list, 1–5 scores, or a punishing streak.
- Never: Not a journal feed. Not Moodling's pet.

### 3.1 Architecture contract

One AlmanacFolio is the year document; it is the single ObservableObject that every view observes and never copies. FolioCanvas, ToneWell, and WashSheet bind to that same document and do not keep a forked year. Mutations live only on the document: commit a DayStroke with neighbor-bleed, rewrite the twelve-tone palette, or change the bleed amount. The UICollectionView representable reads cell tones from the document and owns none of them. No coordinators, no per-screen stores, and no Combine pipelines — a view calls a document method, published state changes, observers redraw.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

SwiftUI hosts a UICollectionView compositional layout through one UIViewRepresentable that draws the 365- or 366-cell year; leap length comes from Calendar.range of days in the year. The radial ToneWell, WashSheet, FolioSettings, and chrome are SwiftUI overlays and sheets on that representable, never a TabView or a pushed stack. Cells, bleed, and wash-runs are Path and Shape, not images. Each of the twelve well spokes has a spoken name so colour is never the only signal. Icon-only chrome has VoiceOver labels. One haptic on a successful commit, none on navigation.

### 3.3 Naming contract

Convention: Almanac lexicon.

Examples to follow: `AlmanacFolio`, `DayStroke`, `WashRun`, `ToneWell`

### 3.4 Dependency contract

Zero external dependencies. No SPM packages, no CocoaPods, and project.yml has no packages key. No VisionKit, no camera session, no Open Food Facts client. Foundation, SwiftUI, and UIKit for the year representable only.

### 3.5 Navigation contract

The year canvas never leaves. Tapping today's cell opens the ToneWell as an in-place overlay; commit paints the cell and dismisses the well. WashSheet and FolioSettings arrive as sheets from the canvas chrome. No tab bar, no entry list, no pushed detail. After onboarding, read ProcessInfo.processInfo.arguments once: -ReviewScreen today stays on FolioCanvas, log presents WashSheet, goals presents FolioSettings.

### 3.6 Screen composition contract

The year canvas never leaves. Today opens an in-place radial tone well; commit paints the cell. Analytics and Settings arrive as sheets from the canvas chrome. No tab bar, no entry list, no pushed detail. Physical screens: FolioCanvas (root; ReviewScreen today), WashSheet (sheet; ReviewScreen log), FolioSettings (sheet; ReviewScreen goals; contact URL, palette, bleed amount, re-run onboarding, reset). ToneWell is an overlay on FolioCanvas, not a destination. Onboarding is a one-shot cover that writes defaults and a completion flag. Empty FolioCanvas copy: The year is empty. The first stroke is yours.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

---

## 4. Target file organization

Scheme: **By document role (YearDocument, Stroke, Wash, Well)**

```
Washfolio/
  YearDocument/
Stroke/
Wash/
Well/
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Canvas
A first-class screen for **Canvas**. Must render empty, populated and error states.

### 5.3 Analytics
A first-class screen for **Analytics**. Must render empty, populated and error states.

### 5.4 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.5 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.6 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.

---

## 6. Domain model

Minimum entities, named per this app's convention:

- **MoodEntry** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **Almanac folio (rag paper, rubric red, iron-gall)**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#F4EBE0` | Screen background |
| `surface` | `#E8D9C4` | Cards, rows, sheets |
| `ink` | `#1A1510` | Primary text and icons |
| `accent` | `#9B2C28` | Primary action, key figure, progress fill |
| `muted` | `#7D6C58` | Secondary text, dividers, disabled |

Define these as named colours in `Assets.xcassets` and reach them through one
typed accessor. Never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **New York**

New York only, reached as system serif: Display for the year title and ordinal captions, Text for body and sheet copy. At most six named steps behind one accessor. Weights carry hierarchy; no size jump above 34pt. Text stays legible at the largest Dynamic Type size.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- One corner radius value applied consistently, or deliberately none if the
  design direction calls for hard edges.
- Every interactive element is at least 44x44 pt.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults + Codable snapshot**

One Codable AlmanacFolio snapshot in UserDefaults under a single key; the UI never sees UserDefaults. A day is startOfDay from Calendar.current and is stored as ordinal day of year. One DayStroke per startOfDay; writes debounce and survive a force-quit; Settings exposes resetAllData(). Simulator-only seed behind wfo.demo.v1 paints a short wash-run on the canvas and marks onboarding complete so the ReviewScreen hook can fire; never seed on a device.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Washfolio/1.0 (iOS; +https://washfolio.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- The app must not present itself as medical advice. It is a personal food log.
- Nutrition data is credited to Open Food Facts, a public database.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.lifestyle`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Light
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.lifestyle
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Neighbor-bleed wash (commit blends toward yesterday)

On commit, today's chosen tone lerps toward yesterday's stored tone when yesterday already has a DayStroke; the mix factor is the Settings bleed amount. An isolated day with no yesterday stroke stays the pure picked tone. Consecutive bled days form a WashRun; a gap ends the run with no broken-streak theatre. Quiet streak is consecutive days ending today or yesterday; a gap restarts. Analytics lists wash-run lengths, never a journal feed of chips. Unit-test the lerp and the family invariant: one MoodEntry per startOfDay, twelve tones, storage keyed by ordinal day of year.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Suminagashi floating-ink marble**

Base prompt, reused and extended for every asset:

```
Suminagashi floating-ink marble on damp rag paper, iron-gall black veins, rubric-red threads, almanac folio grain, quiet studio light, no text, no letters, no UI chrome
```

All 12 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `wfo_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `wfo_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `wfo_Splash` | 1290x2796 | allowed | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `wfo_Onboarding1` | 1024x1536 | allowed | Onboarding page 1 illustration: what the app is for. |
| 4 | `wfo_Onboarding2` | 1024x1536 | allowed | Onboarding page 2 illustration: the main verb. |
| 5 | `wfo_Onboarding3` | 1024x1536 | allowed | Onboarding page 3 illustration: why they stay. |
| 6 | `wfo_EmptyHome` | 1024x1024 | allowed | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `wfo_EmptyList` | 1024x1024 | allowed | Empty state: a secondary list has no rows. |
| 8 | `wfo_CardBackdrop` | 1200x800 | allowed | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `wfo_ControlFace` | 512x512 | allowed | Custom control artwork used for the primary interactive element. |
| 10 | `wfo_TwistHero` | 1024x1024 | allowed | Hero art for the 'Neighbor-bleed wash (commit blends toward yesterday)' feature screen. |
| 11 | `wfo_SuccessMark` | 512x512 | allowed | Shown briefly when the primary action succeeds. |
| 12 | `wfo_HeaderDecor` | 1200x600 | allowed | Decorative header accent on the main screen. |

### Prompt per asset

**`wfo_AppIcon`** — 1024x1024

```
Suminagashi floating-ink marble emblem filling the canvas edge to edge on rag paper, iron-gall veins and one rubric-red thread, no text, no letters, no rounded corners, no drop shadow, no alpha, subject inside the centre 80 percent
```

**`wfo_Splash`** — 1290x2796

```
Tall rag-paper folio page with a quiet centre band, faint suminagashi wash at the margins, iron-gall and rubric-red veins, no text
```

**`wfo_Onboarding1`** — 1024x1536

```
Closed almanac folio on rag paper, suminagashi marble on the cover, iron-gall and rubric red, no text
```

**`wfo_Onboarding2`** — 1024x1536

```
A finger hovering over one cell of a year grid as a twelve-spoke ink well opens, suminagashi tones, rag paper, no text
```

**`wfo_Onboarding3`** — 1024x1536

```
A finished year folio reading as one continuous ink wash, not a heatmap of chips, suminagashi marble, no text
```

**`wfo_EmptyHome`** — 1024x1024

```
An empty year folio of blank rag-paper cells waiting for the first stroke, faint suminagashi mist, calm, no text
```

**`wfo_EmptyList`** — 1024x1024

```
An empty wash-run sheet on rag paper, one unused rubric rule, no rows, no text
```

**`wfo_CardBackdrop`** — 1200x800

```
Low-contrast suminagashi marble on rag paper, pale iron-gall veins, quiet enough for ink text, no text
```

**`wfo_ControlFace`** — 512x512

```
Face of a twelve-spoke radial ink well, almanac folio, iron-gall rim, rubric-red centre blot, no text
```

**`wfo_TwistHero`** — 1024x1024

```
Two neighboring day cells whose inks bleed into one wash, suminagashi marble, rag paper, no text
```

**`wfo_SuccessMark`** — 512x512

```
A small iron-gall ink blot committing a stroke, rubric-red fleck, rag paper, no text
```

**`wfo_HeaderDecor`** — 1200x600

```
Wide rubric rule and floating-ink marble band across rag paper, no text
```


### 13.3 Asset rules

- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, background textures, and anything else that needs a guaranteed transparent region or a guaranteed seamless join are drawn in SwiftUI via `Path` or `Shape`. The image generator is not used for these elements: it guarantees neither an alpha channel nor a seamless tile.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. Never seed on a physical device. Guard with
`#if targetEnvironment(simulator)` and `wfo.demo.v1`.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as primary iconography.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.


---

## 17. Tests

Add a unit test target `WashfolioTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. Snapshot unit tests for every main screen named in section 3.6.
   Each of those screens must be a `*View` or `*Screen` type that constructs
   with no arguments (demo fixtures inside the view). The factory runs these
   tests on iPhone and iPad and keeps the PNGs.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Washfolio -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.

**Uniqueness**
- [ ] Architecture matches **Document-View (one year document, views observe it)** with no leakage across layers.
- [ ] UI approach matches **SwiftUI hosting a UICollectionView compositional representable for the 365-cell year**.
- [ ] Navigation matches **Locked-canvas chrome (tone well overlays the year; sheets only for analytics and settings)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **New York** and nothing else.
- [ ] Palette matches section 7.1 exactly.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Washfolio
xcodegen generate
xcodebuild -scheme Washfolio -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
xcrun simctl list devices available
xcodebuild -scheme Washfolio -destination 'platform=iOS Simulator,id=<UDID>' test
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY or DEVELOPMENT_TEAM in project.yml — CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
