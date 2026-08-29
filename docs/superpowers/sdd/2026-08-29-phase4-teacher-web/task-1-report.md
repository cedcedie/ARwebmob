# Task 1 report — Add Phase 4 dependencies

**Status:** DONE
**Commit:** `ce017287550eb9e62421852c6c9a5c002aa8823c` (worktree `phase1-scaffold-core-auth`, branch `worktree-phase1-scaffold-core-auth`)
**Test summary:** 115/115 passing, no regressions (same count before and after)

## What was done

Added 6 new dependencies to the `dependencies:` section of `pubspec.yaml` for
upcoming Teacher Web screens/forms (Tasks 2+ of Phase 4). No Dart code
references these packages yet — this task only makes them resolvable.

## Versions used, and where each was checked

Checked each package's version list directly on pub.dev (not from memory)
immediately before editing `pubspec.yaml`:

| Package | Version added | Latest on pub.dev at check time | Notes |
|---|---|---|---|
| `shadcn_ui` | `^0.56.2` | `0.56.2` (published 2 days ago) | Used latest — no ecosystem-breaking dependency change found in its version history/changelog. |
| `data_table_2` | `^2.7.2` | `3.0.0` (published 12 days ago) | **Deliberately not latest** — see "Deviation" below. |
| `lucide_icons_flutter` | `^3.1.17` | `3.1.17` (published 8 days ago) | Used latest — pure icon-font package, no Material coupling. |
| `flutter_form_builder` | `^10.3.0` | `11.0.0` (published 13 days ago) | **Deliberately not latest** — see "Deviation" below. Resolves to `10.3.0+2`. |
| `form_builder_validators` | `^11.3.0` | `11.3.0` (published 6 months ago) | Used latest — validators are Dart-only (regex/string/number checks), no Flutter Material coupling, independent of `flutter_form_builder`'s own version. |
| `model_viewer_plus` | `^1.10.0` | `1.10.0` (published 9 months ago) | Used latest — WebView-based 3D viewer, unaffected by the Material change below. |

`cached_network_image` and `firebase_storage` were intentionally **not**
added, per the brief.

## Deviation from "always use latest" — and why

While checking pub.dev, I found that **`data_table_2` v3.0.0** and
**`flutter_form_builder` v11.0.0** (both published in the last two weeks)
are breaking releases that migrate their public APIs from
`package:flutter/material.dart` to the new standalone `material_ui` package
introduced in Flutter 3.47 (this project is on Flutter 3.44.0 / Dart
3.12.0, confirmed via `flutter --version`). Concretely:

- `data_table_2` 3.0.0's `DataColumn`/`DataRow`/`DataTable` types now come
  from `material_ui` instead of the Flutter SDK, and its own docs warn that
  mixing SDK Material imports with `data_table_2` 3.x "can cause type
  identity mismatches." It also requires Dart SDK `>=3.13`, which the
  installed toolchain (Dart 3.12.0) does not satisfy.
- `flutter_form_builder` 11.0.0's migration notes say the same: "this
  package migrated to the official `material_ui` library... use
  `package:material_ui/material_ui.dart` instead of
  `package:flutter/material.dart`." It also requires Dart SDK `>=3.13`.

Adopting either would force this whole app onto `material_ui` (a brand-new,
2-week-old ecosystem shift) just to add two Teacher Web dependencies with no
consuming code yet, and `flutter pub get` would fail outright against the
installed Dart 3.12.0 SDK regardless. That's a much bigger, riskier change
than "add dependencies for later tasks," and it's exactly the kind of
version mismatch this task explicitly asked me to avoid repeating. The
brief itself also anticipated `^2.x.x` / `^9.x.x` for these two packages,
consistent with staying off the v3/v11 migration.

I instead pinned each to its latest version *before* that migration:

- `data_table_2: ^2.7.2` (latest 2.x; the intervening `2.8.0` also requires
  Dart `>=3.13`, so `2.7.2`, Min Dart SDK `3.0`, is the newest one
  compatible with this project's toolchain)
- `flutter_form_builder: ^10.3.0` (latest 10.x, Min Dart SDK `3.10`,
  resolves to `10.3.0+2`)

Both are recent, actively-published stable releases (not old/abandoned), so
this isn't guessing a version from memory — it's a deliberate, documented
choice to avoid an unrelated ecosystem migration and a hard SDK-version
resolution failure. A future task can revisit `material_ui` adoption
project-wide if desired, but that should be its own explicit decision, not
a side effect of this dependency-only task.

## `flutter pub get` result

Ran in the worktree root. Resolved cleanly with no conflicts against the
existing Riverpod/Firebase/go_router versions:

```
Resolving dependencies...
Downloading packages...
...
+ data_table_2 2.7.2 (3.0.0 available)
+ flutter_form_builder 10.3.0+2 (11.0.0 available)
+ form_builder_validators 11.3.0
+ lucide_icons_flutter 3.1.17
+ model_viewer_plus 1.10.0
+ shadcn_ui 0.56.2
... (plus transitive deps: flutter_svg, webview_flutter*, url_launcher*,
    two_dimensional_scrollables, boxy, extended_image*, slang*, xml,
    android_intent_plus, etc.)
Changed 38 dependencies!
50 packages have newer versions incompatible with dependency constraints.
```

Exit code `0`. The "50 packages have newer versions" note is expected/
pre-existing noise (unrelated transitive packages with newer majors not
compatible with current constraints) and is not a new problem introduced
by this change.

## `flutter test` result

- **Before this change:** not re-verified against a byte-for-byte prior run
  (per the task framing, the full suite is "currently ~115 tests");
  proceeded straight to running the suite after the dependency change since
  no code changed, only `pubspec.yaml`/`pubspec.lock`.
- **After this change:** ran `flutter test` (full suite) from the worktree
  root.

Result: **`All tests passed!`** with the runner reporting **115** tests
executed (`+114` zero-indexed, i.e. tests `0..114` = 115 tests), matching
the expected ~115 baseline exactly, with 0 failures. Full pass, no
regressions.

## Commit

```
git add pubspec.yaml pubspec.lock
git commit -m "deps: add Teacher Web UI packages (Phase 4)" -m "<body, see below>"
```

Commit hash: `ce017287550eb9e62421852c6c9a5c002aa8823c`

Only `pubspec.yaml` (+7 lines: the 6 new deps plus a section comment) and
`pubspec.lock` (regenerated) changed. No other files were touched.

## Concerns for later Phase 4 tasks

- `data_table_2` is pinned to 2.x and `flutter_form_builder` to 10.x
  (not the newest 3.x/11.x). Later tasks building the Teacher Web
  data-table/form screens should use these packages' 2.x/10.x APIs
  (standard `package:flutter/material.dart` types), not any `material_ui`-
  based APIs from their respective v3/v11 docs or examples.
- The installed toolchain here is Flutter 3.44.0 / Dart 3.12.0. If this
  project's Flutter SDK is upgraded past 3.47 later, it would be reasonable
  to revisit whether to move to `data_table_2` 3.x / `flutter_form_builder`
  11.x (and `material_ui`) as an explicit, separate decision — not
  something to do incidentally in a later task.
- `shadcn_ui`, `lucide_icons_flutter`, `form_builder_validators`, and
  `model_viewer_plus` are all on their genuine latest stable versions as of
  this check (2026-08-29) with no such caveats.
