/* font_manager.vala
 *
 * Copyright 2025 Ronnie Nissan Yousif
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

using Gee;
using Autoar;

public class Sitra.Managers.FontManager : Object {

    private const string FONTSOURCE_API_URL = "https://api.fontsource.org/v1/download/%s";
    private const string FONTS_DIR_PATH = ".local/share/fonts";
    private const string TRACKING_DIR_PATH = ".local/share/sitra";
    private const string TRACKING_FILE = "installed_fonts.ini";

    private Soup.Session session;
    private string fonts_dir;
    private string tracking_file_path;
    private KeyFile installed_fonts_db;
    private Cancellable? cancellable;

    public signal void installation_started (string font_family);
    public signal void installation_progress (string font_family, double progress);
    public signal void installation_completed (string font_family, bool success, string? error_message);
    public signal void uninstallation_completed (string font_family, bool success, string? error_message);

    public FontManager () {
        session = new Soup.Session ();

        fonts_dir = Path.build_filename (Environment.get_home_dir (), ".local", "share", "fonts");

        var tracking_dir = Path.build_filename (Environment.get_user_data_dir (), "sitra");
        tracking_file_path = Path.build_filename (tracking_dir, TRACKING_FILE);

        try {
            var fonts_file = File.new_for_path (fonts_dir);
            if (!fonts_file.query_exists ()) {
                fonts_file.make_directory_with_parents ();
            }

            var tracking_dir_file = File.new_for_path (tracking_dir);
            if (!tracking_dir_file.query_exists ()) {
                tracking_dir_file.make_directory_with_parents ();
            }
        } catch (Error e) {
            warning ("FontManager: Failed to create directories: %s", e.message);
        }

        installed_fonts_db = new KeyFile ();
        try {
            installed_fonts_db.load_from_file (tracking_file_path, KeyFileFlags.NONE);
        } catch (Error e) {
            debug ("Installed fonts database not found, will be created on first install");
        }
    }

    public bool is_font_installed (string font_id) {
        return installed_fonts_db.has_group (font_id);
    }

    public Gee.List<string> get_installed_fonts () {
        var fonts = new ArrayList<string> ();
        foreach (var group in installed_fonts_db.get_groups ()) {
            fonts.add (group);
        }
        return fonts;
    }

    public async void install_font (Sitra.Models.FontInfo font) throws Error {
        cancellable = new Cancellable ();
        installation_started (font.family);
        installation_progress (font.family, 0.0);

        string? error_msg = null;
        bool success = false;

        try {
            if (is_font_installed (font.id)) {
                throw new IOError.EXISTS ("Font '%s' is already installed".printf (font.family));
            }

            // Step 1: Download font (0% - 50%) - use font.id for API
            installation_progress (font.family, 0.1);
            var zip_file = yield download_font (font.id);
            installation_progress (font.family, 0.5);

            // Step 2: Extract font (50% - 80%)
            var extract_dir = yield extract_font (zip_file, font.id);
            installation_progress (font.family, 0.8);

            // Step 3: Process and install (80% - 100%)
            yield process_and_install (extract_dir, font.id);
            installation_progress (font.family, 0.9);

            // Step 4: Track installation
            track_installation (font);
            installation_progress (font.family, 1.0);

            cancellable = null;

            // Cleanup temporary zip file
            try {
                zip_file.delete ();
            } catch (Error e) {
                debug ("Failed to delete temporary zip: %s", e.message);
            }

            success = true;
        } catch (Error e) {
            error_msg = e.message;
            if (e is IOError.CANCELLED) {
                error_msg = _("Installation cancelled");
            }
            warning ("Font installation failed for %s: %s", font.family, e.message);
            cancellable = null;
        }

        installation_completed (font.family, success, error_msg);
    }

    public void cancel_installation () {
        if (cancellable != null && !cancellable.is_cancelled ()) {
            cancellable.cancel ();
        }
    }

    public async void uninstall_font (Sitra.Models.FontInfo font) throws Error {
        string? error_msg = null;
        bool success = false;

        try {
            if (!is_font_installed (font.id)) {
                throw new IOError.NOT_FOUND ("Font '%s' is not installed".printf (font.family));
            }

            var dest_path = Path.build_filename (fonts_dir, font.id);
            var dest_dir = File.new_for_path (dest_path);
            if (dest_dir.query_exists ()) {
                yield delete_directory_recursive (dest_dir);
            }

            installed_fonts_db.remove_group (font.id);
            try {
                installed_fonts_db.save_to_file (tracking_file_path);
            } catch (Error e) {
                warning ("Failed to save installed fonts database after uninstallation: %s", e.message);
            }

            yield update_font_cache ();

            success = true;
        } catch (Error e) {
            error_msg = e.message;
            warning ("Font uninstallation failed for %s: %s", font.family, e.message);
        }

        uninstallation_completed (font.family, success, error_msg);
    }

    private async File download_font (string font_id) throws Error {
        var url = FONTSOURCE_API_URL.printf (font_id);
        var message = new Soup.Message ("GET", url);

        var temp_dir = Environment.get_tmp_dir ();
        var zip_path = Path.build_filename (temp_dir, "%s.zip".printf (font_id));
        var zip_file = File.new_for_path (zip_path);

        try {
            var input_stream = yield session.send_async (message, Priority.DEFAULT, cancellable);

            if (message.status_code != 200) {
                throw new IOError.FAILED ("Failed to download font: HTTP %u".printf (message.status_code));
            }

            var output_stream = yield zip_file.replace_async (null, false, FileCreateFlags.NONE, Priority.DEFAULT, cancellable);

            yield output_stream.splice_async (input_stream, OutputStreamSpliceFlags.CLOSE_SOURCE | OutputStreamSpliceFlags.CLOSE_TARGET, Priority.DEFAULT, cancellable);

            return zip_file;
        } catch (Error e) {
            throw new IOError.FAILED ("Failed to download font: %s".printf (e.message));
        }
    }

    private async File extract_font (File zip_file, string font_family) throws Error {
        var temp_dir = Environment.get_tmp_dir ();
        var extract_path = Path.build_filename (temp_dir, "sitra-%s".printf (font_family));
        var extract_dir = File.new_for_path (extract_path);

        if (!extract_dir.query_exists ()) {
            extract_dir.make_directory_with_parents ();
        }

        try {
            var extractor = new Extractor (zip_file, extract_dir);

            SourceFunc callback = extract_font.callback;
            Error? extraction_error = null;

            ulong cancel_id = 0;
            if (cancellable != null) {
                cancel_id = cancellable.connect (() => {
                    Idle.add ((owned) callback);
                });
            }

            extractor.start (cancellable);
            yield;

            if (cancel_id > 0) {
                cancellable.disconnect (cancel_id);
            }

            if (cancellable != null && cancellable.is_cancelled ()) {
                throw new IOError.CANCELLED ("Installation cancelled");
            }

            if (extraction_error != null) {
                throw extraction_error;
            }

            return extract_dir;
        } catch (Error e) {
            throw new IOError.FAILED ("Failed to extract font: %s".printf (e.message));
        }
    }

    private async void process_and_install (File extract_dir, string font_family) throws Error {
        File? font_source_dir = null;

        try {
            var enumerator = yield extract_dir.enumerate_children_async (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE,
                FileQueryInfoFlags.NONE,
                Priority.DEFAULT,
                cancellable);

            FileInfo? info;
            while ((info = enumerator.next_file (null)) != null) {
                if (info.get_file_type () == FileType.DIRECTORY) {
                    font_source_dir = extract_dir.get_child (info.get_name ());
                    break;
                }
            }

            if (font_source_dir == null) {
                throw new IOError.NOT_FOUND ("No extracted directory found");
            }

            var webfonts_dir = font_source_dir.get_child ("webfonts");
            if (webfonts_dir.query_exists ()) {
                yield delete_directory_recursive (webfonts_dir);
            }

            var dest_path = Path.build_filename (fonts_dir, font_family);
            var dest_dir = File.new_for_path (dest_path);

            if (dest_dir.query_exists ()) {
                yield delete_directory_recursive (dest_dir);
            }

            dest_dir.make_directory_with_parents ();

            yield copy_directory_recursive (font_source_dir, dest_dir);

            yield delete_directory_recursive (extract_dir);

            yield update_font_cache ();
        } catch (Error e) {
            throw new IOError.FAILED ("Failed to process and install font: %s".printf (e.message));
        }
    }

    private async void copy_directory_recursive (File source, File dest) throws Error {
        var enumerator = yield source.enumerate_children_async (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE,
            FileQueryInfoFlags.NONE,
            Priority.DEFAULT,
            cancellable);

        FileInfo? info;
        while ((info = enumerator.next_file (cancellable)) != null) {
            if (cancellable != null && cancellable.is_cancelled ()) {
                throw new IOError.CANCELLED ("Installation cancelled");
            }
            var source_child = source.get_child (info.get_name ());
            var dest_child = dest.get_child (info.get_name ());

            if (info.get_file_type () == FileType.DIRECTORY) {
                dest_child.make_directory_with_parents ();
                yield copy_directory_recursive (source_child, dest_child);
            } else {
                yield source_child.copy_async (dest_child, FileCopyFlags.OVERWRITE, Priority.DEFAULT, cancellable);
            }
        }
    }

    private async void delete_directory_recursive (File dir) throws Error {
        var enumerator = yield dir.enumerate_children_async (FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE,
            FileQueryInfoFlags.NONE,
            Priority.DEFAULT,
            null);

        FileInfo? info;
        while ((info = enumerator.next_file (null)) != null) {
            var child = dir.get_child (info.get_name ());
            if (info.get_file_type () == FileType.DIRECTORY) {
                yield delete_directory_recursive (child);
            } else {
                child.delete ();
            }
        }

        dir.delete ();
    }

    private async void update_font_cache () throws Error {
        try {
            var subprocess = new Subprocess (
                                             SubprocessFlags.STDERR_SILENCE,
                                             "fc-cache", "-f"
            );
            yield subprocess.wait_async (null);
        } catch (Error e) {
            debug ("Font cache update failed: %s", e.message);
        }
    }

    private void track_installation (Sitra.Models.FontInfo font) {
        var now = new DateTime.now_local ();
        var date_string = now.format ("%Y-%m-%d %H:%M:%S");
        var install_path = Path.build_filename (fonts_dir, font.id);

        installed_fonts_db.set_string (font.id, "id", font.id);
        installed_fonts_db.set_string (font.id, "family", font.family);
        installed_fonts_db.set_string (font.id, "install_date", date_string);
        installed_fonts_db.set_string (font.id, "install_path", install_path);

        try {
            installed_fonts_db.save_to_file (tracking_file_path);
        } catch (Error e) {
            warning ("Failed to save installed fonts database: %s", e.message);
        }
    }
}