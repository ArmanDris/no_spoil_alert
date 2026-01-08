import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/time/calendar
import gleam/time/timestamp
import pog
import sql.{upsert_football_games}

pub type Status {
  Scheduled
  InProgress
  Final
  FinalOverTime
  Suspended
  Postponed
  Delayed
  Cancelled
  Forfeit
}

pub type QuarterStatus {
  First
  Second
  Third
  Fourth
  Half
  OverTime
  FinalQuarterOverTime
}

pub type FootballGame {
  FootballGame(
    game_id: Int,
    date_time: timestamp.Timestamp,
    away_team: String,
    home_team: String,
    status: Option(Status),
    quarter_status: Option(QuarterStatus),
    updated_at: timestamp.Timestamp,
  )
}

pub fn status_to_string(status: Status) {
  case status {
    Scheduled -> "Scheduled"
    InProgress -> "In Progress"
    Final -> "Final"
    FinalOverTime -> "Final (OT)"
    Suspended -> "Suspended"
    Postponed -> "Postponed"
    Delayed -> "Delayed"
    Cancelled -> "Cancelled"
    Forfeit -> "Forfeit"
  }
}

pub fn quarter_status_to_string(quarter_status: QuarterStatus) {
  case quarter_status {
    First -> "1st"
    Second -> "2nd"
    Third -> "3rd"
    Fourth -> "4th"
    Half -> "Half"
    OverTime -> "Overtime"
    FinalQuarterOverTime -> "Overtime"
  }
}

pub fn sort_games(games: List(FootballGame)) {
  list.sort(games, fn(game_one, game_two) {
    timestamp.compare(game_one.updated_at, game_two.updated_at)
  })
}

/// Filters out any games that do not happen on the
/// current day.
pub fn filter_games_today(games: List(FootballGame)) {
  list.filter(games, fn(game) {
    let #(current_date, _time) =
      timestamp.system_time()
      |> timestamp.to_calendar(calendar.local_offset())

    let #(game_date, _time) =
      timestamp.to_calendar(game.date_time, calendar.local_offset())

    int.absolute_value(current_date.day - game_date.day) == 0
    && current_date.month == game_date.month
    && current_date.year == game_date.year
  })
}

fn map_status_to_db_type(status: Option(Status)) {
  case status {
    Some(Scheduled) -> "Scheduled"
    Some(InProgress) -> "InProgress"
    Some(Final) -> "Final"
    Some(FinalOverTime) -> "FinalOverTime"
    Some(Suspended) -> "Suspended"
    Some(Postponed) -> "Postponed"
    Some(Delayed) -> "Delayed"
    Some(Cancelled) -> "Cancelled"
    Some(Forfeit) -> "Forfeit"
    None -> "None"
  }
}

pub fn map_status_from_db_type(db_status_text: String) {
  case db_status_text {
    "Scheduled" -> Some(Scheduled)
    "InProgress" -> Some(InProgress)
    "Final" -> Some(Final)
    "FinalOverTime" -> Some(FinalOverTime)
    "Suspended" -> Some(Suspended)
    "Postponed" -> Some(Postponed)
    "Delayed" -> Some(Delayed)
    "Cancelled" -> Some(Cancelled)
    "Forfeit" -> Some(Forfeit)
    "None" -> None
    _ -> None
  }
}

fn map_quarter_status_to_db_type(status: Option(QuarterStatus)) {
  case status {
    Some(First) -> "First"
    Some(Second) -> "Second"
    Some(Third) -> "Third"
    Some(Fourth) -> "Fourth"
    Some(Half) -> "Half"
    Some(OverTime) -> "OverTime"
    Some(FinalQuarterOverTime) -> "FinalQuarterOverTime"
    None -> "None"
  }
}

pub fn map_quarter_status_from_db_type(status: String) {
  case status {
    "First" -> Some(First)
    "Second" -> Some(Second)
    "Third" -> Some(Third)
    "Fourth" -> Some(Fourth)
    "Half" -> Some(Half)
    "OverTime" -> Some(OverTime)
    "FinalQuarterOverTime" -> Some(FinalQuarterOverTime)
    "None" -> None
    _ -> None
  }
}

/// Upserts a list of FootballGame to the database,
/// updating games that have the same game_id, and
/// inserting if the game_id does not exist. Returns
/// the original set of games.
pub fn upsert_games_to_database(
  games: List(FootballGame),
  database_connection_name: process.Name(pog.Message),
) {
  let database_connection = pog.named_connection(database_connection_name)

  list.each(games, fn(game) {
    upsert_football_games(
      database_connection,
      game.game_id,
      game.home_team,
      game.away_team,
      game.date_time,
      map_status_to_db_type(game.status),
      map_quarter_status_to_db_type(game.quarter_status),
    )
  })
}

fn database_game_to_internal_game(
  database_games: List(sql.GetThisWeeksFootballGamesRow),
) {
  list.map(database_games, fn(database_game) {
    FootballGame(
      game_id: database_game.game_id,
      home_team: database_game.home_team,
      away_team: database_game.away_team,
      date_time: database_game.start_time,
      status: database_game.game_status
        |> option.unwrap("")
        |> map_status_from_db_type(),
      quarter_status: database_game.quarter_status
        |> option.unwrap("")
        |> map_quarter_status_from_db_type(),
      updated_at: database_game.updated_at,
    )
  })
}

pub fn fetch_this_weeks_football_games_from_database(
  database_connection_name: process.Name(pog.Message),
) {
  let database_connection = pog.named_connection(database_connection_name)

  use games_query_result <- result.try(
    sql.get_this_weeks_football_games(database_connection)
    |> result.map_error(fn(query_error) {
      "Error while trying to fetch games from database"
      <> string.inspect(query_error)
    }),
  )

  games_query_result.rows
  |> database_game_to_internal_game()
  |> Ok()
}
