namespace OOXML {


public class Spreadsheet : Object {
	private Archive.Zip archive;
	private Gee.List<Sheet> sheets;


	public Spreadsheet () {
		archive = new Archive.Zip ();
		sheets = new Gee.ArrayList<Sheet> ();
	}


	public void load (File file) throws GLib.Error {
		archive.open (file);

		var reader = new Reader ();
		var xml_doc = load_xml ("xl/sharedStrings.xml");
		reader.shared_strings (xml_doc);
		delete xml_doc;
		load_workbook (reader);
		Xml.Parser.cleanup ();
	}


	private void load_workbook (Reader reader) throws GLib.Error {
		var xml_doc = load_xml ("xl/workbook.xml");

		var workbook_node = xml_doc->get_root_element ();
		if (!(workbook_node->name == "workbook" && workbook_node->ns != null &&
				workbook_node->ns->href == "http://schemas.openxmlformats.org/spreadsheetml/2006/main"))
			throw new Error.WORKBOOK ("xl/workbook.xml is incorrect");

		for (Xml.Node* node = workbook_node->children; node != null; node = node->next) {
			if (node->name == "sheets") {
				int n = 1;
				for (Xml.Node* sheet_node = node->children; sheet_node != null; sheet_node = sheet_node->next) {
//					var sheet_id = (uint) uint64.parse (sheet_node->get_prop ("sheetId"));
					load_worksheet (n, reader);
					n++;
				}
			}
		}

		delete xml_doc;
	}


	private void load_worksheet (uint sheet_id, Reader reader) throws GLib.Error {
		var path = "xl/worksheets/sheet%u.xml".printf (sheet_id);
		var xml_doc = load_xml (path);
		var sheet = reader.worksheet (xml_doc);
		sheets.add (sheet);
//		delete xml_doc;
	}


	private Xml.Doc* load_xml (string path) throws GLib.Error {
		string xml;
		var tmp = archive.extract (path);
		FileUtils.get_contents (tmp.get_path (), out xml);
		return Xml.Parser.read_memory (xml, xml.length);
	}


	public void save_as (File file) throws GLib.Error {
		var writer = new Writer ();

		for (var i = 0; i < sheets.size; i++)
			store_worksheet (sheets[i], i + 1, writer);

		string xml;
		var xml_doc = writer.shared_strings ();
		xml_doc->dump_memory_enc (out xml, null, "UTF-8");
//		delete xml_doc;

		var io = archive.add_from_stream ("xl/sharedStrings.xml");
		xml = Utils.fix_line_ending (xml);
		io.output_stream.write (xml.data);

		archive.write (file);
	}


	private void store_worksheet (Sheet sheet, uint sheet_id, Writer writer) throws GLib.Error {
		Xml.Doc* doc = writer.worksheet (sheet);

		string xml;
		doc->dump_memory_enc (out xml, null, "UTF-8");
		xml = Utils.fix_line_ending (xml);
//		delete doc;

		var path = "xl/worksheets/sheet%u.xml".printf (sheet_id);
		var io = archive.add_from_stream (path);
		io.output_stream.write (xml.data);
	}


	public Sheet sheet (int index) {
		return sheets[index];
	}
}


}
