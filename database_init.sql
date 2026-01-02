-- Adminer 4.17.1 PostgreSQL 16.11 dump

\connect "no_spoil_alert";

CREATE TABLE "public"."football_games" (
    "game_id" integer NOT NULL,
    "home_team" text NOT NULL,
    "away_team" text NOT NULL,
    "start_time" timestamp NOT NULL,
    "game_status" integer,
    "quarter_status" integer,
    "updated_at" timestamp DEFAULT now() NOT NULL,
    CONSTRAINT "football_games_pkey" PRIMARY KEY ("game_id")
) WITH (oids = false);


-- 2025-12-31 23:20:32.577463+00
