import get_schedule.{get_schedule}
import gleam/bytes_tree
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/string
import logging
import mist.{type Connection, type ResponseData}
import table_page_html_generator.{generate_table_page}

fn serve_site() {
  logging.configure()
  logging.set_level(logging.Debug)

  let not_found =
    response.new(404)
    |> response.set_body(mist.Bytes(bytes_tree.new()))

  let assert Ok(_) =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      logging.log(
        logging.Info,
        "Got a request from " <> string.inspect(mist.get_client_info(req.body)),
      )

      case request.path_segments(req) {
        [] -> {
          let response_body =
            get_schedule()
            |> generate_table_page()
            |> bytes_tree.from_string()
            |> mist.Bytes()

          response.new(200)
          |> response.prepend_header("Content-Type", "text/html")
          |> response.set_body(response_body)
        }
        _ -> not_found
      }
    }
    |> mist.new
    |> mist.bind("localhost")
    |> mist.with_ipv6
    |> mist.port(4000)
    |> mist.start()

  process.sleep_forever()
}

pub fn main() {
  serve_site()
}
