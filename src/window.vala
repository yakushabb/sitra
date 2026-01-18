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
    [GtkChild] private unowned Adw.ToastOverlay toast_overlay;
    [GtkChild] private unowned Adw.NavigationSplitView split_view;
    [GtkChild] private unowned Adw.NavigationPage preview_page;
    [GtkChild] private unowned Gtk.Stack preview_stack;
    [GtkChild] private unowned Adw.WrapBox categories;
    [GtkChild] private unowned Gtk.ToggleButton search_button;
    [GtkChild] private unowned Gtk.SearchBar search_bar;
    [GtkChild] private unowned Gtk.SearchEntry search_entry;
    [GtkChild] private unowned Gtk.Entry preview_entry;
    [GtkChild] private unowned Gtk.Box web_container;
    [GtkChild] private unowned Gtk.ActionBar bottom_action_bar;
    [GtkChild] private unowned Gtk.DropDown font_size_dropdown;
    [GtkChild] private unowned Gtk.DropDown line_height_dropdown;
    [GtkChild] private unowned Gtk.DropDown letter_spacing_dropdown;
    [GtkChild] private unowned Gtk.ToggleButton italic_toggle;
    [GtkChild] private unowned Adw.Banner banner;
    [GtkChild] private unowned Gtk.Popover license_popover;
    [GtkChild] private unowned Gtk.Popover category_popover;
    [GtkChild] private unowned Gtk.Label header_font_title;
    [GtkChild] private unowned Adw.ButtonContent header_font_category_button_content;
    [GtkChild] private unowned Adw.ButtonContent header_font_license_button_content;
    [GtkChild] private unowned Gtk.Button integrate_button;
    [GtkChild] private unowned Gtk.Button install_button;
    [GtkChild] private unowned Gtk.Button cancel_button;
    [GtkChild] private unowned Gtk.Button uninstall_button;
    [GtkChild] private unowned Gtk.ProgressBar install_progress_bar;
    [GtkChild] private unowned Adw.WrapBox subsets_box;

    private WebView web_view;
    private Gee.HashMap<string, Gtk.ToggleButton> category_toggles;
    private Gtk.CustomFilter filter;
    private Sitra.Managers.FontsManager fonts_manager;
    private Sitra.Managers.PreviewManager preview_manager;
    private Sitra.Managers.LicensesManager licenses_manager;
    private Sitra.Managers.CategoriesManager categories_manager;
    private Sitra.Managers.FontManager font_manager;
    private Sitra.IntegrationDialog integration_dialog;
    private Sitra.Helpers.NetworkHelper network_helper;
    private string? installing_font_family = null;
    private KeyFile preview_texts;

    private Gtk.FilterListModel filtered_model;
    private Gtk.SingleSelection fonts_model;

    public Window (Adw.Application app) {
        Object (application: app);

        preview_manager = new Sitra.Managers.PreviewManager ();
        licenses_manager = new Sitra.Managers.LicensesManager ();
        categories_manager = new Sitra.Managers.CategoriesManager ();
        font_manager = new Sitra.Managers.FontManager ();
        integration_dialog = new Sitra.IntegrationDialog ();
        network_helper = Sitra.Helpers.NetworkHelper.get_instance ();

        banner.set_revealed (false);

        // --- Load JSON font data ---
        string fonts_json = "";
        string google_fonts_json = "{\"items\": []}";
        try {
            var fonts_bytes = resources_lookup_data ("/io/github/ronniedroid/sitra/fonts.json", 0);
            fonts_json = (string) fonts_bytes.get_data ();

            var google_fonts_bytes = resources_lookup_data ("/io/github/ronniedroid/sitra/google-fonts.json", 0);
            google_fonts_json = (string) google_fonts_bytes.get_data ();
        } catch (Error e) {
            warning ("Failed to load JSON data: %s", e.message);
            if (fonts_json == "") fonts_json = "[]";
        }

        // --- Load Preview Texts ---
        preview_texts = new KeyFile ();
        try {
            var preview_text_bytes = resources_lookup_data ("/io/github/ronniedroid/sitra/preview_text", 0);
            preview_texts.load_from_data ((string) preview_text_bytes.get_data (), -1, KeyFileFlags.NONE);
        } catch (Error e) {
            warning ("Failed to load preview texts: %s", e.message);
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
            fonts_manager.load_from_json (fonts_json, google_fonts_json);
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

        filtered_model = new Gtk.FilterListModel (font_names, filter);

        fonts_model = new Gtk.SingleSelection (filtered_model);
        fonts_model.autoselect = false;
        fonts_model.can_unselect = true;

        Idle.add (() => {
            fonts_model.unselect_all ();
            return false;
        });

        fonts_list.model = fonts_model;
        fonts_list.set_single_click_activate (false);

        // Setup factory for rendering list items
        var factory = new Gtk.SignalListItemFactory ();

        factory.setup.connect ((obj) => {
            var list_item = (Gtk.ListItem) obj;
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            box.spacing = 6;
            box.margin_top = 6;
            box.margin_bottom = 6;

            // Horizontal box for category and variable badge
            var category_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);

            var category_label = new Gtk.Label ("");
            category_label.set_halign (Gtk.Align.START);
            category_label.add_css_class ("dimmed");
            category_label.add_css_class ("caption-heading");
            category_box.append (category_label);

            var variable_badge = new Gtk.Label ("Variable");
            variable_badge.add_css_class ("caption");
            variable_badge.add_css_class ("variable-badge");
            category_box.append (variable_badge);

            box.append (category_box);

            var family_label = new Gtk.Label ("");
            family_label.set_halign (Gtk.Align.START);
            box.append (family_label);

            list_item.child = box;
        });

        factory.bind.connect ((obj) => {
            var list_item = (Gtk.ListItem) obj;
            var box = (Gtk.Box) list_item.child;
            var category_box = (Gtk.Box) box.get_first_child ();
            var category_label = (Gtk.Label) category_box.get_first_child ();
            var variable_badge = (Gtk.Label) category_box.get_last_child ();
            var family_label = (Gtk.Label) box.get_last_child ();

            var string_object = (Gtk.StringObject) list_item.item;
            var font = fonts_manager.get_font (string_object.string);

            category_label.set_label (font.category);
            family_label.set_label (font.family);

            // Show badge only for variable fonts
            variable_badge.visible = font.variable;
        });
        fonts_list.factory = factory;

        fonts_model.selection_changed.connect (() => {
            if (!split_view.get_collapsed () && fonts_model.selected_item != null) {
                var string_object = (Gtk.StringObject) fonts_model.selected_item;
                var family = string_object.string;
                update_italic_toggle_state (family);
                update_preview (family);
                update_license_popover (family);
                update_category_popover (family);
                update_install_button_state ();

                var font = fonts_manager.get_font (family);
                if (font != null)
                    update_subsets (font);
            }
        });

        fonts_list.activate.connect ((position) => {
            var item = filtered_model.get_item (position);
            if (item == null)
                return;

            var string_object = (Gtk.StringObject) item;
            var family = string_object.string;

            update_italic_toggle_state (family);
            update_preview (family);
            update_license_popover (family);
            update_category_popover (family);
            update_install_button_state ();

            var font = fonts_manager.get_font (family);
            if (font != null)
                update_subsets (font);

            if (split_view.get_collapsed ())
                split_view.set_show_content (true);
        });

        network_helper.connectivity_changed.connect ((is_online) => {
            if (!is_online) {
                banner.set_revealed (true);
            } else if (is_online && banner.get_revealed () && fonts_model.selected_item != null) {
                banner.set_revealed (false);
                var string_object = (Gtk.StringObject) fonts_model.selected_item;
                update_preview (string_object.string);
            }
        });

        banner.button_clicked.connect (() => {
            banner.set_revealed (false);
            var string_object = (Gtk.StringObject) fonts_model.selected_item;
            update_preview (string_object.string);
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
            if (fonts_model.selected_item != null) {
                var string_object = (Gtk.StringObject) fonts_model.selected_item;
                update_preview (string_object.string);
            }
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

        // Setup font manager signals
        font_manager.installation_started.connect ((font_family) => {
            installing_font_family = font_family;

            if (is_selected_font (font_family)) {
                install_progress_bar.fraction = 0.0;
                install_progress_bar.visible = true;
                install_button.visible = false;
                cancel_button.visible = true;
            }
        });

        font_manager.installation_progress.connect ((font_family, progress) => {
            if (is_selected_font (font_family)) {
                install_progress_bar.fraction = progress;
            }
        });

        font_manager.installation_completed.connect ((font_family, success, error_message) => {
            installing_font_family = null;

            if (is_selected_font (font_family)) {
                install_progress_bar.visible = false;
                cancel_button.visible = false;
                install_button.visible = true;
            }

            if (success) {
                var toast = new Adw.Toast (_("Font '%s' installed successfully").printf (font_family));
                toast.timeout = 3;
                toast_overlay.add_toast (toast);
                if (is_selected_font (font_family)) {
                    update_install_button_state ();
                }
            } else {
                var toast = new Adw.Toast (_("Failed to install '%s': %s").printf (font_family, error_message ?? "Unknown error"));
                toast.timeout = 5;
                toast_overlay.add_toast (toast);
            }
        });

        font_manager.uninstallation_completed.connect ((font_family, success, error_message) => {
            if (success) {
                var toast = new Adw.Toast (_("Font '%s' uninstalled successfully").printf (font_family));
                toast.timeout = 3;
                toast_overlay.add_toast (toast);
                update_install_button_state ();
            } else {
                var toast = new Adw.Toast (_("Failed to uninstall '%s': %s").printf (font_family, error_message ?? "Unknown error"));
                toast.timeout = 5;
                toast_overlay.add_toast (toast);
            }
        });

        integrate_button.clicked.connect (() => {
            if (fonts_model.selected_item != null) {
                var string_object = (Gtk.StringObject) fonts_model.selected_item;
                var font = fonts_manager.get_font (string_object.string);
                if (font != null) {
                    integration_dialog.populate (font);
                    integration_dialog.present (this);
                }
            }
        });

        install_button.clicked.connect (() => {
            if (fonts_model.selected_item != null) {
                var string_object = (Gtk.StringObject) fonts_model.selected_item;
                var font = fonts_manager.get_font (string_object.string);
                if (font != null) {
                    install_font_async.begin (font.family);
                }
            }
        });

        cancel_button.clicked.connect (() => {
            font_manager.cancel_installation ();
        });

        uninstall_button.clicked.connect (() => {
            if (fonts_model.selected_item != null) {
                var string_object = (Gtk.StringObject) fonts_model.selected_item;
                var font = fonts_manager.get_font (string_object.string);
                if (font != null) {
                    uninstall_font_async.begin (font.family);
                }
            }
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
            bottom_action_bar.set_visible (false);
            return;
        }

        preview_stack.set_visible_child_name ("preview");
        banner.set_revealed (false);
        bottom_action_bar.set_visible (true);

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

        header_font_title.label = preview_font.family;
        var header_font_category_label = preview_font.category == "sans-serif" ? "sans serif" : preview_font.category;
        header_font_category_button_content.label = header_font_category_label;
        header_font_license_button_content.label = preview_font.license;

        var html = preview_manager.build_html (preview_font);
        if (html == null || html.strip ().length == 0)
            html = "<html><body><p>No preview available</p></body></html>";

        web_view.load_html (html, null);
    }

    private void update_subsets (Sitra.Models.FontInfo font) {
        // Clear previous subsets
        Gtk.Widget? child_widget = subsets_box.get_first_child ();
        while (child_widget != null) {
            Gtk.Widget? next = child_widget.get_next_sibling ();
            subsets_box.remove (child_widget);
            child_widget = next;
        }

        if (font.subsets == null)
            return;

        string[] excluded_subsets = { "math", "symbols", "emoji", "icons", "ornaments", "music" };
        Gtk.ToggleButton? group_button = null;

        foreach (var subset in font.subsets) {
            bool excluded = false;
            foreach (var ex in excluded_subsets) {
                if (subset == ex) {
                    excluded = true;
                    break;
                }
            }
            if (excluded) continue;

            string label = subset;
            if (label.has_suffix ("-ext")) {
                label = label.replace ("-ext", " Extended");
            }
            label = label[0].to_string ().up () + label.substring (1);

            var button = new Gtk.ToggleButton.with_label (label);
            button.add_css_class ("category");

            if (group_button == null) {
                group_button = button;
            } else {
                button.set_group (group_button);
            }

            button.toggled.connect (() => {
                if (button.active) {
                    try {
                        string text = preview_texts.get_string ("preview_text", subset);
                        if (preview_entry.get_text () != text) {
                            preview_entry.set_text (text);
                        }
                    } catch (Error e) {
                        // ignore if not found in preview_texts
                    }
                }
            });

            subsets_box.append (button);
        }

        // Try to activate 'Latin' or the first one
        if (group_button != null) {
            Gtk.ToggleButton? latin_button = null;
            Gtk.Widget? iter = subsets_box.get_first_child ();
            while (iter != null) {
                var tb = iter as Gtk.ToggleButton;
                if (tb != null && tb.get_label ().down () == "latin") {
                    latin_button = tb;
                    break;
                }
                iter = iter.get_next_sibling ();
            }

            if (latin_button != null) {
                latin_button.set_active (true);
            } else {
                group_button.set_active (true);
            }
        }
    }

    private void bind_dropdown_to_property (Gtk.DropDown dropdown,
                                            Object target,
                                            string property_name) {
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
        });
    }

    private void update_license_popover (string family_name) {
        update_info_popover (licenses_manager, license_popover, family_name);
    }

    private void update_category_popover (string family_name) {
        update_info_popover (categories_manager, category_popover, family_name);
    }

    private void update_info_popover (Sitra.Managers.BaseInfoManager manager,
                                      Gtk.Popover popover,
                                      string family_name) {
        var font = fonts_manager.get_font (family_name);
        if (font == null)
            return;

        manager.populate_popover (popover, font);
    }

    private async void install_font_async (string font_family) {
        var font = fonts_manager.get_font (font_family);
        if (font == null) {
            warning ("Font not found: %s", font_family);
            return;
        }

        try {
            yield font_manager.install_font (font);
        } catch (Error e) {
            warning ("Font installation error: %s", e.message);
        }
    }

    private async void uninstall_font_async (string font_family) {
        var font = fonts_manager.get_font (font_family);
        if (font == null) {
            warning ("Font not found: %s", font_family);
            return;
        }

        try {
            yield font_manager.uninstall_font (font);
        } catch (Error e) {
            warning ("Font uninstallation error: %s", e.message);
        }
    }

    private bool is_selected_font (string family) {
        if (fonts_model.selected_item == null)
            return false;
        var string_object = (Gtk.StringObject) fonts_model.selected_item;
        return string_object.string == family;
    }

    private void update_install_button_state () {
        if (fonts_model.selected_item == null) {
            install_button.visible = true;
            install_button.sensitive = true;
            uninstall_button.visible = false;
            return;
        }

        var string_object = (Gtk.StringObject) fonts_model.selected_item;
        var font_family = string_object.string;
        var font = fonts_manager.get_font (font_family);

        if (font != null && font_manager.is_font_installed (font.id)) {
            install_button.visible = false;
            cancel_button.visible = false;
            uninstall_button.visible = true;
            uninstall_button.sensitive = true;
        } else if (installing_font_family == font_family) {
            install_button.visible = false;
            cancel_button.visible = true;
            uninstall_button.visible = false;
            install_progress_bar.visible = true;
        } else {
            install_button.visible = true;
            install_button.sensitive = (installing_font_family == null);
            cancel_button.visible = false;
            uninstall_button.visible = false;
            install_progress_bar.visible = false;
        }
    }
}