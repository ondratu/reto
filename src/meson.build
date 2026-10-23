conf = configuration_data()
conf.set_quoted('APP_ID', app_id)
conf.set_quoted('VERSION', meson.project_version())
configure_file(output: 'config.h', configuration: conf)

resources = gnome.compile_resources('reto-resources',
  'reto.gresource.xml',
  source_dir: '.',
  c_name: 'reto',
)

reto_deps = [
  dependency('glib-2.0', version: '>= 2.76'),
  dependency('gio-2.0'),
  dependency('gtk4', version: '>= 4.12'),
  dependency('libadwaita-1', version: '>= 1.8'),
]

# Data handling without any GTK dependency, shared with the unit tests.
core_sources = files(
  'csv-parser.vala',
  'row-model.vala',
  'generation.vala',
  'row.vala',
  'search.vala',
  'search-state.vala',
  'view-state.vala',
)

# Plain data, kept apart because its unit test needs GTK.
shortcut_sources = files('shortcuts.vala')

# The widgets, kept apart from main.vala so the window tests can have a main
# of their own.
ui_sources = files(
  'application.vala',
  'cell.vala',
  'window.vala',
  'config.vapi',
)

reto_sources = [
  core_sources,
  shortcut_sources,
  ui_sources,
  'main.vala',
  resources,
]

executable('reto', reto_sources,
  dependencies: reto_deps,
  include_directories: include_directories('.'),
  vala_args: ['--target-glib=2.76'],
  install: true,
)
