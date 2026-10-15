#!/usr/bin/env python3
"""Run offline macOS fixtures, with owner Keychain/profile access denied."""

import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
from datetime import datetime, timedelta, timezone


ROOT = Path(__file__).resolve().parents[3]
OUTPUT = ROOT / ".build/codesign-tests"
SOURCE = Path(__file__).with_name("codesign.swift")


def run(*args, expected=0, **kwargs):
    result = subprocess.run([str(x) for x in args], capture_output=True, text=True, **kwargs)
    if result.returncode != expected:
        raise AssertionError(f"{args[0]}: expected {expected}, got {result.returncode}\n"
                             f"{result.stdout}{result.stderr}")
    return result.stdout


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    if sys.argv[1:] != ["--sandboxed"]:
        # Keep the compiler's temporary files in the same ignored producer directory.
        temporary = OUTPUT / "tmp"
        temporary.mkdir(exist_ok=True)
        environment = dict(os.environ, TMPDIR=str(temporary))
        profile = ['(version 1)', '(allow default)', '(deny network*)']
        for path in [Path.home() / "Library/Keychains", Path("/Library/Keychains"),
                     Path("/System/Library/Keychains"),
                     Path.home() / "Library/Developer/Xcode/UserData/Provisioning Profiles",
                     Path.home() / "Library/MobileDevice/Provisioning Profiles"]:
            profile.append(f'(deny file-read* file-write* (subpath {json.dumps(str(path))}))')
        subprocess.run(["/usr/bin/sandbox-exec", "-p", "\n".join(profile),
                        sys.executable, "-B", __file__, "--sandboxed"],
                       env=environment, check=True)
        return

    binary = OUTPUT / "codesign"
    run("xcrun", "swiftc", "-module-cache-path", OUTPUT / "module-cache", SOURCE, "-o", binary)
    print(run(binary, "self-test"), end="")
    fixtures = OUTPUT / "fixtures"
    fixtures.mkdir(exist_ok=True)
    key, cert = fixtures / "key.pem", fixtures / "cert.pem"
    run("/usr/bin/openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "2",
        "-subj", "/CN=Code Signing Fixture", "-keyout", key, "-out", cert)
    der = fixtures / "cert.der"
    run("/usr/bin/openssl", "x509", "-in", cert, "-outform", "DER", "-out", der)
    expires = (datetime.now(timezone.utc) + timedelta(days=1)).replace(tzinfo=None)
    payload = {
        "UUID": "00000000-0000-0000-0000-000000000001", "Name": "Fixture",
        "Platform": ["OSX"], "TeamIdentifier": ["TEAM"], "ApplicationIdentifierPrefix": ["PREFIX"],
        "ExpirationDate": expires, "ProvisionedDevices": ["fixture-device"],
        "DeveloperCertificates": [der.read_bytes()],
        "Entitlements": {"com.apple.application-identifier": "PREFIX.*",
                         "com.apple.developer.team-identifier": "TEAM",
                         "keychain-access-groups": ["PREFIX.*"]},
    }
    plist = fixtures / "profile.plist"
    plist.write_bytes(plistlib.dumps(payload))
    signed = fixtures / "signed.provisionprofile"
    run("/usr/bin/openssl", "smime", "-sign", "-binary", "-nodetach", "-in", plist,
        "-signer", cert, "-inkey", key, "-outform", "DER", "-out", signed)
    (fixtures / "empty.provisionprofile").write_bytes(b"")
    # RFC 5652 ContentInfo containing bare data: valid CMS with no signer.
    def asn1(tag, content):
        size = len(content)
        length = bytes([size]) if size < 128 else bytes([0x82]) + size.to_bytes(2, "big")
        return bytes([tag]) + length + content
    data_oid = bytes.fromhex("06092a864886f70d010701")
    unsigned = asn1(0x30, data_oid + asn1(0xA0, asn1(0x04, plist.read_bytes())))
    (fixtures / "unsigned.provisionprofile").write_bytes(unsigned)
    corrupt = signed.read_bytes().replace(b"fixture-device", b"changed-device", 1)
    assert corrupt != signed.read_bytes()
    (fixtures / "corrupt.provisionprofile").write_bytes(corrupt)

    source = fixtures / "main.c"
    source.write_text("int main(void) { return 0; }\n")
    executable = fixtures / "fixture-tool"
    run("xcrun", "clang", source, "-o", executable)
    app = fixtures / "Fixture.app"
    macos = app / "Contents/MacOS"
    macos.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(executable, macos / "fixture-tool")
    (macos / "fixture-tool").chmod(0o755)
    (app / "Contents/Info.plist").write_bytes(plistlib.dumps({
        "CFBundleIdentifier": "com.example.fixture", "CFBundleExecutable": "fixture-tool",
        "CFBundlePackageType": "APPL", "CFBundleVersion": "1",
    }))
    shutil.copyfile(signed, app / "Contents/embedded.provisionprofile")
    resource = app / "Contents/Resources/value"
    resource.parent.mkdir(exist_ok=True)
    resource.write_text("original")
    run("/usr/bin/codesign", "--force", "--sign", "-", "--timestamp=none", app)
    run("/usr/bin/codesign", "--verify", "--strict", "--all-architectures", app)
    tampered = fixtures / "Tampered.app"
    shutil.copytree(app, tampered, dirs_exist_ok=True)
    (tampered / "Contents/Resources/value").write_text("tampered")
    run("/usr/bin/codesign", "--verify", "--strict", tampered, expected=1)
    for name, value in [("Installed.app", "old"), ("Replacement.app", "new")]:
        path = fixtures / name
        path.mkdir(exist_ok=True)
        (path / "value").write_text(value)
    print(run(binary, "self-test", "--fixtures", fixtures), end="")

    # These usage errors must stop before any identity/profile discovery.
    invalid = [[], ["verify", "--bundle"], ["verify", "--profile", "12345678"],
               ["verify", "--bundle", "one", "--bundle", "two"],
               ["select-profile", "--bundle-id", "com.example.*"],
               ["select-profile", "--bundle-id", "com.example.tool", "--identity", ""],
               ["select-profile", "--bundle-id", "com.example.tool", "--profile", "bad"],
               ["self-test", "--json"], ["audit", "--within-days", "-1"]]
    for args in invalid:
        run(binary, *args, expected=64)
    checks = json.loads(run(binary, "verify", "--bundle", app, "--json", expected=1))
    assert checks["ok"] is False
    assert any(c["name"] == "signer-current" and not c["ok"] for c in checks["checks"])
    assert any(c["name"] == "signature" and c["ok"] for c in checks["checks"])
    broken = json.loads(run(binary, "verify", "--bundle", tampered, "--json", expected=1))
    assert any(c["name"] == "signature" and not c["ok"] for c in broken["checks"])
    run(binary, "sign", "--bundle-id", "com.example.tool", "--binary", fixtures / "missing",
        "--output", fixtures / "Output.app", expected=1)
    print(f"offline_fixture_test=ok usage_cases={len(invalid)} "
          "isolation=network-keychains-profiles-denied")


if __name__ == "__main__":
    main()
