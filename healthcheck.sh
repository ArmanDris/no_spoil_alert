#!/bin/sh
#
# This script is run periodically by the Podman container engine to check if
# the application is healthy. If the application instance is determined to be
# unhealthy then Podman will terminate the container, causing systemd to
# replace it with a new instance.
#
# If this script returns exit code 0 then the check is a pass.
# Any other exit code is a failure, with multiple failures in a row meaning the
# instance is unhealthy.
#

exec wget --spider --quiet 'http://localhost:8000'
