# Selecting and copying in the table

How clicks, selection and copying behave in the table, why, and how it is
built. Read it before changing `src/cell.vala`, the selection code in
`src/window.vala` or `src/style.css`.

## The behavior

| You do | Reto does |
| ------ | --------- |
| Click anywhere in a cell | Selects its row (only that one) |
| Shift+click, Ctrl+click | Extends the selection by a range, or toggles a row |
| Drag over the cells | Selects the rows touched by the rubber band |
| Ctrl+A | Selects all the rows shown |
| Ctrl+C (focus in the table) | Copies the selected rows as tab separated text |
| Secondary click or long press in a cell | Opens the context menu |
| ... on a row that is not selected | Selects that row first, and only it |
| ... on a row that is selected | Keeps the selection, the menu is about it |

The menu copies the cell, the selected rows (the menu says "Row" or "Rows"),
the rows with the column titles above them, the column, and the column with
its title. A column is copied as it is sorted and filtered, one value per
line.

The text goes to the clipboard as tab separated values, so it pastes into
cells of a spreadsheet. A value with a tab, a line break or a quote is put in
quotes, with the quotes inside doubled. A single cell is copied as it is,
without quotes. Only the columns that are shown are copied.

A click does the same wherever it lands in a cell, and it does not matter
whether it is on the text or beside it. That was the point of the redesign
below.

## Research

What other software does, and what the toolkit allows:

- A secondary click on an item that is not selected selects it before the menu
  opens, a secondary click on a selected item keeps the selection and the menu
  applies to all of it. It is the convention of file managers, mail clients
  and spreadsheets, and it was proposed for the GNOME HIG as far back as
  [2002][hig-2002]. The
  applications do not all follow it (see the Nautilus and Geary reports in the
  [bug tracker][nautilus]), but the
  ones that keep the selection under the pointer are the ones that are
  pleasant to use with many rows.
- GTK 4 has no text selection across widgets. `Gtk.Label` can select its own
  text, nothing more. In a table where every cell is a label, a drag over
  several cells cannot select text in all of them. The usual answer of data
  viewers (spreadsheets, database clients) is to select cells or rows, and to
  copy them as tab separated text. That is what "selecting over several
  cells" means in Reto.
- A selectable `Gtk.Label` takes the focus and the mouse of its own: it handles
  the primary button over its whole area, shows the text cursor, and does not
  pass the press on to the list row. Inside a `Gtk.ColumnView` that means that
  a click on the text does not select the row, while a click beside the text
  does. This was the first version of Reto's copying, and it behaved as
  broken.
- The widget of a table cell (`columnview > listview > row > cell`) has
  padding of its own, which is not part of the widget in the cell. A gesture
  in that widget does not see presses on the padding, so a menu opened by it
  was missing in a band around the text.

## Decisions

- No selectable labels. The text of a cell cannot be selected by dragging
  over a part of it, "Copy Cell" copies it all. A partial selection of one
  cell is rare in a data viewer and cannot be had together with the selection
  of rows and a consistent click.
- The rows are selected with `Gtk.MultiSelection` and the rubber band of
  `Gtk.ColumnView` (`enable-rubberband`). It gives the click, Shift, Ctrl and
  drag selection of GTK without any code of ours.
- The context menu follows the convention above.
- The selection is about rows, not about cells. A selection of a rectangle of
  cells (as in a spreadsheet) is possible, but is not in GTK and would be a
  selection model and drawing of our own. It is not planned.

## Implementation

- `Reto.Cell` (`src/cell.vala`) is the only thing that gets the presses of the
  table cell. Its gestures are `Gtk.GestureClick` on the secondary button and
  `Gtk.GestureLongPress` for touch, both emit `context_menu`. The primary
  button is not touched, so that it reaches the row and selects it.
- `style.css` removes the padding of the cell widget and puts it into
  `Reto.Cell`, so that the area of `Reto.Cell` is the whole cell. Do not put
  the padding back to the cell widget, the clicks on it would not open the
  menu.
- `Window.set_menu_cell` implements the rules of the menu, and remembers the
  records, the column and the text of the cell the menu was opened on, so that
  the menu copies what it was opened on even if the table changes while it
  is open. Tests call it instead of showing the popover, which cannot be mapped
  on the private display the window tests run on.
- Ctrl+C is a `Gtk.ShortcutController` on the table, not an accelerator of the
  application. An accelerator would take Ctrl+C from the find field and from
  any other widget with something to copy.
- The text is made by `Reto.CopyText` (`src/copy-text.vala`), which does not
  need GTK and has unit tests. The window only chooses what to copy and puts
  the text on the clipboard. The text is put together in a thread, because
  copying a column or all the rows of a large file takes time. A newer copy
  makes the result of an older one obsolete (`Generation`), so that the slow
  copy cannot overwrite the later one.
- Loading another file clears what the menu was opened on.

## Not done

- A key (Menu, Shift+F10) to open the context menu. The column view does not
  tell which cell has the focus, so the menu would need a cell cursor of our
  own.
- Copying the cell under the cursor with the keyboard.

[hig-2002]: https://lists.gnome.org/archives/hig/2002-March/msg00025.html
[nautilus]: https://bugzilla.gnome.org/show_bug.cgi?id=730112
