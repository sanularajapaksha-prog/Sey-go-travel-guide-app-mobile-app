#!/usr/bin/env python3
"""Backfill place images from Google Place IDs into Supabase Storage.

Expected source data:
- Table with a JSON/text column containing Google Place IDs
  (e.g. `photo_storage_paths` with values like ["ChIJ..."]).

Flow:
1) Read rows from Supabase.
2) Extract Place ID.
3) Call Google Place Details API for `photos`.
4) Download first photo via Place Photo API.
5) Upload image bytes to Supabase Storage.
6) Update table with storage path/public URL.
"""

from __future__ import annotations

import argparse
import json
import mimetypes
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any

from dotenv import load_dotenv
from supabase import Client, create_client


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Backfill Google place photos.")
    parser.add_argument("--table", default="places", help="Supabase table name.")
    parser.add_argument(
        "--id-column",
        default="id",
        help="Primary key column used for row updates.",
    )
    parser.add_argument(
        "--source-column",
        default="photo_storage_paths",
        help="Column that currently contains Google Place IDs.",
    )
    parser.add_argument(
        "--target-column",
        default="photo_storage_paths",
        help="Column to update with photo value.",
    )
    parser.add_argument(
        "--target-mode",
        choices=("path", "path_list", "url", "url_list"),
        default="path_list",
        help="How value is written to target column.",
    )
    parser.add_argument(
        "--public-url-column",
        default="",
        help="Optional extra column to store public URL.",
    )
    parser.add_argument(
        "--bucket",
        default="place-images",
        help="Supabase Storage bucket name.",
    )
    parser.add_argument(
        "--folder",
        default="places",
        help="Storage folder prefix inside the bucket.",
    )
    parser.add_argument(
        "--maxwidth",
        type=int,
        default=1200,
        help="Google Place Photo API maxwidth.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Optional limit of rows to process (0 = all).",
    )
    parser.add_argument(
        "--sleep-ms",
        type=int,
        default=150,
        help="Delay between Google API calls.",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Write changes to storage/DB. Without this, runs in dry mode.",
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


def extract_place_id(raw_value: Any) -> str | None:
    if raw_value is None:
        return None
    if isinstance(raw_value, str):
        value = raw_value.strip()
        if value.startswith("ChI"):
            return value
        return None
    if isinstance(raw_value, list):
        for item in raw_value:
            if isinstance(item, str) and item.strip().startswith("ChI"):
                return item.strip()
    return None


def fetch_first_photo_reference(place_id: str, api_key: str) -> str | None:
    query = urllib.parse.urlencode(
        {
            "place_id": place_id,
            "fields": "photos",
            "key": api_key,
        }
    )
    url = (
        "https://maps.googleapis.com/maps/api/place/details/json"
        f"?{query}"
    )
    try:
        with urllib.request.urlopen(url, timeout=20) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except urllib.error.URLError:
        return None

    photos = payload.get("result", {}).get("photos") or []
    if not photos:
        return None
    return photos[0].get("photo_reference")


def download_google_photo(
    photo_reference: str,
    api_key: str,
    maxwidth: int,
) -> tuple[bytes, str]:
    query = urllib.parse.urlencode(
        {
            "maxwidth": maxwidth,
            "photo_reference": photo_reference,
            "key": api_key,
        }
    )
    url = f"https://maps.googleapis.com/maps/api/place/photo?{query}"
    with urllib.request.urlopen(url, timeout=30) as response:
        content = response.read()
        content_type = response.headers.get_content_type()
    return content, content_type


def extension_for_content_type(content_type: str) -> str:
    extension = mimetypes.guess_extension(content_type or "") or ".jpg"
    if extension == ".jpe":
        return ".jpg"
    return extension


def build_target_value(
    target_mode: str,
    storage_path: str,
    public_url: str,
) -> Any:
    if target_mode == "path":
        return storage_path
    if target_mode == "path_list":
        return [storage_path]
    if target_mode == "url":
        return public_url
    return [public_url]


def main() -> int:
    args = parse_args()
    load_dotenv()

    google_api_key = required_env("GOOGLE_MAPS_API_KEY")
    supabase = create_supabase_client()
    bucket = supabase.storage.from_(args.bucket)

    select_columns = [args.id_column, args.source_column]
    if args.id_column != "name":
        select_columns.append("name")

    query = supabase.table(args.table).select(",".join(select_columns))
    if args.limit > 0:
        query = query.limit(args.limit)
    rows = query.execute().data or []

    stats = {
        "rows": len(rows),
        "processed": 0,
        "updated": 0,
        "skipped_no_place_id": 0,
        "skipped_no_photo": 0,
        "errors": 0,
    }

    print(f"Loaded {stats['rows']} rows from `{args.table}`.")
    if not args.apply:
        print("Dry run enabled. Use --apply to upload/update.")

    for row in rows:
        row_id = row.get(args.id_column)
        place_id = extract_place_id(row.get(args.source_column))
        if not place_id:
            stats["skipped_no_place_id"] += 1
            continue

        stats["processed"] += 1
        photo_ref = fetch_first_photo_reference(place_id, google_api_key)
        if not photo_ref:
            stats["skipped_no_photo"] += 1
            continue

        try:
            image_bytes, content_type = download_google_photo(
                photo_ref,
                google_api_key,
                args.maxwidth,
            )
            extension = extension_for_content_type(content_type)
            storage_path = f"{args.folder}/{place_id}{extension}"

            if args.apply:
                bucket.upload(
                    storage_path,
                    image_bytes,
                    {
                        "content-type": content_type or "image/jpeg",
                        "upsert": "true",
                    },
                )
                public_url = bucket.get_public_url(storage_path)
                update_payload: dict[str, Any] = {
                    args.target_column: build_target_value(
                        args.target_mode,
                        storage_path,
                        public_url,
                    )
                }
                if args.public_url_column:
                    update_payload[args.public_url_column] = public_url

                (
                    supabase.table(args.table)
                    .update(update_payload)
                    .eq(args.id_column, row_id)
                    .execute()
                )
                stats["updated"] += 1

            print(
                f"row={row_id} place_id={place_id} "
                f"status={'updated' if args.apply else 'ready'}"
            )
        except Exception as exc:
            stats["errors"] += 1
            print(f"row={row_id} place_id={place_id} error={exc}")

        time.sleep(max(args.sleep_ms, 0) / 1000.0)

    print("\nSummary")
    for key, value in stats.items():
        print(f"- {key}: {value}")

    return 0 if stats["errors"] == 0 else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("\nInterrupted.")
        raise SystemExit(130)
