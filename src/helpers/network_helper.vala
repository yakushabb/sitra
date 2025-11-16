/* network_helper.vala
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

public class Sitra.Helpers.NetworkHelper : Object {
    private static NetworkHelper? instance = null;
    private GLib.NetworkMonitor monitor;

    public signal void connectivity_changed (bool is_online);

    private NetworkHelper () {
        monitor = GLib.NetworkMonitor.get_default ();

        monitor.network_changed.connect ((available) => {
            connectivity_changed (has_connectivity ());
        });
    }

    public static NetworkHelper get_instance () {
        if (instance == null) {
            instance = new NetworkHelper ();
        }
        return instance;
    }

    public bool has_connectivity () {
        return monitor.connectivity == GLib.NetworkConnectivity.FULL;
    }
}
