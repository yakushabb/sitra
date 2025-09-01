public class FontInfo : GLib.Object {
    public string id { get; set; }
    public string family { get; set; }
    public string[] subsets { get; set; }
    public int[] weights { get; set; }
    public string[] styles { get; set; }
    public string defSubset { get; set; }
    public bool variable { get; set; }
    public string lastModified { get; set; }
    public string category { get; set; }
    public string type { get; set; }

    public FontInfo () {
        // Default constructor
    }

    public static FontInfo from_json (Json.Object json) {
        var f = new FontInfo ();
        f.id = json.get_string_member ("id");
        f.family = json.get_string_member ("family");
        f.subsets = json.get_array_member ("subsets").get_string_array ();
        f.weights = json.get_array_member ("weights").get_int_array ();
        f.styles = json.get_array_member ("styles").get_string_array ();
        f.defSubset = json.get_string_member ("defSubset");
        f.variable = json.get_boolean_member ("variable");
        f.lastModified = json.get_string_member ("lastModified");
        f.category = json.get_string_member ("category");
        f.type = json.get_string_member ("type");
        return f;
    }

    public async void load_fonts (string url, List<FontInfo> store) {
    var session = new Soup.Session ();
    var message = new Soup.Message (Soup.Method.GET, url);

    try {
        await session.send_message_async (message);
        if (message.status_code != 200) {
            stderr.printf ("Error: HTTP %d\n", message.status_code);
            return;
        }

        var data = message.response_body.data.get_data ().to_string ();
        Json.Parser parser = new Json.Parser ();
        parser.load_from_data (data);
        var root = parser.get_root ().get_array ();
        foreach (var item in root.get_elements ()) {
            var obj = item.get_object ();
            var font = FontInfo.from_json (obj);
            store.add (font);
        }
    } catch (Error e) {
        stderr.printf ("Network or parsing error: %s\n", e.message);
    }
}

}

