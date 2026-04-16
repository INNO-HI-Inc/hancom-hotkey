#!/usr/bin/env python3
"""Maintain site/appcast.xml with a new Sparkle release entry."""
from __future__ import annotations

import argparse
import os
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"
ET.register_namespace("sparkle", SPARKLE_NS)


APPCAST_SKELETON = f"""<?xml version=\"1.0\" encoding=\"utf-8\"?>
<rss version=\"2.0\" xmlns:sparkle=\"{SPARKLE_NS}\">
  <channel>
    <title>한컴단축키</title>
    <link>https://inno-hi-inc.github.io/hancom-hotkey/appcast.xml</link>
    <description>한컴단축키 업데이트 채널</description>
    <language>ko</language>
  </channel>
</rss>
"""


def ensure_appcast(path: Path) -> ET.ElementTree:
    if path.exists() and path.stat().st_size > 0:
        return ET.parse(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(APPCAST_SKELETON, encoding="utf-8")
    return ET.parse(path)


def build_item(args) -> ET.Element:
    item = ET.Element("item")

    title = ET.SubElement(item, "title")
    title.text = f"버전 {args.version}"

    pub_date = ET.SubElement(item, "pubDate")
    pub_date.text = args.pub_date

    sparkle_version = ET.SubElement(item, f"{{{SPARKLE_NS}}}version")
    sparkle_version.text = args.build

    sparkle_short = ET.SubElement(item, f"{{{SPARKLE_NS}}}shortVersionString")
    sparkle_short.text = args.version

    min_sys = ET.SubElement(item, f"{{{SPARKLE_NS}}}minimumSystemVersion")
    min_sys.text = "13.0"

    if os.path.exists(args.dmg_path):
        length = str(os.path.getsize(args.dmg_path))
    else:
        length = args.length or "0"

    enclosure_attrs = {
        "url": args.enclosure_url,
        "length": length,
        "type": "application/octet-stream",
    }
    if args.signature:
        enclosure_attrs[f"{{{SPARKLE_NS}}}edSignature"] = args.signature
    ET.SubElement(item, "enclosure", enclosure_attrs)

    return item


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--appcast", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--build", required=True)
    parser.add_argument("--dmg-path", required=True)
    parser.add_argument("--enclosure-url", required=True)
    parser.add_argument("--pub-date", required=True)
    parser.add_argument("--signature", default="")
    parser.add_argument("--length", default="")
    args = parser.parse_args()

    appcast_path = Path(args.appcast)
    tree = ensure_appcast(appcast_path)
    root = tree.getroot()
    channel = root.find("channel")
    if channel is None:
        print("appcast malformed: missing <channel>", file=sys.stderr)
        return 1

    # Remove any prior entry for the same version (idempotent re-runs).
    for existing in list(channel.findall("item")):
        short = existing.find(f"{{{SPARKLE_NS}}}shortVersionString")
        if short is not None and short.text == args.version:
            channel.remove(existing)

    item = build_item(args)
    channel.append(item)

    # Pretty-print for humans.
    ET.indent(tree, space="  ")
    tree.write(appcast_path, xml_declaration=True, encoding="utf-8")
    print(f"appcast updated: {appcast_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
