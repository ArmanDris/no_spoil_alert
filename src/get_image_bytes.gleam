import simplifile.{type FileError, read_bits}

fn is_image_name_allowed(image_name: String) {
  case image_name {
    "ARI.png" -> True
    "CIN.png" -> True
    "HOU.png" -> True
    "LV.png" -> True
    "NYG.png" -> True
    "TEN.png" -> True
    "ATL.png" -> True
    "CLE.png" -> True
    "IND.png" -> True
    "MIA.png" -> True
    "NYJ.png" -> True
    "WAS.png" -> True
    "BAL.png" -> True
    "DAL.png" -> True
    "JAX.png" -> True
    "MIN.png" -> True
    "PHI.png" -> True
    "BUF.png" -> True
    "DEN.png" -> True
    "KC.png" -> True
    "NE.png" -> True
    "PIT.png" -> True
    "CAR.png" -> True
    "DET.png" -> True
    "LAC.png" -> True
    "nfl_logo.png" -> True
    "SF.png" -> True
    "CHI.png" -> True
    "GB.png" -> True
    "LAR.png" -> True
    "NO.png" -> True
    "TB.png" -> True
    _ -> False
  }
}

/// Returns the bytes of a file
/// image_name should include the file extension.
pub fn get_image_bytes(image_name: String) -> Result(BitArray, FileError) {
  case is_image_name_allowed(image_name) {
    True -> read_bits("assets/" <> image_name)
    False -> Error(simplifile.Eacces)
  }
}
