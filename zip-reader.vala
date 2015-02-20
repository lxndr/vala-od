namespace OD {


public ZipReader : Reader {


	public override void open (File file) {
		FileInputStream stm;
		var archive = new Archive.Read ();
		archive.support_zip ();
		archive.open2 (
			/* open */
			(_archive) => {
				stm = file.read ();
			},
			/* read */
			(_archive, buffer) => {
				
			},
			/* skip */
			(_archive, off_t request) => {
				stm.seek (SeekType.CUR, request);
			},
			/* close */
			(_archive) => {
				stm.close ();
			});

		archive.close ();
	}


	
}


}
