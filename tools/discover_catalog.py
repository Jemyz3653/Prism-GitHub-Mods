"""Find public GitHub release JARs that match Fabric files indexed by Modrinth."""

import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import date
from hashlib import sha256, sha512
from io import BytesIO
import json
import os
from pathlib import Path
import random
import re
import sys
from urllib.error import HTTPError, URLError
from urllib.parse import quote, unquote, urlencode, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener
from zipfile import BadZipFile, ZipFile

MODRINTH = "https://api.modrinth.com/v2/"
GITHUB = "https://api.github.com/"
AGENT = "Detemkur-Prism-GitHub-Mods/1.0 (github.com/Jemyz3653/Prism-GitHub-Mods)"
ASSET_HOSTS = {"github.com", "release-assets.githubusercontent.com", "objects.githubusercontent.com"}
REPO = re.compile(r"[A-Za-z0-9][A-Za-z0-9-]{0,38}/[A-Za-z0-9_.-]{1,100}")
JAR = re.compile(r"[A-Za-z0-9][A-Za-z0-9.+_-]*\.jar")
MOD = re.compile(r"[a-z][a-z0-9_-]{1,63}")
STABLE_VERSION = re.compile(r"\d+\.\d+(?:\.\d+)?")
MAX_JAR = 32 * 1024 * 1024
MAX_CATALOG = 4 * 1024 * 1024


def host_is_allowed(url, hosts):
    target = urlsplit(url)
    return target.scheme == "https" and target.netloc in hosts


class SafeRedirect(HTTPRedirectHandler):
    def __init__(self, hosts):
        self.hosts = hosts

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        if not host_is_allowed(newurl, self.hosts):
            raise ValueError("Unexpected redirect host")
        request = super().redirect_request(req, fp, code, msg, headers, newurl)
        if request and urlsplit(newurl).netloc != urlsplit(req.full_url).netloc:
            request.remove_header("Authorization")
        return request


def fetch(url, hosts, cap, api=False):
    if not host_is_allowed(url, hosts):
        raise ValueError("Unexpected URL host")
    headers = {"User-Agent": AGENT}
    if api and (token := os.environ.get("GITHUB_TOKEN")):
        headers["Authorization"] = f"Bearer {token}"
    with build_opener(SafeRedirect(hosts)).open(Request(url, headers=headers), timeout=20) as response:
        if not host_is_allowed(response.url, hosts):
            raise ValueError("Unexpected response host")
        if response.headers.get("Content-Length", "").isdigit() and int(response.headers["Content-Length"]) > cap:
            raise ValueError("Response exceeds size limit")
        body = response.read(cap + 1)
    if len(body) > cap:
        raise ValueError("Response exceeds size limit")
    return body


def modrinth(endpoint, **params):
    return json.loads(fetch(MODRINTH + endpoint + "?" + urlencode(params), {"api.modrinth.com"}, 12 * 1024 * 1024))


def github(endpoint):
    return json.loads(fetch(GITHUB + endpoint, {"api.github.com"}, 10 * 1024 * 1024, api=True))


def search(offset, limit):
    return modrinth("search", index="downloads", offset=offset, limit=limit,
                    facets=json.dumps([["project_type:mod"], ["categories:fabric"], ["open_source:true"]]))


def select(when, popular_count, random_count):
    search_page = search(0, max(1, popular_count))
    popular = [hit["project_id"] for hit in search_page["hits"]][:popular_count]
    offset_cap = min(9900, max(0, int(search_page["total_hits"]) - 100))
    offsets = list(range(100, offset_cap + 1, 100))
    rng = random.Random(when.toordinal())
    rng.shuffle(offsets)
    pool = []
    for offset in offsets[:8] if random_count else []:
        pool.extend(hit["project_id"] for hit in search(offset, 100)["hits"])
    pool = sorted(set(pool) - set(popular))
    random_ids = rng.sample(pool, min(random_count, len(pool)))
    return popular, random_ids


def source_repo(url):
    if not url or not host_is_allowed(url, {"github.com", "www.github.com"}):
        return None
    owner, name, *_ = (unquote(urlsplit(url).path).strip("/") + "//").split("/")
    key = f"{owner}/{name.removesuffix('.git')}"
    if not REPO.fullmatch(key) or key.endswith(("/.", "/..")):
        return None
    return key


def has_source(repo, branch):
    tree = github(f"repos/{repo}/git/trees/{quote(branch, safe='')}?recursive=1")
    return any(entry["type"] == "blob" and re.search(r"(?:^|/)src/.*\.(?:java|kt|scala)$", entry["path"])
               for entry in tree.get("tree", []))


def indexed_files(project_id):
    matches = {}
    versions = modrinth(f"project/{project_id}/version", loaders='["fabric"]')
    for version in versions:
        supported = sorted({mc for mc in version["game_versions"] if STABLE_VERSION.fullmatch(mc)})
        if not supported:
            continue
        for file in version["files"]:
            digest = file["hashes"].get("sha512")
            if digest:
                matches.setdefault(file["filename"].lower(), {})[digest] = (version, supported)
    return matches


def inspect_asset(asset, indexed, repo, release):
    name = asset.get("name", "")
    url = asset.get("browser_download_url", "")
    tag = release["tag_name"]
    size = asset.get("size", 0)
    if (not JAR.fullmatch(name) or name.lower().endswith(("-dev.jar", "-sources.jar", "-javadoc.jar"))
            or asset.get("state") != "uploaded" or not 0 < size <= MAX_JAR
            or not host_is_allowed(url, {"github.com"})
            or unquote(urlsplit(url).path).casefold() != f"/{repo}/releases/download/{tag}/{name}".casefold()):
        return None
    raw = fetch(url, ASSET_HOSTS, size)
    content_hash = sha256(raw).hexdigest()
    claimed = asset.get("digest")
    if len(raw) != size or (claimed and claimed != f"sha256:{content_hash}"):
        return None
    match = indexed.get(sha512(raw).hexdigest())
    if not match:
        return None
    version, supported = match
    with ZipFile(BytesIO(raw)) as jar:
        descriptor = jar.getinfo("fabric.mod.json")
        if descriptor.file_size > 128 * 1024:
            return None
        meta = json.loads(jar.read(descriptor))
    mod_id = meta.get("id", "")
    if not MOD.fullmatch(mod_id):
        return None
    depends = meta.get("depends", {})
    if not isinstance(depends, dict):
        return None
    dependencies = {key: value for key, value in depends.items() if key not in {"minecraft", "java", "fabricloader"}}
    return mod_id, {
        "version": version["version_number"],
        "minecraft": supported,
        "loader": "fabric",
        "tag": tag,
        "prerelease": bool(release["prerelease"] or version["version_type"] != "release"),
        "file": name, "url": url, "sha256": content_hash, "bytes": size, "requires": dependencies,
    }


def inspect(project):
    repo = source_repo(project.get("source_url"))
    if not repo:
        return None
    repository = github(f"repos/{repo}")
    if repository.get("private") or not repository.get("size"):
        return None
    repo = repository["full_name"]
    releases = github(f"repos/{repo}/releases?per_page=20")
    if not any(a.get("name", "").lower().endswith(".jar") for r in releases if not r["draft"] for a in r["assets"]):
        return None
    indexed = indexed_files(project["id"])
    found, project_id = [], None
    covered = set()
    for release in sorted(releases, key=lambda r: r["prerelease"]):
        if release["draft"]:
            continue
        for asset in release["assets"]:
            hints = indexed.get(asset["name"].lower())
            if not hints or all(set(versions) <= covered for _, versions in hints.values()):
                continue
            try:
                entry = inspect_asset(asset, hints, repo, release)
            except (HTTPError, URLError, TimeoutError, ValueError, KeyError, BadZipFile) as error:
                print(f"{repo}: skipped asset ({type(error).__name__})", file=sys.stderr)
                continue
            if not entry:
                continue
            mod_id, version = entry
            if project_id and project_id != mod_id:
                continue
            project_id = mod_id
            found.append(version)
            covered.update(version["minecraft"])
            if len(found) >= 8:
                break
        if len(found) >= 8:
            break
    if not found or not has_source(repo, repository["default_branch"]):
        return None
    return {"id": project_id, "name": project["title"][:120], "description": project["description"][:320],
            "repo": repo, "modrinth": project["id"], "releases": found}


def check(project):
    try:
        return inspect(project)
    except HTTPError as error:
        reason = f"HTTP {error.code}"
    except (URLError, TimeoutError, ValueError, KeyError, BadZipFile) as error:
        reason = type(error).__name__
    print(f"{project['id']}: could not check ({reason})", file=sys.stderr)
    return False


def merge(previous, discovered):
    old = previous["projects"]
    manual = [p for p in old if "modrinth" not in p]
    known = {p["repo"].casefold() for p in manual}
    indexed = {p["modrinth"]: p for p in old if "modrinth" in p}
    for item in discovered:
        if item["repo"].casefold() not in known:
            indexed[item["modrinth"]] = item
    return {"schema": 1, "projects": manual + sorted(indexed.values(), key=lambda p: (p["name"].casefold(), p["modrinth"]))}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=Path("mods.json"))
    parser.add_argument("--output", type=Path, default=Path("out/mods.json"))
    parser.add_argument("--popular", type=int, default=100)
    parser.add_argument("--random", type=int, default=50)
    parser.add_argument("--date", type=date.fromisoformat, default=date.today())
    options = parser.parse_args()
    if not 0 <= options.popular <= 100 or not 0 <= options.random <= 50:
        parser.error("Use 0–100 popular and 0–50 random projects")
    popular, sampled = select(options.date, options.popular, options.random)
    ids = popular + sampled
    projects = []
    for start in range(0, len(ids), 50):
        projects.extend(modrinth("projects", ids=json.dumps(ids[start:start + 50])))
    by_id = {p["id"]: p for p in projects}
    with ThreadPoolExecutor(max_workers=5) as pool:
        results = dict(zip(by_id, pool.map(check, by_id.values())))
    found = [p for p in results.values() if p]
    failures = sum(result is False for result in results.values())
    if ids and failures > len(ids) // 4:
        raise RuntimeError(f"Too many failed checks ({failures}/{len(ids)}); keeping the published catalog")
    previous = json.loads(options.input.read_text(encoding="utf-8"))
    merged = merge(previous, found)
    payload = (json.dumps(merged, ensure_ascii=False, separators=(",", ":")) + "\n").encode()
    if len(payload) > MAX_CATALOG:
        raise RuntimeError("Catalog exceeded the launcher size limit")
    options.output.parent.mkdir(parents=True, exist_ok=True)
    temporary = options.output.with_suffix(".tmp")
    temporary.write_bytes(payload)
    temporary.replace(options.output)
    options.output.with_name("discovered.json").write_text(
        json.dumps(found, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    stats = {
        "date": options.date.isoformat(), "popular_checked": len(set(popular) & by_id.keys()),
        "random_checked": len(set(sampled) & by_id.keys()), "verified": len(found), "failures": failures,
        "total": len(merged["projects"]), "new": len(merged["projects"]) - len(previous["projects"]),
    }
    options.output.with_name("stats.json").write_text(json.dumps(stats) + "\n", encoding="utf-8")
    print(json.dumps(stats))


if __name__ == "__main__":
    main()
