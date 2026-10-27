# Reto

A simple, fast CSV file viewer for the GNOME desktop.

*Reto* is Esperanto for a net or a network. A CSV file is exactly that: a net
of rows and columns, woven from plain text. Reto lets you look at it as a whole,
pull on any thread (sort, filter, search) and never get tangled up.

Reto opens a CSV file, parses its header and shows the data in a table that
you can sort, filter and search. It is a viewer: editing is not planned. The
aim is to be as standard a GNOME application as possible.

> **Status:** the first release, 0.1.0. It is a working viewer, but many
> things that people expect from a GNOME application are still planned, see
> below. The changes are listed in the [ChangeLog](ChangeLog.md).

## Features

Done:

- [x] Open a CSV file (file chooser, drag and drop, command line argument)
- [x] Recent files (provided by the GTK file chooser)
- [x] Parse the header row and use it for column titles
- [x] Detect the delimiter (comma, semicolon, tab or pipe)
- [x] Sort the data by a column (numeric columns are sorted as numbers)
- [x] Filter by an enum-like column (a column with few distinct values)
- [x] Search in the data (jump between matches)
- [x] Keyboard shortcuts dialog
- [x] AppStream metainfo (screenshot, branding, keywords), validated in CI
- [x] Flatpak manifest, bundles and a signed Flatpak repository

Planned, grouped by importance:

### Key features for GNOME Core or GNOME Circle

- [ ] Character encodings: detect UTF-8 and fall back to a legacy encoding
      (Windows-1250, ISO-8859-2, ...), with a manual choice
- [ ] Accessibility: check the table, the headers and the find bar with
      a screen reader (Orca), add the missing labels
- [ ] Remember the window size and state (GSettings)

### Should: what people expect from a data viewer

- [ ] Copy a cell, a row or several rows (Ctrl+C as TSV), multiple selection
- [ ] Context menu on a cell (copy the cell, the row, filter by this value)
- [ ] First row as a header on or off
- [ ] Choose the delimiter and the quote character by hand
- [ ] Resizable columns, sensible initial widths, double click to fit, the full
      value in a tooltip
- [ ] Align numbers to the right
- [ ] Several files in tabs (or at least ask before replacing the open file)
- [ ] Reload a file that changed on disk (F5 / Ctrl+R), keeping the sorting and
      the filters
- [ ] Large files: progress and cancel while loading, streaming parser, tell
      the user when the limit of columns cuts the table
- [ ] Filters for any column: "contains" text filter, several values at once,
      number and date ranges, a mark on a filtered column
- [ ] Search options: match case, whole word, regular expression, one column
- [ ] Sort by several columns, natural order, dates
- [ ] Go to a row (Ctrl+L) and check the keyboard navigation of the table

### Could: nice to have

- [ ] Statistics of a column or a selection (count, min, max, sum, average,
      empty cells)
- [ ] Row detail in a side panel
- [ ] Hide, reorder and freeze columns
- [ ] Save the shown data (after filtering and sorting) as CSV or TSV
- [ ] Printing
- [ ] Narrow windows and phones: test and add breakpoints, check high contrast
- [ ] More formats: TSV as a registered type, `.psv`, compressed `.csv.gz`
- [ ] Wrapping of long text and row density

### Last

- [ ] Localization (gettext, plurals, translated desktop file and metainfo)
- [ ] User help (Yelp)

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

## Installation

### Flatpak

Reto is not on Flathub yet. Add the Reto repository and install it, you will
then get updates with the rest of your Flatpak applications:

```sh
flatpak remote-add --user --if-not-exists reto \
    https://reto.zeropage.cz/flatpak/reto.flatpakrepo
flatpak install --user reto cz.zeropage.Reto
flatpak run cz.zeropage.Reto
```

Or download the `.flatpak` bundle for your architecture (`x86_64` or
`aarch64`) from the [releases](https://github.com/ondratu/reto/releases) and
install it. A bundle is not updated automatically:

```sh
flatpak install --user cz.zeropage.Reto-x86_64.flatpak
```

To build the bundle yourself from the manifest in `flatpak/`:

```sh
tools/build-flatpak.sh            # host architecture, output in dist/
```

The *Flatpak* GitHub workflow builds both bundles. It is run manually, or by
publishing a release, which also attaches the bundles to the release and
updates the repository.

### Debian / Ubuntu

There is no package yet, build Reto from source. It needs libadwaita 1.8 or
newer, which is in Debian 14 and Ubuntu 26.04 or newer:

```sh
sudo apt install build-essential meson valac git \
    libgtk-4-dev libadwaita-1-dev

git clone https://github.com/ondratu/reto.git
cd reto
meson setup build
meson compile -C build
sudo meson install -C build
```

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
