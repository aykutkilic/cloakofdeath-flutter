# Fill Routine Deep Dive

Detailed analysis of the fill subroutine at $8BA3 (225 bytes), called by C9 and CA commands.

## Structure

### Data Tables ($8BA3-$8BF7) - 85 bytes

```
$8BA3-$8BD1: Repeated 0x0E values (47 bytes)
             Likely scanline mask or bitmap data

$8BD2-$8BF7: Initialization data (38 bytes)
             Contains setup values and IRQ handler

$8BF7:       RTI instruction - IRQ vector table end marker
```

### Executable Code

#### Part 1: Calculate Fill Seed ($8BF8-$8C15) - 30 bytes

Extracts X/Y offsets from offset byte and calculates seed position relative to vertex0.

```assembly
; Read and decode offset byte
8BF8: LDY #$00                 ; Index 0
8BFA: LDA ($CB),Y              ; Read offset byte via bytecode pointer
8BFC: AND #$F0                 ; Isolate high nibble (X offset)
8BFE: LSR A                    ; Shift right 4 times
8BFF: LSR A                    ; to extract X offset (0-15)
8C00: LSR A
8C01: LSR A
8C02: CLC                      ; Clear carry for addition
8C03: ADC $06E7                ; Add to vertex0 X coordinate
8C06: STA $06E3                ; Store as fill seed X

; Decode Y offset
8C09: JSR $0600                ; Read offset byte again (redundant?)
8C0C: AND #$0F                 ; Isolate low nibble (Y offset)
8C0E: CLC                      ; Clear carry
8C0F: ADC $06E8                ; Add to vertex0 Y coordinate
8C12: STA $06E4                ; Store as fill seed Y
8C15: RTS                      ; Return to C9/CA handler
```

**Offset Encoding**:
```
Byte: XXXXYYYY (binary)
X offset: (byte & 0xF0) >> 4  = bits 7-4 (0-15)
Y offset: byte & 0x0F          = bits 3-0 (0-15)

seed_x = vertex0_x + x_offset
seed_y = vertex0_y + y_offset
```

#### Part 2: Scanline Fill Setup ($8C16-$8C83) - 110 bytes

Sets up direction flags and delta values for the scanline fill algorithm.

```assembly
; Determine fill direction by comparing Y coordinates
8C16: CMP $06E4                ; Compare with seed Y
8C19: BCC $8C29                ; Branch if less than

; Path 1: Fill direction setup (Y >= seed Y)
8C1B: SEC                      ; Set carry for subtraction
8C1C: SBC $06E4                ; Calculate delta Y
8C1F: STA $06EE                ; Store delta in work variable
8C22: LDA #$01                 ; Direction flag = 1 (up?)
8C24: STA $06F0                ; Store direction
8C27: BNE $8C38                ; Continue to main fill

; Path 2: Alternate direction (Y < seed Y)
8C29: LDA $06E4                ; Load seed Y
8C2C: SEC                      ; Set carry
8C2D: SBC $06E6                ; Subtract from something
8C30: STA $06EE                ; Store delta
8C33: LDA #$FF                 ; Direction flag = -1 (down?)
8C35: STA $06F0                ; Store direction

; Continue with X direction setup
8C38: (continues with similar logic for X deltas...)
```

The algorithm calculates:
- **Delta Y** ($06EE): Vertical distance to fill
- **Delta X** ($06ED): Horizontal distance to fill
- **Direction flags** ($06EF, $06F0): 1 or -1 for fill direction
- **Work variables** ($06EC, $06EB): Scanline tracking

#### Part 3: Scanline Fill Loop (Remainder)

The rest of the routine (not fully visible in disassembly) implements the actual pixel-by-pixel scanline fill:

1. Start at seed position
2. Scan horizontally (left/right based on direction flag)
3. Fill pixels until hitting boundary or edge
4. Move to next scanline (up/down based on direction flag)
5. Repeat until area filled or limits reached

## Memory Usage

| Address | Purpose |
|---------|---------|
| `$06E3` | Fill seed X / Current X |
| `$06E4` | Fill seed Y / Current Y |
| `$06E7` | Vertex0 X (for seed calculation) |
| `$06E8` | Vertex0 Y (for seed calculation) |
| `$06EB` | Scanline work variable |
| `$06EC` | Scanline work variable |
| `$06ED` | Delta X |
| `$06EE` | Delta Y |
| `$06EF` | X direction flag (+1/-1) |
| `$06F0` | Y direction flag (+1/-1) |
| `$06F1` | Scanline limit |
| `$06F2` | Current fill color (set by caller) |
| `$D1` | Zero page temporary |
| `$CB/$CC` | Bytecode pointer (for reading offset) |

## Algorithm Summary

```
1. CALCULATE_SEED ($8BF8-$8C15)
   ├─ Read offset byte from bytecode
   ├─ Extract X offset: (offset & 0xF0) >> 4
   ├─ Extract Y offset: offset & 0x0F
   ├─ seed_x = vertex0_x + x_offset
   ├─ seed_y = vertex0_y + y_offset
   └─ Store seed position in $06E3/$06E4

2. SETUP_FILL ($8C16-$8C83)
   ├─ Compare seed Y with boundary Y values
   ├─ Calculate delta Y (vertical distance)
   ├─ Set Y direction flag (1 or -1)
   ├─ Calculate delta X (horizontal distance)
   ├─ Set X direction flag (1 or -1)
   └─ Initialize scanline work variables

3. SCANLINE_FILL (remainder)
   ├─ Start at seed position
   ├─ LOOP:
   │  ├─ Fill pixels horizontally (using direction flag)
   │  ├─ Check boundary conditions
   │  ├─ Move to next scanline (using Y direction)
   │  └─ Continue until complete
   └─ Return to DRAW routine
```

## Key Characteristics

1. **Direction-aware**: Fills can proceed upward or downward based on seed position relative to polygon boundaries

2. **Scanline-based**: Fills one horizontal line at a time, typical of Atari graphics routines

3. **Boundary detection**: Uses polygon edges (drawn by polyline commands) as fill boundaries

4. **No validation**: No bounds checking - assumes valid offset and seed position

## Implementation Notes

For Flutter port:
1. Implement offset byte decoding exactly as shown ($8BF8-$8C15)
2. Calculate seed position relative to vertex0
3. Use standard scanline flood fill algorithm
4. Stop at polygon boundaries (pixels drawn by line commands)
5. Match the direction logic for authenticity (though most fills work downward only)

## Comparison with Modern Fills

**Atari Method**:
- Scanline-based, single direction
- No recursion (stack-based or iterative)
- Hardware-optimized for 6502

**Modern Method**:
- Queue-based flood fill
- Bidirectional scanning
- More robust boundary detection

The Flutter port can use a modern flood fill algorithm as long as it produces visually identical results.

## References

- Called by: C9 command at $490C, CA command at $4935
- Memory map: See C9_CA_COMMANDS_FINAL.md
- Offset encoding: See C9_CA_COMMANDS_FINAL.md
