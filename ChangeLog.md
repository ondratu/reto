# ChangeLog

All changes of Reto that are visible to users. The newest release is on top.

## Unreleased

### Added

- Files in a legacy encoding open correctly: Reto uses the byte order mark or
  valid UTF-8 when there is one, and reads the file as Windows-1250 otherwise.
- The encoding button in the status line reloads the file in an encoding of
  your choice (Unicode, Windows, ISO 8859, DOS, Cyrillic, Greek, Hebrew,
  Arabic, Thai, Japanese, Chinese and Korean ones), and shows the encoding in
  use.
- A file that cannot be read in the detected encoding is no longer shown with
  replaced characters: Reto reports it, and you can choose another encoding.
- Examples in other encodings in `data/examples/`.

## 0.1.1 - 2026-10-26

### Added

- A screenshot, brand colors and a link to the source code in the application
  description (AppStream metainfo), for software centers.

## 0.1.0 - 2026-10-21

The first release.

### Added

- Open a CSV file with the file chooser (Ctrl+O), by drag and drop or as
  a command line argument.
- Show the data in a table, with the header row as column titles.
- Detect the delimiter (comma, semicolon, tab or pipe), ignore a byte order
  mark.
- Sort by a column; columns that contain only numbers are sorted as numbers.
- Filter by a column with few distinct values, reset the sorting and the
  filters (Ctrl+Shift+R).
- Search in the data (Ctrl+F) with the matches marked and a jump between them
  (F3, Shift+F3, Enter, Shift+Enter).
- A status line with the number of the shown rows and the active filters.
- Keyboard shortcuts dialog (Ctrl+?).
