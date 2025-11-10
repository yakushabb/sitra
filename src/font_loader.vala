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

public class Sitra.FontLoader {
    public static Gee.HashMap<string, Sitra.FontInfo> load_from_json (string json_data) throws Error {
        var fonts_map = new Gee.HashMap<string, Sitra.FontInfo> ();
        var parser = new Json.Parser ();
        parser.load_from_data (json_data);
        var root = parser.get_root ().get_array ();

        foreach (var node in root.get_elements ()) {
            var obj = node.get_object ();
            var font = Sitra.FontInfo.from_json (obj);
            fonts_map.set (font.family, font);
        }

        return fonts_map;
    }
}

