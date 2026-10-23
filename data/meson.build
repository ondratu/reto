desktop_file = configure_file(
  input: 'cz.zeropage.Reto.desktop.in',
  output: 'cz.zeropage.Reto.desktop',
  copy: true,
  install: true,
  install_dir: get_option('datadir') / 'applications',
)

metainfo_file = configure_file(
  input: 'cz.zeropage.Reto.metainfo.xml.in',
  output: 'cz.zeropage.Reto.metainfo.xml',
  copy: true,
  install: true,
  install_dir: get_option('datadir') / 'metainfo',
)

install_data(
  'icons/hicolor/scalable/apps/cz.zeropage.Reto.svg',
  install_dir: get_option('datadir') / 'icons/hicolor/scalable/apps',
)

desktop_file_validate = find_program('desktop-file-validate', required: false)
if desktop_file_validate.found()
  test('validate desktop file', desktop_file_validate, args: [desktop_file])
endif

appstreamcli = find_program('appstreamcli', required: false)
if appstreamcli.found()
  test('validate metainfo file', appstreamcli,
    args: ['validate', '--no-net', '--pedantic', metainfo_file],
  )
endif
