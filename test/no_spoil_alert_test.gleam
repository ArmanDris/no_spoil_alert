import get_image_bytes.{get_image_bytes}
import gleam/result
import gleeunit
import simplifile

pub fn main() -> Nil {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  let name = "Joe"
  let greeting = "Hello, " <> name <> "!"

  assert greeting == "Hello, Joe!"
}

pub fn is_image_name_allowed_test() {
  assert result.is_ok(get_image_bytes("ARI.png")) == True
  assert result.is_ok(get_image_bytes("nfl_logo.png")) == True
  assert get_image_bytes(".") == Error(simplifile.Eacces)
  assert get_image_bytes("../.env") == Error(simplifile.Eacces)
  assert get_image_bytes("ARIII.png") == Error(simplifile.Eacces)
  assert get_image_bytes("_TEN.png") == Error(simplifile.Eacces)
}
