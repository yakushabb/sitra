sitra_sources = [
  'main.vala',
  'application.vala',
  'window.vala',
]

sitra_deps = [
  config_dep,
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.4'),
  dependency('json-glib-1.0'),
  dependency('libsoup-3.0'),
  dependency('gio-2.0'),
]

blueprints = custom_target('blueprints',
  input: files(
    'gtk/help-overlay.blp',
    'window.blp',
  ),
  output: '.',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

sitra_sources += gnome.compile_resources('sitra-resources',
  'io.github.ronniedroid.sitra.src.gresource.xml',
  c_name: 'sitra',
  dependencies: blueprints,
)

executable('sitra', sitra_sources,
  dependencies: sitra_deps,
  include_directories: config_inc,
       install: true,
)
