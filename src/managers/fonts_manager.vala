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

    private Gee.Map<string, Sitra.Models.FontInfo> fonts;
    private Gee.Set<string> google_fonts;

    public FontsManager () {
        fonts = new Gee.HashMap<string, Sitra.Models.FontInfo> ();
        google_fonts = new Gee.HashSet<string> ();
    }

    public void load_from_json (string fonts_json, string google_fonts_json) throws Error {
        var google_files_map = new Gee.HashMap<string, Gee.Map<string, string>> ();

        var google_parser = new Json.Parser ();
        google_parser.load_from_data (google_fonts_json);
        var root = google_parser.get_root ().get_object ();
        var items = root.get_array_member ("items");
        foreach (var node in items.get_elements ()) {
            var obj = node.get_object ();
            string family = obj.get_string_member ("family");
            google_fonts.add (family);

            var files_obj = obj.get_object_member ("files");
            var variant_files = new Gee.HashMap<string, string> ();
            foreach (var member_name in files_obj.get_members ()) {
                variant_files.set (member_name, files_obj.get_string_member (member_name));
            }
            google_files_map.set (family, variant_files);
        }

        var parser = new Json.Parser ();
        parser.load_from_data (fonts_json);
        var array = parser.get_root ().get_array ();
        foreach (var node in array.get_elements ()) {
            var font_info = Sitra.Models.FontInfo.from_json (node.get_object ());
            if (google_fonts.contains (font_info.family)) {
                if (google_files_map.has_key (font_info.family)) {
                    font_info.files.set_all (google_files_map.get (font_info.family));
                }
                fonts.set (font_info.family, font_info);
            }
        }
    }

    public Sitra.Models.FontInfo? get_font (string family) {
        return fonts.get (family);
    }

    public Gee.Map<string, Sitra.Models.FontInfo> get_all_fonts () {
        return fonts;
    }

    public Gee.List<string> get_font_names () {
        var names = new Gee.ArrayList<string> ();
        foreach (var key in fonts.keys) {
            names.add (key);
        }
        names.sort ((a, b) => {
            var font_a = fonts.get (a);
            var font_b = fonts.get (b);

            // Calculate combined score (subsets + weights)
            int score_a = font_a.subsets.size + font_a.weights.size;
            int score_b = font_b.subsets.size + font_b.weights.size;

            int score_diff = score_b - score_a;
            if (score_diff != 0) {
                return score_diff;
            }

            // If scores are equal, fall back to alphabetical
            return a.collate (b);
        });
        return names;
    }

    public string?[] get_font_names_array () {
        var names = (string[]) get_font_names ().to_array ();
        var result = new string?[names.length + 1];
        for (int i = 0; i < names.length; i++) {
            result[i] = names[i];
        }
        result[names.length] = null;
        return result;
    }
}
