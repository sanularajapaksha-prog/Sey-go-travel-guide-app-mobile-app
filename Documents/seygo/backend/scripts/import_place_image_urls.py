#!/usr/bin/env python3
"""Bulk import direct image URLs into Supabase places table.

CSV format:
place_id,image_url
ChIJI146xSBZ4joRZ_W0TXLD71Y,https://lh3.googleusercontent.com/...
"""

from __future__ import annotations

import argparse
import csv
import os
from typing import Any

from dotenv import load_dotenv
from supabase import Client, create_client


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Import place image URLs by place_id.",
    )
    parser.add_argument(
        "--input",
        required=True,
        help="CSV path with columns: place_id,image_url",
    )
    parser.add_argument(
        "--table",
        default="placses",
        help="Target Supabase table (default: placses).",
    )
    parser.add_argument(
        "--id-column",
        default="place_id",
        help="Identifier column used to find rows (default: place_id).",
    )
    parser.add_argument(
        "--target-column",
        default="photo_public_urls",
        help="Column to update (default: photo_public_urls).",
    )
    parser.add_argument(
        "--target-mode",
        choices=("url", "url_list"),
        default="url_list",
        help="Write URL as plain string or one-item list.",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Apply updates. Without this flag, script runs as dry-run.",
    )
    return parser.parse_args()


def required_env(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def create_supabase_client() -> Client:
    url = required_env("SUPABASE_URL")
    key = required_env("SUPABASE_SERVICE_ROLE_KEY")
    return create_client(url, key)


def build_value(url: str, target_mode: str) -> Any:
    if target_mode == "url":
        return url
    return [url]


def main() -> int:
    args = parse_args()
    load_dotenv()

    supabase = create_supabase_client()

    total = 0
    valid = 0
    updated = 0
    errors = 0

    with open(args.input, "r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        expected = {"place_id", "image_url"}
        if not expected.issubset(set(reader.fieldnames or [])):
            raise RuntimeError(
                "CSV must contain headers: place_id,image_url"
            )

        for row in reader:
            total += 1
            place_id = (row.get("place_id") or "").strip()
            image_url = (row.get("image_url") or "").strip()

            if not place_id or not image_url:
                continue
            if not image_url.startswith("http"):
                continue

            valid += 1
            payload = {
                args.target_column: build_value(
                    image_url,
                    args.target_mode,
                )
            }

            try:
                if args.apply:
                    (
                        supabase.table(args.table)
                        .update(payload)
                        .eq(args.id_column, place_id)
                        .execute()
                    )
                    updated += 1
                print(
                    f"row={total} place_id={place_id} "
                    f"status={'updated' if args.apply else 'ready'}"
                )
            except Exception as exc:
                errors += 1
                print(
                    f"row={total} place_id={place_id} error={exc}"
                )

    print("\nSummary")
    print(f"- total_csv_rows: {total}")
    print(f"- valid_rows: {valid}")
    print(f"- updated_rows: {updated}")
    print(f"- errors: {errors}")
    print(f"- mode: {'apply' if args.apply else 'dry-run'}")

    return 0 if errors == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())

