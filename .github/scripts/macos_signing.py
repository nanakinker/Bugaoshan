"""Select upstream tags for signing, or fetch their verified notarized DMG."""

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tool"))
from macos_dmg import TAG_RE, asset_name, check_manifest, distribution_version

SIGNING_REPOSITORY = "wjlfish/Bugaoshan-macos"


def run(*args, cwd=None, check=True):
    return subprocess.run(args, cwd=cwd, check=check, capture_output=True, text=True)


def git(source, *args):
    return run("git", *args, cwd=source).stdout.strip()


def output(values):
    text = "".join(f"{key}={value}\n" for key, value in values.items())
    with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as stream:
        stream.write(text)
    print(text, end="")


def select(source, requested):
    tags = git(source, "for-each-ref", "--sort=-creatordate", "--format=%(refname:short)", "refs/tags/v*").splitlines()
    if requested:
        if not TAG_RE.fullmatch(requested) or requested not in tags:
            raise ValueError("Requested upstream tag does not exist")
        tags = [requested]
    for tag in tags:
        if not TAG_RE.fullmatch(tag):
            continue
        marker = run("git", "show", f"{tag}:.github/macos-signing.json", cwd=source, check=False)
        if marker.returncode or json.loads(marker.stdout).get("schema") != 1:
            continue
        existing = run("gh", "release", "view", f"macos-{tag}", "--repo", SIGNING_REPOSITORY,
                       "--json", "isDraft", check=False)
        if not existing.returncode and not json.loads(existing.stdout)["isDraft"]:
            continue
        sha = git(source, "rev-parse", f"{tag}^{{commit}}")
        # Sign only commits already integrated into an upstream release branch.
        if not any(run("git", "merge-base", "--is-ancestor", sha, f"origin/{branch}",
                       cwd=source, check=False).returncode == 0 for branch in ("main", "preview")):
            raise ValueError("Release tag is outside upstream main/preview")
        # The store's released Mac version/build may already exceed Android's
        # preview baseline. Both Mac channels share this explicit release pair.
        version, build = distribution_version(json.loads(marker.stdout))
        return {"tag": tag, "sha": sha, "version": version,
                "build": build, "ready": "true"}
    return {"ready": "false"}


def fetch(args):
    asset = asset_name(args.tag)
    args.output.mkdir(parents=True, exist_ok=True)
    deadline = time.monotonic() + args.timeout
    while True:
        release = run("gh", "release", "view", f"macos-{args.tag}", "--repo", SIGNING_REPOSITORY,
                      "--json", "isDraft,assets", check=False)
        if release.returncode == 0:
            metadata = json.loads(release.stdout)
            names = {entry["name"] for entry in metadata["assets"]}
            if not metadata["isDraft"] and {asset, "macos-manifest.json"}.issubset(names):
                run("gh", "release", "download", f"macos-{args.tag}", "--repo", SIGNING_REPOSITORY,
                    "--pattern", asset, "--pattern", "macos-manifest.json", "--dir", str(args.output))
                manifest = json.loads((args.output / "macos-manifest.json").read_text())
                check_manifest(manifest, args.output / asset, args.tag, args.sha, args.version, args.build)
                return
        if time.monotonic() >= deadline:
            raise TimeoutError("Signed macOS release is not ready; refusing unsigned fallback")
        print(f"Waiting for notarized {args.tag} in {SIGNING_REPOSITORY}...", flush=True)
        time.sleep(60)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["select", "fetch"])
    parser.add_argument("--source", type=Path, default=Path("source"))
    parser.add_argument("--tag", default="")
    parser.add_argument("--sha")
    parser.add_argument("--version")
    parser.add_argument("--build")
    parser.add_argument("--output", type=Path, default=Path("macos-release"))
    parser.add_argument("--timeout", type=int, default=5400)
    args = parser.parse_args()
    if args.mode == "select":
        output(select(args.source, args.tag))
    else:
        if not args.version or not args.build:
            args.version, args.build = distribution_version(json.loads(Path(".github/macos-signing.json").read_text()))
        fetch(args)


if __name__ == "__main__":
    main()
