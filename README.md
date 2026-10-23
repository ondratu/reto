# Reto

A simple, fast CSV file viewer for the GNOME desktop.

Reto opens a CSV file, parses its header and shows the data in a table that
you can sort, filter and search. Editing is not a goal right now, but it is
not ruled out for the future.

> **Status:** early development. Nothing is usable yet.

## Features

Planned, roughly in this order:

- [x] Open a CSV file (file chooser, drag and drop, command line argument)
- [x] Parse the header row and use it for column titles
- [x] Sort the data by a column
- [x] Filter by an enum-like column (a column with few distinct values)
- [x] Search in the data (jump between matches)
- [ ] Editing (maybe, later)

## Technology

- Written in [Vala](https://vala.dev/)
- UI built with [GTK 4](https://www.gtk.org/) (and libadwaita, to follow the
  [GNOME Human Interface Guidelines](https://developer.gnome.org/hig/))
- Built with [Meson](https://mesonbuild.com/) and Ninja

## Platforms

| Platform | Status                     |
| -------- | -------------------------- |
| Linux    | Primary target             |
| Windows  | Possible in the future     |
| macOS    | Maybe, if it turns out to work |

## Building

Requirements: Meson, Ninja, `valac`, GTK 4 (>= 4.12) and libadwaita (>= 1.8)
development files.

```sh
meson setup build
meson compile -C build
./build/src/reto
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Reto is released under the [MIT License](LICENSE).
