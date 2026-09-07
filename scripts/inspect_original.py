#!/usr/bin/env python3
"""Read-only cassette evidence extractor; no emulator or third-party packages.

Usage: python3 scripts/inspect_original.py 'tools/Cloak of Death.cas'
The cassette is not distributed in this repository. Do not parse cas_dump.txt:
its per-record synchronization/checksum bytes interrupt BASIC strings.
"""
import argparse
import hashlib
import json
import struct
from pathlib import Path


def inspect(path):
    raw = path.read_bytes()
    position = 0
    records = []
    while position < len(raw):
        tag = raw[position:position + 4]
        size, _ = struct.unpack_from('<HH', raw, position + 4)
        block = raw[position + 8:position + 8 + size]
        position += 8 + size
        if tag != b'data' or block[:2] != b'UU':
            continue
        if block[2] == 0xfc:
            records.append(block[3:131])
        elif block[2] == 0xfa:
            records.append(block[3:3 + block[130]])
    program = b''.join(records)
    header = struct.unpack_from('<7H', program)
    # Atari SAVE starts at address $100; the file's first fourteen bytes
    # replace sixteen memory bytes. VNTP $110 therefore maps to file offset 14.
    offset = -258
    position = header[4] + offset
    lines = {}
    while position < header[6] + offset:
        number, length = struct.unpack_from('<HB', program, position)
        if length < 3:
            raise ValueError(f'Invalid BASIC line at offset {position}')
        lines[number] = program[position + 3:position + length]
        position += length
    data = []
    for number in (32060, 32070):
        # Statement end offset, DATA token ($01), literal CSV, ATASCII EOL.
        body = lines[number]
        assert body[1] == 1 and body[-1] == 0x9b
        data.extend(map(int, body[2:-1].decode('ascii').split(',')))
    assert len(data) == 53
    nouns = program.index(b'BALL') - 1  # Include the first object ID marker.
    exits = program[nouns + 416:nouns + 416 + 182]
    assert len(exits) == 26 * 7
    # Graphics are not sorted by room ID. The legacy room-1-based extractor
    # dropped room 9's header and most of its drawing. Keep this evidence
    # available independently of that incomplete assets/rooms.bin snapshot.
    hallway_start = program.index(bytes.fromhex('a9 ff 06 8a e4'))
    hall_start = program.index(bytes.fromhex('a1 55 04 08 e2'), hallway_start)
    result = {
        'cassette_sha256': hashlib.sha256(raw).hexdigest(),
        'upstairs_hallway_bytecode_hex': program[hallway_start:hall_start].hex(' '),
        'initial_P_1_to_53': data,
        'exit_columns': ['N', 'S', 'E', 'W', 'U', 'D', 'special'],
        'exits_0_absent_90_conditional': {
            str(room + 1): list(exits[room * 7:room * 7 + 7])
            for room in range(26)
        },
        'tokenized_lines_hex': {
            str(number): lines[number].hex(' ')
            for number in (14, 400, 410, 420, 430, 440, 450, 1410,
                           1450, 1460, 2440, 5610, 6020, 6210, 32100)
        },
    }
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('cassette', type=Path)
    inspect(parser.parse_args().cassette)
