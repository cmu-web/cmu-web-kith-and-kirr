# Contributing

For setup and checks, see [Development](DEVELOPMENT.md).

## Report a Problem

Check existing issues first, then
[report a problem](https://github.com/cmu-web/cmu-web-kith-and-kirr/issues/new?template=bug_report.yml).
Say which Grouper version you run and which page doesn't look right; a
screenshot with made-up content helps.

## Submit a Pull Request

- Branch from `0.x` and open the pull request against `0.x`.
- Keep it to one concern.
- Explain the problem, the resulting behavior and how you checked the
  change.
- Edit `src/`, run `make build`, and commit both `src/` and `grouper/`.
  `make check` (Node only) is the one check to run first; the Check Code
  workflow runs it on every pull request.
- The theme uses only Grouper's places for a site's additions. Never change a
  file of Grouper's other than the empty `customHeader.jsp`.

## Code and Writing Style

- Follow the Web Kilt's [writing
  conventions](https://webkilt.andrew.cmu.edu/0/conventions.html): AP style,
  and Title Case for headings, buttons, labels, menus and tabs.
- Use the template's and the Kilt's colors and type; never invent new ones.
- Use made-up content in examples and screenshots, and Andrew Carnegie
  (ac00) for a person.
- Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
  for commit subjects.

## CMU's Names and Marks

CMU's names, marks and artwork aren't covered by the license. Use them only
as the project already does.
