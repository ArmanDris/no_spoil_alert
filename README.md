# no_spoil_alert

NFL Schedule without the spoilers

## Development

1. Run dev PostgreSQL and adminer with: `docker compose -f client_compose.yml up`

2. Run app with `gleam run`

Changes will update live at `localhost:8000`


## Tests

Run with `gleam test`

## Production

Changes are autodeployed to production.
