# DRAW Routine Disassembly Analysis

Complete disassembly and analysis of the DRAW graphics bytecode interpreter from the original Atari "Cloak of Death" game.

## Files

### Documentation

- **DRAW Algorithm.md** - **START HERE** - Complete DRAW algorithm specification
  - All 7 bytecode commands (coordinates, C8, C9, CA, CB, CC, CD-D0)
  - Complete initialization and main loop analysis
  - Memory map and subroutine addresses
  - Offset byte encoding for fill commands
  - Bytecode examples and implementation guide

- **FILL_ROUTINE_ANALYSIS.md** - Fill algorithm deep dive
  - Fill seed calculation ($8BF8)
  - Scanline fill algorithm details
  - Data table structure

- **cassette_map.md** - Cassette tape structure
  - Loading sequence documentation
  - Chunk mapping with extraction status
  - Memory addresses for each load

### Disassembled Code

- **draw_routine.asm** - DRAW routine (295 bytes at $4881)
  - Complete bytecode interpreter
  - All command handlers (C8, C9, CA, CB, CC, CD-D0)
  - Polyline drawing logic
  - Source: Cassette chunks 144-152

- **draw_routine.bin** - DRAW routine binary (295 bytes)

- **fill_routine.asm** - Fill subroutine (225 bytes at $8BA3)
  - Called by C9/CA commands
  - Fill seed calculation
  - Scanline fill algorithm
  - Source: Cassette chunks 148-149

- **fill_routine.bin** - Fill routine binary (225 bytes)

### Tools

- **disassemble_6502.py** - 6502 disassembler utility
  - Generates .asm files from .bin files
  - Reusable for other 6502 code

## Command Summary

| Command | Format | Description |
|---------|--------|-------------|
| **< 0xA1** | `X Y` | Draw line to (X,Y) or start polyline |
| **0xC8** | `C8` | No-op/continue |
| **0xC9** | `C9 offset` | Close polygon and fill (current color) |
| **0xCA** | `CA color offset` | Close polygon and fill (specified color) |
| **0xCB** | `CB X Y` | Move to position without drawing |
| **0xCC** | `CC color X Y` | Set color and move to position |
| **0xCD-0xD0** | `CD+n` | Set color (0xCD=0, 0xCE=1, 0xCF=2, 0xD0=3) |

## Key Discoveries

1. **Polyline State Machine**: First coordinate pair starts a polyline and becomes vertex0. Subsequent coordinates draw connected lines automatically.

2. **Offset Byte Encoding** (C9/CA): Single byte encodes fill seed position relative to vertex0
   ```
   Format: XXXXYYYY
   X offset: high nibble (0-15)
   Y offset: low nibble (0-15)
   seed = vertex0 + (x_offset, y_offset)
   ```

3. **Color Stack**: Two color registers ($06F2 current, $06F3 saved) enable temporary color changes with automatic restoration.

4. **Compact Encoding**: Commands ≥0xA1, coordinates <0xA1 allows dense bytecode without explicit draw commands.

## Source Data

Extracted from original cassette tape:
- **Cassette file**: `../Cloak of Death.cas`
- **Dump file**: `../cas_dump.txt`
- **DRAW routine**: Chunks 144-152 → 295 bytes at $4881
- **Fill routine**: Chunks 148-149 → 225 bytes at $8BA3

## Implementation Guide

Read **C9_CA_COMMANDS_FINAL.md** for:
- Complete command dispatch logic
- Memory map and variable usage
- Bytecode parsing state machine
- Example sequences
- Flutter implementation notes
