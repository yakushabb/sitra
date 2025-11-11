/* font_loader.vala
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

public class Sitra.Managers.FontsManager : Object {

    private Gee.Map<string, Sitra.Modals.FontInfo> fonts;

    public FontsManager () {
        fonts = new Gee.HashMap<string, Sitra.Modals.FontInfo> ();
    }

    public void load_from_json (string json_data) throws Error {
        var parser = new Json.Parser ();
        parser.load_from_data (json_data);
        var array = parser.get_root ().get_array ();
        foreach (var node in array.get_elements ()) {
            var font_info = Sitra.Modals.FontInfo.from_json (node.get_object ());
            fonts.set (font_info.family, font_info);
        }
    }

    public Sitra.Modals.FontInfo? get_font (string family) {
        return fonts.get (family);
    }

    public Gee.Map<string, Sitra.Modals.FontInfo> get_all_fonts () {
        return fonts;
    }

    public Gee.List<string> get_font_names () {
        var names = new Gee.ArrayList<string> ();
        foreach (var key in fonts.keys) {
            names.add (key);
        }
        names.sort ((a, b) => {
            return a.collate (b); // locale-aware compare
            });
        return names;
    }

    public string?[] get_font_names_array () {
        var names = get_font_names().to_array ();
        var result = new string?[names.length + 1];
        for (int i = 0; i < names.length; i++) {
            result[i] = names[i];
        }
        result[names.length] = null;
        return result;
    }
}
