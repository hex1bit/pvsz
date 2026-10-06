"""Locally add a user-owned GOTY main.pak to an unsigned iPhone/iPad IPA."""
import argparse
import copy
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import struct
import tempfile
import zipfile


def sha256(stream):
    digest = hashlib.sha256()
    for block in iter(lambda: stream.read(1024 * 1024), b''):
        digest.update(block)
    return digest.hexdigest()


def inspect_pak(path):
    # Decode only the directory; preserve the original asset file byte for byte.
    with path.open('rb') as source:
        header = bytes(byte ^ 0xF7 for byte in source.read(4 * 1024 * 1024))
    if len(header) < 8 or struct.unpack_from('<II', header) != (0xBAC04AC0, 0):
        raise ValueError('Unsupported PAK header')
    offset, total, entries = 8, 0, set()
    while True:
        if offset >= len(header):
            raise ValueError('Truncated or oversized PAK index')
        flags = header[offset]
        offset += 1
        if flags & 0x80:
            break
        name_length = header[offset]
        offset += 1
        name = header[offset:offset + name_length].decode('utf-8').replace('\\', '/').lower()
        offset += name_length
        size, _ = struct.unpack_from('<iQ', header, offset)
        offset += 12
        if size < 0:
            raise ValueError('Invalid PAK entry size')
        total += size
        entries.add(name)
    if offset + total != path.stat().st_size:
        raise ValueError('PAK index and payload sizes do not match')
    required = {'properties/default.xml', 'properties/resources.xml', 'properties/lawnstrings.txt'}
    if not required.issubset(entries):
        raise ValueError('This packaging command needs a PAK containing all required properties files')
    with path.open('rb') as source:
        return sha256(source), len(entries)


def bundle(ipa, pak, output):
    if ipa.resolve() == output.resolve():
        raise ValueError('Use a separate output path to preserve the original IPA')
    pak_hash, entry_count = inspect_pak(pak)
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with zipfile.ZipFile(ipa) as source:
            plists = [name for name in source.namelist()
                      if name.startswith('Payload/') and name.count('/') == 2
                      and name.endswith('.app/Info.plist')]
            if len(plists) != 1:
                raise ValueError('Expected one top-level app bundle')
            app = plists[0].removesuffix('Info.plist')
            info = plistlib.loads(source.read(plists[0]))
            if info.get('CFBundleIdentifier') != 'io.github.hex1bit.pvsz.wanzi':
                raise ValueError('Not a WanZi Family IPA')
            if info.get('SDL_FILESYSTEM_BASE_DIR_TYPE') != 'bundle':
                raise ValueError('Rebuild with bundled-resource support before packaging')
            if any(name.startswith(app + '_CodeSignature/') or name == app + 'embedded.mobileprovision'
                   for name in source.namelist()):
                raise ValueError('Bundle resources before Apple signing; input must be unsigned')
            resource_name = app + 'main.pak'
            manifest_name = app + 'WanZiResources.json'
            manifest = {'file': 'main.pak', 'sha256': pak_hash,
                        'bytes': pak.stat().st_size, 'pakEntries': entry_count}
            with tempfile.NamedTemporaryFile(dir=output.parent, suffix='.ipa.tmp', delete=False) as temp:
                temporary = Path(temp.name)
            with zipfile.ZipFile(temporary, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as target:
                for member in source.infolist():
                    if member.filename in (resource_name, manifest_name):
                        continue
                    # Preserve executable modes, symlinks and original bundle metadata.
                    with source.open(member) as original, target.open(copy.copy(member), 'w') as destination:
                        shutil.copyfileobj(original, destination, length=1024 * 1024)
                target.write(pak, resource_name)
                target.writestr(manifest_name, json.dumps(manifest, indent=2) + '\n')
        with zipfile.ZipFile(temporary) as packaged:
            damaged = packaged.testzip()
            if damaged:
                raise ValueError(f'Damaged IPA entry: {damaged}')
            with packaged.open(resource_name) as resource:
                if sha256(resource) != pak_hash:
                    raise ValueError('Bundled PAK checksum mismatch')
        os.replace(temporary, output)
        temporary = None
        with output.open('rb') as installed:
            ipa_hash = sha256(installed)
        report = {'ipa': output.name, 'ipaSha256': ipa_hash, 'ipaBytes': output.stat().st_size,
                  'bundledResources': manifest, 'archiveIntegrity': 'passed',
                  'signed': False, 'devicePlaytest': 'pending'}
        output.with_suffix('.verification.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
        output.with_suffix('.sha256').write_text(f'{ipa_hash}  {output.name}\n', encoding='utf-8')
        print(json.dumps(report, indent=2))
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


if __name__ == '__main__':
    root = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ipa', type=Path, default=root / 'dist/ios/wanzi-family-ios-arm64-unsigned.ipa')
    parser.add_argument('--pak', type=Path, default=root / 'resources/main.pak')
    parser.add_argument('--output', type=Path, default=root / 'dist/ios/wanzi-family-ios-arm64-with-resources-unsigned.ipa')
    arguments = parser.parse_args()
    bundle(arguments.ipa, arguments.pak, arguments.output)
