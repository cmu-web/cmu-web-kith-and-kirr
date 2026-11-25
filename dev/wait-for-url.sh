#!/bin/sh
# Waits until an address answers 200 or 302, checking every 3 seconds for up
# to 5 minutes; exits 1 if it never does.
#
#   dev/wait-for-url.sh http://127.0.0.1:5300/grouper/
set -eu
url=$1
for _ in $(seq 1 100); do
  case "$(curl -s -o /dev/null -w '%{http_code}' "$url")" in 200 | 302) exit 0 ;; esac
  sleep 3
done
echo "No answer at $url" >&2
exit 1
