SELECT *
FROM public.football_games
WHERE start_time >= (now() - interval '6 hours');
