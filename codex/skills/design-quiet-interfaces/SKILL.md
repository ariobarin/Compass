---
name: design-quiet-interfaces
description: Design, redesign, implement, or critique focused product interfaces through surface ownership, stable interaction geometry, progressive disclosure, semantic visual systems, meaningful motion, forgiving recall, truthful asynchronous feedback, responsive reach, and behavior-level validation. Use for web UI and UX work where beauty, calm, coherence, trust, or satisfying interaction matter, including recording, writing, search, reader, personal-tool, creative-tool, and other single-purpose product experiences. Use for audits that must explain why an interface works, for extracting a reusable design language from an existing product, and for turning that language into implementation guidance. Do not use merely to decorate a page, imitate a dark aesthetic, or force sparse layouts onto information-dense products.
---

# Design Quiet Interfaces

Build interfaces that feel calm because the product has accepted complexity on
the user's behalf.

Treat quietness as low cognitive noise, not as a mandated visual mood. A quiet
interface may be bright, playful, dense, loud, or highly branded when that is
what the product requires. Preserve the deeper qualities: clear ownership,
stable objects, causal motion, semantic consistency, truthful feedback, and
deliberate exclusion.

## Load The Relevant Doctrine

Read only the references required by the task, but read each selected reference
completely.

- Read [references/principles.md](references/principles.md) before establishing
  a new visual direction, extracting a design language, or explaining why an
  existing interface feels coherent.
- Read
  [references/interaction-contracts.md](references/interaction-contracts.md)
  when the interface has modes, asynchronous work, recording or capture,
  search, drawers, readers, recovery, responsive behavior, or meaningful
  motion.
- Read [references/validation.md](references/validation.md) before implementing,
  reviewing, or declaring an interface complete.
- Read [references/log-case-study.md](references/log-case-study.md) when a full
  worked example would clarify the reasoning, when deriving another skill or
  design system from this one, or when preserving the evidence behind these
  principles matters.

## Begin With The Product Sentence

Write one sentence that identifies the product's durable job in the user's
language.

Use this form:

> Make it effortless to `<primary act>`, then make the result easy to
> `<durable outcome>`.

Do not begin with colors, components, layouts, or aesthetic references. Use the
sentence to decide what deserves the first viewport, what belongs behind
progressive disclosure, and what should disappear.

Reject product sentences that list features. Rewrite them until they express a
human action and its lasting value.

## Establish The Design Read

State the design read before proposing a system:

> Reading this as: `<product or page kind>` for `<audience>`, with a
> `<visual language>` direction, leaning toward `<implementation family>`.

Then set three explicit dials from 1 to 10:

- `DESIGN_VARIANCE`: compositional conventionality versus asymmetry and
  experimentation.
- `MOTION_INTENSITY`: static feedback versus continuous, cinematic, or
  physics-driven motion.
- `VISUAL_DENSITY`: gallery-like space versus information compression.

Use the values as constraints. Do not assign high motion without designing
meaningful motion. Do not call a composition sparse while filling it with
helper copy, cards, metadata, and decorative indicators.

## Map Surfaces Before Components

Define the smallest set of surfaces that owns the product's work. Give each
surface one job.

Prefer a surface map like this:

| Surface | One job | Primary action | Secondary escape | States |
| --- | --- | --- | --- | --- |
| Capture | Begin the thing | Start | Open history | Idle, arming, active |
| Active mode | Complete the thing | Stop or finish | Cancel if safe | Active, stopping |
| Recall | Find or recover | Search or select | Close | Empty, results, attention |
| Reader | Consume the result | Read or play | Return | Loading, ready, failed |

Adapt the labels to the product. Do not create a surface only because a feature
exists. Place a feature on the surface whose job it advances. If no surface can
own it without losing coherence, remove it or reconsider the product model.

Treat the surface count as a budget. New surfaces require a new user job, not a
new implementation subsystem.

## Define Invariants Before Styling States

Identify the objects whose position, dimensions, or meaning must remain stable
through the complete interaction cycle.

Record invariants such as:

- Keep the primary action at the same physical location through permission,
  loading, active work, stopping, saving, success, and failure.
- Keep start and stop controls at the same footprint when they represent one
  continuous object.
- Keep ordinary feedback out of document flow when inserting it would move the
  primary target.
- Keep overlays from resizing or recentering the underlying task.
- Keep each accent color, icon, and label attached to one durable meaning.
- Keep original user data accessible while derived work is processing.
- Keep the route, Back, and Forward behavior aligned with meaningful selection.

Design every state against these invariants. Do not patch layout shift after
the states have already diverged.

## Design The Complete State Cycle

List every observable state before implementing the success path.

Include the product equivalents of:

1. Idle
2. Arming or permission
3. Active
4. Stopping or committing
5. Durable locally
6. Synchronizing
7. Durable remotely
8. Processing derived content
9. Ready
10. Needs attention
11. Retrying or recovering
12. Missing or unrecoverable

For each state, specify:

- What remains invariant
- What visibly changes
- What action is available
- What statement is true
- Where focus belongs
- What happens on refresh, navigation, offline transition, or interruption
- What reduced-motion users receive

Use one stable object that changes state whenever continuity is more truthful
than replacing it with a new object.

## Make The First Viewport Ruthless

Give the first viewport one unmistakable primary action and at most one quiet
path to secondary work.

Remove:

- Explanations already communicated by the primary control
- Generic greetings and motivational copy
- Success copy that delays the next useful action
- Multiple calls to action with the same intent
- Navigation whose destinations do not matter before the first act
- Decorative status, version, weather, location, or system metadata
- Empty cards created only to balance a grid

Do not confuse emptiness with clarity. Preserve enough structure for
orientation, ownership, and escape.

## Use Progressive Disclosure Without Hiding Agency

Keep secondary work one gesture away without asking users to carry its visual
weight continuously.

Use an overlay, drawer, inspector, or revealed region when the secondary work
is temporary and should not displace the primary task. Preserve a visible
handle or reliable gesture so the secondary surface remains discoverable.

When revealing a surface:

- Let space appear before delayed labels or dense contents.
- Preserve the underlying task's center and dimensions.
- Show enough surrounding context to communicate that the surface is
  temporary.
- Return focus to the invoking control when the surface closes.
- Support pointer, keyboard, touch, and the platform's expected dismissal
  behavior.

Do not use progressive disclosure to bury primary actions, recurring errors,
or decisions required to continue.

## Build A Semantic Visual Grammar

Choose a small set of visual primitives and assign each one a stable job.

### Color

Define roles before values:

- Base surface
- Elevated or overlay surface
- Primary content
- Secondary content
- Structural line
- Primary signal
- Attention or failure
- Success only when success needs a distinct signal

Use one accent unless the product requires multiple semantic channels. Do not
introduce a late-page call-to-action color that competes with the established
signal.

Verify the real foreground and background combinations, including translucent
states, disabled controls, placeholders, focus rings, and overlays.

### Typography

Assign type roles by mode:

- Operating: controls, navigation, state, metadata, and compact lists
- Consuming: titles, reading, reflection, long-form content, and durable output
- Numeric: timers, measurements, counters, and changing values

Use one family when role can be expressed by weight, width, or italic. Use a
second family only when the product contains a genuine shift in mental mode.
Keep body measure near 60 to 70 characters and use tabular numbers for changing
values whose width must not jump.

### Shape

Choose a radius and shape grammar based on function:

- Use pills for actions that behave as one continuous object.
- Use circles for points, recording, presence, signal, or radial response when
  those meanings belong to the product.
- Use modest rounded rectangles for rows or containment that genuinely needs a
  target boundary.
- Use straight lines, alignment, and space instead of cards for ordinary
  grouping.

Do not reproduce a motif simply because it looked beautiful in another
product. Translate its meaning.

### Depth

Use blur, shadow, and elevation only to explain overlap, persistence, or
interaction priority. Keep ordinary content flat. Tint shadows to their
surrounding surface and avoid glass treatment on every container.

## Make Motion Causal

Require every animation to answer one question:

- Where did this surface come from?
- What object changed state?
- Is the system receiving input?
- What requires attention now?
- What relationship persists across the transition?

Use geometry-preserving changes for hover and press. Prefer changes in color,
border, luminance, or shadow over translation, rotation, or scale on important
targets.

When a full-screen mode begins from a control, originate the reveal from that
control. When start becomes stop, morph or crossfade within the same footprint.
When live data drives motion, make the motion correspond to the actual input
instead of playing an unrelated loop.

Use CSS transitions for discrete state changes. Use motion values, animation
frames, or another direct rendering path for continuous input. Do not send
per-frame values through component state.

Pause continuous work while hidden. Cap update frequency to what perception
requires. Clean up observers, contexts, frames, timers, and listeners. Provide
a complete reduced-motion state, not merely a shorter animation.

## Tell The Truth About Asynchronous Work

Name states according to the boundary actually crossed.

Prefer concrete statements such as:

- Saved on this device
- Waiting to sync
- Syncing
- Safely stored
- Processing
- Needs attention

Avoid words such as `Done`, `Saved`, or `Complete` when another durability or
processing boundary remains.

Place ordinary progress beside the object it describes. Avoid success toasts,
background-work popups, or temporary action groups when no decision is
required. Place recovery controls on the surface that owns recovery and expose
them only while action is needed.

Preserve final geometry during processing. Use a skeleton or reserved region
that resembles the resulting content. Keep original media or user input
available independently of derived output whenever the product permits it.

## Design Search Around Recall

Write search copy in the user's memory language. Define what imperfect input
the search system truly supports:

- Exact phrases
- Prefixes
- Fragments
- Misspellings
- Inclusive multiword recall
- Synonyms or semantic similarity
- Dates, people, places, or metadata

Do not promise semantic understanding when the implementation only performs
lexical matching.

Keep search responsive. Debounce only enough to avoid waste, cancel or
invalidate stale requests, and prevent older results from replacing newer
ones. Rank searched results by relevance rather than preserving unrelated
chronological grouping. Preserve chronology when the query is empty.

Use forgiving empty-state copy that suggests the next adjustment without
blaming the user.

## Redesign Mobile Behavior, Not Just Dimensions

Place controls according to reach, grip, interruption risk, and the product's
active mode.

Consider moving an idle primary action into a thumb-reachable zone, then moving
it to a centered or more deliberate position after commitment. Anchor reveals
to the control's real mobile position. Respect safe-area insets and browser UI.

Use at least 44-pixel touch targets where appropriate. Leave context visible
beside temporary drawers. Collapse high-variance layouts explicitly. Make media
and reading widths responsive to actual content needs.

Do not preserve desktop symmetry at the cost of mobile reach.

## Implement At The Owning Boundary

Inspect the existing visual language, tokens, component system, state model,
and repeated patterns before changing code.

Preserve brand assets that express the product's job. Separate them from
accidental inconsistency. Fix system-level causes before polishing individual
screens.

Prefer:

- Semantic HTML and real controls
- One component system or one coherent custom-CSS foundation
- CSS Grid for structural composition
- Server-rendered static layout with isolated interactive leaves where the
  framework supports it
- CSS custom properties for semantic tokens and live visual values
- Stable route identity for meaningful selections
- Contextual loading, empty, error, retry, active, disabled, focus, and hover
  states

Avoid:

- Decorative component abstraction before the interaction contract is stable
- Duplicate state owned by multiple surfaces
- Continuous animation through component rerenders
- Placeholder-only form labels
- Raw scroll listeners when observers or framework primitives fit
- New dependencies for behavior already supported by the current foundation
- Feature-specific visual exceptions that weaken the grammar

## Audit By Mechanism, Not Taste Words

When critiquing an existing interface, explain each reaction through an
observable mechanism.

Replace vague claims such as `clean`, `premium`, `delightful`, or `cluttered`
with evidence about:

- Competing actions
- Moving targets
- Broken hierarchy
- Unowned surfaces
- Untruthful system status
- Inconsistent semantic roles
- Layout shifts
- Unmotivated motion
- Search mismatch
- Reach and touch behavior
- Focus and navigation continuity
- Reading measure and density
- Recovery discoverability

Distinguish product-specific beauty from transferable law. State explicitly
what should not be copied.

## Produce The Smallest Useful Design Artifacts

Create only artifacts that change decisions. Depending on the task, return:

- Product sentence
- Design read and dial values
- Surface map
- State-cycle matrix
- Invariant list
- Semantic token grammar
- Motion map
- Persistence vocabulary
- Responsive behavior notes
- Behavior validation matrix
- Implementation patch

Do not create ceremonial mood boards, token catalogs, or exhaustive component
inventories when they do not advance the product.

## Final Gate

Before calling the work complete, apply the relevant procedures in
[references/validation.md](references/validation.md) and verify that:

- The first viewport expresses the product sentence.
- Each surface owns one job.
- The primary action remains unmistakable.
- Important targets remain geometrically stable across their state cycle.
- Secondary work is discoverable without remaining visually dominant.
- Motion communicates causality, input, or state.
- Async language matches actual durability and processing boundaries.
- Search behavior matches its promise.
- Responsive behavior accounts for reach and safe areas.
- Keyboard focus, Back and Forward navigation, reduced motion, failure,
  recovery, and refresh behavior are complete.
- The visual grammar remains semantically consistent.
- Real behavior has been exercised at desktop and mobile sizes.
- Anything that does not earn its place has been removed.

If evidence is unavailable, identify the unverified states instead of implying
completion.
