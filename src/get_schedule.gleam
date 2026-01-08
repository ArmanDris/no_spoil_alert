import envoy
import football_game.{
  type QuarterStatus, type Status, FootballGame,
  fetch_this_weeks_football_games_from_database, upsert_games_to_database,
}
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/float
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/time/calendar
import gleam/time/duration
import gleam/time/timestamp
import logging
import pog
import sql

/// SportsDataIO returns games that have a null
/// GameID. So this is the type we decode into
/// before finally creating games of type
/// FootballGame.
type ExternalFootballGame {
  ExternalFootballGame(
    game_id: Option(Int),
    date_time: Option(timestamp.Timestamp),
    away_team: String,
    home_team: String,
    status: Option(Status),
    quarter_status: Option(QuarterStatus),
    updated_at: timestamp.Timestamp,
  )
}

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
      "InProgress" -> decode.success(football_game.InProgress)
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
    decode.success(ExternalFootballGame(
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

/// Takes football games of type ExternalFootballGame
/// and converts it to our type FootballGame
fn convert_to_internal_football_games(
  external_games: List(ExternalFootballGame),
) {
  list.fold(external_games, [], fn(accumulator, external_game) {
    let football_game = case external_game.game_id, external_game.date_time {
      Some(game_id), Some(date_time) ->
        Some(FootballGame(
          game_id:,
          date_time:,
          away_team: external_game.away_team,
          home_team: external_game.home_team,
          status: external_game.status,
          quarter_status: external_game.quarter_status,
          updated_at: external_game.updated_at,
        ))
      _, _ -> None
    }

    case football_game {
      None -> accumulator
      Some(football_game) -> list.prepend(accumulator, football_game)
    }
  })
}

/// Returns True if our data is stale enough to warrant requerying SportsDataIO
/// We consider our data stale if it is more than 1 hour old.
fn is_football_game_data_stale(
  database_connection_name: process.Name(pog.Message),
) {
  let database_connection = pog.named_connection(database_connection_name)

  use last_query_time <- result.try(
    sql.get_last_update_timestamp(database_connection)
    |> result.map_error(fn(query_error) {
      "Error querying last updated at time " <> string.inspect(query_error)
    }),
  )

  let seconds_since_last_query = case last_query_time.rows {
    [last_query_time] -> {
      timestamp.difference(
        last_query_time.oldest_updated_at,
        timestamp.system_time(),
      )
      |> duration.to_seconds()
      |> Some()
    }
    _ -> None
  }

  let hours_since_last_query = case seconds_since_last_query {
    None -> None
    Some(seconds) ->
      seconds
      |> float.divide(60.0)
      |> result.unwrap(0.0)
      |> float.divide(60.0)
      |> result.unwrap(0.0)
      |> float.truncate()
      |> Some()
  }

  logging.log(
    logging.Debug,
    "Fetched a last query time from the database of: "
      <> string.inspect(last_query_time.rows)
      <> ". Computed that it has been "
      <> string.inspect(seconds_since_last_query)
      <> " seconds since the last query. Which is "
      <> string.inspect(hours_since_last_query)
      <> " hours.",
  )

  case hours_since_last_query {
    None -> True
    Some(hours_since_last_query) -> hours_since_last_query >= 1
  }
  |> Ok()
}

fn refresh_football_game_data(
  database_connection_name: process.Name(pog.Message),
) {
  let environment =
    "ENVIRONMENT"
    |> envoy.get()
    |> result.unwrap("local")
    |> string.lowercase()

  let request_result = case environment {
    "production" -> {
      let date =
        timestamp.system_time()
        |> timestamp.to_calendar(calendar.local_offset())

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
        request.set_path(
          request,
          "/v3/nfl/scores/json/SchedulesBasic/" <> year <> "POST",
        )
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

  use unsorted_external_games <- result.try(decode_schedule_response(resp.body))

  unsorted_external_games
  |> convert_to_internal_football_games()
  |> upsert_games_to_database(database_connection_name)
  |> Ok()
}

/// Returns a list of FootballGame records, sorted 
/// by game start time, games with missing start 
/// times are returned at the end.
pub fn get_schedule(database_connection_name: process.Name(pog.Message)) {
  let refresh_result = case
    is_football_game_data_stale(database_connection_name)
  {
    Ok(True) -> refresh_football_game_data(database_connection_name)
    Ok(False) -> Ok(Nil)
    Error(error) -> Error(error)
  }

  case refresh_result {
    Ok(_nil) -> Nil
    Error(refresh_error) ->
      logging.log(
        logging.Critical,
        "FAILED TO REFRESH DATABASE: " <> refresh_error,
      )
  }

  fetch_this_weeks_football_games_from_database(database_connection_name)
}
