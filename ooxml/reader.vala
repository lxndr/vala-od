namespace OOXML {


public class Reader {
	public enum CellType {
		BOOLEAN,
		DATE,
		ERROR,
		INLINE_STRING,
		NUMBER,
		SHARED_STRING,
		FORMULA_STRING
	}


	private ShareableList<TextValue> strings;


	public Reader () {
		strings = ShareableList.new_for_text ();
	}


	private Error unknown_tag (Xml.Node* node) {
		return new Error.GENERIC ("Unknown tag '%s' at '%s'", node->name, node->parent->name);
	}


	private Error unknown_attr (Xml.Attr* attr) {
		return new Error.GENERIC ("Unknown attribute '%s' at '%s'", attr->name, attr->parent->name);
	}


	private Error unknown_value (Xml.Attr* attr) {
		var val = st_string (attr);
		return new Error.GENERIC ("Unknown value '%s' of attribute '%s' at '%s'", val, attr->name, attr->parent->name);
	}


	public void shared_strings (Xml.Doc* doc) throws Error {
		Xml.Node* node = doc->get_root_element ();

		if (node->name != "sst" || node->ns == null ||
				node->ns->href != "http://schemas.openxmlformats.org/spreadsheetml/2006/main")
			throw new Error.SHARED_STRINGS ("Unknown xl/sharedStrings.xml format");

		for (Xml.Node* child = node->children; child != null; child = child->next) {
			if (child->name == "si")
				strings.add (ct_rst (child));
			else
				throw unknown_tag (child);
		}
	}


	public Sheet worksheet (Xml.Doc* doc) throws Error {
		Xml.Node* node = doc->get_root_element ();

		if (node->name != "worksheet" || node->ns == null ||
				node->ns->href != "http://schemas.openxmlformats.org/spreadsheetml/2006/main")
			throw new Error.WORKSHEET ("Unknown xl/sheet*.xml format");

		var sheet = new Sheet ();

		for (var child = node->children; child != null; child = child->next) {
			switch (child->name) {
			case "dimension":
				/* TODO: pre-alloc rows and cells */
				break;
			case "sheetViews":
				ct_sheet_views (child, sheet);
				break;
			case "sheetFormatPr":
				ct_sheet_format_pr (child, sheet);
				break;
			case "cols":
				ct_cols (child, sheet);
				break;
			case "sheetData":
				ct_sheet_data (child, sheet);
				break;
			case "mergeCells":
				ct_merge_cells (child, sheet);
				break;
			case "printOptions":
				ct_print_options (child, ref sheet.print_options);
				break;
			case "pageMargins":
				ct_page_margins (child, ref sheet.page_margins);
				break;
			case "pageSetup":
				ct_page_setup (child, ref sheet.page_setup);
				break;
			default:
				throw unknown_tag (child);
			}
		}

		return sheet;
	}


	private void ct_cols (Xml.Node* node, Sheet sheet) throws Error {
		for (var child = node->children; child != null; child = child->next)
			sheet.cols.add (ct_col (child));
	}


	private Column ct_col (Xml.Node* node) throws Error {
		var ret = new Column ();

		for (var attr = node->properties; attr != null; attr = attr->next) {
			switch (attr->name) {
			case "min":
				ret.min = st_uint (attr);
				break;
			case "max":
				ret.max = st_uint (attr);
				break;
			case "width":
				ret.width = st_double (attr);
				break;
			case "style":
				ret.style = st_uint (attr);
				break;
			case "hidden":
				ret.hidden = st_bool (attr);
				break;
			case "bestFit":
				ret.best_fit = st_bool (attr);
				break;
			case "customWidth":
				ret.custom_width = st_bool (attr);
				break;
			case "phonetic":
				ret.phonetic = st_bool (attr);
				break;
			case "outlineLevel":
				ret.outline_level = st_ubyte (attr);
				break;
			case "collapsed":
				ret.collapsed = st_bool (attr);
				break;
			default:
				throw unknown_attr (attr);
			}
		}

		return ret;
	}


	private Pane st_pane (Xml.Attr* attr) throws Error {
		var val = st_string (attr);

		switch (val) {
		case "topLeft":
			return Pane.TOP_LEFT;
		case "topRight":
			return Pane.TOP_RIGHT;
		case "bottomLeft":
			return Pane.BOTTOM_LEFT;
		case "bottomRight":
			return Pane.BOTTOM_RIGHT;
		default:
			throw unknown_value (attr);
		}
	}


	private SheetViewType st_sheet_view_type (Xml.Attr* attr) throws Error {
		var val = st_string (attr);

		switch (val) {
		case "normal":
			return SheetViewType.NORMAL;
		case "pageBreakPreview":
			return SheetViewType.PAGE_BREAK_PREVIEW;
		case "pageLayout":
			return SheetViewType.PAGE_LAYOUT;
		default:
			throw unknown_value (attr);
		}		
	}


	private Selection ct_selection (Xml.Node* node, Sheet sheet) throws Error {
		var ret = new Selection (sheet);

		for (var attr = node->properties; attr != null; attr = attr->next) {
			switch (attr->name) {
			case "pane":
				ret.pane = st_pane (attr);
				break;
			case "activeCell":
				ret.active_cell = st_cell_ref (attr, sheet);
				break;
			case "activeCellId":
				ret.active_cell_id = st_uint (attr);
				break;
			case "sqref":
//				ret.sqref = st_sqref (attr);
				break;
			default:
				throw unknown_attr (attr);
			}
		}

		return ret;
	}


	private SheetView ct_sheet_view (Xml.Node* node, Sheet sheet) throws Error {
		var ret = new SheetView ();

		for (var attr = node->properties; attr != null; attr = attr->next) {
			switch (attr->name) {
			case "windowProtection":
				ret.window_protection = st_bool (attr);
				break;
			case "showFormulas":
				ret.show_formulas = st_bool (attr);
				break;
			case "showGridLines":
				ret.show_grid_lines = st_bool (attr);
				break;
			case "showRowColHeaders":
				ret.show_row_col_headers = st_bool (attr);
				break;
			case "showZeros":
				ret.show_zeros = st_bool (attr);
				break;
			case "rightToLeft":
				ret.right_to_left = st_bool (attr);
				break;
			case "tabSelected":
				ret.tab_selected = st_bool (attr);
				break;
			case "showRuler":
				ret.show_ruler = st_bool (attr);
				break;
			case "showOutlineSymbols":
				ret.show_outline_symbols = st_bool (attr);
				break;
			case "defaultGridColor":
				ret.default_grid_color = st_bool (attr);
				break;
			case "showWhiteSpace":
				ret.show_white_space = st_bool (attr);
				break;
			case "view":
				ret.view = st_sheet_view_type (attr);
				break;
			case "topLeftCell":
				ret.top_left_cell = st_cell_ref (attr, sheet);
				break;
			case "colorId":
				ret.color_id = st_uint (attr);
				break;
			case "zoomScale":
				ret.zoom_scale = st_uint (attr);
				break;
			case "zoomScaleNormal":
				ret.zoom_scale_normal = st_uint (attr);
				break;
			case "zoomScaleSheetLayoutView":
				ret.zoom_scale_sheet_layout_view = st_uint (attr);
				break;
			case "zoomScalePageLayoutView":
				ret.zoom_scale_page_layout_view = st_uint (attr);
				break;
			case "workbookViewId":
				ret.workbook_view_id = st_uint (attr);
				break;
			default:
				throw unknown_attr (attr);
			}
		}

		for (var child = node->children; child != null; child = child->next) {
			switch (child->name) {
			case "selection":
				ret.selections.add (ct_selection (child, sheet));
				break;
			default:
				throw unknown_tag (child);
			}
		}

		return ret;
	}


	private void ct_sheet_views (Xml.Node* node, Sheet sheet) throws Error {
		for (Xml.Node* child = node->children; child != null; child = child->next) {
			if (child->name == "sheetView")
				sheet.views.add (ct_sheet_view (child, sheet));
			else
				throw unknown_tag (child);
		}
	}


	public void ct_sheet_format_pr (Xml.Node* node, Sheet sheet) throws Error {
		for (Xml.Attr* attr = node->properties; attr != null; attr = attr->next) {
			switch (attr->name) {
			case "baseColWidth":
				sheet.base_col_width = st_uint (attr);
				break;
			case "defaultColWidth":
				sheet.default_col_width = st_double (attr);
				break;
			case "defaultRowHeight":
				sheet.default_row_height = st_double (attr);
				break;
			case "customHeight":
				sheet.custom_height = st_bool (attr);
				break;
			case "zeroHeight":
				sheet.zero_height = st_bool (attr);
				break;
			case "thickTop":
				sheet.thick_top = st_bool (attr);
				break;
			case "thickBottom":
				sheet.thick_bottom = st_bool (attr);
				break;
			case "outlineLevelRow":
				sheet.outline_level_row = st_ubyte (attr);
				break;
			case "outlineLevelCol":
				sheet.outline_level_col = st_ubyte (attr);
				break;
			}
		}
	}


	private CellType st_cell_type (Xml.Attr* attr) throws Error {
		var val = st_string (attr);

		switch (val) {
		case "b":
			return CellType.BOOLEAN;
		case "d":
			return CellType.DATE;
		case "n":
			return CellType.NUMBER;
		case "e":
			return CellType.ERROR;
		case "s":
			return CellType.SHARED_STRING;
		case "str":
			return CellType.FORMULA_STRING;
		case "inlineStr":
			return CellType.INLINE_STRING;
		default:
			throw unknown_value (attr);
		}
	}


	private CellValue? cell_value (CellType type, string? v_val, TextValue? is_val) throws Error {
		switch (type) {
		case CellType.NUMBER:
			return new NumberValue.from_string (v_val);
		case CellType.SHARED_STRING:
			int64 index = 0;
			if (v_val == null || int64.try_parse (v_val, out index) == false)
				throw new Error.WORKSHEET ("Wrong value");
			return strings[(int) index];
		case CellType.INLINE_STRING:
			if (is_val == null)
				throw new Error.WORKSHEET ("Wrong value");
			return is_val;
		default:
			return null;
		}
	}


	private Cell ct_cell (Xml.Node* node, Row row) throws Error {
		CellType type = CellType.NUMBER;

		var number_attr = node->get_prop ("r");
		int row_number;
		int cell_number;
		Utils.parse_cell_name (number_attr, out row_number, out cell_number);
		assert (row_number == row.number);
		var cell = row.get_cell (cell_number);

		for (var attr = node->properties; attr != null; attr = attr->next) {
			switch (attr->name) {
			case "r":
				break;
			case "s":
				cell.style = st_uint (attr);
				break;
			case "t":
				type = st_cell_type (attr);
				break;
			case "cm":
				cell.cell_metadata = st_uint (attr);
				break;
			case "vm":
				cell.value_metadata = st_uint (attr);
				break;
			case "ph":
				cell.show_phonetic = st_bool (attr);
				break;
			default:
				throw unknown_attr (attr);
			}
		}

		if (node->children != null) {
			string? v_val = null;
			TextValue? is_val = null;

			for (Xml.Node* child = node->children; child != null; child = child->next) {
				switch (child->name) {
				case "v":
					v_val = st_xstring (child);
					break;
	//			case "is":
	//				is_val = ct_rst (child);
	//				break;
				default:
					throw unknown_tag (child);
				}
			}

			cell.val = cell_value (type, v_val, is_val);
		}

		return cell;
	}


	private Row ct_row (Xml.Node* node, Sheet sheet) throws Error {
		var number_attr = node->get_prop ("r");
		int number = int.parse (number_attr);
		var row = sheet.get_row (number);

		for (var attr = node->properties; attr != null; attr = attr->next) {
			switch (attr->name) {
			case "r":
				break;
			case "spans":
				break;
			case "s":
				row.style = st_uint (attr);
				break;
			case "customFormat":
				row.custom_format = st_bool (attr);
				break;
			case "ht":
				row.height = st_double (attr);
				break;
			case "hidden":
				row.hidden = st_bool (attr);
				break;
			case "customHeight":
				row.custom_height = st_bool (attr);
				break;
			case "outlineLevel":
				row.outline_level = st_ubyte (attr);
				break;
			case "collapsed":
				row.collapsed = st_bool (attr);
				break;
			case "thickTop":
				row.thick_top = st_bool (attr);
				break;
			case "thickBot":
				row.thick_bottom = st_bool (attr);
				break;
			case "ph":
				row.show_phonetic = st_bool (attr);
				break;
			case "dyDescent":
				if (attr->ns != null && attr->ns->href == "http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac")
					row.dyDescent = st_double (attr);
				break;
			default:
				throw unknown_attr (attr);
			}
		}

		for (var child = node->children; child != null; child = child->next) {
			if (child->name == "c")
				ct_cell (child, row);
			else
				throw unknown_tag (child);
		}

		return row;
	}


	private void ct_sheet_data (Xml.Node* node, Sheet sheet) throws Error {
		for (var child = node->children; child != null; child = child->next) {
			if (child->name == "row")
				ct_row (child, sheet);
			else
				throw unknown_tag (child);
		}
	}


	private string ct_merge_cell (Xml.Node* node) throws Error {
		string ret = "";

		for (var attr = node->properties; attr != null; attr = attr->next) {
			switch (attr->name) {
			case "ref":
				ret = st_string (attr);
				break;
			default:
				throw unknown_attr (attr);
			}
		}

		return ret;
	}


	private void ct_merge_cells (Xml.Node* node, Sheet sheet) throws Error {
		for (var child = node->children; child != null; child = child->next) {
			if (child->name == "mergeCell")
				sheet.merge_cells.add (ct_merge_cell (child));
			else
				unknown_tag (child);
		}
	}


	private void ct_print_options (Xml.Node* node, ref PrintOptions options) throws Error {
		for (var attr = node->properties; attr != null; attr = attr->next) {
			switch (attr->name) {
			case "horizontalCentered":
				options.horizontal_centered = st_bool (attr);
				break;
			case "verticalCentered":
				options.vertical_centered = st_bool (attr);
				break;
			case "headings":
				options.headings = st_bool (attr);
				break;
			case "gridLines":
				options.grid_lines = st_bool (attr);
				break;
			case "gridLinesSet":
				options.grid_lines_set = st_bool (attr);
				break;
			default:
				throw unknown_attr (attr);
			}
		}
	}


	private void ct_page_margins (Xml.Node* node, ref PageMargins margins) throws Error {
		for (var attr = node->properties; attr != null; attr = attr->next) {
			switch (attr->name) {
			case "left":
				margins.left = st_double (attr);
				break;
			case "right":
				margins.right = st_double (attr);
				break;
			case "top":
				margins.top = st_double (attr);
				break;
			case "bottom":
				margins.bottom = st_double (attr);
				break;
			case "header":
				margins.header = st_double (attr);
				break;
			case "footer":
				margins.footer = st_double (attr);
				break;
			default:
				throw unknown_attr (attr);
			}
		}
	}


	private Orientation st_orientation (Xml.Attr* attr) throws Error {
		var val = st_string (attr);

		switch (val) {
		case "defaullt":
			return Orientation.DEFAULT;
		case "portrait":
			return Orientation.PORTRAIT;
		case "landscape":
			return Orientation.LANDSCAPE;
		default:
			throw unknown_value (attr);
		}		
	}


	private void ct_page_setup (Xml.Node* node, ref PageSetup setup) throws Error {
		for (var attr = node->properties; attr != null; attr = attr->next) {
			switch (attr->name) {
			case "paperSize":
				setup.paper_size = st_uint (attr);
				break;
			case "orientation":
				setup.orientation = st_orientation (attr);
				break;
			case "verticalDpi":
				setup.vertical_dpi = st_uint (attr);
				break;
			case "id":
				if (attr->ns != null && attr->ns->href == "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
					setup.r_id = st_string (attr);
				break;
			default:
				throw unknown_attr (attr);
			}
		}
	}


	private TextValue ct_rst (Xml.Node* node) throws Error {
		var ret = new RichTextValue ();

		for (Xml.Node* child = node->children; child != null; child = child->next) {
			switch (child->name) {
			case "t":
				return new SimpleTextValue (st_xstring (child));
			case "r":
				ret.pieces.add (ct_relt (child));
				break;
			default:
				throw unknown_tag (child);
			}
		}

		return ret;
	}


	private RichTextPiece ct_relt (Xml.Node* node) throws Error {
		var ret = new RichTextPiece ();

		for (var child = node->children; child != null; child = child->next) {
			switch (child->name) {
			case "rPr":
				ct_rprelt (child, ret);
				break;
			case "t":
				ret.text = st_xstring (child);
				break;
			default:
				throw unknown_tag (child);
			}
		}

		return ret;
	}


	private void ct_rprelt (Xml.Node* node, RichTextPiece piece) throws Error {
		for (var child = node->children; child != null; child = child->next) {
			switch (child->name) {
			case "rFront":
				piece.font = ct_font_name (child);
				break;
			case "charset":
				piece.charset = ct_int_property (child);
				break;
			case "family":
				piece.family = ct_int_property (child);
				break;
			case "b":
				piece.bold = ct_boolean_property (child);
				break;
			case "i":
				piece.italic = ct_boolean_property (child);
				break;
			case "strike":
				piece.strike = ct_boolean_property (child);
				break;
			case "outline":
				piece.outline = ct_boolean_property (child);
				break;
			case "shadow":
				piece.shadow = ct_boolean_property (child);
				break;
			case "condense":
				piece.condense = ct_boolean_property (child);
				break;
			case "extend":
				piece.extend = ct_boolean_property (child);
				break;
//			case "color":
//				break;
			case "sz":
				piece.size = ct_font_size (child);
				break;
			case "u":
				piece.underline = ct_underline_property (child);
				break;
			case "vertAlign":
				break;
			case "scheme":
				break;
			default:
				throw unknown_tag (child);
			}
		}
	}


	private string ct_font_name (Xml.Node* node) throws Error {
		string ret = "";

		for (var attr = node->properties; attr != null; attr = attr->next) {
			switch (attr->name) {
			case "val":
				ret = st_string (attr);
				break;
			default:
				throw unknown_attr (attr);
			}
		}

		return ret;
	}


	private int ct_int_property (Xml.Node* node) throws Error {
		int ret = 0;

		for (var attr = node->properties; attr != null; attr = attr->next) {
			switch (attr->name) {
			case "val":
				ret = st_int (attr);
				break;
			default:
				throw unknown_attr (attr);
			}
		}

		return ret;
	}


	private bool ct_boolean_property (Xml.Node* node) throws Error {
		bool ret = false;

		for (var attr = node->properties; attr != null; attr = attr->next) {
			switch (attr->name) {
			case "val":
				ret = st_bool (attr);
				break;
			default:
				throw unknown_attr (attr);
			}
		}

		return ret;
	}


	private double ct_font_size (Xml.Node* node) throws Error {
		double ret = 0.0;

		for (var attr = node->properties; attr != null; attr = attr->next) {
			switch (attr->name) {
			case "val":
				ret = st_double (attr);
				break;
			default:
				throw unknown_attr (attr);
			}
		}

		return ret;
	}


	private UnderlineType ct_underline_property (Xml.Node* node) throws Error {
		UnderlineType ret = UnderlineType.NONE;

		for (var attr = node->properties; attr != null; attr = attr->next) {
			switch (attr->name) {
			case "val":
				ret = st_underline_values (attr);
				break;
			default:
				throw unknown_attr (attr);
			}
		}

		return ret;
	}


	private UnderlineType st_underline_values (Xml.Attr* attr) throws Error {
		var val = st_string (attr);

		switch (val) {
		case "single":
			return UnderlineType.SINGLE;
		case "double":
			return UnderlineType.DOUBLE;
		case "singleAccounting":
			return UnderlineType.SINGLE_ACCOUNTING;
		case "doubleAccounting":
			return UnderlineType.DOUBLE_ACCOUNTING;
		case "none":
			return UnderlineType.NONE;
		default:
			throw unknown_value (attr);
		}		
	}


	private string st_xstring (Xml.Node* node) {
		if (node->children != null && node->children->type == Xml.ElementType.TEXT_NODE)
			return node->children->content;
		else
			return "";
	}


	private string st_string (Xml.Attr* attr) {
		if (attr->children == null || attr->children->content == null)
			return "";
		return attr->children->content;
	}


	private uint8 st_ubyte (Xml.Attr* attr) {
		return (uint8) uint64.parse (st_string (attr));
	}


	private int st_int (Xml.Attr* attr) {
		return int.parse (st_string (attr));
	}


	private uint st_uint (Xml.Attr* attr) {
		return (uint) uint64.parse (st_string (attr));
	}


	private double st_double (Xml.Attr* attr) {
		return double.parse (st_string (attr));
	}


	private bool st_bool (Xml.Attr* attr) {
		var s = st_string (attr).ascii_down ();
		return s == "1" || s == "true" || s == "yes";
	}


	private Cell st_cell_ref (Xml.Attr* attr, Sheet sheet) {
		return sheet.get_cell (st_string (attr));
	}
}


}
