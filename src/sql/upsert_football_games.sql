INSERT INTO public.football_games (
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
