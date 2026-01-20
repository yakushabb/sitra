/* categories_manager.vala
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

public class Sitra.Managers.CategoriesManager : Sitra.Managers.BaseInfoManager {

    public CategoriesManager () {}

    public override string get_logo_path () {
        return "/io/github/ronniedroid/sitra/category.svg";
    }

    public override string get_resource_path () {
        return "/io/github/ronniedroid/sitra/categories";
    }

    public override string get_group_name () {
        return "categories";
    }

    public override string get_id (Sitra.Models.FontInfo font) {
        return font.category;
    }

    public string format_category_labels (string category) {
        string label;
        switch (category) {
            case "sans-serif": label = _("Sans Serif"); break;
            case "serif": label = _("Serif"); break;
            case "display": label = _("Display"); break;
            case "handwriting": label = _("Handwriting"); break;
            case "monospace": label = _("Monospace"); break;
            case "icons": label = _("Icons"); break;
            case "Variable": label = ("Variable"); break;
            default: label = category; break;
        }
        return label;
    }

    public string[] get_category_labels () {
    return get_all_keys ();
}
}
