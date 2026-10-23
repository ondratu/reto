test_deps = [
  dependency('glib-2.0', version: '>= 2.76'),
  dependency('gobject-2.0'),
  dependency('gio-2.0'),
]

foreach name : [
  'csv-parser', 'row-model', 'search', 'search-state', 'view-state',
]
  test_exe = executable('test-' + name,
    ['test-@0@.vala'.format(name), core_sources],
    dependencies: test_deps,
    vala_args: ['--target-glib=2.76'],
  )
  test(name, test_exe, args: ['--tap'], protocol: 'tap')
endforeach

# The accelerators are parsed by GTK, which needs no display for that.
test_shortcuts = executable('test-shortcuts',
  ['test-shortcuts.vala', shortcut_sources],
  dependencies: [test_deps, dependency('gtk4', version: '>= 4.12')],
  vala_args: ['--target-glib=2.76'],
)
test('shortcuts', test_shortcuts, args: ['--tap'], protocol: 'tap')

if get_option('b_coverage')
  run_target('coverage-summary',
    command: [
      find_program('python3'),
      meson.project_source_root() / 'tools' / 'coverage.py',
      meson.project_build_root(),
    ],
  )
endif
