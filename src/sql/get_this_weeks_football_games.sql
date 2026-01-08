SELECT *
FROM public.football_games
WHERE start_time >= date_trunc('week', now() AT TIME ZONE 'UTC')
ORDER BY start_time ASC;
