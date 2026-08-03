# Log Interface Case Study

## Contents

1. [Scope And Evidence](#scope-and-evidence)
2. [Product Sentence](#product-sentence)
3. [Design Read](#design-read)
4. [The Four Surfaces](#the-four-surfaces)
5. [Visual Grammar](#visual-grammar)
6. [Stable Primary Object](#stable-primary-object)
7. [The Library](#the-library)
8. [The Recording Room](#the-recording-room)
9. [The Reader](#the-reader)
10. [Search](#search)
11. [Persistence And Recovery](#persistence-and-recovery)
12. [Responsive Behavior](#responsive-behavior)
13. [Accessibility And Performance](#accessibility-and-performance)
14. [Copy](#copy)
15. [What Iteration Removed](#what-iteration-removed)
16. [Decision History](#decision-history)
17. [Brand Extension](#brand-extension)
18. [Compromises](#compromises)
19. [Transferable Extraction](#transferable-extraction)
20. [Source Map](#source-map)

## Scope And Evidence

This case study derives the skill's doctrine from `log.ariobarin.com`, a private
voice journal.

The reviewed current source was the Log repository's `origin/main` at commit
`05b7837`, titled `replace app auth with cloudflare access`.

Evidence included:

- Current workspace source and global styles
- Recording, search, persistence, and navigation logic
- UI contract tests
- The project's behavior-verification document
- Checked-in favicon, social image, and historical interface captures
- Commit history that recorded design corrections
- The original product direction: one centered recording action, a collapsed
  library, and search that feels forgiving when the user remembers only rough
  fragments

The live public route reached the Cloudflare Access gate. The authenticated
workspace was not visually inspected in that run. Behavior claims below are
therefore separated between source-backed contracts, checked-in visual
evidence, and historical intent.

## Product Sentence

The repository describes the product as a private voice journal with one job:
record a thought, keep the audio, transcribe it, and make it searchable.

Compressed into the design form:

> Make it effortless to think aloud, then make the thought easy to recover.

This sentence explains both halves of the product:

- Capture must be nearly frictionless.
- Recall must remain close without competing before capture.

It also explains what the product is not:

- A general media manager
- A dashboard
- A transcription editor
- A social publishing surface
- A video recorder
- An AI writing assistant

## Design Read

> Reading this as: a private voice journal for one returning owner, with a
> quiet nocturnal editorial language, leaning toward custom CSS and a small
> primitive layer.

### Design Dials

| Dial | Value | Evidence |
| --- | ---: | --- |
| Design variance | 5 | True-centered primary action plus asymmetric library rail |
| Motion intensity | 4 | Calm at rest, expressive circular mode transition and live rings |
| Visual density | 3 | Sparse capture and reader, density isolated in library |

## The Four Surfaces

The project's UI verification document names four product surfaces:

| Surface | Job | Primary behavior |
| --- | --- | --- |
| Recorder | Start a thought | Begin recording |
| Recording room | Capture safely | Stop recording |
| Library | Find or recover | Search and select, retry only when required |
| Note reader | Listen and reflect | Play original audio and read transcript |

New UI must support recording, finding, listening to, reading, or recovering a
note. This rule prevents features from arriving without surface ownership.

### Surface Separation

The recorder does not display the note list. The library does not resize the
recorder. The recording room makes the base interface inert. The reader does
not remove access to original audio while transcription remains incomplete.

The result is mode clarity without a large navigation system.

## Visual Grammar

### Palette

The CSS defines:

| Token | Value | Role |
| --- | --- | --- |
| `--paper` | `#171716` | Warm near-black base |
| `--paper-deep` | `#232321` | Secondary or elevated surface |
| `--ink` | `#f1eee7` | Warm primary content |
| `--muted` | `#97938b` | Secondary content |
| `--line` | `rgba(241, 238, 231, 0.11)` | Quiet structure |
| `--red` | `#e4624a` | Recording and attention signal |
| `--red-dark` | `#f27a62` | Brightened coral on dark surface |

Measured contrast against `#171716`:

| Foreground | Contrast ratio |
| --- | ---: |
| `#f1eee7` | 15.48:1 |
| `#97938b` | 5.86:1 |
| `#e4624a` | 5.25:1 |
| `#d0ccc4` | 11.20:1 |
| `#969188` | 5.73:1 |

The system avoids pure black and pure white. Warm neutrals connect operational
UI to the emotional material of a journal.

Coral remains scarce. It marks:

- Record
- Stop
- Live low-frequency response
- Attention
- Active loading breath

It does not become a general link or decorative color.

### Typography

DM Sans owns controls, search, list rows, state, and metadata. Newsreader owns
entry titles, timers, and reflective empty-state language.

This separates operating from consuming. The serif is not a random premium
accent. It appears when the user shifts from controlling the tool to reading a
thought.

The reader uses:

- Title size from 40 to 58 pixels on desktop
- Title line height near 1.04
- Transcript size near 17 pixels
- Transcript line height near 1.78
- Maximum reader width near 720 pixels

The timer uses tabular numbers so changing digits do not move.

### Shape

The product repeats a semantic set:

- Coral point for recording
- Concentric circles for voice response
- Pill for the stable record or stop object
- Thin horizontal or vertical lines for quiet structure
- Modest 8-pixel row radius for selectable list targets

The shapes come from recording and signal. They are not applied to every
container.

### Depth

Most content remains flat. Shadow and blur appear where elevation carries
meaning:

- The primary action receives subtle lift.
- The library drawer receives shadow and backdrop blur because it overlaps the
  workspace.
- Ordinary notes and rows do not become cards.

## Stable Primary Object

The record action is the first viewport's dominant object.

Desktop behavior:

- Place at the true viewport center.
- Ignore the narrow library rail when calculating physical center.
- Keep a minimum width of 210 pixels.
- Use an 18-pixel vertical and 27-pixel horizontal inset.
- Keep status below it without changing its box.

The stop action uses the same minimum width and padding. It occupies the same
center point inside the recording room.

### Hover Refinement

An early version translated the record button upward and scaled the stop button
on hover. The `calm recording controls` change removed those geometric effects.

Current hover behavior changes:

- Border contrast
- Surface luminance
- Shadow strength

The target no longer moves. This correction directly improved motor confidence.

### Status Placement

Attention and storage state are positioned under the action with bounded width.
They do not push the action or each other into a new center. When both appear,
the storage state moves farther down while the action remains invariant.

### Contract

The UI verification document requires the record action not to move during:

- Permission
- Stop
- Save
- Upload
- Success
- Failure

It also requires bounding-box capture across these states and cumulative layout
shift at or below 0.10.

## The Library

### Collapsed Rail

Desktop retains a 62-pixel fixed rail on the left. It contains a two-line mark.
The second line is shorter while closed and extends when the library opens.

The visible rail provides orientation and discovery without presenting list
density before it matters.

### Overlay

The open library is up to 390 pixels wide and overlays the workspace. It does
not resize the recorder or reader.

The drawer uses:

- A 340-millisecond transform
- An ease-out curve with strong deceleration
- Direct pointer-linked movement during swipe
- No transition while actively swiping
- Backdrop blur and lateral shadow to explain overlap

The `Library` label fades after the drawer has begun opening. Dense content
appears only once enough space exists.

### Mobile Drawer

On mobile the drawer is at most 320 pixels and leaves 48 pixels of the viewport
visible. A modest scrim establishes focus while retaining context.

### Rows

Each row is one button with:

- One truncated transcript-derived label
- A processing or attention mark only when needed
- Hover and active surface changes without internal reflow
- A minimum 44-pixel target on touch or compact layouts

No context menu remains. Recovery appears separately only when required.

### Grouping

With no query, notes group by Today, Yesterday, or date. During search, headings
disappear so relevance ranking is not contradicted by chronology.

## The Recording Room

The recording room is a fixed full-screen surface over the workspace.

### Entry

The surface begins as a circle at the control's location and expands to fill the
screen. Desktop origin is the center. Mobile origin is the idle control's safe
area position.

The base interface becomes inert. Focus moves to Stop once recording is active,
or to the recording room while arming.

### Active Object

The original `Begin recording` contents crossfade into:

- A small coral stop square
- `Stop recording`

The footprint remains stable.

### Timer

The timer was once very large and visually dominant. Iteration reduced it to a
quiet 22-pixel Newsreader value beneath the control. It confirms progress
without turning duration into the purpose of the surface.

### Storage Copy

`Recording locally` appears below the timer. This is a trust statement, not a
technical footnote. It tells the user where the current thought exists.

### Voice Field

Three concentric rings respond to actual audio:

- Overall waveform power controls field scale.
- 70 to 320 Hz controls the low ring.
- 320 to 1700 Hz controls the middle ring.
- 1700 to 5200 Hz controls the high ring.

The analyser uses a smoothing constant of 0.82. Values are clamped and written
to CSS custom properties. CSS maps them to scale, opacity, border color, and a
restrained coral glow.

The visual response confirms that the microphone is active and receiving the
speaker. It is not a decorative recording animation.

### Exit

Stopping immediately:

- Captures the final time
- Stops live visualization
- Stops media recording
- Begins a bounded close transition

Persistence does not depend on the animation event. A timer provides a fallback
to finish the visual state if necessary.

## The Reader

The reader occupies a narrow centered column rather than a card.

It contains:

- A title derived from the first seven transcript words
- Native audio controls
- A transcript, skeleton, or retry state

Using transcript words avoids generated-title latency and uncertainty. Before a
ready transcript exists, date and time provide the label.

### Original Independence

Audio remains available while transcription is processing or has failed. A
derived failure does not make the original recording feel lost.

### Skeleton

Five skeleton lines preserve transcript geometry. Their widths vary to resemble
text rhythm. The ready transcript replaces the skeleton without a major layout
reset.

### Failure

A small coral attention point and one `Retry transcription` action appear in
context. There is no modal, toast, or separate failure page.

### Reader Navigation

An earlier design overloaded the library control as Back. Later iteration gave
Back its own stable locus while preserving Library access appropriately across
desktop and mobile.

Desktop places the Back icon where the left rail's control normally lives and
hides the library trigger while reading. Mobile keeps the library trigger on
the left and shows a clear `Back` label on the right.

## Search

The search placeholder is:

> Search anything you remember

This phrasing matches rough recall rather than asking for a title or exact
keyword.

### Current Matching

The implementation:

- Lowercases the query
- Splits on whitespace
- Removes one-character terms
- Deduplicates terms
- Limits the query to eight terms
- Converts each term to an escaped prefix query
- Joins terms with inclusive `OR`
- Ranks results with FTS relevance and recency tie-breaking

This supports partial prefixes and incomplete multiword memory. It does not
provide semantic paraphrase or typo correction.

### Request Behavior

The client waits 160 milliseconds after typing, then sends the query. Starting
a new query invalidates the prior request. A late earlier response cannot
replace current results.

### Empty State Copy

Without notes:

> Your recordings will gather here.

Without results:

> Nothing surfaced yet. Try fewer words.

The copy remains calm and suggests how inclusive matching can be broadened.

## Persistence And Recovery

The calm interface is supported by complex durability work behind the glass.

The browser:

- Reserves space before beginning a long recording
- Saves recording chunks into IndexedDB
- Maintains one durable outbox owner
- Preserves data across refresh
- Retries transfer
- Keeps one user recording mapped to one remote artifact

The server:

- Confirms durable audio storage
- Processes transcription asynchronously
- Exposes status separately from original playback
- Protects against duplicate or competing upload ownership

### Visible Vocabulary

The interface distinguishes:

- `Recording locally`
- `Saved locally, waiting to sync`
- `Syncing`
- `Safely stored`
- `Needs attention`

Earlier versions showed success copy, background-work explanations, download
actions, and popup-style recovery. The later `rebuild journal around one
recording flow` change removed them.

### Recovery Location

Automatic retry remains quiet. When manual action is required, `Retry sync`
appears in the library footer. Recovery therefore lives with the collection of
recordings rather than beside the next recording action.

## Responsive Behavior

### Desktop

- Keep the record action at true viewport center.
- Keep a narrow persistent library rail.
- Use an overlay drawer.
- Keep reader Back at the left control locus.

### Mobile

- Place the idle record action near the bottom safe area.
- Animate it to the center after recording begins.
- Originate the recording-room reveal from the bottom action.
- Leave 48 pixels of context beside the drawer.
- Use 44-pixel row targets.
- Make audio controls full width.
- Reduce reader title size and transcript measure.
- Show an explicit Back label.

The mobile design changes reach and behavior. It is not a scaled desktop view.

## Accessibility And Performance

### Accessibility

The implementation includes:

- Semantic main, section, article, heading, button, input, status, and alert
  elements
- Accessible names for icon-only controls
- A screen-reader-only drawer title
- Visible focus treatment
- Focus movement into recording and back to Record
- Inert base content during recording
- Reduced-motion CSS
- Warnings before leaving active capture
- Touch target expansion

### Performance

The visualizer:

- Targets 15 frames per second
- Limits delayed catch-up
- Avoids per-frame React state
- Stops animation frames and closes the audio context
- Suspends while the document is hidden
- Resumes on visibility

The timer aligns updates to visible second boundaries rather than rerendering at
animation frequency.

## Copy

The copy is quiet because it is concrete.

### Strong Examples

- `Begin recording`
- `Stop recording`
- `Recording locally`
- `Search anything you remember`
- `Safely stored`
- `Needs attention`
- `Retry transcription`
- `This recording could not be found.`

These labels state intent, boundary, or available action. They do not perform
brand personality around routine system work.

### Removed Copy

The product removed:

- Generic hints about what to say
- Repeated success confirmations
- Background-work explanations
- Download-a-copy recovery prompts
- Popup actions

Subtraction allowed the remaining words to carry more force.

## What Iteration Removed

The final clarity did not appear in one visual pass. Iteration removed or
reduced:

- Hover movement
- Overlarge timer typography
- Decorative motion
- Sidebar resizing of the stage
- Context menus
- Generated titles
- Embedding-driven semantic search
- Extra archival and management actions
- Popup feedback
- Repeated success copy
- Multiple recording ownership paths
- In-app password UI after Cloudflare Access became the authentication owner

This is a useful distinction: beauty was achieved partly by moving complexity
to correct owners, not simply deleting capability.

## Decision History

The commit sequence documents the refinement:

| Commit | Decision |
| --- | --- |
| `e03e60f` | Rebuild the voice log interface |
| `0c6529b` | Calm recording controls and remove geometric hover motion |
| `9bdfb38` | Make recording rings respond to real audio |
| `b450699` | Anchor recording controls and voice field |
| `df180ec` | Simplify motion, restore true center, add focus treatment |
| `f4f4872` | Reduce timer and visualizer dominance |
| `b069c72` | Make the timer a quiet secondary value |
| `c80e754` | Redesign the mobile recording flow |
| `4d36fe5` | Make search ranking visually govern active results |
| `44d8605` | Give reader navigation its own stable locus |
| `61a9f00` | Rebuild the journal around one recording flow |
| `a329e5e` | Make long recording uploads durable |
| `05b7837` | Delegate production authentication to Cloudflare Access |

The sequence reveals the design method:

1. Establish the product direction.
2. Observe where interaction feels unstable or overexpressive.
3. Correct geometry and hierarchy.
4. Tie motion to real input.
5. Adapt behavior for mobile.
6. Improve recall.
7. Remove competing product paths.
8. Make system truth support the calm surface.

## Brand Extension

The social image uses a light warm-paper field, the `log` wordmark, a coral
center, and subtle concentric rings. The favicon uses the same warm cream,
charcoal, taupe, dark red, and coral with a layered four-point form around the
recording point.

The application itself is dark. The social card is light. Brand continuity
survives because the grammar, not the theme, remains stable:

- Quiet paper
- Editorial wordmark
- Center point
- Concentric signal
- Warm neutral relationship

This demonstrates how to extend a system without copying exact backgrounds.

## Compromises

### Cloudflare Access Entrance

Delegating authentication removes password and login state from the product,
which improves ownership and security. The default Cloudflare Access screen
breaks visual continuity before entry.

### Native Audio Controls

Native controls prioritize accessibility, playback reliability, and low
maintenance. Their visual rendering varies by browser and feels less integrated
than the surrounding custom system.

### Remote Fonts

Fonts load through a remote CSS import. Self-hosting would better support
privacy, predictable rendering, and performance.

### Reduced Motion Processing

CSS collapses animation durations under reduced motion. The audio analysis path
still performs work while recording, even when its visual transition is
effectively static. A stronger implementation could reduce that work too.

### Search Boundary

The inclusive prefix matcher handles rough fragments well but cannot find
conceptual synonyms. The copy should not be interpreted as a semantic-search
guarantee.

## Transferable Extraction

Do not copy:

- Dark mode
- Coral
- Newsreader
- Concentric rings
- A left rail
- A centered pill

Copy:

1. One product sentence
2. One job per surface
3. One dominant action per state
4. Stable primary geometry
5. Secondary complexity one gesture away
6. Motion tied to cause or real input
7. A small semantic visual grammar
8. Search aligned with imperfect recall
9. Persistence copy aligned with actual durability
10. Recovery placed with the objects it repairs
11. Original data independent of derived processing
12. Mobile behavior adapted to reach
13. Accessibility and performance treated as emotional quality
14. Subtraction before polish
15. Behavior-level verification rather than screenshot confidence

The deepest lesson is continuity. The primary object stays where it belongs.
Secondary complexity waits nearby. Motion explains what changed. Search behaves
like memory. Feedback tells the truth. The system absorbs complexity so the
surface can remain calm.

## Source Map

Primary source paths in the Log repository:

- `README.md`
- `app/(workspace)/workspace.tsx`
- `app/globals.css`
- `app/interaction-fixes.css`
- `app/use-log-library.ts`
- `app/use-recorder.ts`
- `app/use-recording-sync.ts`
- `lib/log.ts`
- `lib/search.ts`
- `lib/visualizer.ts`
- `docs/ui-verification.md`
- `tests/version-one-ui.test.ts`
- `tests/interaction-feedback.test.ts`
- `tests/visualizer.test.ts`
- `public/log-icon.svg`
- `public/og.png`
