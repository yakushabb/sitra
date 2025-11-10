/* window.vala
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

using WebKit;
using Gee;

[GtkTemplate (ui = "/io/github/ronniedroid/sitra/window.ui")]
public class Sitra.Window : Adw.ApplicationWindow {
    [GtkChild]
    private unowned Gtk.ListView fonts_list;
    [GtkChild]
    private unowned Adw.NavigationSplitView split_view;
    [GtkChild]
    private unowned Adw.NavigationPage preview_page;
    [GtkChild]
    private unowned Adw.WrapBox categories;
    [GtkChild]
    private unowned Gtk.ToggleButton search_button;
    [GtkChild]
    private unowned Gtk.SearchBar search_bar;
    [GtkChild]
    private unowned Gtk.SearchEntry search_entry;
    [GtkChild]
    private unowned Gtk.Box web_container;
    private WebView web_view;
    private Gee.Map<string, FontInfo> fonts_map;
    private Gee.HashMap<string, Gtk.ToggleButton> category_toggles;
    private Gtk.CustomFilter filter;

    public Window (Adw.Application app) {
        Object (application: app);

        category_toggles = new Gee.HashMap<string, Gtk.ToggleButton> ();

        string[] categories_list = {
            "sans-serif", "display", "serif", "handwriting",
            "monospace", "icons", "variable", "Other"
        };

        foreach (string category in categories_list) {
            var button_label = category == "sans-serif" ? "sans serif" : category;
            var toggle = new Gtk.ToggleButton.with_label (button_label);
            toggle.set_css_classes ({ "category", category });
            categories.append (toggle);
            category_toggles.set (category, toggle);
            toggle.toggled.connect (() => {
                this.filter.changed (Gtk.FilterChange.DIFFERENT);
            });
        }

        this.web_view = new WebView ();
        web_view.vexpand = true;
        web_view.hexpand = true;
        web_container.append (this.web_view);

        var color = Gdk.RGBA ();
        color.parse ("rgba(0,0,0,0)");
        web_view.set_background_color (color);

        // --- JSON font data ---
        string json_data = """
        [
            {
                "family": "Alexandria",
                "category": "serif",
                "variable": false,
                "weights": [100,200,300,400,500,600,700,800,900],
                "subsets": ["arabic","latin","latin-ext","vietnamese"]
            },
            {
                "family": "rubik",
                "category": "sans-serif",
                "variable": false,
                "weights": [100,200,300,400,500,600,700,800,900],
                "subsets": ["arabic","latin","latin-ext","vietnamese"]
            },
            {
                "family": "Roboto",
                "category": "sans-serif",
                "variable": true,
                "weights": [100,300,400,500,700,900],
                "subsets": ["cyrillic","cyrillic-ext","greek","greek-ext","latin","latin-ext","math","symbols","vietnamese"]
            },
            {
                "family": "Lato",
                "category": "sans-serif",
                "variable": false,
                "weights": [100,300,400,700,900],
                "subsets": ["latin","latin-ext"]
            }
        ]
        """;

        try {
            fonts_map = Sitra.FontLoader.load_from_json (json_data);
        } catch (Error e) {
            warning ("Failed to load fonts: %s", e.message);
        }

        var font_keys = fonts_map.keys;
        string[] font_names_temp = font_keys.to_array ();
        font_names_temp += null;
        var font_names = new Gtk.StringList (font_names_temp);

        var font_filter = new Sitra.FontFilter (fonts_map, search_entry, category_toggles);
        this.filter = font_filter.filter;

        var filtered_fonts_model = new Gtk.FilterListModel (font_names, filter);
        var fonts_model = new Gtk.SingleSelection (filtered_fonts_model);

        if (font_names.get_n_items () > 0)
            preview_page.set_title (font_names.get_string (0));
        var preview_font = fonts_map.get (font_names.get_string (0));
        if (preview_font.url == null || preview_font.url.strip() == "") {
            warning("Font '%s' has no URL", preview_font.family);
            return;
        }

        var html = PreviewManager.build_html (preview_font, preview_font.url);
        web_view.load_html (html, null);

        fonts_model.selection_changed.connect (() => {
            if (!split_view.get_collapsed () && fonts_model.selected_item != null) {
                var string_object = (Gtk.StringObject) fonts_model.selected_item;
                preview_page.set_title (string_object.string);
                preview_font = fonts_map.get (string_object.string);
                if (preview_font.url == null || preview_font.url.strip() == "") {
                    warning("Font '%s' has no URL", preview_font.family);
                    return;
                }

                html = PreviewManager.build_html (preview_font, preview_font.url);
                web_view.load_html (html, null);
            }
        });

        fonts_list.activate.connect ((position) => {
            var item = fonts_model.get_item (position);
            if (item != null) {
                var string_object = (Gtk.StringObject) item;
                preview_page.set_title (string_object.string);
                preview_font = fonts_map.get (string_object.string);
                if (preview_font.url == null || preview_font.url.strip() == "") {
                    warning("Font '%s' has no URL", preview_font.family);
                    return;
                }

                html = PreviewManager.build_html (preview_font, preview_font.url);
                web_view.load_html (html, null);

                if (split_view.get_collapsed ())
                    split_view.set_show_content (true);
            }
        });

        fonts_list.model = fonts_model;

        split_view.notify["collapsed"].connect (() => {
            fonts_list.set_single_click_activate (split_view.get_collapsed ());
        });

        search_entry.search_changed.connect (() => {
            filter.changed (Gtk.FilterChange.DIFFERENT);
        });

        search_button.clicked.connect (() => {
            search_bar.search_mode_enabled = !search_bar.search_mode_enabled;
        });
    }
}
