# Interaction Contracts

## Contents

1. [Contract Format](#contract-format)
2. [Primary Action Contract](#primary-action-contract)
3. [Full-Screen Mode Contract](#full-screen-mode-contract)
4. [Drawer And Overlay Contract](#drawer-and-overlay-contract)
5. [Reader Contract](#reader-contract)
6. [Asynchronous Persistence Contract](#asynchronous-persistence-contract)
7. [Processing Contract](#processing-contract)
8. [Recovery Contract](#recovery-contract)
9. [Search And Recall Contract](#search-and-recall-contract)
10. [Selection And Navigation Contract](#selection-and-navigation-contract)
11. [Live Feedback Contract](#live-feedback-contract)
12. [Motion Contract](#motion-contract)
13. [Responsive Reach Contract](#responsive-reach-contract)
14. [Focus And Keyboard Contract](#focus-and-keyboard-contract)
15. [Reduced Motion Contract](#reduced-motion-contract)
16. [Performance Contract](#performance-contract)
17. [Copy Contract](#copy-contract)
18. [State Matrices](#state-matrices)
19. [Implementation Patterns](#implementation-patterns)

## Contract Format

Write behavior contracts in observable terms. Keep implementation choices
separate unless they are necessary to preserve the behavior.

Use this form:

```text
Given <state and relevant history>
When <user action or system event>
Then <visible result>
And <persistence, navigation, focus, or recovery result>
```

Include anti-cheat probes for states that can look correct while violating the
contract. For example, a control may appear centered in screenshots while
moving several pixels between loading and success.

## Primary Action Contract

The primary action must remain unmistakable and physically dependable.

### Required Behavior

- Present one dominant action in the first viewport.
- Keep its accessible name concrete and stable.
- Preserve location and dimensions through its normal state cycle.
- Keep hover and active feedback inside the target's geometry.
- Show ordinary status near the action without shifting it.
- Return focus to the action after a temporary active mode closes.
- Keep secondary actions visually subordinate.

### State Cycle

| State | Label | Enabled | Geometry | Nearby feedback |
| --- | --- | --- | --- | --- |
| Idle | Begin, create, run, or compose | Yes | Baseline | None or durable status |
| Arming | Same intent or clear progress | Usually no | Identical | Quiet permission or setup state |
| Active | Stop, finish, or cancel | Yes | Same perceived object when continuous | Live confirmation |
| Stopping | Clear transition state | No | Identical | Preserve final measurement |
| Local | Ready for another act if safe | Yes | Baseline | Saved locally |
| Syncing | Primary act remains available if safe | Product dependent | Baseline | Syncing |
| Stored | Primary act available | Yes | Baseline | Safely stored, then quiet |
| Attention | Primary act or recovery as appropriate | Product dependent | Baseline | Contextual issue |

### Failure Probes

- Capture bounding boxes in every state and compare them.
- Trigger validation, permission denial, network failure, and retry.
- Verify status insertion does not change action position.
- Verify hover does not translate or scale the target.
- Verify double activation cannot create duplicate work.
- Verify focus returns after completion and failure.

## Full-Screen Mode Contract

Use a full-screen mode when the primary act requires concentration, continuous
feedback, or protection from unrelated actions.

### Entry

- Begin the transition from the invoking control's location.
- Move focus to the active mode or its primary stop control.
- Make the underlying interface inert.
- Preserve a truthful arming state while permissions or resources resolve.
- Do not expose a stop action before stopping is safe unless it can cancel
  arming correctly.

### Active State

- Show only controls and feedback that support the active act.
- Keep the stop or finish action easy to locate.
- Use changing values with tabular numbers.
- Confirm real input or progress without exaggerating precision.
- Warn before navigation when leaving would risk uncaptured work.

### Exit

- Stop continuous resources immediately when the act ends.
- Preserve the final measurement during the visual transition.
- Return focus to the invoking control.
- Keep durability independent of animation completion.
- Allow the close animation to finish through both its event path and a bounded
  fallback timer when necessary.

### Failure Probes

- Deny permission.
- Grant permission slowly.
- Stop immediately after starting.
- Navigate away during active work.
- Hide and restore the page.
- Enable reduced motion.
- End the animation early or prevent its event from firing.

## Drawer And Overlay Contract

Use a drawer or overlay for secondary work that should remain close without
reflowing the primary surface.

### Required Behavior

- Preserve the underlying surface's size and center.
- Provide a visible trigger and accurate expanded state.
- Support expected pointer, keyboard, and touch dismissal.
- Move focus into modal overlays when needed and return it on close.
- Keep the drawer's own scrolling independent of the page.
- Allow touch targets of at least 44 pixels on coarse-pointer or compact
  layouts.
- Leave enough page context visible on small screens to communicate temporary
  overlap when appropriate.

### Reveal Choreography

- Move the container first.
- Reveal its label after enough width exists.
- Avoid sliding every child independently.
- Keep swipe motion tied to the pointer.
- Disable transitions during an active swipe.
- Use a scrim only as strongly as focus requires.

### Interaction Ownership

- Keep each row to one primary action.
- Represent processing or attention through a small stable mark.
- Place retry or sync controls in a footer only while action is required.
- Do not place ordinary success confirmations in the drawer.

### Failure Probes

- Open and close with pointer, keyboard, and swipe.
- Escape while search has text.
- Select a row, then use browser Back and Forward.
- Resize while open.
- Open during active mode and verify the product's intended lockout.
- Tab through the overlay and ensure focus does not leak.

## Reader Contract

Use a reader surface for durable consumption rather than operational control.

### Required Behavior

- Keep the content column at a comfortable measure.
- Use a clear durable title or label.
- Make original media available independently of derived text.
- Preserve authored whitespace where meaningful.
- Give Back behavior a stable visual locus.
- Support deep links when a selected artifact has durable identity.

### Processing

- Preserve the final body's geometry with a skeleton or reserved region.
- Do not replace the body with explanatory processing copy.
- Allow playback or original inspection while derivation continues.
- Update the selected artifact without resetting scroll or navigation
  unnecessarily.

### Failure

- Explain that the original remains available when true.
- Offer one contextual retry action.
- Avoid modal failure if the reader can remain useful.

### Failure Probes

- Open a ready artifact.
- Open one immediately after creation.
- Refresh during processing.
- Force derived processing failure.
- Retry and verify the same route becomes ready.
- Open an unknown durable identifier.

## Asynchronous Persistence Contract

Define persistence boundaries explicitly.

### Example Boundary Model

| Boundary | Meaning | Allowed copy |
| --- | --- | --- |
| Capturing | Data exists in an active process | Recording or capturing |
| Local draft | Durable on this device | Saved locally |
| Queued | Waiting for transfer | Waiting to sync |
| Transferring | Bytes are moving | Syncing or uploading |
| Remote confirmed | Remote owner acknowledged durable storage | Safely stored |
| Derived work | Original is stored, transformation remains | Processing |
| Attention | Automatic progress stopped | Needs attention |

Do not use `Saved` without qualifying which boundary it means.

### Required Behavior

- Preserve one durable local owner for unsynchronized work.
- Prevent retries from creating duplicate durable artifacts.
- Keep automatic retry quiet.
- Expose manual recovery only after automatic progress cannot continue.
- Preserve original data across refresh when the product promises recovery.
- Keep persistence logic independent of UI transition completion.

### Failure Probes

- Go offline before the primary act.
- Go offline during the act.
- Go offline immediately after completion.
- Refresh after local durability but before remote confirmation.
- Restore the network and retry.
- Open two tabs and attempt concurrent recovery.
- Repeat a completed upload request.

## Processing Contract

Derived processing includes transcription, indexing, generation, analysis,
rendering, import, export, compilation, or thumbnail creation.

### Required Behavior

- Separate original durability from derived readiness.
- Keep processing geometry close to final geometry.
- Poll or subscribe without excessive work.
- Pause background polling while hidden when freshness permits.
- Resume promptly when visible.
- Preserve the selected artifact during list refreshes.
- Bound the number of actively monitored items.

### Skeleton Rules

- Match expected content width and vertical rhythm.
- Vary line widths enough to resemble text without creating fake precision.
- Avoid large layout changes when real content replaces the skeleton.
- Provide a status role or accessible label.
- Remove looping motion under reduced motion.

## Recovery Contract

Recovery should appear where the user manages affected objects, only when
automatic recovery has stopped.

### Required Behavior

- State what remains safe.
- State what needs attention.
- Offer one clear action.
- Disable the action while the same recovery is active.
- Preserve the object after a recoverable failure.
- Remove recovery controls after confirmation.
- Keep repeated automatic failures from producing repeated notifications.

### Copy Pattern

Use:

```text
<Safe state>. <Problem or boundary>. <Available action>.
```

Example:

```text
The recording is still on this device. Sync needs attention. Retry from the
library.
```

Avoid implementation detail unless it changes the user's decision.

## Search And Recall Contract

Define the exact matching promise before styling the input.

### Matching Choices

| User memory | Suitable behavior |
| --- | --- |
| Exact wording | Phrase or token match |
| Word beginning | Prefix index |
| Several unordered clues | Inclusive term matching |
| Misspelling | Fuzzy or edit-distance matching |
| Concept without wording | Semantic retrieval |
| Time or context | Metadata filters or blended ranking |

### Request Behavior

- Debounce enough to prevent waste without making typing feel delayed.
- Abort or invalidate stale requests.
- Verify late responses cannot replace current results.
- Keep empty-query browsing separate from active-query ranking.
- Limit result count and query complexity.
- Preserve selected state if its refreshed representation remains present.

### Result Presentation

- Remove chronology headings when relevance controls order.
- Use one action per row.
- Keep row geometry stable across ready, processing, and attention states.
- Use a visible clear action when the query is nonempty.
- Use an empty state that suggests broadening or shortening the query.

### Failure Probes

- Type rapidly enough to reorder response completion.
- Search one-letter and punctuation-only input.
- Search partial prefixes.
- Search multiple clues where only one appears in an artifact.
- Clear while a request is active.
- Select a result, navigate back, and restore the query if the product promises
  that behavior.

## Selection And Navigation Contract

Treat meaningful selection as navigation when users should share, refresh,
bookmark, or traverse it.

### Required Behavior

- Give selected artifacts stable route identity.
- Push a route on intentional selection.
- Clear selection through a route transition.
- Preserve browser Back and Forward semantics.
- Load a deep-linked artifact independently of the surrounding list.
- Distinguish loading, missing, error, and access-blocked states.
- Prevent stale selection responses from replacing a newer route.

### Visual Locus

Keep Back, close, and secondary-surface controls in predictable positions.
Desktop and mobile may use different representations when the interaction
context changes.

## Live Feedback Contract

Live visual response must correspond to real input or progress.

### Audio Example

- Use waveform power for overall amplitude.
- Use bounded frequency bands for distinct ring or bar response.
- Apply smoothing to prevent jitter.
- Clamp values to a stable visual range.
- Use direct style variables or a rendering surface.
- Update only as often as perception requires.

### Generalization

- Drawing can show the actual stroke or pressure.
- Simulation can show the actual changing state.
- Upload can show transferred bytes, not a decorative loop.
- Collaboration can show real presence or cursor activity.
- Search can show current request state without animating idle controls.

Do not fabricate responsiveness from a looping animation when the system is not
receiving input.

## Motion Contract

Create a motion map before implementation.

| Transition | Cause | Origin | Property | Duration | Reduced motion |
| --- | --- | --- | --- | ---: | --- |
| Primary to active mode | User commits | Invoking control | Clip, opacity | 240 to 360ms | Immediate reveal |
| Drawer open | User requests recall | Drawer edge | Transform, scrim | 220 to 360ms | Immediate open |
| Start to stop | State becomes active | Same footprint | Internal opacity | 150 to 220ms | Immediate swap |
| Content ready | Processing completes | Existing region | Opacity | 160 to 240ms | Immediate replace |
| Attention | Automatic progress stops | Affected object | Color or static mark | None or brief | Static mark |

### Required Behavior

- Animate only transform, opacity, clip, color, shadow, or other performant
  properties when possible.
- Keep motion anchored to cause.
- Avoid target movement during hover.
- Stop active resources before exit animation completes.
- Clean up every scheduled operation.
- Verify reduced motion through computed state, not source inspection alone.

## Responsive Reach Contract

Specify behavior by input context, not merely viewport width.

### Compact Touch Layout

- Place idle primary actions in a comfortable thumb zone when appropriate.
- Move committed or stop actions to a deliberate central locus when that
  reduces accidental activation.
- Respect safe-area insets.
- Use full-width media where narrow controls become awkward.
- Keep temporary drawers narrower than the viewport.
- Keep primary labels on one line when possible.

### Pointer Layout

- Preserve true or grid-based centering deliberately.
- Allow narrow persistent rails when they aid discovery without consuming
  attention.
- Use hover only as enhancement.
- Keep keyboard and focus behavior complete.

### Failure Probes

- Rotate the device.
- Resize across the breakpoint while a drawer or active mode is open.
- Test with browser UI and safe areas.
- Test coarse pointer without hover.
- Test long localized labels.
- Test text zoom and 200 percent browser zoom.

## Focus And Keyboard Contract

### Required Behavior

- Use semantic controls.
- Give every control a visible `focus-visible` treatment.
- Move focus into modal or full-screen active modes.
- Return focus to the invoker after close.
- Keep the underlying surface inert while a modal mode is active.
- Use Escape only when cancellation is safe and expected.
- Maintain logical tab order independent of visual animation.
- Give icon-only controls accurate accessible names.
- Keep state feedback in appropriate status or alert regions.

Do not remove outlines without a replacement. Do not rely on placeholder text
as a label.

## Reduced Motion Contract

Reduced motion must preserve:

- State order
- Focus order
- Input confirmation
- Active versus idle distinction
- Progress meaning
- Error and recovery meaning

Replace:

- Pulsing with a static filled signal
- Circular reveal with immediate visibility
- Sliding content with immediate placement
- Skeleton breathing with static geometry
- Live decorative response with a stable active indicator when continuous
  response could cause discomfort

Verify that JavaScript-driven work also reduces or stops when motion is no
longer displayed.

## Performance Contract

Performance supports emotional calm. Latency, jank, and layout shift make a
restrained interface feel untrustworthy.

### Targets

- Keep largest contentful paint plausibly below 2.5 seconds.
- Keep interaction latency plausibly below 200 milliseconds.
- Keep cumulative layout shift at or below 0.10.
- Keep live visual updates at the lowest useful frequency.
- Suspend audio analysis, polling, and animation while hidden when safe.
- Reserve dimensions for images, media, skeletons, and async content.

### Ownership

Keep continuous processing out of general component state. Isolate client-side
interaction leaves. Clean up media tracks, audio contexts, animation frames,
timers, observers, and listeners.

## Copy Contract

### Actions

- Use one label per intent across navigation, body, and recovery.
- Prefer concrete verbs.
- Distinguish Begin from Resume, Stop from Pause, Retry from Restart, and Close
  from Cancel.

### Status

- Describe the actual boundary.
- Keep normal status quiet.
- Explain what remains safe during failure.
- Avoid implementation names.

### Empty States

- Explain what will appear or how to broaden the search.
- Avoid fake enthusiasm.
- Avoid blaming phrasing such as invalid, wrong, or no luck when the user can
  simply adjust the query.

## State Matrices

Use a matrix before implementation.

### Generic Primary Flow

| State | Visible object | Action | Status | Focus | Persistence |
| --- | --- | --- | --- | --- | --- |
| Idle | Primary action | Begin | None | Primary action | None |
| Arming | Same object | Disabled or cancel | Preparing | Active region | None |
| Active | Same object, new internal state | Stop | Live feedback | Stop | In progress |
| Stopping | Same object | Disabled | Finalizing | Active region | Captured |
| Local | Primary action | Begin again if safe | Saved locally | Primary action | Local durable |
| Syncing | Primary action | Product dependent | Syncing | Primary action | Local durable |
| Stored | Primary action | Begin again | Safely stored | Primary action | Remote durable |
| Attention | Primary action plus contextual status | Product dependent | Needs attention | Relevant action | Local or remote known |

### Derived Content

| State | Original | Derived region | Action |
| --- | --- | --- | --- |
| Processing | Available | Skeleton | None |
| Ready | Available | Final content | Consume |
| Failed | Available | Contextual attention | Retry |
| Missing | Unknown or absent | Missing state | Return |

## Implementation Patterns

### Stable Feedback Region

Reserve or overlay status close to the primary action. Keep the action's box
independent of feedback length. Constrain status width and allow wrapping.

### Latest Request Ownership

Give each search or selection channel one request owner. Invalidate the prior
request before starting another. Apply a result only when its token remains
current.

### Direct Continuous Values

Write high-frequency values to CSS custom properties, canvas, SVG attributes,
or motion values. Keep React or framework state for semantic transitions, not
per-frame data.

### Animation Completion Independence

Complete persistence and resource cleanup from the state machine. Let animation
observe completion. Never require an animation event for data durability.

### Route-Owned Selection

Use durable identifiers in the route. Let direct route loading fetch selection
independently. Refresh the surrounding list without replacing a newer route.

### One Recovery Surface

Keep automatic retry in the background. Expose one manual retry control in the
surface that owns affected objects. Remove it immediately after confirmed
recovery.
