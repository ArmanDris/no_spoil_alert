import gleam/bit_array
import gleam/erlang/process
import gleam/http
import gleam/http/request.{type Request}
import gleam/option
import gleam/result
import gleam/string
import gleam/time/timestamp
import logging
import mist.{type Connection}
import pog
import sql
import youid/uuid

pub fn insert_request(
  req: Request(Connection),
  database_connection_name: process.Name(pog.Message),
) {
  let database_connection = pog.named_connection(database_connection_name)

  let request_body = case mist.read_body(req, 4000) {
    Error(_read_error) -> {
      logging.log(
        logging.Critical,
        "Could not log request body because of an erro reading the request body",
      )
      ""
    }
    Ok(bit_array_request) -> bit_array_request.body |> bit_array.inspect()
  }

  sql.insert_request(
    database_connection,
    uuid.v4(),
    timestamp.system_time(),
    http.method_to_string(req.method),
    req.host,
    req.path,
    option.unwrap(req.query, ""),
    string.inspect(mist.get_client_info(req.body)),
    request_body,
  )
  |> result.map_error(fn(error) {
    logging.log(
      logging.Critical,
      "Could not log request. Got query error: " <> string.inspect(error),
    )
    error
  })
}
