test_deps = [
  dependency('glib-2.0', version: '>= 2.76'),
  dependency('gobject-2.0'),
  dependency('gio-2.0'),
]

foreach name : [
  'csv-parser', 'encoding', 'row-model', 'search', 'search-state',
  'view-state',
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

# The window tests need a display. They run under Xvfb where it is
# installed, and are skipped otherwise. The display is private, so the
# windows do not appear in the desktop of whoever runs the tests.
xvfb_run = find_program('xvfb-run', required: false)
if xvfb_run.found()
  test_window = executable('test-window',
    [
      'test-window.vala',
      core_sources,
      shortcut_sources,
      ui_sources,
      resources,
    ],
    dependencies: reto_deps,
    include_directories: include_directories('../src'),
    vala_args: ['--target-glib=2.76'],
  )
  test('window', xvfb_run,
    args: ['--auto-servernum', test_window, '--tap'],
    env: {
      'GSETTINGS_BACKEND': 'memory',
      'GDK_BACKEND': 'x11',
      # There is no session bus to reach the accessibility bus on, and GTK
      # aborts without one.
      'GTK_A11Y': 'none',
      'RETO_TEST_PRIVATE_DISPLAY': '1',
    },
    protocol: 'tap',
    suite: 'gui',
    timeout: 60,
  )
else
  message('xvfb-run not found, the window tests will not run')
endif

if get_option('b_coverage')
  run_target('coverage-summary',
    command: [
      find_program('python3'),
      meson.project_source_root() / 'tools' / 'coverage.py',
      meson.project_build_root(),
    ],
  )
endif
