/* licenses_manager.vala
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

public class Sitra.Managers.LicensesManager : Object {

    public LicensesManager () {}

    /**
     * Populate a popover with license information for the given font
     */
    public void populate_popover (Gtk.Popover popover, Sitra.Models.FontInfo font) {
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 4);
        box.margin_top = 12;
        box.margin_start = 24;
        box.margin_end = 24;
        box.margin_bottom = 12;

        var license_logo = new Gtk.Image.from_resource (
            "/io/github/ronniedroid/sitra/licenses.svg"
        );
        license_logo.pixel_size = 64;
        box.append (license_logo);

        // Only one license
        var license_box = create_license_box (
            font.license,
            get_description (font.license)
        );
        box.append (license_box);

        var clamp = new Adw.Clamp ();
        clamp.maximum_size = 200;
        clamp.set_child (box);

        popover.set_child (clamp);
    }

    private Gtk.Box create_license_box (string id, string description) {

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 4);

        var id_label = new Gtk.Label (id);
        id_label.add_css_class ("heading");

        var desc_label = new Gtk.Label (description);
        desc_label.set_halign (Gtk.Align.START);
        desc_label.wrap = true;

        box.append (id_label);
        box.append (desc_label);

        return box;
    }

    private string get_description (string license_key) {

        const string RESOURCE_PATH = "/io/github/ronniedroid/sitra/licenses";

        var keyfile = new KeyFile ();

        try {
            Bytes data = resources_lookup_data (
                RESOURCE_PATH,
                ResourceLookupFlags.NONE
            );
            keyfile.load_from_bytes (data, KeyFileFlags.NONE);
        } catch (Error e) {
            warning (@"Failed to load $(RESOURCE_PATH): $(e.message)");
            return _("No description available");
        }

        try {
            return keyfile.get_string ("licenses", license_key);
        } catch (Error e) {
            return _("No description available");
        }
    }
}

