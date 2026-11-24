# Deployment

## Release Files

Each version tag (e.g., `0.1.0`) has a GitHub release with:

| File                | What                                                                                                                                                                  |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `kith-and-kirr.zip` | `assets/kith-and-kirr/` (the styles, fonts, logo and favicons), `customHeader.jsp`, `properties/` (the lines for Grouper's settings files), `LICENSE` and `README.md` |
| `site.tar.gz`       | The docs site, built                                                                                                                                                  |

The theme is tested with Grouper 7.9.1.

## Install

The theme uses only the places Grouper sets aside for a site's additions.
With `WEBAPP` as Grouper's web app folder (`/opt/grouper/grouperWebapp` in
Internet2's container):

1. **The assets:** copy `assets/kith-and-kirr/` to
   `$WEBAPP/grouperExternal/public/assets/kith-and-kirr/`.
2. **The header:** copy `customHeader.jsp` over
   `$WEBAPP/WEB-INF/grouperUi2/assetsJsp/customHeader.jsp`. Grouper ships it
   empty and includes it on every page, for a site's own markup. If your site
   already put something there, merge the two.
3. **The UI settings:** add the lines in `properties/grouper-ui.properties` to
   `$WEBAPP/WEB-INF/classes/grouper-ui.properties`: the theme's stylesheets,
   the CMU wordmark and no Sign Out link.
4. **The words:** add the lines in `properties/grouper.text.en.us.properties`
   to `$WEBAPP/WEB-INF/classes/grouperText/grouper.text.en.us.properties`,
   the file Grouper keeps for a site's own wording. Never edit the `.base.`
   file beside it.
5. **The CSRFGuard line:** add the line in
   `properties/Owasp.CsrfGuard.overlay.properties` to
   `$WEBAPP/WEB-INF/classes/Owasp.CsrfGuard.overlay.properties`, keeping the
   settings Grouper ships in that file. See
   [Why the CSRFGuard Line](#why-the-csrfguard-line).
6. **Restart Grouper.**

### In a Container

Mount the files read-only. For the two whole files and the asset folder:

```sh
-v /srv/kith-and-kirr/assets/kith-and-kirr:/opt/grouper/grouperWebapp/grouperExternal/public/assets/kith-and-kirr:ro
-v /srv/kith-and-kirr/customHeader.jsp:/opt/grouper/grouperWebapp/WEB-INF/grouperUi2/assetsJsp/customHeader.jsp:ro
```

The three settings files hold your site's own lines too, so mount your
copies of them with the theme's lines added, or build them into your image.
A file mounted on its own keeps pointing at the file it started with: after
changing one, write it in place (e.g., `cat new > file`) or restart the
container.

### Your Site's Name

In `grouper.text.en.us.properties`:

- `kithAndKirr.siteTitle`: the site's name in the header, `Grouper` unless
  your site calls it something else.
- `kithAndKirr.siteTagline`: a line under the name, blank for none.
- `institutionName`: the university's name in the footer.

## Why the CSRFGuard Line

Once a page has loaded, Grouper's CSRFGuard script appends its token to the
address of every stylesheet, script and image on it. A stylesheet whose
address changes is dropped and downloaded again, so every page downloads
every stylesheet twice, and a browser can paint the page in between with
Grouper's own styles and without the theme's. The line lists the static file
types CSRFGuard leaves alone. The server checks tokens exactly as before;
only static files stop getting one, so they also stop showing up with tokens
in logs and Referer headers.

## When Text Changes Show

Grouper rereads its text file about every 10 minutes, but text shown through
its `grouper:message` tag, such as the group summary's labels, is read once at
startup. After changing the theme's words, restart Grouper to see all of them.

## The Demo

`demo/` holds the public demo's settings: `groups.yaml` (a made-up structure
for Buggy, the Spring Carnival Sweepstakes), `grouper.properties` (read-only),
`grouper.text.en.us.properties` (the theme's tagline under the name) and
`nginx.conf` (every visitor signed in as one made-up person who can see
everything and change nothing).

To run it:

1. Start Grouper and Postgres with the theme, as `dev/compose.yaml` does,
   with `demo/nginx.conf` in front.
2. Load `demo/groups.yaml` with `dev/load.py` while Grouper can still be
   changed.
3. Add `demo/grouper.properties` to Grouper's `grouper.properties` and
   restart Grouper. From then on, every change fails, even for Grouper's
   system account; browsing writes nothing.

Give the Grouper container no outbound network access; only the web server
needs to reach it. To reset the demo, start from an empty database and repeat
the three steps: Grouper's own scheduled jobs can't rebuild it once it's
read-only.
