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

[GtkTemplate (ui = "/io/github/ronniedroid/sitra/window.ui")]
public class Sitra.Window : Adw.ApplicationWindow {
    [GtkChild]
    private unowned Gtk.ListView list_box;
    [GtkChild]
    private unowned Adw.NavigationPage content_page;

    public Window (Adw.Application app) {
        Object (application: app);

        // Model
        var string_model = new Gtk.StringList (
                                               { "Roboto", "Adwaita mono", "Hack", "JetBrainsMono", "IBMPlexMono" });
        var model = new Gtk.SingleSelection (string_model);

        model.selection_changed.connect (() => {
            var string_object = (Gtk.StringObject) model.selected_item;
            content_page.set_title(string_object.string);
        });

        list_box.model = model;
    }
}
