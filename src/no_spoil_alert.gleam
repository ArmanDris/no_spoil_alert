import envoy
import get_schedule.{get_schedule}
import gleam/bytes_tree
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/result
import gleam/string
import load_environment_variables
import logging
import mist.{type Connection, type ResponseData}
import table_page_html_generator.{generate_table_page}

fn serve_site() {
  let environment = "ENVIRONMENT" |> envoy.get() |> result.unwrap("local")

  let bind_interface = case string.lowercase(environment) {
    "production" -> "0.0.0.0"
    _ -> "localhost"
  }

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
    |> mist.bind(bind_interface)
    |> mist.with_ipv6
    |> mist.port(8000)
    |> mist.start()

  process.sleep_forever()
}

pub fn main() {
  logging.configure()
  logging.set_level(logging.Debug)

  case load_environment_variables.config() {
    Error(dot_env_error) -> {
      echo dot_env_error
      logging.log(logging.Critical, "Error loading environment variables")
    }
    Ok(_) -> Nil
  }

  serve_site()
}
