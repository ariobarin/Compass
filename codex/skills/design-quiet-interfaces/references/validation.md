# Interface Validation

## Contents

1. [Validation Standard](#validation-standard)
2. [Choose The Evidence Depth](#choose-the-evidence-depth)
3. [Source Audit](#source-audit)
4. [State Inventory](#state-inventory)
5. [Static Visual Review](#static-visual-review)
6. [Interaction Review](#interaction-review)
7. [Geometry Review](#geometry-review)
8. [Motion Review](#motion-review)
9. [Async And Recovery Review](#async-and-recovery-review)
10. [Search Review](#search-review)
11. [Navigation Review](#navigation-review)
12. [Responsive Review](#responsive-review)
13. [Accessibility Review](#accessibility-review)
14. [Performance Review](#performance-review)
15. [Copy Review](#copy-review)
16. [Visual Grammar Review](#visual-grammar-review)
17. [Anti-Cheat Probes](#anti-cheat-probes)
18. [Defect Classification](#defect-classification)
19. [Completion Evidence](#completion-evidence)
20. [Audit Output Format](#audit-output-format)

## Validation Standard

Do not validate a stateful interface from a single screenshot.

Validate the observable contract across:

- Initial load
- Primary action
- Permission or preparation
- Active use
- Completion
- Background work
- Success
- Failure
- Recovery
- Refresh
- Navigation
- Desktop
- Mobile
- Keyboard
- Reduced motion

Static polish is evidence only for static claims. Use real interaction for
behavior claims.

Keep private user data out of screenshots, recordings, traces, and reports.
Use fixtures, synthetic content, or redaction. Record the viewport, browser,
commit, authentication state, network condition, and motion preference for each
run when reproducibility matters.

## Choose The Evidence Depth

Match validation depth to the claim and risk.

### Design Critique

Inspect:

- Source hierarchy and tokens
- Representative screenshots at desktop and mobile
- Core interaction paths
- Known loading, empty, failure, and recovery states

Do not claim implementation correctness.

### Visual Change

Inspect:

- Before and after at affected viewports
- Hover, focus, active, disabled, and reduced-motion states
- Neighboring components that share tokens or layout
- Text wrapping and responsive breakpoints

### Interaction Change

Inspect:

- The complete state cycle
- Focus movement
- Target geometry
- Interruption and repeated activation
- Recovery and refresh
- Pointer, keyboard, and touch paths

### Persistence Or Data-Safety Change

Inspect:

- Local and remote durability boundaries
- Offline behavior
- Refresh and resume
- Idempotency and duplicate prevention
- Recovery controls
- UI truth at each boundary

## Source Audit

Before rendering, identify the owning implementation.

Inspect:

- Root layout and route structure
- Global and local style sources
- Semantic token definitions
- Component or primitive system
- Interaction state owners
- Search and request logic
- Persistence and recovery state
- Reduced-motion behavior
- Responsive breakpoints
- Tests and acceptance contracts
- History of unusual visual corrections when available

Do not infer the current product from obsolete scaffolds, public exports, or
legacy routes when a newer application surface owns behavior.

### Audit Questions

1. What is the product sentence?
2. What surfaces exist?
3. Which component owns the primary act?
4. Which code owns each async state?
5. Which tokens govern the visual grammar?
6. Which patterns repeat intentionally?
7. Which inconsistencies appear accidental?
8. Which behavior is already protected by tests?
9. Which claims still require live evidence?

## State Inventory

List states from code and observed behavior. Do not rely on visible happy-path
controls alone.

Use a table:

| State | Trigger | Visible result | Available action | Focus | Durability | Evidence |
| --- | --- | --- | --- | --- | --- | --- |

Include hidden but consequential states such as:

- Slow permission
- Permission denial
- Low local storage
- Offline completion
- Stale authentication
- Processing after upload
- Missing deep link
- Stale search result
- Concurrent tab recovery
- Reduced motion
- Page hidden and restored

Mark unreachable states as implementation defects or obsolete code rather than
silently omitting them.

## Static Visual Review

Review the full viewport and focused details.

### Hierarchy

- Identify the first object the eye encounters.
- Count competing primary actions.
- Verify secondary work reads as secondary.
- Check whether whitespace creates focus or merely separates unrelated items.
- Check whether the visual hierarchy matches the current state.

### Typography

- Verify operating and consuming roles.
- Measure body line length and line height.
- Inspect title wrapping at realistic and worst-case lengths.
- Check tabular numbers for changing measurements.
- Check font loading fallback and layout shift.

### Color

- Measure actual contrast.
- Check translucent content against composited surfaces.
- Identify every use of the primary accent.
- Flag semantic collisions.
- Verify attention remains distinguishable without color alone.

### Shape And Depth

- Check radius consistency by function.
- Identify cards that do not need containment.
- Verify shadows correspond to real elevation.
- Check whether blur explains overlap or merely decorates.

### Density

- Evaluate each surface independently.
- Check that sparse surfaces retain orientation.
- Check that dense surfaces have strong grouping and scanning rhythm.

## Interaction Review

Exercise the interface instead of inferring behavior from handlers.

### Primary Action

- Activate with pointer.
- Activate with keyboard.
- Attempt repeated activation.
- Observe preparation, active, stopping, and completion states.
- Verify the label and accessible name.
- Verify focus return.

### Secondary Surface

- Open through every advertised input path.
- Search, select, clear, and close.
- Dismiss through expected platform behavior.
- Verify underlying interaction is blocked when modal.
- Verify the primary surface does not resize.

### Reader Or Detail

- Open a ready object.
- Open a processing object.
- Open a failed object.
- Play or inspect original media.
- Retry derived work.
- Return and preserve meaningful context.

## Geometry Review

Measure, do not eyeball, stable-object claims.

Capture bounding boxes for primary and stop controls during:

1. Idle
2. Hover
3. Active press
4. Permission or arming
5. Active work
6. Stopping
7. Local save
8. Transfer
9. Success
10. Error
11. Recovery

Compare:

- `x`
- `y`
- `width`
- `height`
- Center point

Define intentional exceptions, such as a mobile action that begins in a thumb
zone and moves to center after commitment.

### Layout Shift

Observe cumulative layout shift and record unexpected contributors. Pay special
attention to:

- Font replacement
- Async status insertion
- Skeleton replacement
- Image and media loading
- Validation errors
- Drawer open and close
- Long copy

Keep cumulative layout shift at or below 0.10 unless a stricter product target
applies.

## Motion Review

For every animation, record:

| Animation | Trigger | Communicated relationship | Properties | Cleanup | Reduced motion |
| --- | --- | --- | --- | --- | --- |

Reject animations that cannot name the relationship they communicate.

### Inspect

- Origin matches the invoking object.
- Related elements move as one system.
- Important targets do not move on hover.
- Continuous response maps to real input.
- Hidden pages suspend unnecessary work.
- Exit cleanup occurs before or independently of animation completion.
- No stale timers, frames, observers, or media contexts remain.
- Reduced motion preserves state clarity.

### Time-Separated Evidence

Use at least two snapshots separated in time to verify whether a supposedly
static reduced-motion state still animates. Check computed styles and changing
geometry, not only declared CSS.

## Async And Recovery Review

Simulate the boundaries the copy claims.

### Local Durability

- Complete the act offline.
- Verify the artifact exists in the promised local owner.
- Refresh only after local durability is confirmed.
- Verify the original remains available.

### Remote Durability

- Restore the network.
- Observe automatic retry.
- Confirm remote acknowledgment.
- Verify the UI changes from local or syncing to stored only after
  confirmation.

### Failure

- Force transfer failure.
- Force derived processing failure.
- Verify ordinary automatic retries remain quiet.
- Verify manual recovery appears only when needed.
- Retry once and confirm the control disappears after success.

### Idempotency

- Repeat a completion request.
- Refresh during transfer.
- Restore two tabs.
- Verify one user act creates one durable artifact.

### Copy Audit

At each state, ask: what exact boundary has been crossed? Compare the answer to
the displayed copy.

## Search Review

Validate the implementation's actual promise.

### Matching

- Exact word
- Partial prefix
- Multiple unordered clues
- Query with one absent clue
- One-character input
- Duplicate terms
- Punctuation
- Case difference
- Misspelling if promised
- Conceptual paraphrase if promised

### Request Ordering

Cause an earlier query to respond after a later query. Verify the later query
remains visible.

### Presentation

- Verify empty query uses the intended browse order.
- Verify active query uses relevance order.
- Verify chronology headings disappear when they misrepresent rank.
- Verify clear search is visible only when needed.
- Verify result-row geometry stays stable across statuses.

### Empty State

Check that copy suggests a productive next action and matches the search
system's capabilities.

## Navigation Review

### Deep Link

- Load a selected artifact directly.
- Verify its state without depending on a preloaded list.
- Verify missing and failed routes remain distinct.

### History

- Select an artifact.
- Return to the primary surface.
- Use browser Back and Forward.
- Verify selection, route, and visible controls agree.

### Stale Requests

Navigate rapidly between selections. Delay the first response. Verify it cannot
replace the current route.

### Refresh

Refresh idle, selected, processing, active where safe, and recovery states.
Verify promised continuity.

## Responsive Review

Validate at representative widths and at boundary widths.

Suggested minimum set:

- Narrow phone
- Typical phone
- Large phone or compact tablet
- Tablet
- Narrow desktop
- Wide desktop

### Inspect

- Primary action reach
- Safe-area spacing
- Drawer context glimpse
- Text wrapping
- Audio or media width
- Reader measure
- Touch target size
- Hover independence
- Breakpoint transition while open
- Landscape behavior
- Browser zoom at 200 percent

Do not accept a desktop screenshot scaled to phone width as mobile validation.

## Accessibility Review

### Semantics

- Use `main`, `nav`, `aside`, `section`, `article`, headings, labels, buttons,
  links, status, and alert roles correctly.
- Keep heading order meaningful.
- Give icon-only controls accessible names.
- Exclude decorative motifs from the accessibility tree.

### Keyboard

- Reach every action.
- Observe visible focus.
- Open and close overlays.
- Start and stop the primary act.
- Retry failures.
- Verify focus restoration.

### Modal Behavior

- Keep underlying content inert.
- Keep focus inside when appropriate.
- Restore focus to the invoker.
- Verify Escape only performs a safe expected action.

### Contrast And Zoom

- Verify WCAG AA for actual states.
- Check placeholders, disabled controls, and focus rings.
- Test 200 percent zoom and text enlargement.

### Motion

- Enable reduced motion.
- Verify all states remain understandable.
- Confirm looping and continuous decorative motion stops.

## Performance Review

### Rendering

- Inspect largest contentful paint.
- Inspect cumulative layout shift.
- Inspect interaction latency.
- Verify media dimensions are reserved.
- Verify fonts do not produce damaging shifts.

### Continuous Work

- Measure visualizer or animation frame rate.
- Verify the chosen frequency is perceptually sufficient.
- Hide the page and confirm frames, polling, and audio analysis suspend when
  safe.
- Restore the page and confirm prompt recovery.

### Network

- Test slow responses.
- Test offline and reconnect.
- Verify skeletons match final geometry.
- Verify stale requests cannot overwrite current state.

## Copy Review

Read every visible string in state order.

Check:

- One label per intent
- Concrete verbs
- Actual persistence boundary
- No implementation explanation without decision value
- No duplicate helper copy
- No invented precision
- No premature success
- Calm, actionable failure
- Search promise matches capability
- Empty states remain useful
- No em dashes or en dashes when the project forbids them

## Visual Grammar Review

Inventory uses of:

- Primary accent
- Attention color
- Success color
- Display type
- Body type
- Pill shape
- Card shape
- Shadow
- Blur
- Animated pulse
- Uppercase eyebrow
- Icon family

For each, ask whether every use carries the same responsibility. Flag semantic
drift before adjusting individual values.

## Anti-Cheat Probes

Use probes that distinguish real behavior from superficial compliance.

### Stable Geometry

Do not accept matching screenshots from different crops. Compare element
bounding boxes in one viewport.

### Reduced Motion

Do not accept a media query in source. Observe computed animation and geometry
over time.

### Saved State

Do not accept success copy. Verify the relevant storage owner acknowledges the
artifact.

### Search Relevance

Do not accept a search input. Verify prefix, inclusive, ordering, stale-request,
and empty-query behavior.

### Overlay Stability

Do not accept visual overlap. Measure the underlying primary surface before and
after opening.

### Focus

Do not accept visible controls. Start with keyboard only and verify focus entry,
containment, and return.

### Live Feedback

Do not accept a moving visualization. Change the actual input and verify the
response corresponds.

### Recovery

Do not accept a retry button. Verify the original survives, one retry succeeds,
and the control disappears afterward.

## Defect Classification

Classify findings by owning mechanism.

### Product Model

- Competing jobs
- Missing surface ownership
- Feature without durable value

### Interaction

- Moving target
- Broken focus
- Wrong navigation history
- Unsafe interruption

### State

- Missing state
- Untruthful status
- Duplicate owner
- Recovery gap

### Visual Grammar

- Semantic color drift
- Type-role drift
- Unmotivated shape or depth
- Density mismatch

### Motion

- No causal relationship
- Cleanup leak
- Reduced-motion failure
- Per-frame rerender

### Responsive

- Desktop shrink
- Poor reach
- Unsafe-area collision
- Touch target failure

### Performance

- Layout shift
- Jank
- Unbounded polling
- Hidden-page work

Fix the owning mechanism before polishing its symptoms.

## Completion Evidence

Record:

- Exact commit or artifact version
- Tested routes and surfaces
- Desktop and mobile viewports
- Browser and input modes
- Authentication state
- Network states
- Motion preference
- Checks run
- Measurements captured
- Unverified states

Do not imply production behavior from a build, static render, or source review.
Do not imply accessibility from semantic markup alone.

## Audit Output Format

Lead with the design thesis and the highest-impact mechanisms.

Use this structure when a full report is useful:

1. Product sentence
2. Design read and dials
3. Surface map
4. Why the interface works
5. Where the interface breaks its own grammar
6. Transferable principles
7. Elements that should not be copied
8. Highest-impact system changes
9. Behavior evidence
10. Unverified states

For each finding, include:

- Observation
- Mechanism
- User consequence
- Owning boundary
- Smallest coherent correction
- Evidence needed to close it

Avoid generic scorecards unless the numbers change decisions. Prefer a small
set of precise findings over a long list of taste adjectives.
