namespace OOXML {


public class Writer {
	private Xml.Ns* ns;
	private Xml.Ns* r_ns;
	private Xml.Ns* mc_ns;
	private Xml.Ns* x14ac_ns;

	private ShareableList<TextValue> strings;


	public Writer () {
		ns = new Xml.Ns (null, "http://schemas.openxmlformats.org/spreadsheetml/2006/main", null);
		r_ns = new Xml.Ns (null, "http://schemas.openxmlformats.org/officeDocument/2006/relationships", "r");
		mc_ns = new Xml.Ns (null, "http://schemas.openxmlformats.org/markup-compatibility/2006", "mc");
		x14ac_ns = new Xml.Ns (null, "http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac", "x14ac");

		strings = ShareableList.new_for_text ();
	}


	public Xml.Doc* shared_strings () throws Error {
		Xml.Doc* doc = new Xml.Doc ("1.0");
		doc->standalone = 1;

		Xml.Node* node = doc->new_node (ns, "sst");
		st_uint (node, null, "count", strings.size);
		st_uint (node, null, "uniqueCount", strings.size);

		ns->next = null;
		node->ns_def = ns;

		foreach (var val in strings)
			ct_rst (node, val);

		doc->set_root_element (node);
		return doc;
	}


	private void ct_rst (Xml.Node* parent, TextValue val) {
		Xml.Node* node = parent->new_child (ns, "si");

		if (val is SimpleTextValue)
			st_xstring (node, "t", ((SimpleTextValue) val).text);
		else if (val is RichTextValue)
			ct_relt (node, (RichTextValue) val);
		else
			assert (val is SimpleTextValue || val is RichTextValue);
	}


	private void ct_relt (Xml.Node* parent, RichTextValue val) {
		foreach (var piece in val.pieces) {
			Xml.Node* node = new Xml.Node (ns, "r");
			ct_rprelt (node, piece);
			st_xstring (node, "t", piece.text);
		}
	}


	private void ct_rprelt (Xml.Node* parent, RichTextPiece piece) {
		Xml.Node* node = parent->new_child (ns, "rPr");

		ct_font_name (node, "rFont", piece.font);
		ct_int_property (node, "charset", piece.charset);
		ct_int_property (node, "family", piece.family);
		ct_bool_property (node, "b", piece.bold);
		ct_bool_property (node, "i", piece.italic);
		ct_bool_property (node, "strike", piece.strike);
		ct_bool_property (node, "outline", piece.outline);
		ct_bool_property (node, "shadow", piece.shadow);
		ct_bool_property (node, "condense", piece.condense);
		ct_bool_property (node, "extend", piece.extend);
//		st_color (node, "color", piece.color);
		ct_font_size (node, "sz", piece.size);
//		st_underline_property (node, "u", piece.underline);
//		st_vertical_align_font_property (node, "vertAlign", piece.vertical_align);
//		st_font_schema (node, "scheme", piece.scheme);
	}


	private void ct_font_name (Xml.Node* parent, string name, string val) {
		Xml.Node* node = parent->new_child (ns, name);
		st_string (node, ns, "val", val);
	}


	private void ct_font_size (Xml.Node* parent, string name, double val) {
		Xml.Node* node = parent->new_child (ns, name);
		st_double (node, ns, "val", val);
	}


	private void ct_int_property (Xml.Node* parent, string name, int val) {
		Xml.Node* node = parent->new_child (ns, name);
		st_int (node, ns, "val", val);
	}


	private void ct_bool_property (Xml.Node* parent, string name, bool val) {
		Xml.Node* node = parent->new_child (ns, name);
		st_bool (node, ns, "val", val);
	}


	public Xml.Doc* worksheet (Sheet sheet) {
		Xml.Doc* doc = new Xml.Doc ("1.0");
		doc->standalone = 1;

		ns->next = r_ns;
		r_ns->next = mc_ns;
		mc_ns->next = x14ac_ns;

		Xml.Node* node = doc->new_node (ns, "worksheet");
		node->ns_def = ns;
		node->new_ns_prop (mc_ns, "Ignorable", "x14ac");

		ct_sheet_views (node, sheet);
		ct_sheet_format_pr (node, sheet);
		ct_cols (node, sheet);
		ct_sheet_data (node, sheet);
		ct_merge_cells (node, sheet);
		ct_print_options (node, ref sheet.print_options);
		ct_page_margins (node, ref sheet.page_margins);
		ct_page_setup (node, ref sheet.page_setup);

		doc->set_root_element (node);
		return doc;
	}


	private void ct_sheet_views (Xml.Node* parent, Sheet sheet) {
		Xml.Node* node = parent->new_child (ns, "sheetViews");
		foreach (var view in sheet.views)
			ct_sheet_view (node, view);
	}


	private void ct_sheet_view (Xml.Node* parent, SheetView sheet_view) {
		Xml.Node* node = parent->new_child (ns, "sheetView");

		if (sheet_view.window_protection != false)
			st_bool (node, ns, "windowProtection", sheet_view.window_protection);
		if (sheet_view.show_formulas != false)
			st_bool (node, ns, "showFormulas", sheet_view.show_formulas);
		if (sheet_view.show_grid_lines != true)
			st_bool (node, ns, "showGridLines", sheet_view.show_grid_lines);
		if (sheet_view.show_row_col_headers != true)
			st_bool (node, ns, "showRowColHeaders", sheet_view.show_row_col_headers);
		if (sheet_view.show_zeros != true)
			st_bool (node, ns, "showZeros", sheet_view.show_zeros);
		if (sheet_view.right_to_left != false)
			st_bool (node, ns, "rightToLeft", sheet_view.right_to_left);
		if (sheet_view.tab_selected != false)
			st_bool (node, ns, "tabSelected", sheet_view.tab_selected);
		if (sheet_view.show_ruler != true)
			st_bool (node, ns, "showRuler", sheet_view.show_ruler);
		if (sheet_view.show_outline_symbols != true)
			st_bool (node, ns, "showOutlineSymbols", sheet_view.show_outline_symbols);
		if (sheet_view.default_grid_color != true)
			st_bool (node, ns, "defaultGridColor", sheet_view.default_grid_color);
		if (sheet_view.show_white_space != true)
			st_bool (node, ns, "showWhiteSpace", sheet_view.show_white_space);
		if (sheet_view.view != SheetViewType.NORMAL)
			st_sheet_view_type (node, ns, "view", sheet_view.view);
		if (sheet_view.top_left_cell != null)
			st_cell_ref (node, ns, "topLeftCell", sheet_view.top_left_cell);
		if (sheet_view.color_id != 64)
			st_uint (node, ns, "colorId", sheet_view.color_id);
		if (sheet_view.zoom_scale != 100)
			st_uint (node, ns, "zoomScale", sheet_view.zoom_scale);
		if (sheet_view.zoom_scale_normal != 0)
			st_uint (node, ns, "zoomScaleNormal", sheet_view.zoom_scale_normal);
		if (sheet_view.zoom_scale_sheet_layout_view != 0)
			st_uint (node, ns, "zoomScaleSheetLayoutView", sheet_view.zoom_scale_sheet_layout_view);
		if (sheet_view.zoom_scale_page_layout_view != 0)
			st_uint (node, ns, "zoomScalePageLayoutView", sheet_view.zoom_scale_page_layout_view);
		st_uint (node, ns, "workbookViewId", sheet_view.workbook_view_id);

//		foreach (var selection in sheet_view.selections)
//			ct_selection (node, selection);
	}


	private void st_sheet_view_type (Xml.Node* parent, Xml.Ns* ns, string name, SheetViewType type) {
		unowned string s;

		switch (type) {
		case SheetViewType.PAGE_BREAK_PREVIEW:
			s = "pageBreakPreview";
			break;
		case SheetViewType.PAGE_LAYOUT:
			s = "pageLayout";
			break;
		case SheetViewType.NORMAL:
		default:
			s = "normal";
			break;
		}

		st_string (parent, ns, name, s);
	}


	private void ct_selection (Xml.Node* parent, Selection selection) {
		Xml.Node* node = parent->new_child (ns, "selection");

		if (selection.pane != Pane.TOP_LEFT)
			st_pane (node, ns, "pane", selection.pane);
		st_cell_ref (node, ns, "activeCell", selection.active_cell);
		if (selection.active_cell_id != 0)
			st_uint (node, ns, "activeCellId", selection.active_cell_id);
//		st_sqref (node, ns, "sqref", slection.sqref);
	}


	private void st_pane (Xml.Node* parent, Xml.Ns* ns, string name, Pane pane) {
		unowned string s;

		switch (pane) {
		case Pane.BOTTOM_RIGHT:
			s = "bottomRight";
			break;
		case Pane.TOP_RIGHT:
			s = "topRight";
			break;
		case Pane.BOTTOM_LEFT:
			s = "bottomLeft";
			break;
		case Pane.TOP_LEFT:
		default:
			s = "topLeft";
			break;
		}

		st_string (parent, ns, name, s);
	}


	private void ct_sheet_format_pr (Xml.Node* parent, Sheet sheet) {
		Xml.Node* node = parent->new_child (ns, "sheetFormatPr");

		if (sheet.base_col_width != 8)
			st_uint (node, ns, "baseColWidth", sheet.base_col_width);
		if (sheet.default_col_width >= 0.0)
			st_double (node, ns, "defaultColWidth", sheet.default_col_width);
		if (sheet.default_row_height >= 0.0)
			st_double (node, ns, "defaultRowHeight", sheet.default_row_height);
		if (sheet.custom_height != false)
			st_bool (node, ns, "customHeight", sheet.custom_height);
		if (sheet.zero_height != false)
			st_bool (node, ns, "zeroHeight", sheet.zero_height);
		if (sheet.thick_top != false)
			st_bool (node, ns, "thickTop", sheet.thick_top);
		if (sheet.thick_bottom != false)
			st_bool (node, ns, "thickBottom", sheet.thick_bottom);
		if (sheet.outline_level_row != 0)
			st_ubyte (node, ns, "outlineLevelRow", sheet.outline_level_row);
		if (sheet.outline_level_col != 0)
			st_ubyte (node, ns, "outlineLevelCol", sheet.outline_level_col);
	}


	private void ct_cols (Xml.Node* parent, Sheet sheet) {
		if (sheet.cols.size == 0)
			return;

		Xml.Node* node = parent->new_child (ns, "cols");
		foreach (var col in sheet.cols)
			ct_col (node, col);
	}


	private void ct_col (Xml.Node* parent, Column col) {
		Xml.Node* node = parent->new_child (ns, "col");

		st_uint (node, ns, "min", col.min);
		st_uint (node, ns, "max", col.max);
		st_double (node, ns, "width", col.width);
		if (col.style != 0)
			st_uint (node, ns, "style", col.style);
		if (col.hidden != false)
			st_bool (node, ns, "hidden", col.hidden);
		if (col.best_fit != false)
			st_bool (node, ns, "bestFit", col.best_fit);
		if (col.custom_width != false)
			st_bool (node, ns, "customWidth", col.custom_width);
		if (col.phonetic != false)
			st_bool (node, ns, "phonetic", col.phonetic);
		if (col.outline_level != 0)
			st_uint (node, ns, "outlineLevel", col.outline_level);
		if (col.collapsed != false)
			st_bool (node, ns, "collapsed", col.collapsed);
	}


	private void ct_sheet_data (Xml.Node* parent, Sheet sheet) {
		Xml.Node* node = parent->new_child (ns, "sheetData");
		foreach (var row in sheet.rows)
			if (row.is_empty () == false)
				ct_row (node, row);
	}


	private void ct_row (Xml.Node* parent, Row row) {
		Xml.Node* node = parent->new_child (ns, "row");

		st_uint (node, ns, "r", row.number);
		if (row.style != 0)
			st_uint (node, ns, "s", row.style);
		if (row.custom_format != false)
			st_bool (node, ns, "customFormat", row.custom_format);
		if (row.height >= 0.0)
			st_double (node, ns, "ht", row.height);
		if (row.hidden != false)
			st_bool (node, ns, "hidden", row.hidden);
		if (row.custom_height != false)
			st_bool (node, ns, "customHeight", row.custom_height);
		if (row.outline_level != 0)
			st_ubyte (node, ns, "outlineLevel", row.outline_level);
		if (row.collapsed != false)
			st_bool (node, ns, "collapsed", row.collapsed);
		if (row.thick_top != false)
			st_bool (node, ns, "thickTop", row.thick_top);
		if (row.thick_bottom != false)
			st_bool (node, ns, "thickBot", row.thick_bottom);
		if (row.show_phonetic != false)
			st_bool (node, ns, "ph", row.show_phonetic);
		if (row.dyDescent != 0.0)
			st_double (node, x14ac_ns, "dyDescent", row.dyDescent);

		foreach (var cell in row.cells)
			if (cell.is_empty () == false)
				ct_cell (node, cell);
	}


	private void ct_cell (Xml.Node* parent, Cell cell) {
		Xml.Node* node = parent->new_child (ns, "c");

		st_cell_ref (node, ns, "r", cell);
		if (cell.style != 0)
			st_uint (node, ns, "s", cell.style);
		if (cell.cell_metadata != 0)
			st_uint (node, ns, "cm", cell.cell_metadata);
		if (cell.value_metadata != 0)
			st_uint (node, ns, "vm", cell.cell_metadata);
		if (cell.show_phonetic != false)
			st_bool (node, ns, "ph", cell.show_phonetic);

		if (cell.val == null)
			return;

		var value_type = cell.val.get_type ();
		if (value_type == typeof (NumberValue)) {
			char[] buf = new char[double.DTOSTR_BUF_SIZE];
			st_xstring (node, "v", ((NumberValue) cell.val).val.to_str (buf));
		} else if (value_type.is_a (typeof (TextValue))) {
			st_string (node, ns, "t", "s");
			var index = strings.try_add ((TextValue) cell.val);
			st_xstring (node, "v", index.to_string ());
		}
	}


	private void ct_merge_cells (Xml.Node* parent, Sheet sheet) {
		Xml.Node* node = parent->new_child (ns, "mergeCells");

		st_uint (node, ns, "count", sheet.merge_cells.size);
		foreach (var merge_cell in sheet.merge_cells)
			ct_merge_cell (node, merge_cell);
	}


	private void ct_merge_cell (Xml.Node* parent, string val) {
		Xml.Node* node = parent->new_child (ns, "mergeCell");
		st_string (node, ns, "ref", val);
	}


	private void ct_print_options (Xml.Node* parent, ref PrintOptions options) {
		Xml.Node* node = parent->new_child (ns, "printOptions");

		if (options.horizontal_centered != false)
			st_bool (node, ns, "horizontalCentered", options.horizontal_centered);
		if (options.vertical_centered != false)
			st_bool (node, ns, "verticalCentered", options.vertical_centered);
		if (options.headings != false)
			st_bool (node, ns, "headings", options.headings);
		if (options.grid_lines != false)
			st_bool (node, ns, "gridLines", options.grid_lines);
		if (options.grid_lines_set != true)
			st_bool (node, ns, "gridLinesSet", options.grid_lines_set);

		if (node->properties == null)
			node->unlink ();
	}


	private void ct_page_margins (Xml.Node* parent, ref PageMargins margins) {
		Xml.Node* node = parent->new_child (ns, "pageMargins");

		st_double (node, ns, "left", margins.left);
		st_double (node, ns, "right", margins.right);
		st_double (node, ns, "top", margins.top);
		st_double (node, ns, "bottom", margins.bottom);
		st_double (node, ns, "header", margins.header);
		st_double (node, ns, "footer", margins.footer);
	}


	private void ct_page_setup (Xml.Node* parent, ref PageSetup setup) {
		Xml.Node* node = parent->new_child (ns, "pageSetup");

		if (setup.paper_size != 1)
			st_uint (node, ns, "paperSize", setup.paper_size);
		if (setup.orientation != Orientation.DEFAULT)
			st_orientation (node, ns, "orientation", setup.orientation);
		if (setup.vertical_dpi != 600)
			st_uint (node, ns, "verticalDpi", setup.vertical_dpi);
		st_string (node, r_ns, "id", setup.r_id);

		if (node->properties == null)
			node->unlink ();
	}


	private void st_orientation (Xml.Node* parent, Xml.Ns* ns, string name, Orientation val) {
		unowned string s;

		switch (val) {
		case Orientation.PORTRAIT:
			s = "portrait";
			break;
		case Orientation.LANDSCAPE:
			s = "landscape";
			break;
		case Orientation.DEFAULT:
			s = "default";
			break;
		default:
			s = "unknwown";
			break;
		}

		st_string (parent, ns, name, s);
	}


	private void st_cell_ref (Xml.Node* parent, Xml.Ns* ns, string name, Cell cell) {
		st_string (parent, ns, name, cell.get_name ());
	}


	private void st_xstring (Xml.Node* parent, string name, string text) {
		parent->new_text_child (ns, name, text);
	}


	private void st_bool (Xml.Node* parent, Xml.Ns* ns, string name, bool val) {
		unowned string s = "0";
		if (val == true)
			s = "1";
		st_string (parent, ns, name, s);
	}


	private void st_ubyte (Xml.Node* parent, Xml.Ns* ns, string name, uint8 val) {
		st_string (parent, ns, name, val.to_string ());
	}


	private void st_uint (Xml.Node* parent, Xml.Ns* ns, string name, uint val) {
		st_string (parent, ns, name, val.to_string ());
	}


	private void st_int (Xml.Node* parent, Xml.Ns* ns, string name, int val) {
		st_string (parent, ns, name, val.to_string ());
	}


	private void st_double (Xml.Node* parent, Xml.Ns* ns, string name, double val) {
		char[] buf = new char[double.DTOSTR_BUF_SIZE];
		st_string (parent, ns, name, val.to_str (buf));
	}


	private void st_string (Xml.Node* parent, Xml.Ns* ns, string name, string val) {
		parent->new_ns_prop (ns, name, val);
	}
}


}
