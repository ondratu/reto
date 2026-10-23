# Contributing to Reto

Thanks for your interest! This document describes the project's conventions
and decisions. It will grow with the project.

## Language

Everything in the repository is in English: source code, comments, commit
messages, issues, documentation and user-visible strings. The application is
English-only and is not translated.

## Technology and conventions

- **Language:** Vala. Follow the
  [Vala coding style](https://wiki.gnome.org/Projects/Vala/Hacking)
  (4 spaces, braces on the same line, `snake_case` members, `PascalCase`
  types).
- **UI toolkit:** GTK 4, with libadwaita where it helps to follow the
  [GNOME HIG](https://developer.gnome.org/hig/).
- **Build system:** Meson. No hand-written Makefiles.
- **Project layout:** the usual layout of a GNOME application:
  `src/` for sources, `data/` for the `.desktop` file, AppStream metainfo,
  GSettings schema and icons.
- **UI definitions:** prefer Blueprint or GtkBuilder `.ui` templates
  (`[GtkTemplate]`) over building widgets by hand where it keeps the code
  readable.
- **Application ID:** `cz.zeropage.Reto`. It is used for the D-Bus name,
  desktop file, icon, AppStream metainfo and the Flatpak manifest.
- **Distribution:** native packages (Meson install) and Flatpak
  (the manifest lives in a separate repository). Keep the app working inside
  the Flatpak sandbox: open files through `Gtk.FileDialog` (portals), do not
  request broad filesystem access.

## Design principles

- Follow the GNOME HIG: adaptive layout, header bar, standard keyboard
  shortcuts, light and dark style support.
- Keep it a *viewer* first. Do not add features that make the viewer
  slower or more complicated, such as editing, without discussion.
- Large files should not freeze the UI; load and sort without blocking the
  main loop.
- Keep the CSV parsing and data model separate from the UI so they can be
  tested without GTK.
- Keep application logic testable. Whatever can be decided without a widget
  (texts shown to the user, which action is available, what the search is
  on, how a request is told from an obsolete one) belongs in a class or
  function without GTK, with unit tests. The window only connects it to the
  widgets and runs the threads. When you add UI code, first ask what in it
  could be a plain function of its inputs, and move that out.

## Development setup

```sh
pip install pre-commit
pre-commit install
```

The hooks are configured in `.pre-commit-config.yaml` and run on every
commit. To run them on all files, use `pre-commit run --all-files`.

Hooks check whitespace, EditorConfig, YAML, spelling (codespell), Vala style
(`io.elementary.vala-lint`) and the AppStream metainfo (`appstreamcli`). The
last two are not installable through pre-commit; install them from your
distribution. CI runs the remaining hooks and a Meson build with
`meson test`, which also validates the desktop file.

## Tests

```sh
meson test -C build
```

The logic that does not need GTK has unit tests in `tests/`: the CSV parsing
and the data model (`csv-parser.vala`, `row-model.vala`, `row.vala`,
`search.vala`) and the state of the view (`search-state.vala`,
`view-state.vala`, `generation.vala`). They are listed as `core_sources` in
`src/meson.build`, which are built into the tests without GTK, so keep GTK out
of them. New logic needs tests too: add a `tests/test-<name>.vala` and list it
in `tests/meson.build`. The table of keyboard shortcuts (`shortcuts.vala`) is
checked by a test that needs GTK but no display.
Use `meson test -C build -v` to list every test case.

`tests/test-window.vala` is the exception to "without GTK": it opens the real
window and checks that the widgets are wired to the actions and to the logic
behind them (open a file, search, sort, filter, reset). It does not mock the
widgets; it drives them through actions and properties, finds them by their
`id` in `window.ui`, and runs the main loop until the result shows. It needs a
display, so Meson runs it under `xvfb-run` (package `xvfb`) in the `gui`
suite and skips it where `xvfb-run` is missing. The display is private, so no
window appears in your desktop; started by hand, the binary skips itself. Run
only that suite with `meson test -C build --suite gui`. Keep these tests few:
they check the wiring, the decisions are tested without GTK.

To see line coverage of the sources (needs only `gcov`), configure a build
with coverage and run the `coverage-summary` target:

```sh
meson setup build-coverage -Db_coverage=true
ninja -C build-coverage coverage-summary
```

`tools/coverage.py` does the same in one step. The code that talks to widgets
(`window.vala`, `application.vala`, `cell.vala`) is covered only by the few
window tests, which is why it should stay thin.

## Platforms

Linux is the primary target. Avoid Linux-only APIs where a portable
alternative exists (GLib/GIO rather than POSIX calls), so that Windows and
possibly macOS builds stay feasible.

## Commits

- Small, focused commits are preferred over large ones.
- Write the message in English, short, and describe what changes in
  behavior (new, fixed, changed) rather than implementation details.

## License

By contributing, you agree that your contributions are licensed under the
[MIT License](LICENSE).
