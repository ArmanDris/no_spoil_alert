import football_game.{
  type FootballGame, quarter_status_to_string, status_to_string,
}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleam/time/calendar
import gleam/time/timestamp

fn month_to_string(month) {
  case month {
    calendar.January -> "Jan"
    calendar.February -> "Feb"
    calendar.March -> "Mar"
    calendar.April -> "Apr"
    calendar.May -> "May"
    calendar.June -> "Jun"
    calendar.July -> "Jul"
    calendar.August -> "Aug"
    calendar.September -> "Sep"
    calendar.October -> "Oct"
    calendar.November -> "Nov"
    calendar.December -> "Dec"
  }
}

fn format_time(time: calendar.TimeOfDay) {
  let formatted_minutes = case time.minutes < 10 {
    True -> string.append("0", int.to_string(time.minutes))
    False -> int.to_string(time.minutes)
  }

  case time.hours <= 12 {
    True -> {
      case time.hours == 0 {
        True -> int.to_string(12) <> ":" <> formatted_minutes <> " AM"
        False -> int.to_string(time.hours) <> ":" <> formatted_minutes <> " AM"
      }
    }
    False -> int.to_string(time.hours - 12) <> ":" <> formatted_minutes <> " PM"
  }
}

fn generate_rows_html(rows: List(FootballGame)) {
  rows
  |> list.map(fn(row) {
    let parsed_game_id =
      row.game_id |> option.map(int.to_string) |> option.unwrap("No Data")

    let parsed_time = case row.date_time {
      None -> "No data"
      Some(time) -> {
        let #(date, time) = timestamp.to_calendar(time, calendar.utc_offset)
        case row.game_id == Some(19_039) {
          True -> {
            echo time
            Nil
          }
          False -> Nil
        }
        month_to_string(date.month)
        <> " "
        <> int.to_string(date.day)
        <> ", "
        <> format_time(time)
        <> " UTC"
      }
    }

    let parsed_status = case row.status {
      Some(status) -> status_to_string(status)
      None -> "No Data"
    }

    let parsed_quarter_status = case row.quarter_status {
      Some(quarter_status) -> quarter_status_to_string(quarter_status)
      None -> "No Data"
    }

    "<tr>
      <td>" <> parsed_game_id <> "</td>
      <td>" <> row.home_team <> "</td>
      <td>" <> row.away_team <> "</td>
      <td>" <> parsed_time <> "</td>
      <td>" <> parsed_status <> "
      <td>" <> parsed_quarter_status <> "</td>
      <td>" <> timestamp.to_rfc3339(row.updated_at, calendar.utc_offset) <> "</td>
    </tr>"
  })
  |> string.concat()
}

pub fn generate_table_page(rows: Result(List(FootballGame), String)) {
  let page_body = case rows {
    Error(error_message) -> {
      io.println_error(error_message)
      "<p>Failed to fetch nfl game schedules</p>"
    }
    Ok(rows) -> " <table>
      <tr>
        <th>Game ID</th>
        <th>Home Team</th>
        <th>Away Team</th>
        <th>Start Time</th>
        <th>Game Status</th>
        <th>Quarter Status</th>
        <th>Updated At</th>
      </tr>
      " <> generate_rows_html(rows)
  }

  "<html lang='en'
    <head>
      <title>nfl schedule</title>
    </head>
    <body>
    " <> page_body <> "
    </body>
  </html>
  <style>
    table, th, td {
      border: 1px solid black;
    }
  </style>"
}
