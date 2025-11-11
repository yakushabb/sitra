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
    private unowned Gtk.Entry preview_entry;
    [GtkChild]
    private unowned Gtk.Box web_container;
    private WebView web_view;
    private Gee.HashMap<string, Gtk.ToggleButton> category_toggles;
    private Gtk.CustomFilter filter;
    private Sitra.Managers.FontsManager fonts_manager;
    private Sitra.Managers.PreviewManager preview_manager;

    public Window (Adw.Application app) {
        Object (application: app);

        this.preview_manager = new Sitra.Managers.PreviewManager ();

        preview_entry.changed.connect (() => {
            // Use entry text, or fallback to default preview text if empty
            var text = preview_entry.text.strip ();
            if (text.length == 0)
                text = "Sphinx of black quartz, judge my vow."; // or preview_manager.preview_text

            this.preview_manager.preview_text = text;

            // Get currently selected font
            var fonts_model = (Gtk.SingleSelection) fonts_list.model;
            if (fonts_model.selected_item != null) {
                var string_object = (Gtk.StringObject) fonts_model.selected_item;
                var selected_family = string_object.string;
                var selected_font = fonts_manager.get_font (selected_family);
                if (selected_font != null)
                    update_preview (selected_font.family);
            }
        });

        // --- JSON font data ---
        string json_data = """
        [
            {
                "family": "Rubik",
                "category": "sans-serif",
                "variable": true,
                "weights": [300,400,500,600,700,800,900],
                "subsets": ["arabic","latin","latin-ext","vietnamese"]
            },
            {
                "family": "Roboto",
                "category": "sans-serif",
                "variable": true,
                "weights": [100,200,300,400,500,600,700,800,900],
                "subsets": ["cyrillic","cyrillic-ext","greek","greek-ext","latin","latin-ext","math","symbols","vietnamese"]
            },
            {
                "family": "Lato",
                "category": "sans-serif",
                "variable": false,
                "weights": [100,300,400,700,900],
                "subsets": ["latin"]
            }
        ]
        """;

        // --- Setup WebView ---
        this.web_view = new WebView ();
        web_view.vexpand = true;
        web_view.hexpand = true;
        web_container.append (this.web_view);

        var color = Gdk.RGBA ();
        color.parse ("rgba(0,0,0,0)");
        web_view.set_background_color (color);

        // --- Setup categories ---
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
            this.category_toggles.set (category, toggle);
            toggle.toggled.connect (() => {
                this.filter.changed (Gtk.FilterChange.DIFFERENT);
            });
        }

        // --- Setup fonts list/preview ---

        this.fonts_manager = new Sitra.Managers.FontsManager ();

        try {
            fonts_manager.load_from_json (json_data);
        } catch (Error e) {
            warning ("Failed to load fonts: %s", e.message);
        }

        var font_names = new Gtk.StringList (fonts_manager.get_font_names_array ());

        var fonts_filter = new Sitra.Helpers.FontsFilterHelper (fonts_manager.get_all_fonts (), search_entry, category_toggles);
        this.filter = fonts_filter.filter;

        var filtered_fonts_model = new Gtk.FilterListModel (font_names, filter);
        var fonts_model = new Gtk.SingleSelection (filtered_fonts_model);

        if (font_names.get_n_items () > 0) {
            this.update_preview (font_names.get_string (0));
        }

        fonts_model.selection_changed.connect (() => {
            if (!split_view.get_collapsed () && fonts_model.selected_item != null) {
                var string_object = (Gtk.StringObject) fonts_model.selected_item;
                this.update_preview (string_object.string);
            }
        });

        fonts_list.activate.connect ((position) => {
            var item = fonts_model.get_item (position);
            if (item != null) {
                var string_object = (Gtk.StringObject) item;
                this.update_preview (string_object.string);

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

    private void update_preview (string family_name) {
        var preview_font = fonts_manager.get_font (family_name);
        if (preview_font == null) {
            stderr.printf ("ERROR: Font not found: %s\n", family_name);
            return;
        }
        // Ensure at least one weight
        if (preview_font.weights == null || preview_font.weights.size == 0) {
            preview_font.weights = new Gee.ArrayList<int> ();
            preview_font.weights.add (400);
        }
        preview_page.set_title (family_name);
        var html = this.preview_manager.build_html (preview_font);
        if (html == null || html.strip ().length == 0) {
            html = "<html><body><p>No preview available</p></body></html>";
        }
        web_view.load_html (html, null);
    }
}
