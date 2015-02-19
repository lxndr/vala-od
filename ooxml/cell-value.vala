namespace OOXML {


public abstract class CellValue : Object {
}


public class NumberValue : CellValue {
	public double val { get; set; default = 0; }


	public NumberValue (double n) {
		Object (val: n);
	}


	public NumberValue.from_string (string s) {
		Object (val: double.parse (s));
	}
}


public abstract class TextValue : CellValue {
	public abstract string to_string ();
}


public class SimpleTextValue : TextValue {
	public string text { get; set; default = ""; }


	public SimpleTextValue (string _text) {
		Object (text: _text);
	}


	public SimpleTextValue.empty () {
		Object ();
	}


	public override string to_string () {
		return text;
	}
}


public class RichTextPiece {
	public string text;
	public string? font;
	public int charset;
	public int family;
	public bool bold;
	public bool italic;
	public bool strike;
	public bool outline;
	public bool shadow;
	public bool condense;
	public bool extend;
	public double size;
	public UnderlineType underline;
}


public class RichTextValue : TextValue {
	public Gee.List<RichTextPiece> pieces;


	public RichTextValue () {
		pieces = new Gee.ArrayList<RichTextPiece> ();
	}


	public override string to_string () {
		var sb = new StringBuilder ();
		foreach (var piece in pieces)
			sb.append (piece.text);
		return sb.str;
	}
}


}
