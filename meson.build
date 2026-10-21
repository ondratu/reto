project('reto', ['c', 'vala'],
  version: '0.1.0',
  meson_version: '>= 0.62.0',
  license: 'MIT',
  default_options: ['warning_level=1'],
)

app_id = 'cz.zeropage.Reto'

i18n = import('i18n')
gnome = import('gnome')

add_project_arguments(
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  language: 'c',
)

subdir('data')
subdir('src')
subdir('po')

gnome.post_install(
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)
