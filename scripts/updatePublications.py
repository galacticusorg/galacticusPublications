#!/usr/bin/env python3
"""Update the `publications.xml` database, adding in any new data
(updated NASA ADS bibcodes, DOIs, etc.), and ensuring that tags in
the Galacticus repo are also updated.

Andrew Benson (30-May-2025; ported to Python 09-May-2026)
"""

import json
import subprocess
import sys
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET


def main():
    if len(sys.argv) != 4:
        sys.exit("Usage: updatePublications.py <apiToken> <slackURL> <repoPath>")
    api_token, slack_url, repo_path = sys.argv[1:4]

    # Extract all tags from the repo.
    print("Looking for existing tags...")
    tags = {}
    git_output = subprocess.check_output(
        ["git", "--git-dir", f"{repo_path}/.git", "tag", "-l"],
        text=True,
    )
    for tag in git_output.splitlines():
        if not tag:
            continue
        tags[tag] = 0
        if tag.startswith("publication/"):
            print(f" found: {tag}")
    print("...done")

    # Parse the database.
    tree = ET.parse("publications.xml")
    publications = list(tree.getroot().findall("publication"))

    # Extract/construct current bibcodes.
    print("Searching for bibcodes in database...")
    bibcodes = {}
    for publication in publications:
        attrib = publication.attrib
        if "bibCode" in attrib:
            bibcode = attrib["bibCode"]
        elif "arXiv" in attrib:
            arxiv_reduced = attrib["arXiv"].replace(".", "")
            bibcode = f"{attrib['year']}arXiv{arxiv_reduced}{attrib['author'][0]}"
        else:
            print(ET.tostring(publication, encoding="unicode"))
            sys.exit("no bibcode available for this entry")
        bibcodes[bibcode] = {"entry": publication}
        print(f"   found bibcode: {bibcode}")
    print("...done")

    # Pull records from NASA ADS.
    body = ("bibcode\n" + "\n".join(sorted(bibcodes.keys()))).encode("utf-8")
    url = (
        "https://api.adsabs.harvard.edu/v1/search/bigquery"
        f"?q=*:*&rows={len(bibcodes)}"
        "&fl=bibcode,alternate_bibcode,doi,title,author,year,pub,volume,page"
    )
    request = urllib.request.Request(
        url,
        data=body,
        headers={
            "Authorization": f"Bearer {api_token}",
            "Content-Type": "big-query/csv",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request) as response:
            response_body = response.read().decode("utf-8")
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")
        sys.exit(f"Failed to retrieve record identifiers: {error.code}{detail}")
    except urllib.error.URLError as error:
        sys.exit(f"Failed to retrieve record identifiers: {error.reason}")
    records = json.loads(response_body)

    # Match records with our entries.
    print("Matching NASA ADS bibcodes to entries...")
    for record in records["response"]["docs"]:
        matched = None
        if record["bibcode"] in bibcodes:
            matched = record["bibcode"]
        else:
            for alt in record.get("alternate_bibcode", []):
                if alt in bibcodes:
                    matched = alt
        if matched is None:
            sys.exit(f"unable to match record (bibcode: {record['bibcode']}) to entry")
        bibcodes[matched]["record"] = record
        print(f"   matched record for bibcode: {matched}")
    print("...done")

    # Process each entry and apply updates.
    print("Checking for updates...")
    new_tags = []
    for bibcode, info in bibcodes.items():
        if "record" not in info:
            print(f"   FAIL: no ADS record found for bibcode '{bibcode}'")
            sys.exit(1)
        entry = info["entry"]
        record = info["record"]

        # Replace the bibcode with the canonical bibcode.
        if record["bibcode"] != entry.get("bibCode"):
            print(
                f"   update bibcode to canonical value: {entry.get('bibCode')} "
                f"--> {record['bibcode']}"
            )
            entry.set("bibCode", record["bibcode"])

        # Add DOI if necessary.
        for doi in record.get("doi", []):
            if "arXiv" in doi:
                continue
            if doi != entry.get("doi"):
                entry.set("doi", doi)
                print(f"   update doi for bibcode {entry.get('bibCode')} to: {doi}")
            break

        # Add journal URL if necessary. Resolve the DOI via doi.org's
        # handle API, which returns the publisher URL as structured JSON.
        if "doi" in entry.attrib:
            try:
                with urllib.request.urlopen(
                    f"https://doi.org/api/handles/{entry.get('doi')}"
                ) as response:
                    handle = json.loads(response.read())
            except urllib.error.URLError as error:
                sys.exit(
                    f"Failed to resolve DOI for bibcode {entry.get('bibCode')}: "
                    f"{error.reason}"
                )
            journal_url = next(
                (
                    value["data"]["value"]
                    for value in handle.get("values", [])
                    if value.get("type") == "URL"
                    and "arxiv" not in value["data"]["value"].lower()
                ),
                None,
            )
            if journal_url is not None and journal_url != entry.get("journalURL"):
                entry.set("journalURL", journal_url)
                print(
                    f"   update journal URL for bibcode {entry.get('bibCode')} "
                    f"to: {journal_url}"
                )

        # Update repo tags.
        if "commit" in entry.attrib:
            message = (
                f'"Publication: {entry.get("title")} by {entry.get("author")} '
                f'({entry.get("year")})"'
            )
            commit = entry.get("commit")
            for kind, value in (
                ("arXiv", entry.get("arXiv")),
                ("bibcode", (entry.get("bibCode") or "").replace(".", "_") or None),
                ("doi", entry.get("doi")),
            ):
                if not value:
                    continue
                tag = f"publication/{kind}/{value}"
                if tag in tags:
                    tags[tag] += 1
                else:
                    new_tags.append(f"git tag -a {tag} {commit} -m {message}")

    # Add deletes for any obsoleted tags.
    for tag, count in tags.items():
        if count == 0 and tag.startswith("publication/"):
            new_tags.append(f"git tag -d {tag}")
    print("...done")

    # Write updated database file.
    write_publications("publications.xml", publications)

    # Send a Slack notification for any new tags needed.
    if new_tags:
        print("New tags to be created:\n\t" + "\n\t".join(new_tags))
        payload = json.dumps({"tags": "\n".join(new_tags) + "\n"})
        result = subprocess.run(
            [
                "curl", "-X", "POST",
                "-H", "Content-type: application/json",
                "--data", payload,
                slack_url,
            ]
        )
        if result.returncode != 0:
            print(
                f"Warning: curl exited with status {result.returncode} "
                f"when sending Slack notification",
                file=sys.stderr,
            )
    else:
        print("No new tags to be created")


def write_publications(path, publications):
    """Write publications XML in a format matching XML::Simple's XMLout."""
    lines = ["<publications>"]
    for publication in publications:
        attrs = " ".join(
            f'{name}="{_xml_escape(value)}"'
            for name, value in sorted(publication.attrib.items())
        )
        lines.append(f"  <publication {attrs} />")
    lines.append("</publications>")
    with open(path, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")


def _xml_escape(value):
    return (
        value.replace("&", "&amp;")
             .replace("<", "&lt;")
             .replace(">", "&gt;")
             .replace('"', "&quot;")
    )


if __name__ == "__main__":
    main()
