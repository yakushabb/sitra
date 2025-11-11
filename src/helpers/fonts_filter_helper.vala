/* font_filter.vala
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

public class Sitra.Helpers.FontsFilterHelper : Object {
    public Gtk.CustomFilter filter { get; private set; }

    private Gee.Map<string, Sitra.Modals.FontInfo> fonts_map;
    private Gtk.SearchEntry search_entry;
    private Gee.HashMap<string, Gtk.ToggleButton> category_toggles;

    public FontsFilterHelper (Gee.Map<string, Sitra.Modals.FontInfo> fonts_map,
        Gtk.SearchEntry search_entry,
        Gee.HashMap<string, Gtk.ToggleButton> category_toggles) {

        this.fonts_map = fonts_map;
        this.search_entry = search_entry;
        this.category_toggles = category_toggles;

        this.filter = new Gtk.CustomFilter ((item) => {
            return match_item (item);
        });
    }

    private bool match_item (Object? item) {
        var string_object = item as Gtk.StringObject;
        if (string_object == null)
            return false;

        string query = search_entry ? .text ? .strip () ? .down () ?? "";
        string family_name = string_object.string;
        var font = fonts_map.get (family_name);
        if (font == null) {
            warning ("Font '%s' not found in map", family_name);
            return false;
        }
        bool variable_only = category_toggles.has_key ("variable") &&
            category_toggles.get ("variable").active;

        var active_categories = new Gee.ArrayList<string> ();
        foreach (var key in category_toggles.keys) {
            if (key != "variable" && category_toggles.get (key).active)
                active_categories.add (key);
        }

        if (variable_only && !font.variable)
            return false;

        if (active_categories.size > 0 && !active_categories.contains (font.category))
            return false;

        if (query == "")
            return true;

        string[] terms = query.split (" ");
        foreach (string term in terms) {
            if (term == "")
                continue;

            bool found = false;

            if (font.family.down ().contains (term)) {
                found = true;
            } else {
                foreach (var subset in font.subsets) {
                    if (subset.down ().contains (term)) {
                        found = true;
                        break;
                    }
                }
            }

            if (!found)
                return false;
        }

        return true;
    }
}
