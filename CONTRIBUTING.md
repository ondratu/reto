# Contributing to Reto

Thanks for your interest! This document describes the project's conventions
and decisions. It will grow with the project.

## Language

Everything in the repository is in English: source code, comments, commit
messages, issues, documentation and user-visible strings (translations come
later through gettext).

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
  GSettings schema and icons, `po/` for translations.
- **UI definitions:** prefer Blueprint or GtkBuilder `.ui` templates
  (`[GtkTemplate]`) over building widgets by hand where it keeps the code
  readable.
- **Application ID:** `cz.zeropage.Reto`. It is used for the D-Bus name,
  desktop file, icon, AppStream metainfo and the Flatpak manifest.
- **Distribution:** native packages (Meson install) and Flatpak
  (`cz.zeropage.Reto.yaml`). Keep the app working inside the Flatpak sandbox:
  open files through `Gtk.FileDialog` (portals), do not request broad
  filesystem access.

## Design principles

- Follow the GNOME HIG: adaptive layout, header bar, standard keyboard
  shortcuts, light and dark style support.
- Keep it a *viewer* first. Do not add features that make the viewer
  slower or more complicated, such as editing, without discussion.
- Large files should not freeze the UI; load and sort without blocking the
  main loop.
- Keep the CSV parsing and data model separate from the UI so they can be
  tested without GTK.

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
