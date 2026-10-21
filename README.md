# Reto

A simple, fast CSV file viewer for the GNOME desktop.

Reto opens a CSV file, parses its header and shows the data in a table that
you can sort by any column. Searching in the data is planned. Editing is not
a goal right now, but it is not ruled out for the future.

> **Status:** early development. Nothing is usable yet.

## Features

Planned, roughly in this order:

- [x] Open a CSV file (file chooser, drag and drop, command line argument)
- [x] Parse the header row and use it for column titles
- [ ] Sort the data by a column
- [ ] Search in the data
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

Requirements: Meson, Ninja, `valac`, GTK 4 (>= 4.10) and libadwaita (>= 1.5)
development files.

```sh
meson setup build
meson compile -C build
./build/src/reto
```

### Flatpak

The application ID is `cz.zeropage.Reto`.

```sh
flatpak-builder --user --install --force-clean build-flatpak \
  cz.zeropage.Reto.yaml
flatpak run cz.zeropage.Reto
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Reto is released under the [MIT License](LICENSE).
