while true; do
  {
    printf "HTTP/1.1 200 OK\r\n"
    printf "Content-Type: application/json\r\n"
    printf "Connection: close\r\n\r\n"
    cat sports_data_io_response.json
  } | socat TCP-LISTEN:4001,reuseaddr -
done

