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

    [GtkChild] private unowned Gtk.ListView fonts_list;
    [GtkChild] private unowned Adw.NavigationSplitView split_view;
    [GtkChild] private unowned Adw.NavigationPage preview_page;
    [GtkChild] private unowned Gtk.Stack preview_stack;
    [GtkChild] private unowned Adw.WrapBox categories;
    [GtkChild] private unowned Gtk.ToggleButton search_button;
    [GtkChild] private unowned Gtk.SearchBar search_bar;
    [GtkChild] private unowned Gtk.SearchEntry search_entry;
    [GtkChild] private unowned Gtk.Entry preview_entry;
    [GtkChild] private unowned Gtk.Box web_container;
    [GtkChild] private unowned Gtk.DropDown font_size_dropdown;
    [GtkChild] private unowned Gtk.DropDown line_height_dropdown;
    [GtkChild] private unowned Gtk.DropDown letter_spacing_dropdown;
    [GtkChild] private unowned Gtk.ToggleButton italic_toggle;
    [GtkChild] private unowned Adw.Banner banner;

    private WebView web_view;
    private Gee.HashMap<string, Gtk.ToggleButton> category_toggles;
    private Gtk.CustomFilter filter;
    private Sitra.Managers.FontsManager fonts_manager;
    private Sitra.Managers.PreviewManager preview_manager;
    private Sitra.Helpers.NetworkHelper network_helper;

    private string? last_activated_font = null;

    public Window (Adw.Application app) {
        Object (application: app);

        preview_manager = new Sitra.Managers.PreviewManager ();
        network_helper = Sitra.Helpers.NetworkHelper.get_instance ();

        banner.set_revealed (false);

        // --- Load JSON font data ---
        string json_data = "";
        try {
            var bytes = resources_lookup_data ("/io/github/ronniedroid/sitra/fonts.json", 0);
            json_data = (string) bytes.get_data ();
        } catch (Error e) {
            warning ("Failed to load fonts.json: %s", e.message);
            json_data = "[]";
        }

        // --- WebView ---
        web_view = new WebView ();
        web_view.vexpand = true;
        web_view.hexpand = true;
        web_container.append (web_view);

        var color = Gdk.RGBA ();
        color.parse ("rgba(0,0,0,0)");
        web_view.set_background_color (color);

        // --- Categories ---
        category_toggles = new Gee.HashMap<string, Gtk.ToggleButton> ();

        string[] categories_list = {
            "sans-serif", "display", "serif", "handwriting",
            "monospace", "icons", "variable", "other"
        };

        foreach (string category in categories_list) {
            var label = category == "sans-serif" ? "sans serif" : category;
            var toggle = new Gtk.ToggleButton.with_label (label);
            toggle.set_css_classes ({ "category", category });
            categories.append (toggle);
            category_toggles[category] = toggle;

            toggle.toggled.connect (() => {
                filter.changed (Gtk.FilterChange.DIFFERENT);
            });
        }

        // --- Fonts data ---
        fonts_manager = new Sitra.Managers.FontsManager ();

        try {
            fonts_manager.load_from_json (json_data);
        } catch (Error e) {
            warning ("Failed to load fonts: %s", e.message);
        }

        var font_names = new Gtk.StringList (
            fonts_manager.get_font_names_array ()
        );

        var fonts_filter = new Sitra.Helpers.FontsFilterHelper (
            fonts_manager.get_all_fonts (),
            search_entry,
            category_toggles
        );

        filter = fonts_filter.filter;

        var filtered_model = new Gtk.FilterListModel (font_names, filter);

        var fonts_model = new Gtk.NoSelection (filtered_model);
        fonts_list.model = fonts_model;
        fonts_list.set_single_click_activate (true);

        fonts_list.activate.connect ((position) => {
            var item = filtered_model.get_item (position);
            if (item == null)
                return;

            var string_object = (Gtk.StringObject) item;
            var family = string_object.string;

            last_activated_font = family;

            update_italic_toggle_state (family);
            update_preview (family);

            if (split_view.get_collapsed ())
                split_view.set_show_content (true);
        });

        network_helper.connectivity_changed.connect ((is_online) => {
            if (!is_online) {
                banner.set_revealed (true);
            } else if (is_online && banner.get_revealed () && last_activated_font != null) {
                banner.set_revealed (false);
                update_preview (last_activated_font);
            }
        });

        banner.button_clicked.connect (() => {
            if (network_helper.has_connectivity () && last_activated_font != null) {
                banner.set_revealed (false);
                update_preview (last_activated_font);
            }
        });

        preview_entry.changed.connect (() => {
            var text = preview_entry.text.strip ();
            if (text.length == 0)
                text = preview_manager.DEFAULT_PREVIEW_TEXT;

            preview_manager.preview_text = text;
        });

        italic_toggle.bind_property (
            "active",
            preview_manager,
            "italic",
            BindingFlags.DEFAULT
        );

        bind_dropdown_to_property (font_size_dropdown, preview_manager, "font-size");
        bind_dropdown_to_property (line_height_dropdown, preview_manager, "line-height");
        bind_dropdown_to_property (letter_spacing_dropdown, preview_manager, "letter-spacing");

        preview_manager.notify.connect (() => {
            if (last_activated_font != null)
                update_preview (last_activated_font);
        });

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

    // --- Helpers ---

    private void update_italic_toggle_state (string family) {
        var font = fonts_manager.get_font (family);
        if (font == null)
            return;

        bool has_italic = font.styles.contains ("italic");
        italic_toggle.set_sensitive (has_italic);

        if (!has_italic) {
            italic_toggle.set_active (false);
            preview_manager.italic = false;
        }
    }

    private void update_preview (string family_name) {
        if (!network_helper.has_connectivity ()) {
            banner.set_revealed (true);
            preview_stack.set_visible_child_name ("status");
            return;
        }

        preview_stack.set_visible_child_name ("preview");
        banner.set_revealed (false);

        var preview_font = fonts_manager.get_font (family_name);
        if (preview_font == null) {
            stderr.printf ("ERROR: Font not found: %s\n", family_name);
            return;
        }

        if (preview_font.weights == null || preview_font.weights.size == 0) {
            preview_font.weights = new Gee.ArrayList<int> ();
            preview_font.weights.add (400);
        }

        preview_page.set_title (family_name);

        var html = preview_manager.build_html (preview_font);
        if (html == null || html.strip ().length == 0)
            html = "<html><body><p>No preview available</p></body></html>";

        web_view.load_html (html, null);
    }

    private void bind_dropdown_to_property (
        Gtk.DropDown dropdown,
        Object target,
        string property_name
    ) {
        dropdown.bind_property (
            "selected-item",
            target,
            property_name,
            BindingFlags.DEFAULT,
            (binding, from_value, ref to_value) => {
                var selected = from_value.get_object () as Gtk.StringObject;
                if (selected != null) {
                    to_value.set_string (selected.string);
                    return true;
                }
                return false;
            }
        );
    }
}

