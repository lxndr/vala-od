namespace OD {


public struct ZipEntity {
	string name;
	uint16 compression_method;
	uint32 compressed_size;
	uint32 uncompressed_size;
	int64 offset;
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
			stream.skip (2); /* flags */
			entity.compression_method = stream.read_uint16 ();
			stream.skip (8); /* mod time, mod date, crc32 */
			entity.compressed_size = stream.read_uint32 ();
			entity.uncompressed_size = stream.read_uint32 ();
			var file_name_length = stream.read_uint16 ();
			var extra_length = stream.read_uint16 ();
			var comment_length = stream.read_uint16 ();
			stream.skip (8); /* disk number start, internat attrs, externat attrs */
			entity.offset = stream.read_uint32 ();
			entity.name = read_string (stream, file_name_length);
			stream.skip (extra_length);
			stream.skip (comment_length);
			entity_list.add (entity);
		}

		/* skip entity headers */
		foreach (var entity in entity_list) {
			stream.seek (entity.offset, SeekType.SET);

			signature = stream.read_uint32 ();
			if (signature != 0x04034b50)
				throw new DocumentError.ZIP ("Wrong local header signature");

			var version = stream.read_uint16 ();
			if (version != 0x14)
				throw new DocumentError.ZIP ("Unsupported local header version");
			stream.skip (2); /* flags */
			if (stream.read_uint16 () != entity.compression_method)
				throw new DocumentError.ZIP ("Compression method mismatch between local header and central directory");
			stream.skip (8);
			if (stream.read_uint32 () != entity.compressed_size)
				throw new DocumentError.ZIP ("Compressed size mismatch between local header and central directory");
			if (stream.read_uint32 () != entity.uncompressed_size)
				throw new DocumentError.ZIP ("Uncompressed size mismatch between local header and central directory");
			var name_length = stream.read_uint16 ();
			var extra_length = stream.read_uint16 ();
			if (read_string (stream, name_length) != entity.name)
				throw new DocumentError.ZIP ("File name mismatch between local header and central directory");
			stream.skip (extra_length);
			entity.offset = stream.tell ();
		}
	}


	public Gee.List<string> file_list () {
		var list = new Gee.ArrayList<string> ();
		foreach (var entity in entity_list)
			list.add (entity.name);
		return list;
	}


	private string read_string (InputStream stm, size_t length) throws IOError {
		var buf = string.nfill (length, '.');
		stm.read (buf.data);
		return buf;
	}


	public InputStream? open_file (string path) throws Error {
		var entity = find_entity (path);
		if (entity == null)
			return null;

		stream.seek (entity.offset, SeekType.SET);
		return new ConverterInputStream (stream,
				new ZlibDecompressor (ZlibCompressorFormat.RAW));
	}


	private ZipEntity? find_entity (string name) {
		foreach (var entity in entity_list)
			if (entity.name == name)
				return entity;
		return null;
	}
}


}
