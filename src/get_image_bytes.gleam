import simplifile.{type FileError, read_bits}

/// Returns the bytes of a file
/// image_name should include the file extension.
pub fn get_image_bytes(image_name: String) -> Result(BitArray, FileError) {
  read_bits("assets/" <> image_name)
}
