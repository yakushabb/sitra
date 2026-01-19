/* base_info_manager.vala
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

public abstract class Sitra.Managers.BaseInfoManager : Object {

    public abstract string get_logo_path ();
    public abstract string get_resource_path ();
    public abstract string get_group_name ();
    public abstract string get_id (Sitra.Models.FontInfo font);

    public void populate_popover (Gtk.Popover popover, Sitra.Models.FontInfo font) {
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 4);
        box.margin_top = 12;
        box.margin_start = 12;
        box.margin_end = 12;
        box.margin_bottom = 12;

        var logo = new Gtk.Image.from_resource (get_logo_path ());
        logo.pixel_size = 64;
        box.append (logo);

        string id = get_id (font);
        var info_box = create_info_box (
            id,
            get_description (id)
        );
        box.append (info_box);

        var clamp = new Adw.Clamp ();
        clamp.maximum_size = 180;
        clamp.set_child (box);

        popover.set_child (clamp);
    }

    protected Gtk.Box create_info_box (string id, string description) {

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 4);

        var id_label = new Gtk.Label (id);
        id_label.set_css_classes ({"heading", "category"});

        var desc_label = new Gtk.Label (description);
        desc_label.set_halign (Gtk.Align.START);
        desc_label.wrap = true;

        box.append (id_label);
        box.append (desc_label);

        return box;
    }

    protected string get_description (string key) {

        string resource_path = get_resource_path ();

        var keyfile = new KeyFile ();

        try {
            Bytes data = resources_lookup_data (
                resource_path,
                ResourceLookupFlags.NONE
            );
            keyfile.load_from_bytes (data, KeyFileFlags.NONE);
        } catch (Error e) {
            warning (@"Failed to load $(resource_path): $(e.message)");
            return _("No description available");
        }

        try {
            return keyfile.get_string (get_group_name (), key);
        } catch (Error e) {
            return _("No description available");
        }
    }
}
