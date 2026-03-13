; DRAW Routine Disassembly
; 295 bytes extracted from cassette chunk 144+
; ======================================================================

.org $4881

4881: 58           CLI  
4882: A9 8D        LDA  #$8D
4884: 85 59        STA  $59
4886: A9 07        LDA  #$07
4888: 85 57        STA  $57
488A: A9 01        LDA  #$01
488C: 8D F2 06     STA  $06F2
488F: 9F 8D F3 06  STA  
4893: 68           PLA  
4894: 68           PLA  
4895: 85 CC        STA  $CC
4897: 68           PLA  
4898: 85 CB        STA  $CB
489A: A5 58        LDA  $58
489C: 85 CE        STA  $CE
489E: A5 59        LDA  $59
48A0: 85 CF        STA  $CF
48A2: 20 00 06     JSR  $0600
48A5: A2 0F        LDX  #$0F
48A7: A0 00        LDY  #$00
48A9: 91 CE        STA  ($CE),Y
48AB: C8           INY  
48AC: D0 FB        BNE  $48A9
48AE: E6 CF        INC  $CF
48B0: CA           DEX  
48B1: D0 F6        BNE  $48A9
48B3: 20 00 06     JSR  $0600
48B6: 8D C4 02     STA  $02C4
48B9: 20 00 06     JSR  $0600
48BC: 8D C5 02     STA  $02C5
48BF: 20 00 06     JSR  $0600
48C2: 8D C6 02     STA  $02C6
48C5: 20 00 06     JSR  $0600
48C8: C9 A1        CMP  #$A1
48CA: B0 2D        BCS  $48F9
48CC: 8D E3 06     STA  $06E3
48CF: 8D E7 06     STA  $06E7
48D2: 20 00 06     JSR  $0600
48D5: 8D E4 06     STA  $06E4
48D8: 8D E8 06     STA  $06E8
48DB: 20 0F 06     JSR  $060F
48DE: 20 68 06     JSR  $0668
48E1: 20 00 06     JSR  $0600
48E4: C9 A1        CMP  #$A1
48E6: B0 11        BCS  $48F9
48E8: 8D E5 06     STA  $06E5
48EB: 20 00 06     JSR  $0600
48EE: 8D E6 06     STA  $06E6
48F1: 20 C1 8B     JSR  $8BC1
48F4: 18           CLC  
48F5: 90 EA        BCC  $48E1
48F7: 90 CC        BCC  $48C5
48F9: C9 C9        CMP  #$C9
48FB: D0 1E        BNE  $491B
48FD: AD E7 06     LDA  $06E7
4900: 8D E5 06     STA  $06E5
4903: AD E8 06     LDA  $06E8
4906: 8D E6 06     STA  $06E6
4909: 20 C1 8B     JSR  $8BC1
490C: 20 A3 8B     JSR  $8BA3
490F: AD 03 F3     LDA  $F303
4912: 06 8D        ASL  $8D
4914: F2           .byte $F2  ; Unknown opcode
4915: 06 20        ASL  $20
4917: 88           DEY  
4918: 06 18        ASL  $18
491A: 90 DC        BCC  $48F8
491C: C9 CA        CMP  #$CA
491E: D0 24        BNE  $4944
4920: AD E7 06     LDA  $06E7
4923: 8D E5 06     STA  $06E5
4926: AD E8 06     LDA  $06E8
4929: 8D E6 06     STA  $06E6
492C: 20 C1 8B     JSR  $8BC1
492F: 20 00 06     JSR  $0600
4932: 8D F2 06     STA  $06F2
4935: 20 A3 8B     JSR  $8BA3
4938: 20 88 06     JSR  $0688
493B: AD F3 06     LDA  $06F3
493E: 8D F2 06     STA  $06F2
4941: 18           CLC  
4942: 90 B4        BCC  $48F8
4944: C9 CD        CMP  #$CD
4946: 90 0B        BCC  $4953
4948: E9 CD        SBC  #$CD
494A: 8D F2 06     STA  $06F2
494D: 8D F3 06     STA  $06F3
4950: 18           CLC  
4951: 90 A5        BCC  $48F8
4953: C9 C8        CMP  #$C8
4955: D0 03        BNE  $495A
4957: 18           CLC  
4958: 90 9E        BCC  $48F8
495A: C9 CB        CMP  #$CB
495C: D0 18        BNE  $4976
495E: 20 00 06     JSR  $0600
4961: 8D E3 06     STA  $06E3
4964: 20 00 06     JSR  $0600
4967: 8D E4 06     STA  $06E4
496A: AD F3 06     LDA  $06F3
496D: 8D F2 06     STA  $06F2
4970: 20 88 06     JSR  $0688
4973: 18           CLC  
4974: 90 82        BCC  $48F8
4976: C9 CC        CMP  #$CC
4978: D0 1E        BNE  $4998
497A: 20 00 06     JSR  $0600
497D: 8D F2 06     STA  $06F2
4980: 20 00 06     JSR  $0600
4983: 8D E3 06     STA  $06E3
4986: 20 00 06     JSR  $0600
4989: 8D E4 06     STA  $06E4
498C: 20 88 06     JSR  $0688
498F: AD F3 2C     LDA  $2CF3
4992: 06 8D        ASL  $8D
4994: F2           .byte $F2  ; Unknown opcode
4995: 06 18        ASL  $18
4997: 90 DC        BCC  $4975
4999: A9 00        LDA  #$00
499B: 8D E3 06     STA  $06E3
499E: 8D E4 06     STA  $06E4
49A1: 20 0F 06     JSR  $060F
49A4: 20 68 06     JSR  $0668
49A7: 60           RTS  