namespace OOXML {


public enum Pane {
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT
}


public enum Orientation {
	DEFAULT,
	PORTRAIT,
	LANDSCAPE
}


public enum UnderlineType {
	NONE,
	SINGLE,
	DOUBLE,
	SINGLE_ACCOUNTING,
	DOUBLE_ACCOUNTING
}


public class Selection : Object {
	private Sheet sheet;

	public Pane pane;
	public Cell? active_cell;
	public uint active_cell_id;
//	public SqRef sqref;


	public Selection (Sheet _sheet) {
		sheet = _sheet;
		pane = Pane.TOP_LEFT;
		active_cell = sheet.get_cell ("A1");
		active_cell_id = 0;
//		sqref = 
	}
}


public enum SheetViewType {
	NORMAL,
	PAGE_BREAK_PREVIEW,
	PAGE_LAYOUT
}



public class SheetView : Object {
	public bool window_protection;
	public bool show_formulas;
	public bool show_grid_lines;
	public bool show_row_col_headers;
	public bool show_zeros;
	public bool right_to_left;
	public bool tab_selected;
	public bool show_ruler;
	public bool show_outline_symbols;
	public bool default_grid_color;
	public bool show_white_space;
	public SheetViewType view;
	public Cell? top_left_cell;
	public uint color_id;
	public uint zoom_scale;
	public uint zoom_scale_normal;
	public uint zoom_scale_sheet_layout_view;
	public uint zoom_scale_page_layout_view;
	public uint workbook_view_id;

	public Gee.List<Selection> selections;


	public SheetView () {
		window_protection = false;
		show_formulas = false;
		show_grid_lines = true;
		show_row_col_headers = true;
		show_zeros = true;
		right_to_left = false;
		tab_selected = false;
		show_ruler = true;
		show_outline_symbols = true;
		default_grid_color = true;
		show_white_space = true;
		view = SheetViewType.NORMAL;
		top_left_cell = null;
		color_id = 64;
		zoom_scale = 100;
		zoom_scale_normal = 0;
		zoom_scale_sheet_layout_view = 0;

		selections = new Gee.ArrayList<Selection> ();
	}
}


public struct PrintOptions {
	bool horizontal_centered;
	bool vertical_centered;
	bool headings;
	bool grid_lines;
	bool grid_lines_set;


	public PrintOptions () {
		horizontal_centered = false;
		vertical_centered = false;
		headings = false;
		grid_lines = false;
		grid_lines_set = true;
	}
}


public struct PageMargins {
	double left;
	double right;
	double top;
	double bottom;
	double header;
	double footer;
}


public struct PageSetup {
	uint paper_size;
	Orientation orientation;
	uint vertical_dpi;
	string r_id;


	public PageSetup () {
		paper_size = 1;
		orientation = Orientation.DEFAULT;
		vertical_dpi = 600;
	}
}


public class Column : Object {
	public uint min;
	public uint max;
	public double width;
	public uint style;
	public bool hidden;
	public bool best_fit;
	public bool custom_width;
	public bool phonetic;
	public uint8 outline_level;
	public bool collapsed;


	public Column () {
		style = 0;
		hidden = false;
		best_fit = false;
		custom_width = false;
		phonetic = false;
		outline_level = 0;
		collapsed = false;
	}
}


public class Sheet : Object {
	public uint base_col_width;
	public double default_col_width;
	public double default_row_height;
	public bool custom_height;
	public bool zero_height;
	public bool thick_top;
	public bool thick_bottom;
	public uint8 outline_level_row;
	public uint8 outline_level_col;
	public PrintOptions print_options;
	public PageMargins page_margins;
	public PageSetup page_setup;

	public Gee.List<SheetView> views;
	public Gee.List<string> merge_cells;
	public Gee.List<Column> cols;
	public Gee.List<Row> rows;


	public Sheet () {
		base_col_width = 8;
		default_col_width = -1.0;
		default_row_height = -1.0;
		custom_height = false;
		zero_height = false;
		thick_top = false;
		thick_bottom = false;
		outline_level_row = 0;
		outline_level_col = 0;

		print_options = PrintOptions ();
		page_setup = PageSetup ();

		views = new Gee.ArrayList<SheetView> ();
		merge_cells = new Gee.ArrayList<string> ();
		cols = new Gee.ArrayList<Column> ();
		rows = new Gee.ArrayList<Row> ();
	}


	private void grow_rows_if_needed (int needed_row_number) {
		while (rows.size < needed_row_number)
			rows.add (new Row (this));
		stdout.printf ("GROW ROWS.SIZE %d FOR NUMBER %d\n", rows.size, needed_row_number);
	}


	public int row_number (Row row) {
		return rows.index_of (row) + 1;
	}


	public Row get_row (int number) {
		grow_rows_if_needed (number);
		return rows[number - 1];
	}


	public void set_row (int number, Row row) {
		grow_rows_if_needed (number);
		rows[number - 1] = row;
	}


	public void insert_row (int number) {
		grow_rows_if_needed (number);
		rows.insert (number - 1, new Row (this));
	}


	public Cell get_cell (string cell_name) {
		int row_number;
		int cell_number;

		Utils.parse_cell_name (cell_name, out row_number, out cell_number);
		return get_row (row_number).get_cell (cell_number);
	}


	public void put_string (string cell_name, string text) {
		get_cell (cell_name).put_string (text);
	}


	public void put_number (string cell_name, double number) {
		get_cell (cell_name).val = new NumberValue (number);
	}


	public Cell? find_text (string? text) {
		if (text == null)
			return null;

		foreach (var row in rows)
			foreach (var cell in row.cells)
				if (cell.val != null && cell.val is SimpleTextValue)
					if (((SimpleTextValue) cell.val).text == text)
						return cell;

		return null;
	}
}


}
