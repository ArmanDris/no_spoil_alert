SELECT *
FROM public.football_games
WHERE start_time >= (
    date_trunc('week', now() AT TIME ZONE 'America/Los_Angeles')
    AT TIME ZONE 'America/Los_Angeles'
)
ORDER BY start_time ASC;
