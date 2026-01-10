import football_game.{type FootballGame, status_to_string}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/time/calendar
import gleam/time/duration
import gleam/time/timestamp
import logging

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
    let parsed_time =
      fn() {
        let #(date, time) =
          timestamp.to_calendar(row.date_time, duration.hours(-8))
        month_to_string(date.month)
        <> " "
        <> int.to_string(date.day)
        <> ", "
        <> format_time(time)
        <> " PST"
      }()

    let parsed_status = case row.status {
      Some(status) -> status_to_string(status)
      None -> "No Data"
    }

    "<tr>
      <td> <div class='cell-div'> <img src='/assets/" <> row.home_team <> ".png'>" <> row.home_team <> "</div> </td>
      <td> <div class='cell-div'> <img src='/assets/" <> row.away_team <> ".png'>" <> row.away_team <> "</div> </td>
      <td>" <> parsed_time <> "</td>
      <td>" <> parsed_status <> "</td>
    </tr>"
  })
  |> string.concat()
}

pub fn generate_header_html(last_updated) {
  let last_updated = case last_updated {
    Ok(time) -> {
      let minutes_since_last_update =
        time
        |> timestamp.difference(timestamp.system_time())
        |> duration.to_seconds()
        |> float.divide(60.0)
        |> result.unwrap(0.0)
        |> float.truncate()

      let minutes = case minutes_since_last_update {
        1 -> "minute"
        _ -> "minutes"
      }

      "<p>Updated "
      <> int.to_string(minutes_since_last_update)
      <> " "
      <> minutes
      <> " ago</p>"
    }
    Error(error) -> {
      logging.log(
        logging.Critical,
        "Error fetching last updated timestamp: " <> string.inspect(error),
      )

      ""
    }
  }
  "
  <header>
    <img src='assets/nfl_logo.png' />
    <div>
      <h1>No Spoil Alert</h1>
      " <> last_updated <> "
    </div>
  </header>
  "
}

pub fn generate_table_page(
  rows: Result(List(FootballGame), String),
  last_updated: Result(
    timestamp.Timestamp,
    football_game.FetchLastUpdatedResult,
  ),
) {
  let page_header = generate_header_html(last_updated)

  let page_body = case rows {
    Error(error_message) -> {
      io.println_error(error_message)
      "<p>Failed to fetch nfl game schedules</p>"
    }
    Ok(rows) -> " <table>
      <tr>
        <th>Home</th>
        <th>Away</th>
        <th>Kickoff</th>
        <th>Status</th>
      </tr>
      " <> generate_rows_html(rows)
  }

  "<html lang='en'>
    <head>
      <title>nfl schedule</title>
    </head>
    <body>
      " <> page_header <> "
      <main>
      <div>
        " <> page_body <> "
      </div>
      </main>
    </main>
  </html>
  <style>
    * {
      margin: 0;
      padding: 0;
    }
    header {
      border-bottom: 1px solid black;
      width: 100%;
      display: grid;
      grid-template-columns: 1fr 1fr 1fr;
      align-items: center;
      justify-content: center;
      margin-bottom: 64px;
    }
    header img {
      justify-self: start;
      max-height: 60px;
      max-width: 60px;
      margin: 16px;
    }
    header div {
      justify-self: center;
      text-align: center;
    }
    main {
      width: 100%;
      display: flex;
      justify-content: center;
    }
    table {
      width: 800px;
    }
    table, th, td {
      border: 1px solid black;
      font-size: 24px;
    }
    td {
      padding: 8px;
    }
    td img {
      max-height: 60px;
      max-width: 60px;
      margin-right: 8px;
    }
    .cell-div {
      display: flex;
      align-items: center;
      height: 60px;
    }
  </style>"
}
