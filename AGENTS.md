# Kith & Kirr: Notes for AI Agents

Read [CONTRIBUTING.md](CONTRIBUTING.md) and [DEVELOPMENT.md](DEVELOPMENT.md)
before changing anything. The rules agents most often break here:

- Never edit or replace Grouper's own files. The theme uses only the empty
  `customHeader.jsp`, Grouper's settings files for a site's own values and
  its own folder under Grouper's public assets.
- Edit `src/`, then run `make build` and commit both `src/` and
  `grouper/`. Never edit `grouper/` by hand.
- In `src/kith-and-kirr.css`, use the template's and the Kilt's colors and
  type; never invent new ones. Find the Kilt component first: ask the Web
  Kilt MCP server (https://webkilt.andrew.cmu.edu/mcp) or browse the
  Components page (https://webkilt.andrew.cmu.edu/0/components.html).
- `docs/` is the public docs site's source (Jekyll & Plaid); don't put notes
  there. Use the template's classes first, then the Kilt's (cmu-), never a
  project class.
- Grouper loads pages by Ajax: a header script has to watch for new content,
  and anything it writes into a page escapes Grouper's text.
- `demo/groups.yaml` uses made-up people only (e.g., Andrew Carnegie, ac00);
  quote any value with a comma in it.
- Follow the Web Kilt's [writing conventions](https://webkilt.andrew.cmu.edu/0/conventions.html).
- Versions use semantic versioning as plain numbers (e.g., `0.1.0`).
