"""Write a Fallout 76 BA2 archive (BTDX version 1, GNRL) from a directory.

usage: python tools/ba2pack.py <out.ba2> <srcdir>

Every file under <srcdir> is stored under its relative path with forward slashes
(e.g. interface/VendorBoard.swf), zlib-compressed. Name and directory hashes are the
CRC32 (polynomial 0xEDB88320, init 0, no final xor) of the lower-case stem and directory.
"""
import os, struct, sys, zlib

_TABLE = []
for _i in range(256):
    _c = _i
    for _ in range(8):
        _c = (_c >> 1) ^ 0xEDB88320 if _c & 1 else _c >> 1
    _TABLE.append(_c)


def ba2_hash(s):
    h = 0
    for b in s.encode('utf-8'):
        h = _TABLE[(h ^ b) & 0xFF] ^ (h >> 8)
    return h & 0xFFFFFFFF


def pack(out_path, src_dir):
    files = []
    for root, _dirs, names in os.walk(src_dir):
        for n in sorted(names):
            full = os.path.join(root, n)
            rel = os.path.relpath(full, src_dir).replace(os.sep, '/')
            files.append((rel, open(full, 'rb').read()))
    if not files:
        raise SystemExit('no files under ' + src_dir)
    header_len = 24
    rec_len = 36
    payload_off = header_len + rec_len * len(files)
    records = []
    payloads = []
    off = payload_off
    for rel, data in files:
        d, base = (rel.rsplit('/', 1) + [''])[:2] if '/' in rel else ('', rel)
        stem, ext = (base.rsplit('.', 1) + [''])[:2] if '.' in base else (base, '')
        packed = zlib.compress(data, 9)
        records.append(struct.pack('<I4sIIQIII', ba2_hash(stem.lower()), ext.lower().encode('ascii')[:4].ljust(4, b'\0'),
                                   ba2_hash(d.lower()), 0x00100100, off, len(packed), len(data), 0xBAADF00D))
        payloads.append(packed)
        off += len(packed)
    name_table = b''.join(struct.pack('<H', len(rel.encode('utf-8'))) + rel.encode('utf-8') for rel, _ in files)
    header = struct.pack('<4sI4sIQ', b'BTDX', 1, b'GNRL', len(files), off)
    with open(out_path, 'wb') as f:
        f.write(header)
        f.write(b''.join(records))
        f.write(b''.join(payloads))
        f.write(name_table)
    for rel, data in files:
        print('  %s  %d bytes' % (rel, len(data)))
    print('%d files -> %s' % (len(files), out_path))


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(2)
    pack(sys.argv[1], sys.argv[2])
