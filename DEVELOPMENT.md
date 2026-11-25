# Development

Set up your computer once with
[Working on CMU Web Projects](https://github.com/cmu-web/.github/blob/main/DEVELOPMENT.md);
this page covers this project's own commands.

Kith & Kirr is a stylesheet, a header file and settings for Grouper's web
UI, built with a Node script. The development Grouper runs in Docker or
Podman.

## Build It

- `src/` is the source: `kith-and-kirr.css`, `customHeader.jsp`, the fonts
  and wordmark in `src/assets/`, and the settings lines in `src/properties/`.
  The logo and favicons are in `images/`.
- `make setup` once, then `make build` writes `grouper/`, the folder a Grouper
  admin copies from, with the Web Kilt's `cmu-cms.css` from the pinned Kilt
  (`@cmu-web/kilt` in `package.json`). Commit `src/` and `grouper/` together.
- A new Kilt is an npm upgrade (Dependabot proposes each release) and a
  rebuild.

## Run It

`make run` runs Grouper 7.9.1 with the theme, Postgres and nginx, then loads
the demo structure. `make` lists every target.

```sh
make run      # http://127.0.0.1:5300/grouper/
make restart  # restart Grouper with the settings rebuilt
make seed     # load demo/groups.yaml again
make down     # stop it and keep its database
make wipe     # stop it and delete its database
```

`PORT=3901 make run` uses another port. It uses Docker, or Podman when
Docker isn't installed; `ENGINE=podman` picks Podman.
Grouper takes a few minutes to start the first time.

- **Sign-in:** nginx signs every request in as Andrew Carnegie (ac00), a
  made-up person in the demo's viewer group.
- **The theme:** Grouper reads `grouper/` straight from the repository.
  Changes to the CSS show on reload; `customHeader.jsp` recompiles on the next
  page. After `make build`, run `make restart` to rewrite the settings
  files in `dev/data/` and restart Grouper, for settings and
  `grouper:message` text.
- **Settings:** `dev/data/` holds Grouper's settings files, written by
  `make run` from `grouper/properties/` and `dev/conf/`, and the CSRFGuard
  file Grouper ships, with the theme's line added.

## The Demo Structure

`demo/groups.yaml` is the demo's Grouper structure: people, folders, groups,
composites, end dates, inherited privileges, Grouper settings and checks.
The comment at its top explains each field. `make seed` builds it, then
runs the checks. The loader behind it, `dev/load.py`, takes options for the
rarer cases:

```sh
python3 dev/load.py --check               # run the checks only
python3 dev/load.py --yaml other.yaml     # load another structure
```

Each load starts over: it deletes the YAML's top folders and everything in
them, then rebuilds from the YAML, so it also undoes any changes made in the
UI. It never touches Grouper's own `etc` folder. It needs Python 3 and
PyYAML.

## Check a Change

The everyday check is `make check`: it builds into a temporary folder and
stops if `grouper/` doesn't match.

To look at a change, run `make run`, check the pages you touched at 1300
and 390 pixels wide, and run the demo's checks
(`python3 dev/load.py --check`). Use made-up people
only, from the demo structure.

## Docs Site

`docs/` is the docs site's source, built by Jekyll with Jekyll & Plaid as its
remote theme. With Ruby and Bundler:

```sh
cd docs && bundle install
PAGES_REPO_NWO=cmu-web/cmu-web-kith-and-kirr bundle exec jekyll serve
```

`make docs` builds it with a local Jekyll & Plaid checkout and its gems
instead, for a look at Jekyll & Plaid changes before its next release.

## Release

1. Update `package.json`'s version, run `npm install` and `make build`,
   and commit "chore: release X".
2. Tag it with a bare number (`git tag -a 0.1.0 -m 0.1.0`) and push the
   branch and the tag.
3. Make the GitHub release with its notes. The Attach Release Files workflow
   attaches `kith-and-kirr.zip` and `site.tar.gz` to it.
