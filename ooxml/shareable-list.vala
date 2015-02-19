namespace OOXML {


public class ShareableList<T> : Gee.ArrayList<T> {
	public ShareableList (owned Gee.EqualDataFunc<T>? _equal_func) {
		base (_equal_func);
	}


	public int try_add (T item) {
		var idx = index_of (item);
		if (idx > -1)
			return idx;

		base.add (item);
		return size - 1;
	}


	public static ShareableList<TextValue> new_for_text () {
		return new ShareableList<TextValue> ((a, b) => {
			var a_type = a.get_type ();

			if (a_type != b.get_type ())
				return false;

			if (a_type ==typeof (SimpleTextValue)) {
				unowned SimpleTextValue sa = (SimpleTextValue) a;
				unowned SimpleTextValue sb = (SimpleTextValue) b;
				return sa.text == sb.text;
			}

			unowned RichTextValue ra = (RichTextValue) a;
			unowned RichTextValue rb = (RichTextValue) b;

			if (ra.pieces.size != rb.pieces.size)
				return false;

			return false;
		});
	}
}


}
