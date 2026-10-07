#!/usr/bin/env python3
"""Compare local App Store Connect and RevenueCat commerce catalog exports."""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


ASC_TYPE_MAP = {
    "AUTO_RENEWABLE_SUBSCRIPTION": "subscription",
    "SUBSCRIPTION": "subscription",
    "SUBSCRIPTIONS": "subscription",
    "CONSUMABLE": "consumable",
    "NON_CONSUMABLE": "non_consumable",
    "NONCONSUMABLE": "non_consumable",
    "NON_RENEWING_SUBSCRIPTION": "non_renewing_subscription",
}

RC_TYPE_MAP = {
    "SUBSCRIPTION": "subscription",
    "CONSUMABLE": "consumable",
    "NON_CONSUMABLE": "non_consumable",
    "NONCONSUMABLE": "non_consumable",
    "NON_RENEWING_SUBSCRIPTION": "non_renewing_subscription",
}

PRODUCT_ID_KEYS = (
    "productId",
    "product_id",
    "productID",
    "store_identifier",
    "storeIdentifier",
    "identifier",
)

TYPE_KEYS = ("type", "productType", "product_type", "inAppPurchaseType", "kind")


def load_json(path: Path) -> Any:
    try:
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    except OSError as error:
        raise SystemExit(f"Could not read {path}: {error}") from error
    except json.JSONDecodeError as error:
        raise SystemExit(f"Invalid JSON in {path}: {error}") from error


def as_list(value: Any) -> list[Any]:
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def merged_record(record: Any) -> dict[str, Any]:
    if not isinstance(record, dict):
        return {}
    merged: dict[str, Any] = {}
    attrs = record.get("attributes")
    if isinstance(attrs, dict):
        merged.update(attrs)
    merged.update(record)
    return merged


def pick(record: dict[str, Any], keys: tuple[str, ...]) -> Any:
    for key in keys:
        value = record.get(key)
        if value not in (None, ""):
            return value
    return None


def normalize_type(value: Any, mapping: dict[str, str], default: str | None = None) -> str:
    if value in (None, ""):
        return default or "unknown"
    text = str(value).strip()
    return mapping.get(text.upper(), text.lower())


def product_id(record: dict[str, Any]) -> str | None:
    value = pick(record, PRODUCT_ID_KEYS)
    if value in (None, ""):
        return None
    return str(value)


def extract_asc(data: Any) -> tuple[dict[str, dict[str, Any]], list[str], list[str]]:
    products: dict[str, dict[str, Any]] = {}
    duplicates: list[str] = []
    malformed: list[str] = []
    counts: Counter[str] = Counter()

    def add(raw: Any, default_type: str | None = None) -> None:
        record = merged_record(raw)
        pid = product_id(record)
        if not pid:
            malformed.append(json.dumps(raw, ensure_ascii=False, sort_keys=True)[:240])
            return
        record_type = pick(record, TYPE_KEYS)
        normalized = normalize_type(record_type, ASC_TYPE_MAP, default_type)
        if normalized in {"inapppurchases", "in-app-purchases", "in_app_purchases"}:
            normalized = normalize_type(record.get("inAppPurchaseType"), ASC_TYPE_MAP, default_type)
        counts[pid] += 1
        products[pid] = {
            "product_id": pid,
            "type": normalized,
            "label": record.get("referenceName") or record.get("name") or record.get("id") or "",
            "group": record.get("subscriptionGroupId") or record.get("groupId") or record.get("group_id") or "",
            "duration": record.get("subscriptionPeriod") or record.get("duration") or "",
        }

    if isinstance(data, list):
        for item in data:
            add(item)
    elif isinstance(data, dict):
        for key in ("subscriptions", "autoRenewableSubscriptions", "subscriptionProducts"):
            for item in as_list(data.get(key)):
                add(item, "subscription")
        for key in ("iaps", "inAppPurchases", "in_app_purchases", "products"):
            for item in as_list(data.get(key)):
                add(item)
        if "data" in data:
            for item in as_list(data.get("data")):
                add(item)
    else:
        raise SystemExit("ASC catalog must be a JSON object or array")

    duplicates = sorted(pid for pid, count in counts.items() if count > 1)
    return products, duplicates, malformed


def extract_revenuecat(data: Any) -> tuple[dict[str, dict[str, Any]], list[str], list[str], dict[str, list[str]]]:
    products: dict[str, dict[str, Any]] = {}
    duplicates: list[str] = []
    malformed: list[str] = []
    counts: Counter[str] = Counter()
    entitlement_products: dict[str, list[str]] = defaultdict(list)

    def add_product(raw: Any) -> None:
        record = merged_record(raw)
        pid = product_id(record)
        if not pid:
            malformed.append(json.dumps(raw, ensure_ascii=False, sort_keys=True)[:240])
            return
        counts[pid] += 1
        products[pid] = {
            "store_identifier": pid,
            "type": normalize_type(pick(record, TYPE_KEYS), RC_TYPE_MAP),
            "label": record.get("display_name") or record.get("name") or record.get("id") or "",
        }

    def add_entitlement(raw: Any) -> None:
        record = merged_record(raw)
        entitlement_id = str(record.get("id") or record.get("identifier") or record.get("name") or "unknown")
        attached = (
            record.get("products")
            or record.get("product_identifiers")
            or record.get("attached_products")
            or record.get("attachedProducts")
            or []
        )
        for item in as_list(attached):
            if isinstance(item, str):
                pid = item
            else:
                pid = product_id(merged_record(item))
            if pid:
                entitlement_products[entitlement_id].append(pid)

    if isinstance(data, list):
        for item in data:
            add_product(item)
    elif isinstance(data, dict):
        for key in ("products", "items"):
            for item in as_list(data.get(key)):
                add_product(item)
        if "data" in data:
            for item in as_list(data.get("data")):
                add_product(item)
        for key in ("entitlements", "entitlement_list"):
            for item in as_list(data.get(key)):
                add_entitlement(item)
    else:
        raise SystemExit("RevenueCat catalog must be a JSON object or array")

    duplicates = sorted(pid for pid, count in counts.items() if count > 1)
    return products, duplicates, malformed, dict(entitlement_products)


def build_report(asc: dict[str, dict[str, Any]], rc: dict[str, dict[str, Any]], asc_dupes: list[str], rc_dupes: list[str], asc_bad: list[str], rc_bad: list[str], entitlement_products: dict[str, list[str]], allow_consumable_entitlements: bool) -> dict[str, Any]:
    asc_ids = set(asc)
    rc_ids = set(rc)
    type_mismatches = []
    for pid in sorted(asc_ids & rc_ids):
        asc_type = asc[pid]["type"]
        rc_type = rc[pid]["type"]
        if asc_type != "unknown" and rc_type != "unknown" and asc_type != rc_type:
            type_mismatches.append({"product_id": pid, "asc_type": asc_type, "revenuecat_type": rc_type})

    consumable_entitlements = []
    if not allow_consumable_entitlements:
        for entitlement, product_ids in sorted(entitlement_products.items()):
            for pid in product_ids:
                if rc.get(pid, {}).get("type") == "consumable":
                    consumable_entitlements.append({"entitlement": entitlement, "product_id": pid})

    return {
        "asc_count": len(asc),
        "revenuecat_count": len(rc),
        "missing_in_revenuecat": [asc[pid] for pid in sorted(asc_ids - rc_ids)],
        "missing_in_app_store_connect": [rc[pid] for pid in sorted(rc_ids - asc_ids)],
        "type_mismatches": type_mismatches,
        "duplicate_asc_product_ids": asc_dupes,
        "duplicate_revenuecat_store_identifiers": rc_dupes,
        "malformed_asc_items": asc_bad,
        "malformed_revenuecat_items": rc_bad,
        "consumable_entitlement_warnings": consumable_entitlements,
    }


def has_issues(report: dict[str, Any]) -> bool:
    return any(
        report[key]
        for key in (
            "missing_in_revenuecat",
            "missing_in_app_store_connect",
            "type_mismatches",
            "duplicate_asc_product_ids",
            "duplicate_revenuecat_store_identifiers",
            "malformed_asc_items",
            "malformed_revenuecat_items",
            "consumable_entitlement_warnings",
        )
    )


def print_markdown(report: dict[str, Any]) -> None:
    print("# App Store Commerce Catalog Drift")
    print()
    print(f"ASC products: {report['asc_count']}")
    print(f"RevenueCat products: {report['revenuecat_count']}")
    print()
    if not has_issues(report):
        print("No catalog drift detected.")
        return

    sections = [
        ("Missing in RevenueCat", "missing_in_revenuecat", "product_id"),
        ("Missing in App Store Connect", "missing_in_app_store_connect", "store_identifier"),
    ]
    for title, key, id_key in sections:
        items = report[key]
        if items:
            print(f"## {title}")
            for item in items:
                label = f" ({item['label']})" if item.get("label") else ""
                print(f"- {item[id_key]}: {item.get('type', 'unknown')}{label}")
            print()

    if report["type_mismatches"]:
        print("## Type Mismatches")
        for item in report["type_mismatches"]:
            print(f"- {item['product_id']}: ASC={item['asc_type']} RevenueCat={item['revenuecat_type']}")
        print()

    if report["consumable_entitlement_warnings"]:
        print("## Consumable Entitlement Warnings")
        for item in report["consumable_entitlement_warnings"]:
            print(f"- {item['product_id']} attached to entitlement {item['entitlement']}")
        print()

    duplicate_sections = [
        ("Duplicate ASC Product IDs", "duplicate_asc_product_ids"),
        ("Duplicate RevenueCat Store Identifiers", "duplicate_revenuecat_store_identifiers"),
    ]
    for title, key in duplicate_sections:
        if report[key]:
            print(f"## {title}")
            for pid in report[key]:
                print(f"- {pid}")
            print()

    malformed_sections = [
        ("Malformed ASC Items", "malformed_asc_items"),
        ("Malformed RevenueCat Items", "malformed_revenuecat_items"),
    ]
    for title, key in malformed_sections:
        if report[key]:
            print(f"## {title}")
            for item in report[key]:
                print(f"- {item}")
            print()


def main() -> int:
    parser = argparse.ArgumentParser(description="Compare local ASC and RevenueCat commerce catalog JSON.")
    parser.add_argument("--asc", required=True, type=Path, help="App Store Connect catalog JSON export")
    parser.add_argument("--revenuecat", required=True, type=Path, help="RevenueCat catalog JSON export")
    parser.add_argument("--json", action="store_true", help="Print JSON instead of Markdown")
    parser.add_argument(
        "--allow-consumable-entitlements",
        action="store_true",
        help="Do not flag consumable products attached to entitlements",
    )
    args = parser.parse_args()

    asc_products, asc_dupes, asc_bad = extract_asc(load_json(args.asc))
    rc_products, rc_dupes, rc_bad, entitlement_products = extract_revenuecat(load_json(args.revenuecat))
    report = build_report(
        asc_products,
        rc_products,
        asc_dupes,
        rc_dupes,
        asc_bad,
        rc_bad,
        entitlement_products,
        args.allow_consumable_entitlements,
    )

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        print_markdown(report)
    return 1 if has_issues(report) else 0


if __name__ == "__main__":
    sys.exit(main())
