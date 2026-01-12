//// This module contains the code to run the sql queries defined in
//// `./src/sql`.
//// > 🐿️ This module was generated automatically using v4.6.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import pog

/// A row you get from running the `get_football_games` query
/// defined in `./src/sql/get_football_games.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetFootballGamesRow {
  GetFootballGamesRow(
    game_id: Int,
    home_team: String,
    away_team: String,
    start_time: Timestamp,
    game_status: Option(String),
    quarter_status: Option(String),
    updated_at: Timestamp,
  )
}

/// Runs the `get_football_games` query
/// defined in `./src/sql/get_football_games.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_football_games(
  db: pog.Connection,
) -> Result(pog.Returned(GetFootballGamesRow), pog.QueryError) {
  let decoder = {
    use game_id <- decode.field(0, decode.int)
    use home_team <- decode.field(1, decode.string)
    use away_team <- decode.field(2, decode.string)
    use start_time <- decode.field(3, pog.timestamp_decoder())
    use game_status <- decode.field(4, decode.optional(decode.string))
    use quarter_status <- decode.field(5, decode.optional(decode.string))
    use updated_at <- decode.field(6, pog.timestamp_decoder())
    decode.success(GetFootballGamesRow(
      game_id:,
      home_team:,
      away_team:,
      start_time:,
      game_status:,
      quarter_status:,
      updated_at:,
    ))
  }

  "SELECT *
FROM football_games
ORDER BY start_time ASC;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_last_update_timestamp` query
/// defined in `./src/sql/get_last_update_timestamp.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetLastUpdateTimestampRow {
  GetLastUpdateTimestampRow(newest_updated_at: Timestamp)
}

/// Runs the `get_last_update_timestamp` query
/// defined in `./src/sql/get_last_update_timestamp.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_last_update_timestamp(
  db: pog.Connection,
) -> Result(pog.Returned(GetLastUpdateTimestampRow), pog.QueryError) {
  let decoder = {
    use newest_updated_at <- decode.field(0, pog.timestamp_decoder())
    decode.success(GetLastUpdateTimestampRow(newest_updated_at:))
  }

  "SELECT MAX(updated_at) AS newest_updated_at
FROM public.football_games;

"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_this_weeks_football_games` query
/// defined in `./src/sql/get_this_weeks_football_games.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetThisWeeksFootballGamesRow {
  GetThisWeeksFootballGamesRow(
    game_id: Int,
    home_team: String,
    away_team: String,
    start_time: Timestamp,
    game_status: Option(String),
    quarter_status: Option(String),
    updated_at: Timestamp,
  )
}

/// Runs the `get_this_weeks_football_games` query
/// defined in `./src/sql/get_this_weeks_football_games.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_this_weeks_football_games(
  db: pog.Connection,
) -> Result(pog.Returned(GetThisWeeksFootballGamesRow), pog.QueryError) {
  let decoder = {
    use game_id <- decode.field(0, decode.int)
    use home_team <- decode.field(1, decode.string)
    use away_team <- decode.field(2, decode.string)
    use start_time <- decode.field(3, pog.timestamp_decoder())
    use game_status <- decode.field(4, decode.optional(decode.string))
    use quarter_status <- decode.field(5, decode.optional(decode.string))
    use updated_at <- decode.field(6, pog.timestamp_decoder())
    decode.success(GetThisWeeksFootballGamesRow(
      game_id:,
      home_team:,
      away_team:,
      start_time:,
      game_status:,
      quarter_status:,
      updated_at:,
    ))
  }

  "SELECT *
FROM public.football_games
WHERE start_time >= (
    date_trunc('week', now() AT TIME ZONE 'America/Los_Angeles')
    AT TIME ZONE 'America/Los_Angeles'
)
ORDER BY start_time ASC;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `upsert_football_games` query
/// defined in `./src/sql/upsert_football_games.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn upsert_football_games(
  db: pog.Connection,
  arg_1: Int,
  arg_2: String,
  arg_3: String,
  arg_4: Timestamp,
  arg_5: String,
  arg_6: String,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "INSERT INTO public.football_games (
  game_id,
  home_team,
  away_team,
  start_time,
  game_status,
  quarter_status
)
VALUES ($1, $2, $3, $4, $5, $6)
ON CONFLICT (game_id)
DO UPDATE SET
  home_team      = EXCLUDED.home_team,
  away_team      = EXCLUDED.away_team,
  start_time     = EXCLUDED.start_time,
  game_status    = EXCLUDED.game_status,
  quarter_status = EXCLUDED.quarter_status,
  updated_at     = DEFAULT;
"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.timestamp(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.text(arg_6))
  |> pog.returning(decoder)
  |> pog.execute(db)
}
