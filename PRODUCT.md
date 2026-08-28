# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Two roles:
- **Students** — Philippine Junior High School learners (Grades 7–10, DepEd/MATATAG curriculum), accessing science lessons, AR-augmented content, and quizzes tied to specific curriculum quarters/weeks. Assume typical junior-high digital literacy, not prior AR/tech-product experience.
- **Teachers** — manage lesson content, generate/print AR markers, create and grade quizzes, monitor class analytics, and control content access via unlock codes.

## Product Purpose

AR Science Explorer delivers the DepEd Grade 7–10 science curriculum (chemistry, biology, physics, quarters 1–4) through printed AR markers that unlock 3D visualizations, paired with lessons, pre/post-test quizzes, and progress tracking. It exists to make abstract science concepts (atoms, cells, forces, etc.) tangible by anchoring them to physical worksheets students scan with a camera.

## Positioning

The mechanism a generic LMS or quiz app can't copy: physical, printed, quarter/week-specific AR markers that trigger 3D science visualizations in the classroom, directly tied to the DepEd curriculum's own quarter/week structure — not a generic "scan any image" AR toy, and not a screen-only lesson viewer.

## Operating Context

- Classroom setting: teachers print AR marker sheets per lesson week; students scan them with a device camera to trigger the AR model.
- Content is gated by unlock codes (subject-wide, lesson-specific, or quiz-retake codes) that teachers generate and distribute.
- Backend: Firebase Auth + Firestore. Students authenticate via `studentId@arscience.school`-style accounts; teachers via a separate email domain/role.
- Local storage is used for uploaded lesson PDFs (base64) and some persisted UI preferences (theme, unlocked subjects) — a known technical constraint, not a deliberate architecture choice.

## Capabilities and Constraints

- Stack: React 18 + TypeScript (strict) + Vite + Tailwind CSS + Firebase + Zustand, React Router with role-based route guards.
- AR rendering relies on marker images (`public/markers/`) mapped 1:1 to `Q{quarter}W{week}` lesson slots, with GLB 3D models per lesson and a fallback marker path when an image fails to load.
- Quiz system has three unlock-code types (subject/lesson-wide, per-lesson, per-student retake) with one-time-use and expiration tracking.
- Pre-Tests are designed to always be retakeable by students without a code; this rule currently exists only in code, not communicated in the UI (a known gap surfaced in the design critique).
- No native mobile app — AR runs in-browser via camera access.

## Brand Commitments

- Product name **"AR Science Explorer"** is locked and must be preserved through any redesign.
- Logo mark (orbiting-atom motif), color palette (teal primary + subject colors), and all other visual elements are explicitly open for full replacement as part of the current redesign — the existing look is reference/anti-reference only, not a constraint.
- **Standing craft-bar reference (canon path, chosen deliberately over an exotic visual-world direction because this is an Operate-mode task tool, not a marketing surface):** Linear (crisp, restrained UI, confident whitespace, no decorative chrome), Notion (calm content density, quiet typographic hierarchy), Duolingo (warm, encouraging tone specifically at student failure/success moments — never punitive). Execute at this craft level; do not default to generic "AI dashboard" gradients/badges/mega-radii, and do not introduce an unrelated visual metaphor.

## Evidence on Hand

- Real curriculum content: `src/data/curriculum.ts`, `src/data/lessons.ts`, `src/data/q2QuizTemplates.ts` etc. contain actual DepEd-aligned learning competencies, objectives, and quiz questions per quarter/week — this is real content, not placeholder copy, and must be preserved as-is through any redesign.
- Real AR marker assets exist per quarter/week in `public/markers/` (recently aligned/replaced).
- No user testimonials, case studies, or external press exist; none should be fabricated.

## Product Principles

1. The AR marker mechanism is the product's actual differentiator and should be visually and structurally foregrounded, not buried as one tab among several.
2. Student-facing design should read as encouraging and age-appropriate for Grades 7–10, especially at failure/low-stakes-mistake moments (locked content, failed quizzes) — never punitive.
3. Teacher-facing design should read as a serious, efficient operating tool (Operate mode): clarity and task speed over decoration.
4. Student and teacher surfaces should share one coherent visual system (type scale, radius scale, component vocabulary) rather than two unrelated visual languages, even though their tone/content differs.
5. Real curriculum content and existing business logic (unlock codes, retake rules, quiz scoring) are product truth and must be preserved exactly; only presentation is in scope for redesign.

## Accessibility & Inclusion

Standard WCAG AA web accessibility: sufficient color contrast (avoid sub-4.5:1 caption text), full keyboard operability, visible focus states, accessible labels for icon-only controls and non-text status indicators (the current tooltip-only correctness dots are a known gap). No specialized device/bandwidth constraint beyond that.
