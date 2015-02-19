namespace Archive {


public class Zip : Object {
	private class CentralDirectory : Object {
		public uint16 version;
		public uint16 version_needed;
		public uint16 flags;
		public uint16 compression_method;
		public uint16 mod_time;
		public uint16 mod_date;
		public uint32 crc32;
		public uint32 compressed_size;
		public uint32 uncompressed_size;
		public string fname;
		public string comment;
		public Bytes extra;
		public uint16 disk_number_start;
		public uint16 internal_attrs;
		public uint32 external_attrs;
		public uint32 header_offset;
	}


	private DataInputStream fstm;
	private Gee.List<CentralDirectory> cdir_list;
	private Gee.Map<string, GLib.File> file_list;
	private Gee.Map<string, GLib.File> changed_files;	/* this is changed and new files */


	public Zip () {
		cdir_list = new Gee.ArrayList<CentralDirectory> ();
		file_list = new Gee.HashMap<string, GLib.File> ();
		changed_files  = new Gee.HashMap<string, GLib.File> ();
	}


	public GLib.File extract (string path) throws Error {
		var file = file_list[path];
		if (file != null)
			return file;

		var cdir = find_cdir (path);
		if (cdir == null)
			error ("Could not find file '%s' in zip archive", path);

		fstm.seek (cdir.header_offset, SeekType.SET);

		/* read file header */
		var sig = fstm.read_uint32 ();
		if (sig != 0x04034b50)
			error ("Ain't local header");

		var version = fstm.read_uint16 ();
		if (version != 0x14)
			error ("Unsupported version");

		var general_flags = fstm.read_uint16 ();

		var compression_method = fstm.read_uint16 ();
		if (compression_method != cdir.compression_method)
			error ("compression_method mismatch");

		var mod_file_time = fstm.read_uint16 ();
		if (mod_file_time != cdir.mod_time)
			error ("mod_time mismatch");

		var mod_file_date = fstm.read_uint16 ();
		if (mod_file_date != cdir.mod_date)
			error ("mod_date mismatch");

		var crc32 = fstm.read_uint32 ();
		if (crc32 != cdir.crc32)
			warning ("crc32 mismatch %llx - %llx", crc32, cdir.crc32);

		var compressed_size = fstm.read_uint32 ();
		if (compressed_size != cdir.compressed_size)
			warning ("compressed_size mismatch %ld - %ld", compressed_size, cdir.compressed_size);

		var uncompressed_size = fstm.read_uint32 ();
		if (uncompressed_size != cdir.uncompressed_size)
			warning ("uncompressed_size mismatch %ld - %ld", uncompressed_size, cdir.uncompressed_size);

		var name_length = fstm.read_uint16 ();
		var extra_length = fstm.read_uint16 ();

		var file_name = read_string (fstm, name_length);
		if (file_name != cdir.fname)
			error ("file_name mismatch");

		fstm.skip (extra_length);

		Bytes zdata = fstm.read_bytes (cdir.compressed_size);
		var src_stm = new MemoryInputStream.from_bytes (zdata);

		FileIOStream io;
		file = GLib.File.new_tmp (null, out io);

		var conv = new ZlibDecompressor (ZlibCompressorFormat.RAW);
		var conv_stm = new ConverterOutputStream (io.output_stream, conv);
		conv_stm.splice (src_stm, 0);
		io.close ();

		file_list[path] = file;
		return file;
	}


	public InputStream read_file (string path) throws Error {
		return extract (path).read ();
	}


	public FileIOStream add_from_stream (string path) throws GLib.Error {
		FileIOStream io;
		var tmp = GLib.File.new_tmp (null, out io);
		changed_files[path] = tmp;
		return io;
	}


	private CentralDirectory? find_cdir (string path) {
		foreach (var cdir in cdir_list) {
			if (cdir.fname == path)
				return cdir;
		}
		return null;
	}


	private Bytes compress (GLib.File file, uint16 method,
			out uint32 crc_sum, out uint32 comp_size, out uint32 uncomp_size) throws Error {
		var istm = file.read ();
		var ostm = new MemoryOutputStream.resizable ();

		istm.seek (0, SeekType.END);
		uncomp_size = (uint32) istm.tell ();
		istm.seek (0, SeekType.SET);

		var uncomp_data = istm.read_bytes (uncomp_size);
		var crc = ZLib.Utility.crc32 ();
		crc = ZLib.Utility.crc32 (crc, uncomp_data.get_data ());
		crc_sum = (uint32) crc;
		istm.seek (0, SeekType.SET);

		if (method == 8) {
			var conv = new ZlibCompressor (ZlibCompressorFormat.RAW);
			var conv_stm = new ConverterOutputStream (ostm, conv);
			conv_stm.splice (istm, 0);
		}

		ostm.close ();
		Bytes data = ostm.steal_as_bytes ();
		comp_size = data.length;
		return data;
	}


	private void write_cdir (DataOutputStream stm, CentralDirectory cdir) throws Error {
		stm.put_uint32 (0x02014b50);
		stm.put_uint16 (cdir.version);
		stm.put_uint16 (cdir.version_needed);
		stm.put_uint16 (cdir.flags);
		stm.put_uint16 (cdir.compression_method);
		stm.put_uint16 (cdir.mod_time);
		stm.put_uint16 (cdir.mod_date);
		stm.put_uint32 (cdir.crc32);
		stm.put_uint32 (cdir.compressed_size);
		stm.put_uint32 (cdir.uncompressed_size);
		stm.put_uint16 ((uint16) cdir.fname.length);
		stm.put_uint16 ((uint16) cdir.extra.length);
		stm.put_uint16 ((uint16) cdir.comment.length);
		stm.put_uint16 (cdir.disk_number_start);
		stm.put_uint16 (cdir.internal_attrs);
		stm.put_uint32 (cdir.external_attrs);
		stm.put_uint32 (cdir.header_offset);

		stm.put_string (cdir.fname);
		if (cdir.extra != null && cdir.extra.length > 0)
			stm.write_bytes (cdir.extra);
		stm.put_string (cdir.comment);
	}


	private void write_data_descriptor (CentralDirectory cdir,
			DataOutputStream ostm) throws IOError {
		ostm.put_uint32 (0x08074b50);
		ostm.put_uint32 (cdir.crc32);
		ostm.put_uint32 (cdir.compressed_size);
		ostm.put_uint32 (cdir.uncompressed_size);
	}


	private void write_local_header (DataOutputStream ostm, CentralDirectory cdir,
			Bytes? extra) throws Error {
		bool bit3 = (cdir.flags & (1 << 3)) > 0;

		uint32 crc32 = 0;
		uint32 comp_sz = 0;
		uint32 ucomp_sz = 0;

		if (bit3 == false) {
			crc32 = cdir.crc32;
			comp_sz = cdir.compressed_size;
			ucomp_sz = cdir.uncompressed_size;
		}

		var extra_length = 0;
		if (extra != null)
			extra_length = extra.length;

		ostm.put_uint32 (0x04034b50);
		ostm.put_uint16 (cdir.version_needed);
		ostm.put_uint16 (cdir.flags);
		ostm.put_uint16 (cdir.compression_method);
		ostm.put_uint16 (cdir.mod_time);
		ostm.put_uint16 (cdir.mod_date);
		ostm.put_uint32 (crc32);
		ostm.put_uint32 (comp_sz);
		ostm.put_uint32 (ucomp_sz);
		ostm.put_uint16 ((uint16) cdir.fname.length);
		ostm.put_uint16 ((uint16) extra_length);
		ostm.put_string (cdir.fname);

		if (extra != null && extra.length > 0)
			ostm.write_bytes (extra);
	}


	private void copy_entity (DataOutputStream ostm, CentralDirectory cdir,
			DataInputStream istm) throws Error {
		bool bit3 = (cdir.flags & (1 << 3)) > 0;
		var offset = ostm.tell ();

		/* copy extra field */
		istm.seek (cdir.header_offset + 0x1c, SeekType.SET);
		var extra_length = istm.read_uint16 ();
		istm.skip (cdir.fname.length);
		var extra = read_bytes (istm, extra_length);

		write_local_header (ostm, cdir, extra);

		/* copy data */
		Bytes data = istm.read_bytes (cdir.compressed_size);
		ostm.write_bytes (data);

		/* write data descriptor */
		if (bit3 == true)
			write_data_descriptor (cdir, ostm);

		cdir.header_offset = (uint32) offset;
	}


	private void write_entity (DataOutputStream ostm, CentralDirectory cdir, Bytes data) throws GLib.Error {
		bool bit3 = (cdir.flags & (1 << 3)) > 0;

		var offset = ostm.tell ();

		write_local_header (ostm, cdir, null);
		ostm.write_bytes (data);

		if (bit3 == true)
			write_data_descriptor (cdir, ostm);

		cdir.header_offset = (uint32) offset;
	}


	public void write (File f) throws Error {
		FileIOStream io;
		var tmp = GLib.File.new_tmp (null, out io);
		var stm = new DataOutputStream (io.output_stream);
		stm.byte_order = DataStreamByteOrder.LITTLE_ENDIAN;

		foreach (var cdir in cdir_list) {
			unowned string fname = cdir.fname;

			if (changed_files.has_key (fname) == true) {
				var file = changed_files[fname];
				var data = compress (file, cdir.compression_method, out cdir.crc32,
						out cdir.compressed_size, out cdir.uncompressed_size);
				write_entity (stm, cdir, data);
			} else {
				copy_entity (stm, cdir, fstm);
			}
		}

		var cdir_offset = stm.tell ();

		foreach (var cdir in cdir_list)
			write_cdir (stm, cdir);

		var cdir_size = stm.tell () - cdir_offset;

		/* write end of central directory */
		stm.put_uint32 (0x06054b50);
		stm.put_uint16 (0);
		stm.put_uint16 (0);
		stm.put_uint16 ((uint16) cdir_list.size);
		stm.put_uint16 ((uint16) cdir_list.size);
		stm.put_uint32 ((uint32) cdir_size);
		stm.put_uint32 ((uint32) cdir_offset);
		stm.put_uint16 (0);

		io.close ();
		fstm.close ();
		tmp.move (f, FileCopyFlags.OVERWRITE);
	}


	private string read_string (InputStream stm, size_t length) throws IOError {
		var buf = string.nfill (length, '.');
		stm.read (buf.data);
		return buf;
	}


	/* FIXME this function is a workaround to suppress runtime warning */
	private Bytes read_bytes (InputStream stm, size_t length) throws Error {
		if (length == 0)
			return ByteArray.free_to_bytes (new ByteArray ());
		else
			return stm.read_bytes (length);
	}


	private void read_central_directory (int64 end_offset) throws Error {
		while (fstm.tell () < end_offset) {
			var sig = fstm.read_uint32 ();
			if (sig != 0x02014b50)
				error ("Wrong signature for Central Directory");

			var cdir = new CentralDirectory ();
			cdir.version             = fstm.read_uint16 ();
			cdir.version_needed      = fstm.read_uint16 ();
			cdir.flags               = fstm.read_uint16 ();
			cdir.compression_method  = fstm.read_uint16 ();
			cdir.mod_time            = fstm.read_uint16 ();
			cdir.mod_date            = fstm.read_uint16 ();
			cdir.crc32               = fstm.read_uint32 ();
			cdir.compressed_size     = fstm.read_uint32 ();
			cdir.uncompressed_size   = fstm.read_uint32 ();
			var fname_length         = fstm.read_uint16 ();
			var extra_length         = fstm.read_uint16 ();
			var comment_length       = fstm.read_uint16 ();
			cdir.disk_number_start   = fstm.read_uint16 ();
			cdir.internal_attrs      = fstm.read_uint16 ();
			cdir.external_attrs      = fstm.read_uint32 ();
			cdir.header_offset       = fstm.read_uint32 ();

			cdir.fname               = read_string (fstm, fname_length);
			cdir.extra               = read_bytes (fstm, extra_length);
			cdir.comment             = read_string (fstm, comment_length);

			cdir_list.add (cdir);
		}
	}


	public void open (GLib.File f) throws Error {
		fstm = new DataInputStream (f.read ());
		fstm.byte_order = DataStreamByteOrder.LITTLE_ENDIAN;

		/* reading End of Central Directory */
		/* FIXME: it has to do some searching */
		fstm.seek (-0x16, SeekType.END);
		var sig = fstm.read_uint32 ();
		if (sig != 0x06054b50)
			error ("Could not find End of Central Directory");

		fstm.skip (2); /*  */
		fstm.skip (2); /*  */
		fstm.skip (2); /*  */
		fstm.skip (2); /*  */

		var cdir_size = fstm.read_uint32 ();
		var cdir_offset = fstm.read_uint32 ();

		fstm.seek (cdir_offset, SeekType.SET);
		read_central_directory (cdir_offset + cdir_size);
	}
}


}
