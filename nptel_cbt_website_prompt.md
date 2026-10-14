# Prompt: Build an NPTEL-Style Computer-Based Test (CBT) Website

Build a complete, production-quality Computer-Based Test (CBT) website that simulates the NPTEL online exam experience. It is for personal exam practice.

**Deliverable:** a single `index.html` with embedded CSS and vanilla JavaScript (no build step, no backend). The only external dependency allowed is Google Fonts. Add clear code comments and a short README explaining how to run the site and how to load questions.

---

## 1. Exam Configuration

Put everything in one `CONFIG` object at the top of the script:

- **Duration:** 180 minutes (editable, with quick presets of 30 / 60 / 180 minutes for practice)
- **Marking:** +1 per correct answer, 0 negative marking (both configurable)
- **Multiple-correct questions:** full marks only for an exact match (configurable option for partial credit)
- **Violation limit:** maximum tab-switch / fullscreen-exit warnings before auto-submit (default 3, configurable)

---

## 2. Question Bank

Load questions from a separate JSON array (`questions.json`, or an editable JS array at the top of the file).

**Schema:**

```json
{
  "id": 1,
  "week": 1,
  "topic": "Communication",
  "type": "single | multiple | truefalse",
  "text": "Question text",
  "options": [{ "id": "A", "text": "Option text" }],
  "answer": ["A"],
  "explanation": "Optional"
}
```

- Include 5 sample questions (at least one of each type) so the site works out of the box.
- True/False questions use fixed options: **True** and **False**.

---

## 3. Pre-Exam Flow (in this order)

1. **Welcome screen:** exam name, number of questions, duration and marking scheme.
2. **Instructions page** covering:
   - duration and the "no pause once started" rule
   - question types and how to answer each (circle = one answer, square box = select all that apply)
   - the question palette colour legend
   - marking scheme
   - navigation buttons and mark-for-review behaviour
   - auto-submit when time ends
   - fullscreen requirement and what counts as a violation
   - a required checkbox: *"I have read and understood the instructions"* before the Continue button enables
3. **System check page** with live pass/fail status for:
   - internet connection: `navigator.onLine` plus 3-5 timed ping requests to detect latency and instability, with a **Re-check** button
   - fullscreen support
   - screen size
4. **Start Test** button. On click, enter fullscreen with `requestFullscreen()` (it requires a user gesture), start the timer and begin the test.

---

## 4. Test Interface

### Layout

- **Top bar:** exam title, a large countdown timer (`hh:mm:ss`), and a compact progress indicator.
  - Timer turns subtly amber at 30 minutes left and red at 10 minutes left.
  - Show gentle, non-blocking toasts at 30, 10 and 5 minutes remaining.
- **Main area:** one question at a time, with a question number, a type label, the question text and the options.
- **Question palette** (side panel, collapsible on mobile):
  - numbered grid with 5 states: *Not Visited*, *Not Answered*, *Answered*, *Marked for Review*, *Answered & Marked*
  - live counts for each state
  - click to jump to any question
  - filter by week

### Answer Option Controls (important)

The control shape must tell the student the question type at a glance:

| Question type | Indicator shape | Behaviour | Label above options |
|---|---|---|---|
| Single correct | **Circle** (radio style) | Selecting one deselects the others | "Select one answer" |
| True/False | **Circle** (radio style) | Selecting one deselects the other | "True or False" |
| Multiple correct | **Square box** (checkbox style, slightly rounded corners) | Any number of options can be selected, and clicking again deselects | "Select all that apply" |

Details:

- Draw custom indicators with CSS (do not rely on the browser default look). Use the same size and alignment for every option.
- The whole option card is clickable, not only the indicator.
- **Circle:** when selected, show a filled inner dot that scales in smoothly.
- **Square:** when selected, fill with the accent colour and animate a checkmark drawing in (SVG stroke animation).
- Clear states for hover, focus (visible focus ring), selected and disabled.
- Use real `<input type="radio">` and `<input type="checkbox">` elements, visually restyled, so keyboard and screen-reader behaviour stays correct. Group them with `fieldset` / `legend` and ARIA labels.
- Reuse the same shapes (read-only) on the review screen, with correct and wrong markers shown next to them.

### Behaviour

- **Buttons:** Previous, Save & Next, Clear Response, Mark for Review & Next, and Submit Test.
- **Shuffle:**
  - randomise question order and option order for each attempt using Fisher-Yates
  - persist the shuffled order so a refresh does not reshuffle
  - keep True/False options in fixed order (True first)
  - keep the "all of the above" / "none of the above" style options last if they exist
- **Auto-save:** save each answer, the current question and time spent per question to `localStorage`.
- **Accurate timer:** use an absolute end timestamp (`Date.now()`) rather than a decrementing counter, so it stays correct after refresh, tab throttling or sleep.
- **Keyboard shortcuts:** `N` / `P` for next and previous, `1-4` or `A-D` to select options, `M` to mark for review. Show a small shortcut hint.

---

## 5. Exam-Integrity Features (best effort, client side)

- Detect fullscreen exit, tab switch (`visibilitychange`) and window blur.
  - Show a blocking overlay: *"Return to fullscreen to continue"* with a button that re-enters fullscreen.
  - Count each violation, display the warning count, and auto-submit when the limit is reached.
- Disable right-click, text selection on questions, copy/cut/paste, and common shortcuts (`F12`, `Ctrl+U`, `Ctrl+S`, `Ctrl+P`).
- Add a `beforeunload` warning.
- Detect a second tab running the test (`BroadcastChannel` or a `localStorage` lock) and block it.
- If the internet drops mid-test, show a calm offline banner. The test keeps running locally, and the banner clears when the connection returns.
- Log every violation with a timestamp and show the log in the final analysis.

---

## 6. Submission

- A confirmation modal with a summary (answered, unanswered, marked for review, time left) and **Submit** / **Go back** buttons.
- Auto-submit when the timer reaches zero.
- Guard against double submission.
- Exit fullscreen after submission.

---

## 7. Post-Submission Analysis Page

- **Score hero:** marks obtained / total, percentage, accuracy, attempted vs unattempted, and total time taken, with an animated count-up.
- **Breakdown** by week and by question type, drawn as clean horizontal bars in SVG/CSS (no heavy chart library).
  - Highlight the strongest and weakest week.
  - Show a short "What to revise" list.
- **Time analysis:** average time per question, the 5 slowest questions, and fast guesses (answered in under 5 seconds and wrong).
- **Full review** of every question: your answer vs the correct answer, plus the explanation if available.
  - Filters: All / Correct / Wrong / Unattempted / Marked for review.
- **Violation log.**
- **Actions:** Retake (new shuffle), Retake only wrong questions, Export result as JSON, Print / Save as PDF.
- **History:** keep past attempts in `localStorage` and show a small score-trend list.

---

## 8. Design and Animation

- **Look:** minimal white UI. `#FFFFFF` background, near-black text (`#111827`), one calm accent colour (indigo or deep blue), light grey borders and generous whitespace.
- **Fonts:** Inter for UI and body text (with a system-font fallback), and tabular numbers for the timer.
- **Style:** 8px spacing grid, 12px rounded corners, very soft shadows. No gradients and no clutter.
- **Animations** (subtle only, 150-250 ms ease):
  - fade and slight slide between questions
  - soft scale on option select
  - circle dot scale-in and checkbox tick draw-in
  - palette hover state
  - animated progress bar
  - score count-up
- Respect `prefers-reduced-motion`.
- **Responsive:** laptop first, usable on tablet and mobile.
- **Accessible:** semantic HTML, ARIA labels, visible focus rings and good colour contrast.

---

## 9. Quality Requirements

- Clean, modular code organised into sections: state, storage, timer, shuffle, rendering, integrity, analysis.
- Handle edge cases:
  - refresh mid-test
  - reopening after a crash
  - the browser back button
  - double submit
  - the time expiring while the confirm modal is open
  - a multiple-correct question with no option selected counting as unattempted
- Test the full flow end to end before giving me the final code, and list anything that could not be tested.
