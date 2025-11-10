sitra_sources = [
  'main.vala',
  'application.vala',
  'window.vala',
  'preview_manager.vala',
  'font_info.vala',
  'font_loader.vala',
  'font_filter.vala',
]

sitra_deps = [
  config_dep,
  dependency('glib-2.0'),
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
