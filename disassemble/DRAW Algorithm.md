# DRAW Algorithm - Complete Disassembly Analysis

## Overview

The DRAW routine is the graphics bytecode interpreter for "Cloak of Death". It reads bytecode commands from memory and renders vector graphics by drawing lines, filling polygons, and managing colors.

**Location**: 295 bytes at $4881 (extracted from cassette chunks 144-152)
**Entry Point**: $4881 (called from BASIC via `USR(DRAW, bytecode_address)`)

## Bytecode Command Set

| Command | Format | Description |
|---------|--------|-------------|
| **< 0xA1** | `X Y` | Draw line to (X,Y) or start polyline |
| **0xC8** | `C8` | End/continue (no-op) |
| **0xC9** | `C9 offset` | Close polygon and fill (current color) |
| **0xCA** | `CA color offset` | Close polygon and fill (specified color) |
| **0xCB** | `CB X Y` | Move to position (X,Y) without drawing |
| **0xCC** | `CC color X Y` | Set color and move to position |
| **0xCD-0xD0** | `CD+n` | Set color (0xCD=color 0, 0xCE=color 1, 0xCF=color 2, 0xD0=color 3) |

## Initialization ($4881-$48C4)

```assembly
4881: CLI                      ; Enable interrupts
4882: LDA #$8D / STA $59       ; Setup pointer high byte
4886: LDA #$07 / STA $57       ; Setup AUX value
488A: LDA #$01                 ; Initialize color to 1
488C: STA $06F2                ; Store current color
488F: STA $06F3                ; Store saved color

; Retrieve bytecode address from stack (passed from BASIC USR() call)
4893: PLA / PLA / STA $CC      ; Get high byte of bytecode address
4897: PLA / STA $CB            ; Get low byte of bytecode address

; Setup screen buffer pointer
489A: LDA $58 / STA $CE        ; Copy to working pointer
489E: LDA $59 / STA $CF

; Clear screen buffer (4096 bytes = 16 pages * 256 bytes)
48A2: JSR $0600                ; Read byte (but why here?)
48A5: LDX #$0F                 ; 16 pages
48A7: LDY #$00
48A9: STA ($CE),Y              ; Clear byte
48AB: INY
48AC: BNE $48A9                ; Loop 256 times
48AE: INC $CF                  ; Next page
48B0: DEX
48B1: BNE $48A9                ; Loop 16 times

; Read graphics mode setup
48B3: JSR $0600 / STA $02C4    ; Read graphics mode 1
48B9: JSR $0600 / STA $02C5    ; Read graphics mode 2
48BF: JSR $0600 / STA $02C6    ; Read graphics mode 3
```

**Result**: Screen buffer cleared, bytecode pointer initialized

## Main Command Loop ($48C5-$49A7)

### Command Dispatch

```assembly
48C5: JSR $0600                ; Read command byte
48C8: CMP #$A1                 ; Command or coordinate?
48CA: BCS $48F9                ; If >= 0xA1, check commands

; COORDINATE HANDLER (value < 0xA1)
48CC: STA $06E3                ; Store as current X
48CF: STA $06E7                ; Store as vertex0 X (first point)
48D2: JSR $0600                ; Read Y coordinate
48D5: STA $06E4                ; Store as current Y
48D8: STA $06E8                ; Store as vertex0 Y
48DB: JSR $060F                ; Setup for drawing
48DE: JSR $0668                ; Additional setup

; POLYLINE LOOP - Read subsequent points and draw lines
48E1: JSR $0600                ; Read next byte
48E4: CMP #$A1                 ; Another coordinate?
48E6: BCS $48F9                ; No, it's a command - exit loop
48E8: STA $06E5                ; Store as line endpoint X
48EB: JSR $0600                ; Read endpoint Y
48EE: STA $06E6                ; Store as line endpoint Y
48F1: JSR $8BC1                ; Draw line from current to endpoint
48F4: CLC
48F5: BCC $48E1                ; Continue reading points
```

**Key Insight**: The first coordinate pair starts a polyline and becomes vertex0. Subsequent coordinates draw lines from the previous point, creating a connected path.

### Command Handlers

#### 0xC9 - Close and Fill (Current Color)

**Location**: $48F9 | **Format**: `C9 offset_byte`

```assembly
48F9: CMP #$C9 / BNE $491B     ; Check if C9
48FD: LDA $06E7 / STA $06E5    ; Copy vertex0 X to endpoint
4903: LDA $06E8 / STA $06E6    ; Copy vertex0 Y to endpoint
4909: JSR $8BC1                ; Draw closing line
490C: JSR $8BA3                ; Call fill routine
491A: BCC $48F8                ; Return to main loop
```

#### 0xCA - Close and Fill (Specified Color)

**Location**: $491C | **Format**: `CA color offset_byte`

```assembly
491C: CMP #$CA / BNE $4944     ; Check if CA
4920: LDA $06E7 / STA $06E5    ; Copy vertex0 X to endpoint
4926: LDA $06E8 / STA $06E6    ; Copy vertex0 Y to endpoint
492C: JSR $8BC1                ; Draw closing line
492F: JSR $0600                ; Read color parameter
4932: STA $06F2                ; Set as current color
4935: JSR $8BA3                ; Call fill routine
4938: JSR $0688                ; Post-fill processing
493B: LDA $06F3                ; Restore previous color
493E: STA $06F2
4942: BCC $48F8                ; Return to main loop
```

#### 0xCD-0xD0 - Set Color

**Location**: $4944 | **Format**: `CD` (color 0), `CE` (color 1), `CF` (color 2), `D0` (color 3)

```assembly
4944: CMP #$CD                 ; Less than CD?
4946: BCC $4953                ; Yes, check other commands
4948: SBC #$CD                 ; Convert to color number (0-3)
494A: STA $06F2                ; Set current color
494D: STA $06F3                ; Set saved color
4951: BCC $48F8                ; Return to main loop
```

**Example**: `0xCE` → subtract 0xCD = 1 → color 1

#### 0xC8 - No-op/Continue

**Location**: $4953 | **Format**: `C8`

```assembly
4953: CMP #$C8 / BNE $495A     ; Check if C8
4958: BCC $48F8                ; Return to main loop (do nothing)
```

#### 0xCB - Move To Position

**Location**: $495A | **Format**: `CB X Y`

```assembly
495A: CMP #$CB / BNE $4976     ; Check if CB
495E: JSR $0600                ; Read X coordinate
4961: STA $06E3                ; Set current X
4964: JSR $0600                ; Read Y coordinate
4967: STA $06E4                ; Set current Y
496A: LDA $06F3                ; Load saved color
496D: STA $06F2                ; Restore as current color
4970: JSR $0688                ; Additional processing
4974: BCC $48F8                ; Return to main loop
```

**Use**: Move the drawing cursor without drawing a line

#### 0xCC - Set Color and Position

**Location**: $4976 | **Format**: `CC color X Y`

```assembly
4976: CMP #$CC / BNE $4998     ; Check if CC
497A: JSR $0600                ; Read color
497D: STA $06F2                ; Set current color
4980: JSR $0600                ; Read X coordinate
4983: STA $06E3                ; Set current X
4986: JSR $0600                ; Read Y coordinate
4989: STA $06E4                ; Set current Y
498C: JSR $0688                ; Additional processing
4997: BCC $4975                ; Return to main loop
```

**Use**: Combined color change and move operation

#### Unknown Command - Reset and Return

**Location**: $4998 | **Fallback**: Any other command

```assembly
4999: LDA #$00                 ; Clear position
499B: STA $06E3                ; X = 0
499E: STA $06E4                ; Y = 0
49A1: JSR $060F                ; Reset
49A4: JSR $0668                ; Reset
49A7: RTS                      ; Exit DRAW routine
```

## Memory Map

| Address | Name | Purpose |
|---------|------|---------|
| `$57` | AUX | Auxiliary value (7) |
| `$58/$59` | SCREEN_PTR | Screen buffer pointer ($??8D) |
| `$CB/$CC` | BYTECODE_PTR | Current bytecode position |
| `$CE/$CF` | WORK_PTR | Working screen pointer |
| `$D1` | TEMP | Zero page temporary |
| `$02C4-$02C6` | GFX_MODE | Graphics mode parameters |
| `$06E3` | CURRENT_X | Current drawing X position |
| `$06E4` | CURRENT_Y | Current drawing Y position |
| `$06E5` | LINE_END_X | Line endpoint X |
| `$06E6` | LINE_END_Y | Line endpoint Y |
| `$06E7` | VERTEX0_X | First polygon vertex X |
| `$06E8` | VERTEX0_Y | First polygon vertex Y |
| `$06EC-$06F1` | FILL_WORK | Fill algorithm work variables |
| `$06F2` | CURRENT_COLOR | Current drawing color (0-3) |
| `$06F3` | SAVED_COLOR | Previous/saved color |

## Subroutine Map

| Address | Name | Purpose |
|---------|------|---------|
| `$0600` | READ_BYTE | Read next byte from bytecode stream |
| `$060F` | SETUP | Drawing setup/initialization |
| `$0668` | SETUP2 | Additional setup |
| `$0688` | POST_PROCESS | Post-drawing processing |
| `$8BA3` | FILL_POLYGON | Fill closed polygon (see fill_routine.asm) |
| `$8BC1` | DRAW_LINE | Draw line using Bresenham algorithm |

## Offset Byte Encoding (C9/CA Commands)

The offset byte following C9/CA commands encodes the fill seed position:

```
Format: XXXXYYYY (binary)
  High nibble (bits 7-4): X offset (0-15)
  Low nibble (bits 3-0):  Y offset (0-15)

Fill seed position:
  seed_x = vertex0_x + ((offset_byte & 0xF0) >> 4)
  seed_y = vertex0_y + (offset_byte & 0x0F)
```

**Calculated by**: Fill routine at $8BF8 (see fill_routine.asm and FILL_ROUTINE_ANALYSIS.md)

## Example Bytecode Sequences

### Draw a Triangle

```
10 20        # Move to (10, 20) - vertex0
30 40        # Draw line to (30, 40)
50 20        # Draw line to (50, 20)
C9 22        # Close triangle and fill
             # offset 0x22 = X+2, Y+2 from vertex0
             # Fill seed at (12, 22)
```

### Draw Square with Different Colors

```
CD           # Set color 0
10 10        # Move to (10, 10) - start square
10 30        # Draw to (10, 30)
30 30        # Draw to (30, 30)
30 10        # Draw to (30, 10)
CA 02 AA     # Close and fill with color 2
             # offset 0xAA = X+10, Y+10
             # Fill seed at (20, 20)
CD           # Restore to color 0
```

### Move Without Drawing

```
10 20        # Move to (10, 20)
CB 50 60     # Move to (50, 60) without line
70 80        # Draw line from (50,60) to (70,80)
```

## Key Insights

1. **Polyline State Machine**: The routine maintains state through vertex0 coordinates, allowing polygons to be closed by referencing the starting point.

2. **Relative Filling**: Fill seed is calculated relative to vertex0, making polygon definitions portable.

3. **Color Stack**: Both current ($06F2) and saved ($06F3) colors allow temporary color changes (CA command) with automatic restoration.

4. **Compact Encoding**: Commands use high byte values (≥0xA1) to distinguish from coordinates (≤0xA0), allowing dense bytecode.

5. **Zero-overhead Polylines**: Consecutive coordinate pairs automatically draw connected lines without explicit draw commands.

## Implementation Notes

### For Flutter Port

1. **Bytecode Parsing**: Implement state machine matching the command dispatch logic
2. **Polyline Tracking**: Maintain vertex0 coordinates for polygon closing
3. **Color Management**: Implement color stack (current/saved) for CA command
4. **Coordinate Range**: Assume coordinates are 0-160 (X) and 0-96 (Y) for Atari graphics mode
5. **Fill Seed**: Calculate from offset byte as documented
6. **Line Drawing**: Use Bresenham algorithm (as original does via $8BC1)

### Differences from Original

The original code:
- Draws directly to Atari screen memory
- Uses 6502 CPU and hardware graphics
- No bounds checking (relies on valid bytecode)

The Flutter port should:
- Draw to pixel buffer or Canvas
- Add validation for robustness
- Match visual output pixel-perfectly where possible

## References

- `draw_routine.asm` - Complete disassembly (295 bytes)
- `fill_routine.asm` - Fill subroutine disassembly (225 bytes)
- `FILL_ROUTINE_ANALYSIS.md` - Detailed fill algorithm analysis
- `cassette_map.md` - Memory loading structure
