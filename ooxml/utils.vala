namespace OOXML {

namespace Utils {


public int pow_integer (int n, int p) {
	int v = 1;
	for (int i = 0; i < p; i++)
		v *= n;
	return v;
}


public void parse_cell_name (string name, out int row_number, out int cell_number) {
	try {
		var re = new Regex ("([A-Z]+)([0-9]+)");
		var tokens = re.split (name);

		/* x coord */
		unowned string s = tokens[1];
		var s_len = s.length;
		cell_number = 0;
		for (var i = 0; i < s_len; i++) {
			var d = s[i] - 0x40; /* one 'digit' */
			var p = s_len - i - 1;
			cell_number += pow_integer (26, p) * d;
		}

		/* y coord */
		row_number = (int) int64.parse (tokens[2]);
	} catch (RegexError e) {
		error ("Regex error in 'parse_cell_name': %s", e.message);
	}
}


public string format_cell_name (int row_number, int cell_number) {
	/* TODO */
	string cell = "";
//	if (cell_number > (26 * 26))
//		cell += "%c".printf ((uint8) (cell_number / (26 * 26)) + 0x40);

	cell_number--;
	if (cell_number >= 26)
		cell += "%c".printf ((uint8) (cell_number / 26) + 0x40);
	cell += "%c".printf ((uint8) (cell_number % 26) + 0x41);

	return cell + row_number.to_string ();
}


public int parse_int (string? s) {
	if (s == null)
		return 0;
	return int.parse (s);
}


public bool parse_bool (string? s) {
	return s != null && (s == "true" || s == "1");
}


public double parse_double (string? s) {
	if (s == null)
		return 0;
	return double.parse (s);
}


public unowned string format_bool (bool b) {
	if (b == true)
		return "1";
	else
		return "0";
}


public string format_double (double d) {
	char[] buf = new char[double.DTOSTR_BUF_SIZE];
	return d.to_str (buf);
}


public string fix_line_ending (string s) {
	return s.replace ("\n", "\r\n");
}


}

}
