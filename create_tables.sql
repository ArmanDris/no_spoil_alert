DROP TABLE football_games;

CREATE TABLE public.football_games (
  game_id        BIGINT PRIMARY KEY,
  home_team      TEXT NOT NULL,
  away_team      TEXT NOT NULL,
  start_time     TIMESTAMP NOT NULL,
  game_status    TEXT,
  quarter_status TEXT,
  updated_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE requests;

CREATE TABLE public.requests (
  id           UUID PRIMARY KEY,
  received_at  TIMESTAMP NOT NULL,
  method       TEXT NOT NULL,
  host         TEXT NOT NULL,
  path         TEXT NOT NULL,
  query        TEXT NOT NULL,
  remote_ip    TEXT NOT NULL,
  request_body TEXT NOT NULL,
  headers      JSONB NOT NULL
);
