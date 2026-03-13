# Cassette Loading Map - Cloak of Death

## Loading Sequence

### Phase 1: CLOAD (Blocks 1-113)
The BASIC program is loaded by CLOAD, which includes:
- The BASIC source code
- **String data containing machine code routines:**
  - `CLS$` (26 bytes) - Clear screen routine
  - `FIND$` (126 bytes) - FIND graphics search routine
  - `GR$` (295 bytes) - **DRAW graphics routine**

Line 2 of BASIC sets up pointers:
```
2  FIND=ADR(FIND$):DRAW=ADR(GR$):CLS=ADR(CLS$)
```

**Key Insight**: The assembly routines are **embedded in BASIC string variables**, not loaded to fixed addresses!

### Phase 2: Runtime Data Load (Blocks 114-195)
After CLOAD, when the program RUNs, line 30010-30060 loads additional data via GOSUB 34:

```basic
30010 ADDR=PEEK(134)+256*PEEK(135):NUM=888:AUX=7:GOSUB 34
30020 ADDR=ADR(O$):NUM=3102:AUX=C7:GOSUB 34
30030 ADDR=35972:NUM=172:GOSUB 34
30040 ADDR=35747:NUM=225:GOSUB 34
30050 ADDR=1536:NUM=256:GOSUB 34
30060 ADDR=30000:NUM=5388:GOSUB 34
```

#### Load #1: 888 bytes
- **Destination**: Variable table start (PEEK(134)+256*PEEK(135))
- **Purpose**: Initial game state data
- **Cassette chunks**: ~7 chunks × 128 bytes

#### Load #2: 3102 bytes to O$ string
- **Destination**: ADR(O$) - Object/location string array
- **Size**: 3102 bytes
- **Cassette chunks**: ~24 chunks

#### Load #3: 172 bytes to $8C94
- **Destination**: Address 35972 ($8C94)
- **Purpose**: Unknown auxiliary data
- **Cassette chunks**: 2 chunks

#### Load #4: 225 bytes to $8BA3
- **Destination**: Address 35747 ($8BA3)
- **Purpose**: **FILL ROUTINE** - Called by C9/CA commands (JSR $8BA3)
- **Cassette chunks**: 2 chunks (148-149)
- **Contains**: Fill seed calculation and scanline fill algorithm
- **Status**: ✅ Extracted and disassembled (see fill_routine.asm)

#### Load #5: 256 bytes to $0600
- **Destination**: Address 1536 ($0600)
- **Purpose**: Bytecode interpreter utilities
- **Cassette chunks**: 2 chunks
- **Contains**: READ_BYTE subroutine and helper functions

#### Load #6: 5388 bytes to $7530
- **Destination**: Address 30000 ($7530)
- **Purpose**: **FIND graphics bytecode data** (room drawings)
- **Size**: 5388 bytes
- **Cassette chunks**: ~42 chunks

## String Data Location

The machine code routines are in the **BASIC program's string data**, loaded during CLOAD (blocks 1-113):

- **CLS$** (26 bytes): Clear screen assembly routine
- **FIND$** (126 bytes): FIND search assembly routine
- **GR$** (295 bytes): **DRAW graphics rendering assembly routine**

### Finding the Routines

The string data is embedded in the BASIC program cassette image. To find it:

1. Look for the BASIC program data in early chunks (1-113)
2. The string data follows the BASIC tokenized code
3. Search for:
   - 26-byte sequence (CLS$)
   - 126-byte sequence (FIND$)
   - 295-byte sequence (GR$) ← **This is the DRAW routine!**

## Chunk Calculation

With 128-byte data chunks:
- **Blocks 1-113**: BASIC program + string data (CLS$, FIND$, GR$)
- **Blocks 114+**: Runtime data loads

### Runtime Load Chunk Mapping

Starting at chunk 114:
- **Chunks 114-120**: 888 bytes (initial game state)
- **Chunks 121-145**: 3102 bytes (O$ object/location strings)
- **Chunks 146-147**: 172 bytes ($8C94 auxiliary data)
- **Chunks 148-149**: 225 bytes ($8BA3 FILL routine) ✅ Extracted
- **Chunks 150-151**: 256 bytes ($0600 bytecode utilities)
- **Chunks 152-193**: 5388 bytes ($7530 FIND graphics bytecode)

**Total**: ~80 chunks for runtime data (114-193)

## Machine Code Routines Found

### DRAW Routine (with C9/CA handlers)
- **Location**: Chunks 144-152 (overlapping with runtime loads)
- **Memory address**: $4881 (not directly loaded, part of string data)
- **Size**: 295 bytes (GR$ string)
- **Status**: ✅ Extracted and disassembled (see draw_routine.asm)
- **Contains**:
  - Bytecode interpreter main loop
  - C9 command handler at $48F9
  - CA command handler at $491C
  - Calls to fill routine at $8BA3

### Fill Subroutine
- **Location**: Chunks 148-149
- **Memory address**: $8BA3 (load #4)
- **Size**: 225 bytes
- **Status**: ✅ Extracted and disassembled (see fill_routine.asm)
- **Contains**:
  - 85 bytes data tables ($8BA3-$8BF7)
  - Fill seed calculation ($8BF8-$8C15)
  - Scanline fill algorithm ($8C16+)

## Analysis Complete

All C9/CA command code has been successfully extracted and disassembled. See the following files:
- **C9_CA_COMMANDS_FINAL.md** - Complete specification
- **draw_routine.asm** - DRAW routine with C9/CA handlers
- **fill_routine.asm** - Fill algorithm subroutine
