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
import not_found_page_html_generator.{not_found_page_html_generator}
import pog
import table_page_html_generator.{generate_table_page}

fn serve_site(db_pool_name: process.Name(pog.Message)) {
  let environment =
    "ENVIRONMENT"
    |> envoy.get()
    |> result.unwrap("COULD NOT FIND ENVIRONMENT ENV VARIABLE")
    |> string.lowercase()

  let bind_interface = case environment {
    "production" -> "0.0.0.0"
    _ -> "localhost"
  }

  let assert Ok(_) =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      logging.log(
        logging.Info,
        "Got a request from " <> string.inspect(mist.get_client_info(req.body)),
      )

      case request.path_segments(req) {
        [] -> {
          let response_body =
            get_schedule(db_pool_name)
            |> generate_table_page()
            |> bytes_tree.from_string()
            |> mist.Bytes()

          response.new(200)
          |> response.prepend_header("Content-Type", "text/html")
          |> response.set_body(response_body)
        }
        _ -> {
          let response_body =
            not_found_page_html_generator()
            |> bytes_tree.from_string()
            |> mist.Bytes()

          response.new(404)
          |> response.prepend_header("Content-Type", "text/html")
          |> response.set_body(response_body)
        }
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
      logging.log(
        logging.Critical,
        "Error loading environment variables:" <> string.inspect(dot_env_error),
      )
    }
    Ok(_) -> Nil
  }

  let environment =
    "ENVIRONMENT"
    |> envoy.get()
    |> result.unwrap("COULD NOT FIND ENVIRONMENT ENV VARIABLE")
    |> string.lowercase()

  let database_url =
    case environment {
      "production" -> "PRODUCTION_DATABASE_URL"
      _ -> "LOCAL_DATABASE_URL"
    }
    |> envoy.get()
    |> result.unwrap("COULD NOT FIND PRODUCTION DATABASE URL")

  let db_pool_name = process.new_name("db_pool")
  let assert Ok(pog_config) = pog.url_config(db_pool_name, database_url)
  let assert Ok(_) =
    pog_config
    |> pog.pool_size(10)
    |> pog.start

  serve_site(db_pool_name)
}
