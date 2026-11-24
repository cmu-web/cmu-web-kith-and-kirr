#!/bin/sh
# Builds the docs site (docs/) into docs/_site with a local
# Jekyll & Plaid checkout, for a look before Jekyll & Plaid's next release.
# The Attach Release Files workflow builds it with remote_theme instead.
#
#   dev/site.sh            # then serve docs/_site, e.g., python3 -m http.server -d docs/_site
#   JP=/path/to/cmu-web-jekyll-and-plaid dev/site.sh
set -eu
cd "$(dirname "$0")/.."
JP=${JP:-$PWD/../cmu-web-jekyll-and-plaid}
W=$(mktemp -d)
cp -R docs/. "$W/"
rm -rf "$W/_site"
for d in _layouts _includes assets; do cp -R "$JP/$d" "$W/"; done
sed -i 's/^remote_theme:.*$//' "$W/_config.yml"
(cd "$W" && PAGES_REPO_NWO=cmu-web/cmu-web-kith-and-kirr JEKYLL_GITHUB_TOKEN= \
  BUNDLE_GEMFILE="$JP/docs/Gemfile" BUNDLE_PATH="$JP/vendor/bundle" \
  bundle exec jekyll build -q -d "$PWD/_site")
rm -rf docs/_site && mv "$W/_site" docs/_site && rm -rf "$W"
echo "built docs/_site"
