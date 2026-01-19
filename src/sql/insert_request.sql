INSERT INTO requests(
  id,
  received_at,
  method,
  host,
  path,
  query,
  remote_ip,
  request_body,
  headers
)
VALUES (
  $1, -- uuid
  $2, -- timestamp
  $3, -- method
  $4, -- host
  $5, -- path
  $6, -- query
  $7, -- remote_ip
  $8, -- request_body
  $9  -- headers (jsonb)
);
