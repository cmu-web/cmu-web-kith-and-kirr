// Builds grouper/, the folder a Grouper admin copies from:
//   * grouper/assets/kith-and-kirr/: the Web Kilt's cmu-cms.css from the
//     installed Kilt (@cmu-web/kilt in package.json), the theme's CSS, Open
//     Sans with its license, the CMU wordmark, the logo and the favicons
//   * grouper/customHeader.jsp: the site name, footer and page scripts
//   * grouper/properties/: the lines for Grouper's own settings files
//
// A new Kilt is an npm upgrade (Dependabot proposes each release) and a
// rebuild:
//   npm run build
// npm run check builds into a temporary folder and stops if grouper/ differs.
// The build overwrites files in place and deletes only files it no longer
// makes, so a Grouper with grouper/ mounted keeps seeing it.
import {
  copyFileSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  readdirSync,
  rmSync,
} from "node:fs";
import { createRequire } from "node:module";
import { tmpdir } from "node:os";
import { dirname, join, relative } from "node:path";

const require = createRequire(import.meta.url);
export const KILT = require("@cmu-web/kilt/package.json").version;
const root = join(dirname(new URL(import.meta.url).pathname), "..");
const check = process.argv.includes("--check");
const out = check ? mkdtempSync(join(tmpdir(), "kith-and-kirr-")) : join(root, "grouper");

const made = new Set();
function copy(from, to) {
  mkdirSync(dirname(to), { recursive: true });
  copyFileSync(from, to);
  made.add(to);
  if (!check) console.log("wrote", relative(root, to));
}
const list = (dir) =>
  readdirSync(dir, { recursive: true, withFileTypes: true })
    .filter((d) => d.isFile())
    .map((d) => relative(dir, join(d.parentPath, d.name)))
    .sort();

const assets = join(out, "assets/kith-and-kirr");
copy(require.resolve("@cmu-web/kilt/css/cmu-cms.css"), join(assets, "cmu-cms.css"));
copy(join(root, "src/kith-and-kirr.css"), join(assets, "kith-and-kirr.css"));
for (const name of readdirSync(join(root, "src/assets")))
  copy(join(root, "src/assets", name), join(assets, name));
for (const name of ["cmu-grouper-logo.svg", "favicon.svg", "favicon-32.png", "apple-touch-icon.png"])
  copy(join(root, "images", name), join(assets, name));
copy(join(root, "src/customHeader.jsp"), join(out, "customHeader.jsp"));
for (const name of readdirSync(join(root, "src/properties")))
  copy(join(root, "src/properties", name), join(out, "properties", name));

if (!check)
  for (const name of list(out))
    if (!made.has(join(out, name))) {
      rmSync(join(out, name));
      console.log("deleted", relative(root, join(out, name)));
    }

if (check) {
  if (!existsSync(join(root, "grouper"))) {
    console.error("No grouper/ yet; run npm run build");
    process.exit(1);
  }
  const built = list(out);
  const committed = list(join(root, "grouper"));
  const stale = [...new Set([...built, ...committed])].filter((name) => {
    try {
      return !readFileSync(join(out, name)).equals(readFileSync(join(root, "grouper", name)));
    } catch {
      return true;
    }
  });
  rmSync(out, { recursive: true, force: true });
  if (stale.length) {
    console.error(
      `grouper/ isn't current (Kilt ${KILT}); run npm run build:\n  ${stale.join("\n  ")}`,
    );
    process.exit(1);
  }
  console.log(`grouper/ is current (Kilt ${KILT})`);
}
