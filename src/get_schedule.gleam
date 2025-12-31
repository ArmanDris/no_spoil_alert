import envoy
import football_game.{FootballGame, sort_games}
import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json
import gleam/option.{None}
import gleam/result
import gleam/string
import gleam/time/calendar
import gleam/time/timestamp

fn decode_schedule_response(response_body) {
  let quarter_status_decoder = {
    use quarter_string <- decode.then(decode.string)
    case quarter_string {
      "1" -> decode.success(football_game.First)
      "2" -> decode.success(football_game.Second)
      "3" -> decode.success(football_game.Third)
      "4" -> decode.success(football_game.Fourth)
      "Half" -> decode.success(football_game.Half)
      "OT" -> decode.success(football_game.OverTime)
      "F/OT" -> decode.success(football_game.FinalQuarterOverTime)
      _ -> decode.failure(football_game.First, "QuarterStatusEnum")
    }
  }

  let status_decoder = {
    use status_string <- decode.then(decode.string)
    case status_string {
      "Scheduled" -> decode.success(football_game.Scheduled)
      "InProgress" -> decode.success(football_game.InProgess)
      "Final" -> decode.success(football_game.Final)
      "F/OT" -> decode.success(football_game.FinalOverTime)
      "Suspended" -> decode.success(football_game.Suspended)
      "Postponed" -> decode.success(football_game.Postponed)
      "Delayed" -> decode.success(football_game.Delayed)
      "Cancelled" -> decode.success(football_game.Cancelled)
      "Forfeit" -> decode.success(football_game.Forfeit)
      _ -> decode.failure(football_game.Cancelled, "StatusEnum")
    }
  }

  let timestamp_decoder = {
    use timestamp_string <- decode.then(decode.string)

    // Sports data IO returns a rfc3339 timestamp
    // without the "Z" so we append it
    let fixed_timestamp = timestamp_string <> "Z"

    case timestamp.parse_rfc3339(fixed_timestamp) {
      Ok(timestamp) -> decode.success(timestamp)
      Error(Nil) -> {
        decode.failure(
          timestamp.from_unix_seconds(0),
          "Expected an rfc3339 timestamp",
        )
      }
    }
  }

  let football_game_decoder = {
    use game_id <- decode.field("GameID", decode.optional(decode.int))
    use date_time <- decode.field(
      "DateTimeUTC",
      decode.optional(timestamp_decoder),
    )
    use status <- decode.field("Status", decode.optional(status_decoder))
    use home_team <- decode.field("HomeTeam", decode.string)
    use away_team <- decode.field("AwayTeam", decode.string)
    use quarter_status <- decode.optional_field(
      "Quarter",
      None,
      decode.optional(quarter_status_decoder),
    )
    decode.success(FootballGame(
      game_id:,
      date_time:,
      away_team:,
      home_team:,
      status:,
      quarter_status:,
      updated_at: timestamp.system_time(),
    ))
  }

  use parsed_body <- result.try(
    json.parse(response_body, decode.list(football_game_decoder))
    |> result.map_error(fn(json_parse_error) {
      "get_schedule.gleam: Failed to decode the API response. "
      <> string.inspect(json_parse_error)
    }),
  )

  Ok(parsed_body)
}

/// Returns a list of FootballGame records, sorted 
/// by game start time, games with missing start 
/// times are returned at the end.
pub fn get_schedule() {
  let date =
    timestamp.system_time() |> timestamp.to_calendar(calendar.local_offset())

  let environment =
    "ENVIRONMENT"
    |> envoy.get()
    |> result.unwrap("local")
    |> string.lowercase()

  let request_result = case environment {
    "production" -> {
      let year = { date.0 }.year |> int.to_string()

      use sports_data_io_api_key <- result.try(
        "SPORTS_DATA_IO_API_KEY"
        |> envoy.get()
        |> result.map_error(fn(_nil) {
          "missing SPORTS_DATA_IO_API_KEY, cannot query endpoint"
        }),
      )

      "https://api.sportsdata.io/v3/nfl/scores/json/SchedulesBasic/"
      |> request.to()
      |> result.map_error(fn(_nil) { "Failed to construct request record" })
      |> result.map(fn(request) {
        request.set_path(request, "/v3/nfl/scores/json/SchedulesBasic/" <> year)
      })
      |> result.map(fn(request) {
        request.set_query(request, [#("key", sports_data_io_api_key)])
      })
    }
    _ ->
      "http://localhost:4001"
      |> request.to()
      |> result.map_error(fn(_nil) { "failed to construct request record" })
  }

  use request <- result.try(request_result)

  use resp <- result.try(
    httpc.send(request)
    |> result.map_error(fn(httpc_error) {
      "get_schedule.gleam: Failed to query the game schedule endpoint. "
      <> string.inspect(httpc_error)
    })
    |> result.try(fn(response) {
      case response.status >= 200 && response.status <= 299 {
        True -> Ok(response)
        False ->
          Error(
            "get_schedule.gleam: SportsDataIO returned an non ok response: "
            <> int.to_string(response.status)
            <> ", and a body of: "
            <> response.body,
          )
      }
    }),
  )

  use unsorted_games <- result.try(decode_schedule_response(resp.body))

  unsorted_games
  |> sort_games()
  |> Ok()
}
