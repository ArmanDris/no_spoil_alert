import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/time/calendar
import gleam/time/timestamp

pub type Status {
  Scheduled
  InProgess
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
    InProgess -> "In Progress"
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
