#!/usr/bin/env python3
"""
Simple 6502 disassembler for the DRAW routine.
"""

import sys

# 6502 instruction table (simplified for common opcodes)
OPCODES = {
    0x00: ("BRK", "impl", 1),
    0x01: ("ORA", "X,ind", 2),
    0x05: ("ORA", "zpg", 2),
    0x06: ("ASL", "zpg", 2),
    0x08: ("PHP", "impl", 1),
    0x09: ("ORA", "#", 2),
    0x0A: ("ASL", "A", 1),
    0x0C: ("TSB", "abs", 3),
    0x0D: ("ORA", "abs", 3),
    0x0E: ("ASL", "abs", 3),
    0x10: ("BPL", "rel", 2),
    0x14: ("TRB", "zpg", 2),
    0x16: ("ASL", "zpg,X", 2),
    0x18: ("CLC", "impl", 1),
    0x19: ("ORA", "abs,Y", 3),
    0x1B: ("TCS", "impl", 1),
    0x1C: ("TRB", "abs", 3),
    0x1D: ("ORA", "abs,X", 3),
    0x20: ("JSR", "abs", 3),
    0x21: ("AND", "X,ind", 2),
    0x22: ("JSL", "long", 4),
    0x23: ("AND", "sr,S", 2),
    0x24: ("BIT", "zpg", 2),
    0x25: ("AND", "zpg", 2),
    0x26: ("ROL", "zpg", 2),
    0x27: ("AND", "[dp]", 2),
    0x28: ("PLP", "impl", 1),
    0x29: ("AND", "#", 2),
    0x2A: ("ROL", "A", 1),
    0x2B: ("PLD", "impl", 1),
    0x2C: ("BIT", "abs", 3),
    0x2D: ("AND", "abs", 3),
    0x2E: ("ROL", "abs", 3),
    0x30: ("BMI", "rel", 2),
    0x35: ("AND", "zpg,X", 2),
    0x36: ("ROL", "zpg,X", 2),
    0x37: ("AND", "[dp],Y", 2),
    0x38: ("SEC", "impl", 1),
    0x3A: ("DEC", "A", 1),
    0x3C: ("BIT", "abs,X", 3),
    0x40: ("RTI", "impl", 1),
    0x41: ("EOR", "X,ind", 2),
    0x43: ("EOR", "sr,S", 2),
    0x48: ("PHA", "impl", 1),
    0x49: ("EOR", "#", 2),
    0x4C: ("JMP", "abs", 3),
    0x4E: ("LSR", "abs", 3),
    0x50: ("BVC", "rel", 2),
    0x52: ("EOR", "(dp)", 2),
    0x53: ("EOR", "(sr,S),Y", 2),
    0x56: ("LSR", "zpg,X", 2),
    0x58: ("CLI", "impl", 1),
    0x60: ("RTS", "impl", 1),
    0x64: ("STZ", "zpg", 2),
    0x65: ("ADC", "zpg", 2),
    0x66: ("ROR", "zpg", 2),
    0x67: ("ADC", "[dp]", 2),
    0x68: ("PLA", "impl", 1),
    0x69: ("ADC", "#", 2),
    0x6A: ("ROR", "A", 1),
    0x6C: ("JMP", "(abs)", 3),
    0x6D: ("ADC", "abs", 3),
    0x6E: ("ROR", "abs", 3),
    0x6F: ("ADC", "long", 4),
    0x70: ("BVS", "rel", 2),
    0x72: ("ADC", "(dp)", 2),
    0x78: ("SEI", "impl", 1),
    0x7B: ("TDC", "impl", 1),
    0x80: ("BRA", "rel", 2),
    0x84: ("STY", "zpg", 2),
    0x85: ("STA", "zpg", 2),
    0x86: ("STX", "zpg", 2),
    0x88: ("DEY", "impl", 1),
    0x89: ("BIT", "#", 2),
    0x8A: ("TXA", "impl", 1),
    0x8C: ("STY", "abs", 3),
    0x8D: ("STA", "abs", 3),
    0x8E: ("STX", "abs", 3),
    0x90: ("BCC", "rel", 2),
    0x91: ("STA", "(dp),Y", 2),
    0x94: ("STY", "zpg,X", 2),
    0x95: ("STA", "zpg,X", 2),
    0x96: ("STX", "zpg,Y", 2),
    0x98: ("TYA", "impl", 1),
    0x99: ("STA", "abs,Y", 3),
    0x9A: ("TXS", "impl", 1),
    0x9D: ("STA", "abs,X", 3),
    0x9E: ("STZ", "abs,X", 3),
    0x9F: ("STA", "long,X", 4),
    0xA0: ("LDY", "#", 2),
    0xA1: ("LDA", "X,ind", 2),
    0xA2: ("LDX", "#", 2),
    0xA4: ("LDY", "zpg", 2),
    0xA5: ("LDA", "zpg", 2),
    0xA6: ("LDX", "zpg", 2),
    0xA8: ("TAY", "impl", 1),
    0xA9: ("LDA", "#", 2),
    0xAA: ("TAX", "impl", 1),
    0xAC: ("LDY", "abs", 3),
    0xAD: ("LDA", "abs", 3),
    0xAE: ("LDX", "abs", 3),
    0xB0: ("BCS", "rel", 2),
    0xB1: ("LDA", "(dp),Y", 2),
    0xB4: ("LDY", "zpg,X", 2),
    0xB5: ("LDA", "zpg,X", 2),
    0xB6: ("LDX", "zpg,Y", 2),
    0xB7: ("LDA", "[dp],Y", 2),
    0xB8: ("CLV", "impl", 1),
    0xB9: ("LDA", "abs,Y", 3),
    0xBA: ("TSX", "impl", 1),
    0xBC: ("LDY", "abs,X", 3),
    0xBD: ("LDA", "abs,X", 3),
    0xBE: ("LDX", "abs,Y", 3),
    0xC0: ("CPY", "#", 2),
    0xC1: ("CMP", "X,ind", 2),
    0xC3: ("CMP", "sr,S", 2),
    0xC5: ("CMP", "zpg", 2),
    0xC8: ("INY", "impl", 1),
    0xC9: ("CMP", "#", 2),
    0xCA: ("DEX", "impl", 1),
    0xCB: ("WAI", "impl", 1),
    0xCC: ("CPY", "abs", 3),
    0xCD: ("CMP", "abs", 3),
    0xCE: ("DEC", "abs", 3),
    0xCF: ("CMP", "long", 4),
    0xD0: ("BNE", "rel", 2),
    0xDE: ("DEC", "abs,X", 3),
    0xE0: ("CPX", "#", 2),
    0xE4: ("CPX", "zpg", 2),
    0xE6: ("INC", "zpg", 2),
    0xE8: ("INX", "impl", 1),
    0xE9: ("SBC", "#", 2),
    0xEA: ("NOP", "impl", 1),
    0xF0: ("BEQ", "rel", 2),
    0xF8: ("SED", "impl", 1),
    0xFE: ("INC", "abs,X", 3),
}

def disassemble_6502(data, start_addr=0x0600):
    """Disassemble 6502 machine code."""
    output = []
    pc = 0

    while pc < len(data):
        addr = start_addr + pc
        opcode = data[pc]

        if opcode in OPCODES:
            mnemonic, mode, length = OPCODES[opcode]

            # Format operands based on addressing mode
            operands = ""
            if length == 2:
                operand = data[pc + 1] if pc + 1 < len(data) else 0
                if mode == "#":
                    operands = f"#${operand:02X}"
                elif mode == "rel":
                    target = addr + 2 + (operand if operand < 128 else operand - 256)
                    operands = f"${target:04X}"
                elif mode == "zpg":
                    operands = f"${operand:02X}"
                elif mode == "X,ind":
                    operands = f"(${operand:02X},X)"
                elif mode == "(dp),Y":
                    operands = f"(${operand:02X}),Y"
                elif mode == "zpg,X":
                    operands = f"${operand:02X},X"
                elif mode == "zpg,Y":
                    operands = f"${operand:02X},Y"
                else:
                    operands = f"${operand:02X}"
            elif length == 3:
                low = data[pc + 1] if pc + 1 < len(data) else 0
                high = data[pc + 2] if pc + 2 < len(data) else 0
                word = (high << 8) | low
                if mode == "abs":
                    operands = f"${word:04X}"
                elif mode == "(abs)":
                    operands = f"(${word:04X})"
                elif mode == "abs,X":
                    operands = f"${word:04X},X"
                elif mode == "abs,Y":
                    operands = f"${word:04X},Y"
                else:
                    operands = f"${word:04X}"

            # Format bytes
            bytes_str = " ".join(f"{data[pc+i]:02X}" for i in range(length) if pc+i < len(data))
            bytes_str = f"{bytes_str:<12}"

            output.append(f"{addr:04X}: {bytes_str} {mnemonic:<4} {operands}")
            pc += length
        else:
            # Unknown opcode
            output.append(f"{addr:04X}: {opcode:02X}           .byte ${opcode:02X}  ; Unknown opcode")
            pc += 1

    return "\n".join(output)

def main():
    with open('draw_routine.bin', 'rb') as f:
        data = f.read()

    print("; DRAW Routine Disassembly")
    print("; 256 bytes loaded to $0600")
    print("; " + "="*70)
    print()

    disassembly = disassemble_6502(data, start_addr=0x0600)
    print(disassembly)

    # Save to file
    with open('draw_routine.asm', 'w') as f:
        f.write("; DRAW Routine Disassembly\n")
        f.write("; 256 bytes loaded to $0600\n")
        f.write("; " + "="*70 + "\n\n")
        f.write(".org $0600\n\n")
        f.write(disassembly)

    print("\n" + "="*70)
    print("✓ Saved disassembly to draw_routine.asm")

if __name__ == "__main__":
    main()
