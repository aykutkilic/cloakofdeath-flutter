; FILL Routine Disassembly
; Called by C9/CA commands via JSR $8BA3
; 225 bytes loaded to $8BA3 (35747)
; ======================================================================

.org $8BA3

8BA3: 0E 0E 0E     ASL  $0E0E
8BA6: 0E 0E 0E     ASL  $0E0E
8BA9: 0E 0E 0E     ASL  $0E0E
8BAC: 0E 0E 0E     ASL  $0E0E
8BAF: 0E 0E 0E     ASL  $0E0E
8BB2: 0E 0E 0E     ASL  $0E0E
8BB5: 36 0E        ROL  $0E,X
8BB7: 0E 0E 0E     ASL  $0E0E
8BBA: 0E 0E 0E     ASL  $0E0E
8BBD: 0E 0E 0E     ASL  $0E0E
8BC0: 0E 0E 0E     ASL  $0E0E
8BC3: 0E 0E 0E     ASL  $0E0E
8BC6: 0E 0E 0E     ASL  $0E0E
8BC9: 0E 0E 0E     ASL  $0E0E
8BCC: 0E 0E 0E     ASL  $0E0E
8BCF: 0E 0E 0E     ASL  $0E0E
8BD2: 8E 42 20     STX  $2042
8BD5: 9E 02 02     STZ  $0202,X
8BD8: 02           .byte $02  ; Unknown opcode
8BD9: 02           .byte $02  ; Unknown opcode
8BDA: 02           .byte $02  ; Unknown opcode
8BDB: 02           .byte $02  ; Unknown opcode
8BDC: 02           .byte $02  ; Unknown opcode
8BDD: 02           .byte $02  ; Unknown opcode
8BDE: 02           .byte $02  ; Unknown opcode
8BDF: 02           .byte $02  ; Unknown opcode
8BE0: 02           .byte $02  ; Unknown opcode
8BE1: 41 A4        EOR  ($A4,X)
8BE3: 8C 48 8A     STY  $8A48
8BE6: 48           PHA  
8BE7: A9 CA        LDA  #$CA
8BE9: A2 94        LDX  #$94
8BEB: 8D 0A D4     STA  $D40A
8BEE: 8D 17 D0     STA  $D017
8BF1: 8E 18 D0     STX  $D018
8BF4: 68           PLA  
8BF5: AA           TAX  
8BF6: 68           PLA  
8BF7: 40           RTI  
8BF8: A0 00        LDY  #$00
8BFA: B1 CB        LDA  ($CB),Y
8BFC: 29 F0        AND  #$F0
8BFE: 4A           .byte $4A  ; Unknown opcode
8BFF: 4A           .byte $4A  ; Unknown opcode
8C00: 4A           .byte $4A  ; Unknown opcode
8C01: 4A           .byte $4A  ; Unknown opcode
8C02: 18           CLC  
8C03: 6D E7 06     ADC  $06E7
8C06: 8D E3 06     STA  $06E3
8C09: 20 00 06     JSR  $0600
8C0C: 29 0F        AND  #$0F
8C0E: 18           CLC  
8C0F: 6D E8 06     ADC  $06E8
8C12: 8D E4 06     STA  $06E4
8C15: 60           RTS  
8C16: CD E4 06     CMP  $06E4
8C19: 90 0E        BCC  $8C29
8C1B: 38           SEC  
8C1C: ED           .byte $ED  ; Unknown opcode
8C1D: E4 06        CPX  $06
8C1F: 8D EE 06     STA  $06EE
8C22: A9 01        LDA  #$01
8C24: 8D F0 06     STA  $06F0
8C27: D0 0F        BNE  $8C38
8C29: AD E4 06     LDA  $06E4
8C2C: 38           SEC  
8C2D: ED           .byte $ED  ; Unknown opcode
8C2E: E6 06        INC  $06
8C30: 8D EE 06     STA  $06EE
8C33: A9 FF        LDA  #$FF
8C35: 8D 7C F0     STA  $F07C
8C38: 06 AD        ASL  $AD
8C3A: E5           .byte $E5  ; Unknown opcode
8C3B: 06 CD        ASL  $CD
8C3D: E3           .byte $E3  ; Unknown opcode
8C3E: 06 90        ASL  $90
8C40: 0E 38 ED     ASL  $ED38
8C43: E3           .byte $E3  ; Unknown opcode
8C44: 06 8D        ASL  $8D
8C46: ED           .byte $ED  ; Unknown opcode
8C47: 06 A9        ASL  $A9
8C49: 01 8D        ORA  ($8D,X)
8C4B: EF           .byte $EF  ; Unknown opcode
8C4C: 06 D0        ASL  $D0
8C4E: 0F           .byte $0F  ; Unknown opcode
8C4F: AD E3 06     LDA  $06E3
8C52: 38           SEC  
8C53: ED           .byte $ED  ; Unknown opcode
8C54: E5           .byte $E5  ; Unknown opcode
8C55: 06 8D        ASL  $8D
8C57: ED           .byte $ED  ; Unknown opcode
8C58: 06 A9        ASL  $A9
8C5A: FF           .byte $FF  ; Unknown opcode
8C5B: 8D EF 06     STA  $06EF
8C5E: A9 00        LDA  #$00
8C60: 8D EC 06     STA  $06EC
8C63: 8D EB 06     STA  $06EB
8C66: AD ED 06     LDA  $06ED
8C69: CD EE 06     CMP  $06EE
8C6C: 90 0D        BCC  $8C7B
8C6E: 8D F1 06     STA  $06F1
8C71: 85 D1        STA  $D1
8C73: 4A           .byte $4A  ; Unknown opcode
8C74: 8D EC 06     STA  $06EC
8C77: A9 00        LDA  #$00
8C79: F0 0C        BEQ  $8C87
8C7B: AD EE 06     LDA  $06EE
8C7E: 8D F1 06     STA  $06F1
8C81: 85 D1        STA  $D1
8C83: 4A           .byte $4A  ; Unknown opcode