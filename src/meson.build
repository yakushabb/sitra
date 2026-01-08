sitra_sources += files(
  'main.vala',
  'application.vala',
  'window.vala',
  'integration_dialog.vala',
)

# Subdirectories
subdir('managers')
subdir('helpers')
subdir('modals')

sitra_deps = [
  config_dep,
  dependency('glib-2.0'),
  dependency('gio-2.0'),
  dependency('gobject-2.0'),
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.4'),
  dependency('webkitgtk-6.0'),
  dependency('gee-0.8'),
  dependency('libsoup-3.0'),
  dependency('json-glib-1.0'),
]

blueprints = custom_target('blueprints',
  input: files(
    'shortcuts-dialog.blp',
    'window.blp',
    'integration_dialog.blp',
  ),
  output: '.',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

sitra_sources += gnome.compile_resources('io.github.ronniedroid.sitra',
  'io.github.ronniedroid.sitra.src.gresource.xml',
  c_name: 'sitra',
  dependencies: blueprints,
)

executable('sitra', sitra_sources,
  dependencies: sitra_deps,
  include_directories: config_inc,
       install: true,
)
