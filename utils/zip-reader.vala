namespace OD {


public struct ZipEntity {
	string file_name;
	uint16 compression_method;
	uint32 compressed_size;
	uint32 uncompressed_size;
	uint32 header_offset;
}


[Compact]
public class ZipReader {
	public DataInputStream stream;
	public Gee.List<ZipEntity?> entity_list;


	public ZipReader (File file) throws Error {
		entity_list = new Gee.ArrayList<ZipEntity?> ();

		stream = new DataInputStream (file.read ());
		stream.byte_order = DataStreamByteOrder.LITTLE_ENDIAN;

		/* find the end of central directory */
		uint32 signature = 0;
		int64 offset = -21;
		do {
			offset--;
			stream.seek (offset, SeekType.END);
			signature = stream.read_uint32 ();
		} while (signature != 0x06054b50);

		/* read the end of central directory */
		stream.skip (8);
		var cdir_size = stream.read_uint32 ();
		var cdir_offset = stream.read_uint32 ();

		/* read central directory */
		var end_offset = cdir_offset + cdir_size;
		stream.seek (cdir_offset, SeekType.SET);

		while (stream.tell () < end_offset) {
			signature = stream.read_uint32 ();
			if (signature != 0x02014b50)
				throw new DocumentError.ZIP ("Wrong signature for central directory");

			var entity = ZipEntity ();
			stream.skip (4); /* version, version_needed */
			var flags = stream.read_uint16 ();
			entity.compression_method = stream.read_uint16 ();
			stream.skip (8); /* mod time, mod date, crc32 */
			entity.compressed_size = stream.read_uint32 ();
			entity.uncompressed_size = stream.read_uint32 ();
			var file_name_length = stream.read_uint16 ();
			var extra_length = stream.read_uint16 ();
			var comment_length = stream.read_uint16 ();
			stream.skip (8); /* disk number start, internat attrs, externat attrs */
			entity.header_offset = stream.read_uint32 ();
			entity.file_name = read_string (stream, file_name_length);
			stream.skip (extra_length);
			stream.skip (extra_length);
			entity_list.add (entity);
		}
	}


	private string read_string (InputStream stm, size_t length) throws IOError {
		var buf = string.nfill (length, '.');
		stm.read (buf.data);
		return buf;
	}
}


}
