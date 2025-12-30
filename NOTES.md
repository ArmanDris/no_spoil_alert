### We can query for the game schedule with:

https://api.sportsdata.io/v3/nfl/scores/json/SchedulesBasic/{season}?key={api_key}

Season would be `2025`, maybe we can get the system year and place it there so this works every year?

We can also make it work for the pre and post season using `2025PRE` and `2025POST`, `2025STAR`.

## Caution:

We query the api on every page visit. This is so bad. We should have a database that stores all this, and then we re-query every 1 min or something.
If no game is going on then we should not even re-query at all, unless we havent in like a week, since games may have been updated since then.
