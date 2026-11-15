"""Build a catalog from public GitHub releases and the Fabric JAR descriptors."""
import concurrent.futures
import hashlib
import io
import json
from pathlib import Path
import urllib.request
import zipfile

OWNER = "Jemyz3653"
PROJECTS = {
    "LilyBloom": "Flowering lily pads, new sizes, and pottable water lilies.",
    "BloomDepth": "3D models for vanilla flowers and flowering plants.",
    "CivicCraft": "Furniture for homes, shops, and museums.",
    "CardboardStands": "Freestanding and wall-mounted displays for custom PNGs.",
}

def request(url):
    with urllib.request.urlopen(urllib.request.Request(url,headers={"User-Agent":"Prism-GitHub-Mods"}), timeout=35) as r:
        return r.read()

def project(item):
    repo, summary = item
    key = f"{OWNER}/{repo}"
    releases = json.loads(request(f"https://api.github.com/repos/{key}/releases?per_page=100"))
    versions = []
    title = mod_id = None
    for release in releases:
        if release["draft"]:
            continue
        for asset in release["assets"]:
            name = asset["name"]
            if not name.endswith(".jar") or name.endswith(("-sources.jar", "-javadoc.jar", "-dev.jar")):
                continue
            url = asset["browser_download_url"]
            digest = asset["digest"].removeprefix("sha256:")
            raw = request(url)
            if hashlib.sha256(raw).hexdigest() != digest or len(raw) != asset["size"]:
                raise ValueError(f"Release asset changed: {url}")
            with zipfile.ZipFile(io.BytesIO(raw)) as jar:
                meta = json.loads(jar.read("fabric.mod.json"))
            title = title or meta["name"]
            mod_id = mod_id or meta["id"]
            minecraft = meta["depends"]["minecraft"]
            if minecraft not in {"26.3", "~26.3"} or meta["id"] != mod_id:
                raise ValueError(f"Catalog needs an explicit version mapping for {url}")
            ecosystem = {"minecraft", "java", "fabricloader"}
            requires = {k:v for k,v in meta["depends"].items() if k not in ecosystem}
            versions.append({
                "version": meta["version"], "minecraft": ["26.3"], "loader": "fabric",
                "tag": release["tag_name"], "prerelease": release["prerelease"],
                "file": name, "url": url, "sha256": digest, "bytes": asset["size"],
                "requires": requires,
            })
    return {"id":mod_id, "name":title, "description":summary, "repo":key,"releases":versions}

if __name__ == '__main__':
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        projects = list(pool.map(project,PROJECTS.items()))
    data = {"schema":1,"projects":projects}
    (Path(__file__).resolve().parents[1]/"mods.json").write_text(json.dumps(data,indent=2,ensure_ascii=False)+"\n")
