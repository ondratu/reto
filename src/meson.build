conf = configuration_data()
conf.set_quoted('APP_ID', app_id)
conf.set_quoted('VERSION', meson.project_version())
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
configure_file(output: 'config.h', configuration: conf)

resources = gnome.compile_resources('reto-resources',
  'reto.gresource.xml',
  source_dir: '.',
  c_name: 'reto',
)

reto_deps = [
  dependency('glib-2.0', version: '>= 2.76'),
  dependency('gio-2.0'),
  dependency('gtk4', version: '>= 4.10'),
  dependency('libadwaita-1', version: '>= 1.5'),
]

# Data handling without any GTK dependency, shared with the unit tests.
core_sources = files(
  'csv-parser.vala',
  'row-model.vala',
  'row.vala',
  'search.vala',
)

reto_sources = [
  core_sources,
  'main.vala',
  'application.vala',
  'window.vala',
  'config.vapi',
  resources,
]

executable('reto', reto_sources,
  dependencies: reto_deps,
  include_directories: include_directories('.'),
  vala_args: ['--target-glib=2.76'],
  install: true,
)
