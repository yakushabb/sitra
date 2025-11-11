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

public class Sitra.Managers.PreviewManager : Object {

    // User-set preview text
    public string preview_text { get; set; }

    // Constructor with optional default text
    public PreviewManager (string preview_text = "Sphinx of black quartz, judge my vow.") {
        this.preview_text = preview_text;
    }

    /**
     * Generate the remote URL for a font file.
     * - Variable fonts: only one file
     * - Non-variable fonts: one per weight
     */
    private string get_font_url (Sitra.Modals.FontInfo font, int? weight = null) {
        string font_slug = font.family.down().replace(" ", "-");

        if (font.variable) {
            return "https://cdn.jsdelivr.net/fontsource/fonts/%s:vf@latest/latin-wght-normal.woff2".printf(font_slug);
        } else {
            int w = weight != null ? weight : 400;
            return "https://cdn.jsdelivr.net/fontsource/fonts/%s@latest/latin-%d-normal.woff2".printf(font_slug, w);
        }
    }

    /**
     * Builds the HTML preview for a font.
     *
     * @param font The FontInfo object.
     */
    public string build_html (Sitra.Modals.FontInfo font) {
        var html = new StringBuilder();

        // HTML header + style tag
        html.append ("<!DOCTYPE html><html><head><meta charset='UTF-8'>\n<style>\n");

        // @font-face declarations
        if (font.variable) {
            string font_url = get_font_url(font);
            html.append_printf ("""
                @font-face {
                    font-family: '%s';
                    src: url('%s');
                }
            """, font.family, font_url);
        } else {
            foreach (var w in font.weights) {
                string font_url = get_font_url(font, w);
                html.append_printf ("""
                    @font-face {
                        font-family: '%s';
                        font-weight: %d;
                        src: url('%s');
                    }
                """, font.family, w, font_url);
            }
        }

        // Body CSS
        html.append_printf("""
            :root { color-scheme: light dark; }

            html, body {
                background-color: transparent;
                color: var(--window-fg-color, #000000);
                margin: 12px 0 0 0;
            }

            p.sample-text {
                font-family: '%s', sans-serif;
                font-size: 24px;
            }

            .weight-label {
                font-size: 12px;
                opacity: 0.6;
                line-height: 0;
                margin: 0;
            }
        """, font.family);

        html.append ("</style></head><body>\n");

        // Generate preview lines
        foreach (var w in font.weights) {
            html.append_printf("""
                <div>
                    <h2 class='weight-label'>Weight %d</h2>
                    <p class='sample-text' style='font-weight: %d;'>%s</p>
                </div>
            """, w, w, this.preview_text);
        }

        // Close HTML
        html.append ("</body></html>\n");

        return html.str;
    }
}
