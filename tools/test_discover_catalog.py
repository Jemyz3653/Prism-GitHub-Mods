import hashlib
import io
import json
import unittest
from datetime import date
from unittest.mock import patch
from zipfile import ZipFile

import discover_catalog as catalog


class CatalogTests(unittest.TestCase):
    def test_sample_is_disjoint_and_repeatable(self):
        pages = []

        def search(offset, limit):
            pages.append(offset)
            return {"total_hits": 29741, "hits": [{"project_id": str(i)} for i in range(offset, offset + limit)]}
        with patch.object(catalog, "search", search):
            a = catalog.select(date(2026, 11, 15), 100, 50)
            self.assertEqual(a, catalog.select(date(2026, 11, 15), 100, 50))
        self.assertEqual(tuple(map(len, a)), (100, 50))
        self.assertFalse(set(a[0]) & set(a[1]))
        self.assertGreater(max(pages), 10000)

    def test_source_repository_host_and_path(self):
        self.assertEqual(catalog.source_repo("https://github.com/Some-Owner/Mod.git/tree/main"), "Some-Owner/Mod")
        self.assertIsNone(catalog.source_repo("https://github.com@example.com/Some-Owner/Mod"))
        self.assertIsNone(catalog.source_repo("https://github.com/Some-Owner/.."))

    def test_only_exact_indexed_fabric_jar_is_accepted(self):
        data = io.BytesIO()
        with ZipFile(data, "w") as jar:
            jar.writestr("fabric.mod.json", json.dumps({"id": "example", "depends": {"fabric-api": "*"}}))
        jar = data.getvalue()
        asset = {"name": "example+fabric.jar", "browser_download_url":
                 "https://github.com/Example/ExampleMod/releases/download/v1/example%2Bfabric.jar",
                 "size": len(jar), "state": "uploaded", "digest": "sha256:" + hashlib.sha256(jar).hexdigest()}
        version = {"version_number": "1", "version_type": "release"}
        indexed = {hashlib.sha512(jar).hexdigest(): (version, ["26.3"])}
        release = {"tag_name": "v1", "prerelease": False}
        with patch.object(catalog, "fetch", return_value=jar):
            mod_id, release_row = catalog.inspect_asset(asset, indexed, "Example/ExampleMod", release)
            self.assertEqual(mod_id, "example")
            self.assertEqual(release_row["minecraft"], ["26.3"])
            self.assertEqual(release_row["requires"], {"fabric-api": "*"})
            self.assertIsNone(catalog.inspect_asset(asset, {}, "Example/ExampleMod", release))
            self.assertIsNone(catalog.inspect_asset(asset, indexed, "Other/ExampleMod", release))

    def test_merge_preserves_manual_projects_and_replaces_discovered_project(self):
        manual = {"repo": "Owner/Manual"}
        indexed = {"repo": "Else/Indexed", "name": "Old", "modrinth": "abcd"}
        replacement = {"repo": "Else/Indexed", "name": "New", "modrinth": "abcd"}
        duplicate_manual = {"repo": "owner/manual", "name": "Manual", "modrinth": "efgh"}
        result = catalog.merge({"projects": [manual, indexed]}, [replacement, duplicate_manual])
        self.assertEqual(result["projects"], [manual, replacement])


if __name__ == "__main__":
    unittest.main()
