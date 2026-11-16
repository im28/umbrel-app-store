#!/bin/sh
# Prints a one-time pairing link for this T3 Code server.
#
#   t3-pair-url [base-url] [t3 auth pairing create flags...]
#
# Inside the container the server only knows its Docker address, so the link has to be built
# with the address your devices use. The default is T3_PUBLIC_URL (the Umbrel's LAN address).
# Pass another base URL for the tailnet, for example:
#   t3-pair-url http://umbrel.<tailnet>.ts.net:3773
#
# The link is a password until it is used or expires. Do not paste it into logs.
set -eu
base="${T3_PUBLIC_URL:-http://umbrel.local:3773}"
case "${1:-}" in
  http://* | https://*) base="$1"; shift ;;
esac
exec t3 auth pairing create --base-url "$base" "$@"
