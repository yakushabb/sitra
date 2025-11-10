/* application.vala
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

public class Sitra.Application : Adw.Application {
    public Application () {
        Object (
            application_id: "io.github.ronniedroid.sitra",
            flags: ApplicationFlags.DEFAULT_FLAGS,
            resource_base_path: "/io/github/ronniedroid/sitra"
        );
    }

    construct {
        ActionEntry[] action_entries = {
            { "about", this.on_about_action },
            { "quit", this.quit }
        };
        this.add_action_entries (action_entries, this);
        this.set_accels_for_action ("app.quit", {"<primary>q"});
    }

    public override void activate () {
        base.activate ();
        var win = this.active_window ?? new Sitra.Window (this);
        win.present ();
    }

    private void on_about_action () {
        string[] developers = { "Ronnie Nissan" };
        var about = new Adw.AboutDialog () {
            application_name = "sitra",
            application_icon = "io.github.ronniedroid.sitra",
            developer_name = "Ronnie Nissan",
            translator_credits = _("translator-credits"),
            version = "0.1.0",
            developers = developers,
            copyright = "© 2025 Ronnie Nissan",
        };

        about.present (this.active_window);
    }
}
