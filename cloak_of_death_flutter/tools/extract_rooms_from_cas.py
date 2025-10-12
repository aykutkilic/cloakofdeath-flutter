#!/usr/bin/env python3
"""
Extract room bytecode data from Cloak of Death cassette file.

CAS file format:
- Each data chunk has a 3-byte header: 55 55 FC
- Each chunk contains up to 128 bytes of data
- Each chunk ends with a 1-byte checksum
- Total chunk size = 3 (header) + 128 (data) + 1 (checksum) = 132 bytes

This script extracts only the actual data bytes, removing headers and checksums.
"""

import sys
import struct
from pathlib import Path


def extract_data_from_cas(cas_path, output_path):
    """Extract room data from CAS file, removing chunk headers and checksums."""

    with open(cas_path, 'rb') as f:
        cas_data = f.read()

    print(f"CAS file size: {len(cas_data)} bytes")

    # Find the start of room data by searching for the first room marker (0xA1)
    # Room 1 starts with: A1 55 04 08 E2 ...
    room_data_start = None
    for i in range(len(cas_data) - 5):
        if cas_data[i:i+5] == b'\xa1\x55\x04\x08\xe2':
            room_data_start = i
            print(f"Found room data at offset {i} (0x{i:04X})")
            break

    if room_data_start is None:
        print("ERROR: Could not find room data marker (0xA1 55 04 08 E2)")
        return False

    # Back up to find the chunk header before room data
    # Look for the nearest "55 55 FC" before room_data_start
    chunk_start = room_data_start
    while chunk_start > 0:
        if cas_data[chunk_start:chunk_start+3] == b'\x55\x55\xfc':
            print(f"Found chunk header at offset {chunk_start} (0x{chunk_start:04X})")
            break
        chunk_start -= 1

    if chunk_start == 0:
        print("ERROR: Could not find chunk header before room data")
        return False

    # Extract all data chunks from this point until we find the end marker
    # End is marked by a sequence of 0x00 bytes or reaching EOF
    extracted_data = bytearray()
    pos = chunk_start
    chunk_num = 0
    consecutive_null_chunks = 0

    while pos < len(cas_data):
        # Check for chunk header
        if pos + 132 > len(cas_data):
            print(f"Reached end of file at offset {pos}")
            break

        # Check if we have a chunk header
        if cas_data[pos:pos+3] == b'\x55\x55\xfc':
            # Extract 128 bytes of data (skip 3-byte header, ignore 1-byte checksum)
            data_start = pos + 3
            data_end = pos + 131  # 3 + 128
            chunk_data = cas_data[data_start:data_end]

            # Check if chunk is all zeros (end of data)
            if chunk_data == b'\x00' * 128:
                consecutive_null_chunks += 1
                if consecutive_null_chunks >= 2:
                    print(f"Found {consecutive_null_chunks} consecutive null chunks at offset {pos}, stopping")
                    break
            else:
                consecutive_null_chunks = 0

            extracted_data.extend(chunk_data)
            chunk_num += 1
            pos += 132  # Move to next chunk

            if chunk_num % 10 == 0:
                print(f"Processed {chunk_num} chunks, extracted {len(extracted_data)} bytes")
        else:
            # Not a valid chunk header, try next byte
            print(f"WARNING: Expected chunk header at {pos} (0x{pos:04X}), got {cas_data[pos:pos+3].hex()}")
            print(f"Trying to find next chunk...")

            # Search for next chunk header
            found_next = False
            for search_pos in range(pos + 1, min(pos + 200, len(cas_data) - 3)):
                if cas_data[search_pos:search_pos+3] == b'\x55\x55\xfc':
                    print(f"Found next chunk header at {search_pos} (0x{search_pos:04X})")
                    pos = search_pos
                    found_next = True
                    break

            if not found_next:
                print(f"Could not find next chunk header, stopping")
                break

    print(f"\nTotal chunks processed: {chunk_num}")
    print(f"Total data extracted: {len(extracted_data)} bytes")

    # Write to output file
    with open(output_path, 'wb') as f:
        f.write(extracted_data)

    print(f"\nWrote {len(extracted_data)} bytes to {output_path}")

    # Show first 32 bytes for verification
    print(f"\nFirst 32 bytes:")
    print(' '.join(f'{b:02x}' for b in extracted_data[:32]))

    # Verify room markers
    print(f"\nSearching for room markers (0xA0-0xBB):")
    for i in range(len(extracted_data)):
        if 0xA0 <= extracted_data[i] <= 0xBB:
            room_id = extracted_data[i] - 0xA0
            print(f"  Room {room_id:2d} marker at offset {i:5d} (0x{i:04X}): {extracted_data[i]:02X}")
            if i + 16 < len(extracted_data):
                print(f"    Next 16 bytes: {' '.join(f'{b:02x}' for b in extracted_data[i:i+16])}")

    return True


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python3 extract_rooms_from_cas.py <input.cas> <output.bin>")
        sys.exit(1)

    cas_file = Path(sys.argv[1])
    output_file = Path(sys.argv[2])

    if not cas_file.exists():
        print(f"ERROR: CAS file not found: {cas_file}")
        sys.exit(1)

    success = extract_data_from_cas(cas_file, output_file)
    sys.exit(0 if success else 1)
