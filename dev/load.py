#!/usr/bin/env python3
"""Loads a demo structure from a YAML file into the development Grouper.

The default file is demo/groups.yaml, the demo's made-up structure; --yaml
loads any other file in the same form. Each run starts over: it deletes the
top folders the YAML uses (and everything in them), then rebuilds every
folder, group, membership, composite and inherited privilege from the YAML,
and runs the YAML's checks against Grouper. Everything about the structure
comes from the YAML. Grouper's own etc folder is never touched.

    python3 dev/load.py                  # replace the structure, then run the checks
    python3 dev/load.py --check          # run the checks only
    python3 dev/load.py --dry-run        # write load.gsh and check.gsh only
    python3 dev/load.py --settings-only  # write the YAML's settings only

Steps:
  1. Adds or updates the YAML's people in Grouper's people table.
  2. Writes the YAML's settings into dev/data/grouper.properties.
  3. Writes load.gsh and check.gsh to dev/data/, copies them into the
     Grouper container and runs them in GSH, the checks in a second run so
     they read what Grouper stored.
Exits 1 if any check fails or a script reports an error.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))


def parse_args():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--yaml", default=os.path.join(HERE, "..", "demo", "groups.yaml"))
    p.add_argument(
        "--gsh",
        default=os.path.join(HERE, "data", "load.gsh"),
        help="where to write the GSH script",
    )
    p.add_argument("--dry-run", action="store_true", help="write load.gsh and check.gsh and stop")
    p.add_argument("--check", action="store_true", help="run the checks only, without loading")
    p.add_argument(
        "--settings-only", action="store_true", help="write the YAML's settings and stop"
    )
    p.add_argument("--container", default="kith-and-kirr-grouper-1")
    p.add_argument(
        "--engine",
        default=os.environ.get("ENGINE") or ("docker" if shutil.which("docker") else "podman"),
        help="docker or podman (default: ENGINE, then Docker if it's installed)",
    )
    p.add_argument("--db-container", default="kith-and-kirr-db-1")
    p.add_argument("--people-table", default="demo_person")
    p.add_argument("--source", default="people", help="the subject source the people are in")
    p.add_argument(
        "--properties",
        default=os.path.join(HERE, "data", "grouper.properties"),
        help="the grouper.properties file the container mounts",
    )
    return p.parse_args()


def strip(path):
    """A folder or group path without its trailing colon."""
    return str(path).rstrip(":")


def default_name(path):
    """A display name from an ID: underscores as spaces, in Title Case."""
    return strip(path).split(":")[-1].replace("_", " ").title()


def g(value):
    """A Groovy string literal."""
    return json.dumps("" if value is None else str(value))


def end_days(spec):
    """Days for an end date given as +Nd (N days after the script runs)."""
    m = re.fullmatch(r"\+(\d+)d", str(spec).strip())
    if not m:
        sys.exit(f"end date {spec!r} is not +Nd")
    return int(m.group(1))


KNOWN_KEYS = {
    "people": {"name", "role"},
    "folders": {"name", "description"},
    "groups": {"name", "description", "members", "includes", "intersect", "minus"},
    "checks": {"group", "has", "lacks", "why"},
}


def validate(data):
    """Stops on keys the loader doesn't know. An unquoted comma inside {...}
    ends a value early and turns the rest into a stray key."""
    problems = []
    for section in ("people", "folders", "groups"):
        for name, spec in (data.get(section) or {}).items():
            for key in spec or {}:
                if key not in KNOWN_KEYS[section]:
                    problems.append(f"{section} {name}: unknown key {key!r}")
    for check in data.get("checks") or []:
        for key in check:
            if key not in KNOWN_KEYS["checks"]:
                problems.append(f"check {check.get('group')}: unknown key {key!r}")
    if problems:
        sys.exit("The YAML: quote any value with a comma in it\n  " + "\n  ".join(problems))


def build_gsh(data, source):
    groups = {strip(k): v or {} for k, v in data["groups"].items()}
    folders = {strip(k): v or {} for k, v in (data.get("folders") or {}).items()}
    privileges = {strip(k): strip(v) for k, v in (data.get("privileges") or {}).items()}

    # Every folder: the ones named in the YAML plus every group's ancestors
    paths = set(folders)
    for name in groups:
        parts = name.split(":")[:-1]
        for i in range(1, len(parts) + 1):
            paths.add(":".join(parts[:i]))
    for name in list(paths):
        parts = name.split(":")
        for i in range(1, len(parts)):
            paths.add(":".join(parts[:i]))
    tops = sorted({p.split(":")[0] for p in paths})

    out = []
    w = out.append
    w("// Written by dev/load.py from the demo YAML; edit the YAML, not this file.")
    w("import edu.internet2.middleware.grouper.rules.RuleApi")
    w("import edu.internet2.middleware.grouper.userData.GrouperUserDataApi")
    w("grouperSession = GrouperSession.startRootSession();")
    w("def person(id) { SubjectFinder.findByIdAndSource(id, %s, true) }" % g(source))
    w("def group(name) { GroupFinder.findByName(grouperSession, name, true) }")
    w("def stem(name) { StemFinder.findByName(grouperSession, name, true) }")
    w("def subject(ref) { ref.contains(':') ? group(ref).toSubject() : person(ref) }")
    w("failures = 0;")
    w("try {")

    # Start over: composites first, so no group is a factor of one being deleted
    w("  // Start over: delete the YAML's top folders and everything in them")
    w("  for (top in %s) {" % json.dumps(tops))
    w("    Stem s = StemFinder.findByName(grouperSession, top, false)")
    w("    if (s == null) continue")
    w(
        "    for (Group x : s.getChildGroups(Stem.Scope.SUB)) { if (x.hasComposite()) x.deleteCompositeMember() }"
    )
    w("  }")
    w("  for (top in %s) {" % json.dumps(tops))
    w("    Stem s = StemFinder.findByName(grouperSession, top, false)")
    w("    if (s != null) s.obliterate(false, false)")
    w(
        "    if (StemFinder.findByName(grouperSession, top, false) != null) throw new RuntimeException('could not delete ' + top)"
    )
    w("  }")
    w("  // Grouper caches its rules; the deleted folders' rules would fire on the new ones")
    w("  edu.internet2.middleware.grouper.rules.RuleEngine.clearRuleEngineCache();")

    # Folders, parents first
    w("  // Folders")
    for path in sorted(paths, key=lambda p: (p.count(":"), p)):
        spec = folders.get(path, {})
        w(
            "  new StemSave(grouperSession).assignName(%s).assignDisplayExtension(%s).assignDescription(%s).save();"
            % (g(path), g(spec.get("name") or default_name(path)), g(spec.get("description")))
        )

    # Groups, empty for now
    w("  // Groups")
    for name, spec in groups.items():
        w(
            "  new GroupSave(grouperSession).assignName(%s).assignDisplayExtension(%s).assignDescription(%s).save();"
            % (g(name), g(spec.get("name") or default_name(name)), g(spec.get("description")))
        )

    # Inherited privileges, applied to what already exists
    w("  // Inherited privileges: admin on the folder and on every folder and group in it")
    for path, manager in privileges.items():
        w("  if (true) {")
        w("    Stem s = stem(%s); Subject m = subject(%s);" % (g(path), g(manager)))
        w("    s.grantPriv(m, NamingPrivilege.STEM_ADMIN, false);")
        w(
            "    RuleApi.inheritFolderPrivileges(s, Stem.Scope.SUB, m, [NamingPrivilege.STEM_ADMIN] as Set);"
        )
        w(
            "    RuleApi.inheritGroupPrivileges(s, Stem.Scope.SUB, m, [AccessPrivilege.ADMIN] as Set);"
        )
        w("    edu.internet2.middleware.grouper.rules.RuleEngine.clearRuleEngineCache();")
        w("    RuleApi.runRulesForOwner(s);")
        w("  }")

    # Members, includes and composites
    w("  // Members, included groups and composites")
    for name, spec in groups.items():
        for m in spec.get("members") or []:
            if isinstance(m, dict):
                w(
                    "  new MembershipSave().assignGroup(group(%s)).assignSubject(person(%s)).assignImmediateMshipDisabledTime(System.currentTimeMillis() + %dL * 86400000L).save();"
                    % (g(name), g(m["id"]), end_days(m["end"]))
                )
            else:
                w("  group(%s).addMember(person(%s), false);" % (g(name), g(m)))
        for inc in spec.get("includes") or []:
            w("  group(%s).addMember(group(%s).toSubject(), false);" % (g(name), g(strip(inc))))
        for key, kind in (("intersect", "INTERSECTION"), ("minus", "COMPLEMENT")):
            if spec.get(key):
                a, b = [strip(x) for x in spec[key]]
                if spec.get("members") or spec.get("includes"):
                    sys.exit(f"{name}: a composite can't also have members or includes")
                w(
                    "  group(%s).addCompositeMember(CompositeType.%s, group(%s), group(%s));"
                    % (g(name), kind, g(a), g(b))
                )

    # Each person's UI user data (favorites, recently used), made while the
    # database is writable, so a read-only demo only reads it
    w('  String userData = "etc:grouperUi:grouperUiUserData";')
    for pid in data.get("people") or {}:
        for kind in ("Groups", "Stems", "Members", "AttributeDefs", "AttributeDefNames"):
            for use in ("favorite", "recentlyUsed"):
                w("  GrouperUserDataApi.%s%s(userData, person(%s));" % (use, kind, g(pid)))
    w('  println("LOAD DONE");')
    w("} catch (Throwable e) {")
    w('  println("LOAD ERROR " + e);')
    w("  e.printStackTrace();")
    w("}")
    return "\n".join(out) + "\n", tops


def build_check_gsh(data, source, tops):
    """A separate script, run after the load, so it reads what Grouper stored
    (composite members are filled in after the loading script's changes)."""
    out = []
    w = out.append
    w("// Written by dev/load.py from the demo YAML; edit the YAML, not this file.")
    w("grouperSession = GrouperSession.startRootSession();")
    w("def person(id) { SubjectFinder.findByIdAndSource(id, %s, true) }" % g(source))
    w("def group(name) { GroupFinder.findByName(grouperSession, name, true) }")
    w("failures = 0;")
    w("try {")
    w("  int stems = 0, groupsMade = 0, members = 0;")
    w(
        "  for (top in %s) { Stem s = StemFinder.findByName(grouperSession, top, true); stems += 1 + s.getChildStems(Stem.Scope.SUB).size(); for (Group x : s.getChildGroups(Stem.Scope.SUB)) { groupsMade++; members += x.getImmediateMembers().size(); } }"
        % json.dumps(tops)
    )
    w(
        '  println("COUNT folders " + stems + ", groups " + groupsMade + ", direct memberships " + members);'
    )
    w("  // Effective members who are people, as Grouper computes them")
    for c in data.get("checks") or []:
        has = c.get("has")
        lacks = c.get("lacks") or []
        conds = [f"people.contains({g(i)})" for i in (has or [])]
        conds += [f"!people.contains({g(i)})" for i in lacks]
        if has == [] and not lacks:
            conds.append("people.isEmpty()")
        cond = " && ".join(conds) or "true"
        label = f"{strip(c['group'])}: {c.get('why', '')}"
        w("  if (true) {")
        w("    Group x = group(%s);" % g(strip(c["group"])))
        w(
            "    List people = x.getMembers().findAll { it.getSubjectSourceId() == %s }.collect { it.getSubjectId() }.sort();"
            % g(source)
        )
        w("    boolean ok = %s;" % cond)
        w("    if (!ok) failures++;")
        w(
            '    println("CHECK " + (ok ? "PASS " : "FAIL ") + %s + " (people: " + people.join(", ") + ")");'
            % g(label)
        )
        w("  }")
    w('  println("CHECKS DONE failures " + failures);')
    w("} catch (Throwable e) {")
    w('  println("CHECKS ERROR " + e);')
    w("  e.printStackTrace();")
    w("}")
    return "\n".join(out) + "\n"


def sql_text(value):
    return "'" + str(value).replace("'", "''") + "'"


def load_people(data, args):
    """Adds or updates each YAML person in Grouper's people table."""
    rows = []
    for pid, spec in (data.get("people") or {}).items():
        name = spec["name"]
        parts = name.split()
        sortable = (
            f"{parts[-1]}, {' '.join(parts[:-1])} ({pid})" if len(parts) > 1 else f"{name} ({pid})"
        )
        rows.append(
            "(%s, %s, %s, %s, %s, %s)"
            % (
                sql_text(pid),
                sql_text(pid),
                sql_text(name),
                sql_text(sortable),
                sql_text(f"{name.lower()} {pid}"),
                sql_text(f"{pid}@example.edu"),
            )
        )
    sql = (
        f"INSERT INTO {args.people_table} (subject_id, login_id, name, description, search_text, email) VALUES\n"
        + ",\n".join(rows)
        + "\nON CONFLICT (subject_id) DO UPDATE SET name = EXCLUDED.name, description = EXCLUDED.description,"
        " search_text = EXCLUDED.search_text, email = EXCLUDED.email;\n"
    )
    subprocess.run(
        [
            args.engine,
            "exec",
            "-i",
            args.db_container,
            "psql",
            "-q",
            "-v",
            "ON_ERROR_STOP=1",
            "-U",
            "grouper",
            "-d",
            "grouper",
        ],
        input=sql,
        text=True,
        check=True,
    )
    print(f"people: {len(rows)} in {args.people_table}")


def write_settings(data, args):
    """Writes the YAML's settings into grouper.properties in place; returns True if it changed."""
    settings = dict(data.get("settings") or {})
    if not settings:
        return False
    for key in list(settings):
        if key.endswith(".group"):
            settings.setdefault(key[: -len(".group")] + ".use", "true")
    with open(args.properties, encoding="utf-8") as f:
        lines = f.read().splitlines()
    before = list(lines)
    for key, value in settings.items():
        line = f"{key} = {value}"
        for i, existing in enumerate(lines):
            if re.match(rf"^\s*{re.escape(key)}\s*=", existing):
                lines[i] = line
                break
        else:
            lines.append(line)
    if lines == before:
        return False
    # Same file, rewritten in place, so a single-file mount keeps seeing it
    with open(args.properties, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    return True


def main():
    args = parse_args()
    with open(args.yaml, encoding="utf-8") as f:
        data = yaml.safe_load(f)
    validate(data)
    if args.settings_only:
        write_settings(data, args)
        return 0
    script, tops = build_gsh(data, args.source)
    check_path = os.path.join(os.path.dirname(args.gsh), "check.gsh")
    os.makedirs(os.path.dirname(args.gsh), exist_ok=True)
    with open(args.gsh, "w", encoding="utf-8") as f:
        f.write(script)
    with open(check_path, "w", encoding="utf-8") as f:
        f.write(build_check_gsh(data, args.source, tops))
    print(f"wrote {args.gsh} and {check_path}")
    if args.dry_run:
        return 0

    if not args.check:
        load_people(data, args)
        if write_settings(data, args):
            print(f"settings changed in {args.properties}: restart Grouper for them to take effect")
        if not run_gsh(args, args.gsh, "load", "LOAD DONE"):
            return 1
    # Composite groups are filled as they're made (dev/conf/grouper.properties),
    # so the first check normally passes; check every 15 seconds for up to 10
    # minutes in case Grouper is still catching up, printing the checks in full
    # the first and last time
    deadline = time.monotonic() + 600
    attempt = 0
    while True:
        last = time.monotonic() + 15 > deadline
        if run_gsh(args, check_path, "check", "CHECKS DONE failures 0", quiet=attempt and not last):
            return 0
        if last:
            return 1
        if attempt == 0:
            print(
                "checking every 15 seconds for up to 10 minutes, while Grouper fills composite groups"
            )
        attempt += 1
        time.sleep(15)


def run_gsh(args, path, name, done, quiet=False):
    """Copies a script into the container, runs it in GSH and prints its
    COUNT, CHECK, LOAD and CHECKS lines (only the CHECKS line when quiet);
    True if it printed the done line."""
    target = f"/tmp/kith-and-kirr-{name}.gsh"
    subprocess.run([args.engine, "cp", path, f"{args.container}:{target}"], check=True)
    run = subprocess.run(
        [args.engine, "exec", args.container, "gsh", target], capture_output=True, text=True
    )
    output = run.stdout + run.stderr
    lines = [
        line
        for line in output.splitlines()
        if line.startswith(("COUNT ", "CHECK ", "LOAD ", "CHECKS "))
    ]
    print("\n".join(line for line in lines if not quiet or line.startswith("CHECKS ")))
    if done in lines:
        return True
    log = os.path.join(os.path.dirname(args.gsh), f"{name}.log")
    with open(log, "w", encoding="utf-8") as f:
        f.write(output)
    if not quiet:
        print(f"see {log} for the full output")
    return False


if __name__ == "__main__":
    sys.exit(main())
