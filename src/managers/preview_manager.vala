/* preview_manager.vala
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

using GLib;

public class Sitra.Managers.PreviewManager : Object {

    public string preview_text { get; set; }

    public PreviewManager (string preview_text = "Sphinx of black quartz, judge my vow.") {
        this.preview_text = preview_text;
    }

    /**
     * Builds the HTML preview for a font.
     *
     * @param font The FontInfo object (or any object with family, variable, weights).
     * @param font_url Optional remote URL for @font-face. Can be null.
     */
    public string build_html (Sitra.Modals.FontInfo font, string? font_url = null) {
        var html = new StringBuilder ();

        // HTML header
        html.append ("<!DOCTYPE html><html><head><meta charset=\"UTF-8\">\n<style>\n");

        // Optional remote font
        if (font_url != null && font_url.strip () != "") {
            html.append_printf ("""
                @font-face {
                    font-family: '%s';
                    src: url('%s');
                }
            """, font.family, font_url);
        }

        // Body CSS
        html.append_printf ("""
         :root {
            color-scheme: light dark;
        }

        html, body {
            background-color: transparent;
            color: var(--window-fg-color, #000000);
            margin: 0;
            padding: 1em;
        }

        p.sample-text {
            font-family: '%s', sans-serif;
            font-size: 24px;
        }

        .weight-label {
            font-size: 12px;
            opacity: 0.6;
        }
        """, font.family);

        html.append ("</style></head><body>\n");

        // Generate sample text lines
        foreach (var w in font.weights) {
                html.append_printf ("""
                    <div>
                        <div class='weight-label'>Weight %d</div>
                        <p class='sample-text' style='font-weight: %d;'>%s</p>
                    </div>
                """, w, w, this.preview_text);
            }

        // Close HTML
        html.append ("</body></html>\n");

        return html.str;
    }
}
