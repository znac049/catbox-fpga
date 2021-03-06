; Command line parsed ok:
;   output hex: NO
;     rom base: 6000
;      rom end: 67ff
;    IRQ entry: 60a8
;    NMI entry: 60c7
;  RESET entry: 60c7
;      verbose: NO
;     ROM file: cat.bin
;   Label file: cat.lab
;


RIOT_DRA                = $00
RIOT_DDRA               = $01
RIOT_DRB                = $02
RIOT_DDRB               = $03

RIOT_RdTimer            = $04
RIOT_Reg5               = $05
RIOT_WEDC_Neg           = $06
RIOT_WEDC_Pos           = $07

RIOT_Reg_08             = $08
RIOT_Reg_09             = $09
RIOT_Reg_0a             = $0a
RIOT_Reg_0b             = $0b

RIOT_Rt_En              = $0c

RIOT_Reg_0d             = $0d
RIOT_Reg_0e             = $0e
RIOT_Reg_0f             = $0f
RIOT_Reg_10             = $10
RIOT_Reg_11             = $11
RIOT_Reg_12             = $12
RIOT_Reg_13             = $13

RIOT_Wt_Div1_Dis        = $14
RIOT_Wt_Div8_Dis        = $15
RIOT_Wt_Div64_Dis       = $16
RIOT_Wt_Div1K_Dis       = $17

RIOT_Reg_18             = $18
RIOT_Reg_19             = $19
RIOT_Reg_1a             = $1a
RIOT_Reg_1b             = $1b

RIOT_Wt_Div1_En         = $1c
RIOT_Wt_Div8_En         = $1d
RIOT_Wt_Div64_En        = $1e
RIOT_Wt_Div1K_En        = $1f

GameBoxCounter          = $2000
SegmentSelect           = $2b00
DigitSelect             = $3000
SigAnalReset            = $3800

SourceAddrSwitch        = $4000
SourceDataSwitch        = $4001
ByteSwitch              = $4002
KByteSwitch             = $4003
SpareSwitch		= $4004
RWSwitch                = $4005
SelfTestSwitch          = $4006
SigAnDone               = $4007

Switches                = $4008
ModeSw			= $02
DataSetSw		= $04
AddressIncSw		= $08
ErrorDisplaySw		= $10

Col0                    = $4010
Col1                    = $4020
Col2                    = $4040
Col3                    = $4080

Switches2               = $4100
PulseSw			= $02
StaticSw		= $04

;
; Program variables
;

Var82			= $82	; Init to 0. Used in Sig An. mode
	
Var83	                = $83   ; Previous lower byte of sig???
	
Var84	                = $84   ; Previous upper byte of sig???

Var86			= $86

Var87			= $87
	
; Tester mode: Init to 0.
Var94			= $94

Var95			= $95
	
Var96			= $96	; Init to 0. Used in Sig An. mode

; Tester mode: Init to 0.
Var97			= $97	;

; Tester mode: Init to 0.
Var98			= $98	; Used in Sig An. mode

Var99			= $99
	
Var9a			= $9a

;  Tester mode: Init to 0.
Var9b			= $9b	;

; Tester mode: Init to 0.	
; Sig An. mode: Gets written with #$40 if sig has changed??? Some sort of down counter/delay??
Var9c			= $9c	;

			*=$6000

                        !byte                $02,$bb,$5a,$30,$50,$ee,$3d,$a8,$43,$4f,$50,$59,$52,$49,$47,$48 ; 6000
                        !byte                $54,$20,$31,$39,$38,$30,$2c,$20,$41,$54,$41,$52,$49,$2c,$20,$49 ; 6010
                        !byte                $4e,$43,$2e                                                     ; 6020

; 
; We jump here from two other locations: L6027 and L60ec
; 
L6023                   LDA $80              ; 6023 
                        AND #$7f             ; 6025 
                        STA $80              ; 6027 
                        BIT SelfTestSwitch   ; 6029 - Check selftest switch - reset catbox if no longer active
                        BPL L6031            ; 602C 
                        JMP NMI              ; 602E 

L6031                   LDA Switches         ; 6031 
                        AND #$02             ; 6034 - Tester mode switch. 1->Sig An. 0->RW mode
                        BEQ TesterMode       ; 6036 
                        JSR SigAnMode        ; 6038 - Sig an. mode
                        JMP L6054            ; 603B 

; 
; tester mode switch set to RW
;
TesterMode
L603e                   LDA #$00             ; 603E 
                        STA Var9b            ; 6040 
                        STA Var97            ; 6042 
                        STA Var9c            ; 6044 
                        STA Var98            ; 6046 
                        STA SigAnalReset     ; 6048
	
                        JSR L60ef            ; 604B 
                        JSR L62c7            ; 604E 
                        JSR L6324            ; 6051 

L6054                   LDA #$00             ; 6054 
                        STA $94              ; 6056 
L6058                   LDA $80              ; 6058 
                        BMI L6067            ; 605A 
                        INC $94              ; 605C 
                        BNE L6058            ; 605E 
                        LDA #$2f             ; 6060 
                        STA RIOT_Wt_Div64_En ; 6062 
                        CLI                  ; 6064 
                        BNE L6058            ; 6065 

L6067                   JMP L6023            ; 6067 

;
; Subroutine entry point
; 
; 	Called when tester mode switch is set to Sig An.
;
SigAnMode
L606a                   LDA #$00             ; 606A 
                        STA Var96            ; 606C 
                        STA Var98            ; 606E 
                        STA Var82            ; 6070
	
                        LDA #$10             ; 6072 
                        STA Var9b            ; 6074
	
                        LDA Var9c            ; 6076 
                        BEQ L6082            ; 6078
	
                        DEC Var9c            ; 607A 
                        LDA #$40             ; 607C 
                        STA Var97            ; 607E 
                        BNE L6086            ; 6080 - always branch

L6082                   LDA #$00             ; 6082 
                        STA Var97            ; 6084 

L6086                   BIT SigAnDone        ; 6086 
                        BPL SigComplete      ; 6089 
                        RTS                  ; 608B 

;
; Signature analysis complete
; 
SigComplete
L608c                   LDX #$40             ; 608C

                        LDA RIOT_DRB         ; 608E - lower byte of signature
                        CMP $83              ; 6090 
                        BEQ L6096            ; 6092 
                        STX $9c              ; 6094 
L6096                   STA $83              ; 6096


                        LDA RIOT_DRA         ; 6098 - upper byte of signature
                        CMP $84              ; 609A 
                        BEQ L60a0            ; 609C 
                        STX $9c              ; 609E 
L60a0                   STA $84              ; 60A0

                        LDA #$00             ; 60A2 
                        STA SigAnalReset     ; 60A4 - hard reset the Signal Analyser
                        RTS                  ; 60A7 

IRQ                     PHA                  ; 60A8 
                        TXA                  ; 60A9 
                        PHA                  ; 60AA 
                        TYA                  ; 60AB 
                        PHA                  ; 60AC 
                        CLD                  ; 60AD 
                        LDA $80              ; 60AE 
                        ORA #$80             ; 60B0 
                        STA $80              ; 60B2 
                        LDA #$2f             ; 60B4 
                        STA RIOT_Wt_Div64_En ; 60B6 
                        LDA SelfTestSwitch   ; 60B8 
                        BMI L60c0            ; 60BB 
                        JSR L642e            ; 60BD 

L60c0                   PLA                  ; 60C0 
                        TAY                  ; 60C1 
                        PLA                  ; 60C2 
                        TAX                  ; 60C3 
                        PLA                  ; 60C4 
                        CLI                  ; 60C5 
                        RTI                  ; 60C6 


	
;
; Cold start entrypoint
; 
Reset
NMI                     SEI                  ; 60C7 - Disable interrupts
                        CLD                  ; 60C8 
                        LDX #$ff             ; 60C9 
                        TXS                  ; 60CB 
                        LDA #$00             ; 60CC 
                        BIT SelfTestSwitch   ; 60CE 
                        BPL SelfTest         ; 60D1 
                        JMP NormalOp         ; 60D3 

;
; Main entry point if selftest switch is active
;
SelfTest
ClrRAM                  STA $00,X            ; 60D6 - Clear RAM from $80-$FF 
                        DEX                  ; 60D8 
                        BMI ClrRAM           ; 60D9 

                        STA DigitSelect      ; 60DB - Blank the display
                        STA SigAnalReset     ; 60DE
	
                        STA RIOT_RdTimer     ; 60E1 - Disable any pending RIOT interrupt (I think)
	
                        STA RIOT_DDRA        ; 60E3 - Set Port A as inputs
                        STA RIOT_DDRB        ; 60E5 - Set Port B as inputs
	
                        LDA #$2f             ; 60E7 - $27 = 47. 47 * 64 = 3008
                        STA RIOT_Wt_Div64_En ; 60E9 - Timer: div 64, enable interrupts -> interrupt every 3008 clocks
                        CLI                  ; 60EB - Enable interrupts
                        JMP L6023            ; 60EC

	

L60ef                   LDA Switches2        ; 60EF - Static and pulse switches
                        ROR                  ; 60F2 
                        ROR                  ; 60F3 
                        ROR                  ; 60F4 
                        JSR L6295            ; 60F5 
                        LDY #$00             ; 60F8 
                        BIT Var9a            ; 60FA 
                        BMI L6101            ; 60FC 
                        BVS L610f            ; 60FE 
                        RTS                  ; 6100 

L6101                   LDA #$20             ; 6101 
                        STA Var98            ; 6103
	
                        STY Var99            ; 6105 

                        LDA Var86            ; 6107 
                        STA Var83            ; 6109 

	                LDA Var87            ; 610B 
                        STA Var84            ; 610D 

L610f                   LDA Var9a            ; 610F 
                        AND #$bf             ; 6111 
                        STA Var9a            ; 6113 

                        STY Var96            ; 6115
	
                        LDA Var83            ; 6117 
                        STA Var86            ; 6119
	
                        LDA Var84            ; 611B 
                        STA Var87            ; 611D
	
L611f                   LDA Switches         ; 611F 
                        AND #ModeSw          ; 6122 
                        BNE L612b            ; 6124 
                        BIT SelfTestSwitch   ; 6126 
                        BPL L612c            ; 6129 

L612b                   RTS                  ; 612B 

L612c                   STY Var94            ; 612C 
                        STY Var95            ; 612E 
                        BIT KByteSwitch      ; 6130 
                        BPL L6139            ; 6133 
                        LDA #$03             ; 6135 
                        STA Var95            ; 6137 

L6139                   BIT RWSwitch         ; 6139 
                        BMI L6141            ; 613C 
                        JMP L61c5            ; 613E 

; 
; Not sure why we check a switch that isn't there?
; 
L6141                   BIT SpareSwitch      ; 6141 
                        BPL L6149            ; 6144 
                        JMP L6221            ; 6146 

L6149                   BIT ByteSwitch       ; 6149 
                        BPL L615c            ; 614C
	
                        LDA #$0b             ; 614E 
                        SEI                  ; 6150 
                        STA GameBoxCounter   ; 6151
	
                        LDA ($83),Y          ; 6154 
                        CLI                  ; 6156 
                        STA $82              ; 6157 
                        JMP L6194            ; 6159 

L615c                   LDA SourceDataSwitch ; 615C 
                        BMI L616c            ; 615F 
                        LDA $83              ; 6161 
                        BIT SourceAddrSwitch ; 6163 
                        BPL L616a            ; 6166 
                        EOR #$ff             ; 6168 

L616a                   STA $82              ; 616A 

L616c                   LDA #$0b             ; 616C 
                        SEI                  ; 616E 
                        STA GameBoxCounter   ; 616F 
                        LDA ($83),Y          ; 6172 
                        CLI                  ; 6174 
                        CMP $82              ; 6175 
                        BEQ L6181            ; 6177 
                        STA $85              ; 6179 
                        LDA #$80             ; 617B 
                        STA $96              ; 617D 
                        BMI L61aa            ; 617F 

L6181                   INC $83              ; 6181 
                        BNE L6187            ; 6183 
                        INC $84              ; 6185 

L6187                   DEC $94              ; 6187 
                        BNE L615c            ; 6189 
                        LDA $95              ; 618B 
                        BEQ L6194            ; 618D 
                        DEC $95              ; 618F 
                        JMP L615c            ; 6191 

L6194                   BIT $9a              ; 6194 
                        BPL L61c2            ; 6196 
                        LDA Switches2        ; 6198 
                        AND #PulseSw         ; 619B 
                        BEQ L61c2            ; 619D 
                        LDA $86              ; 619F 
                        STA $83              ; 61A1 
                        LDA $87              ; 61A3 
                        STA $84              ; 61A5 
                        JMP L611f            ; 61A7 

L61aa                   LDX #$00             ; 61AA 
L61ac                   BIT SelfTestSwitch   ; 61AC 
                        BMI L61c2            ; 61AF 
                        LDA Switches         ; 61B1 
                        AND #ModeSw          ; 61B4 
                        BNE L61c2            ; 61B6 
                        LDA Switches2        ; 61B8 
                        AND #PulseSw         ; 61BB 
                        BNE L61aa            ; 61BD 
                        DEX                  ; 61BF 
                        BNE L61ac            ; 61C0 

L61c2                   STY $98              ; 61C2 
                        RTS                  ; 61C4 

L61c5                   BIT ByteSwitch       ; 61C5 
                        BPL L61d0            ; 61C8 
                        JSR L620f            ; 61CA 
                        JMP L61f6            ; 61CD 

L61d0                   LDA SourceDataSwitch ; 61D0 
                        BMI L61e0            ; 61D3 
                        LDA $83              ; 61D5 
                        BIT SourceAddrSwitch ; 61D7 
                        BPL L61de            ; 61DA 
                        EOR #$ff             ; 61DC 

L61de                   STA $82              ; 61DE 

L61e0                   JSR L620f            ; 61E0 
                        DEC $94              ; 61E3 
                        BNE L61ed            ; 61E5 
                        LDA $95              ; 61E7 
                        BEQ L61f6            ; 61E9 
                        DEC $95              ; 61EB 

L61ed                   INC $83              ; 61ED 
                        BNE L61d0            ; 61EF 
                        INC $84              ; 61F1 
                        JMP L61d0            ; 61F3 

L61f6                   LDA $86              ; 61F6 
                        STA $83              ; 61F8 
                        LDA $87              ; 61FA 
                        STA $84              ; 61FC 
                        BIT $9a              ; 61FE 
                        BPL L620c            ; 6200 
                        LDA Switches2        ; 6202 
                        AND #PulseSw         ; 6205 
                        BEQ L620c            ; 6207 
                        JMP L611f            ; 6209 

L620c                   STY $98              ; 620C 
                        RTS                  ; 620E 

L620f                   SEI                  ; 620F 
                        LDA RIOT_Rt_En       ; 6210 
                        PHA                  ; 6212 
                        LDA $82              ; 6213 
                        LDX #$0a             ; 6215 
                        STX GameBoxCounter   ; 6217 
                        STA ($83),Y          ; 621A 
                        PLA                  ; 621C 
                        STA RIOT_Wt_Div64_En ; 621D 
                        CLI                  ; 621F 
                        RTS                  ; 6220 

L6221                   STY $82              ; 6221 
                        STY $85              ; 6223 
                        LDA #$0f             ; 6225 
                        BIT ByteSwitch       ; 6227 
                        BPL L6230            ; 622A 
                        LDA #$07             ; 622C 
                        BNE L6237            ; 622E 

L6230                   BIT KByteSwitch      ; 6230 
                        BPL L6237            ; 6233 
                        LDA #$1f             ; 6235 

L6237                   STA $95              ; 6237 
L6239                   LDA #$0b             ; 6239 
                        SEI                  ; 623B 
                        STA GameBoxCounter   ; 623C 
                        LDA ($83),Y          ; 623F 
                        CLI                  ; 6241 
                        BIT SourceDataSwitch ; 6242 
                        BPL L6254            ; 6245 
                        CLC                  ; 6247 
                        ADC $82              ; 6248 
                        STA $82              ; 624A 
                        TYA                  ; 624C 
                        ADC $85              ; 624D 
                        STA $85              ; 624F 
                        JMP L6267            ; 6251 

L6254                   BIT SourceAddrSwitch ; 6254 
                        BMI L6263            ; 6257 
                        CLC                  ; 6259 
                        ADC $82              ; 625A 
                        ADC #$00             ; 625C 
                        STA $82              ; 625E 
                        JMP L6267            ; 6260 

L6263                   EOR $82              ; 6263 
                        STA $82              ; 6265 

L6267                   INC $83              ; 6267 
                        BNE L626d            ; 6269 
                        INC $84              ; 626B 

L626d                   DEC $94              ; 626D 
                        BNE L6239            ; 626F 
                        LDA $95              ; 6271 
                        BEQ L627a            ; 6273 
                        DEC $95              ; 6275 
                        JMP L6239            ; 6277 

L627a                   LDA $82              ; 627A 
                        STA $83              ; 627C 
                        LDA $85              ; 627E 
                        STA $84              ; 6280 
                        LDA #$02             ; 6282 
                        BIT ByteSwitch       ; 6284 
                        BMI L6290            ; 6287 
                        ASL                  ; 6289 
                        BIT KByteSwitch      ; 628A 
                        BPL L6290            ; 628D 
                        ASL                  ; 628F 

L6290                   STA $82              ; 6290 
                        STY $98              ; 6292 
                        RTS                  ; 6294 

L6295                   BMI L62a7            ; 6295 
                        LDA $99              ; 6297 
                        AND #$7f             ; 6299 
                        BNE L62a4            ; 629B 
                        STA $99              ; 629D 
                        LDA #$00             ; 629F 
                        STA $9a              ; 62A1 
                        RTS                  ; 62A3 

L62a4                   DEC $99              ; 62A4 
                        RTS                  ; 62A6 

L62a7                   LDA $99              ; 62A7 
                        CMP #$ff             ; 62A9 
                        BNE L62b4            ; 62AB 
                        LDA $9a              ; 62AD 
                        ORA #$80             ; 62AF 
                        STA $9a              ; 62B1 
                        RTS                  ; 62B3 

L62b4                   INC $99              ; 62B4 
                        LDA $99              ; 62B6 
                        CMP #$10             ; 62B8 
                        BNE L62c6            ; 62BA 
                        ORA #$40             ; 62BC 
                        STA $99              ; 62BE 
                        LDA $9a              ; 62C0 
                        ORA #$40             ; 62C2 
                        STA $9a              ; 62C4 

L62c6                   RTS                  ; 62C6 

L62c7                   LDA Switches2        ; 62C7 
                        AND #$04             ; 62CA 
                        BNE L62cf            ; 62CC 
                        RTS                  ; 62CE 

L62cf                   LDA #$00             ; 62CF 
                        STA $96              ; 62D1 
                        LDA RWSwitch         ; 62D3 
                        BPL L6302            ; 62D6 
                        LDY #$00             ; 62D8 
L62da                   LDA #$0b             ; 62DA 
                        SEI                  ; 62DC 
                        STA GameBoxCounter   ; 62DD 
                        LDA ($83),Y          ; 62E0 
                        CLI                  ; 62E2 
                        STA $82              ; 62E3 
                        LDA #$20             ; 62E5 
                        STA $98              ; 62E7 
                        LDA #$01             ; 62E9 
                        STA SigAnalReset     ; 62EB 
                        BIT RWSwitch         ; 62EE 
                        BPL L62fa            ; 62F1 
                        LDA Switches2        ; 62F3 
                        AND #$04             ; 62F6 
                        BNE L62da            ; 62F8 

L62fa                   LDA #$00             ; 62FA 
                        STA $98              ; 62FC 
                        STA SigAnalReset     ; 62FE 
                        RTS                  ; 6301 

L6302                   LDY #$00             ; 6302 
                        JSR L620f            ; 6304 
                        LDA #$20             ; 6307 
                        STA $98              ; 6309 
                        LDA #$01             ; 630B 
                        STA SigAnalReset     ; 630D 
L6310                   BIT RWSwitch         ; 6310 
                        BMI L631c            ; 6313 
                        LDA Switches2        ; 6315 
                        AND #$04             ; 6318 
                        BNE L6310            ; 631A 

L631c                   LDA #$00             ; 631C 
                        STA $98              ; 631E 
                        STA SigAnalReset     ; 6320 
                        RTS                  ; 6323 

L6324                   LDA Switches         ; 6324 
                        AND #$08             ; 6327 
                        BEQ L6341            ; 6329 
                        INC $83              ; 632B 
                        BNE L6331            ; 632D 
                        INC $84              ; 632F 

L6331                   LDA #$00             ; 6331 
                        STA $96              ; 6333 
L6335                   LDX #$00             ; 6335 
L6337                   LDA Switches         ; 6337 
                        AND #$08             ; 633A 
                        BNE L6335            ; 633C 
                        DEX                  ; 633E 
                        BNE L6337            ; 633F 

L6341                   LDA #$00             ; 6341 
                        STA $9d              ; 6343 
                        LDA $40F0            ; 6345 
                        AND #$1e             ; 6348 
                        BEQ L635d            ; 634A 
                        LDA $40F0            ; 634C 
                        AND #$1e             ; 634F 
                        BEQ L635d            ; 6351 
                        LDA #$80             ; 6353 
                        STA $9d              ; 6355 
                        LDA #$04             ; 6357 
                        STA $9e              ; 6359 
                        BNE L636c            ; 635B 

L635d                   LDA Switches         ; 635D 
                        AND #$04             ; 6360 
                        BEQ L637b            ; 6362 
                        LDA #$40             ; 6364 
                        STA $9d              ; 6366 
                        LDA #$02             ; 6368 
                        STA $9f              ; 636A 

L636c                   JSR L637c            ; 636C 
L636f                   LDX #$00             ; 636F 
L6371                   LDA $40F0            ; 6371 
                        AND #$1e             ; 6374 
                        BNE L636f            ; 6376 
                        DEX                  ; 6378 
                        BNE L6371            ; 6379 

L637b                   RTS                  ; 637B 

L637c                   LDA #$00             ; 637C 
                        STA $aa              ; 637E 
                        STA $96              ; 6380 
                        LDX #$04             ; 6382 
L6384                   STA $a0,X            ; 6384 
                        STA $a5,X            ; 6386 
                        DEX                  ; 6388 
                        BPL L6384            ; 6389 
                        BIT $9d              ; 638B 
                        BPL L63ac            ; 638D 
                        LDY #$01             ; 638F 
L6391                   JSR L63c1            ; 6391 
                        ASL                  ; 6394 
                        ASL                  ; 6395 
                        ASL                  ; 6396 
                        ASL                  ; 6397 
                        STA $0083,Y          ; 6398 
                        DEC $9e              ; 639B 
                        JSR L63c1            ; 639D 
                        ORA $0083,Y          ; 63A0 
                        STA $0083,Y          ; 63A3 
                        DEC $9e              ; 63A6 
                        DEY                  ; 63A8 
                        BPL L6391            ; 63A9 
                        RTS                  ; 63AB 

L63ac                   JSR L63c1            ; 63AC 
                        ASL                  ; 63AF 
                        ASL                  ; 63B0 
                        ASL                  ; 63B1 
                        ASL                  ; 63B2 
                        STA $82              ; 63B3 
                        DEC $9f              ; 63B5 
                        JSR L63c1            ; 63B7 
                        ORA $82              ; 63BA 
                        STA $82              ; 63BC 
                        DEC $9f              ; 63BE 
                        RTS                  ; 63C0 

L63c1                   TYA                  ; 63C1 
                        PHA                  ; 63C2 
L63c3                   JSR L63e9            ; 63C3 
                        PHA                  ; 63C6 
                        LDA Switches         ; 63C7 
                        AND #$02             ; 63CA 
                        BEQ L63d1            ; 63CC 
                        JMP NMI              ; 63CE 

L63d1                   PLA                  ; 63D1 
                        LDY #$08             ; 63D2 
L63d4                   DEX                  ; 63D4 
                        BNE L63d4            ; 63D5 
                        DEY                  ; 63D7 
                        BNE L63d4            ; 63D8 
                        BIT $aa              ; 63DA 
                        BMI L63c3            ; 63DC 
                        BCS L63c3            ; 63DE 
                        TAX                  ; 63E0 
                        LDA #$80             ; 63E1 
                        STA $aa              ; 63E3 
                        PLA                  ; 63E5 
                        TAY                  ; 63E6 
                        TXA                  ; 63E7 
                        RTS                  ; 63E8 

L63e9                   LDA #$40             ; 63E9 
                        STA $95              ; 63EB 
                        LDA #$80             ; 63ED 
                        STA $94              ; 63EF 
                        LDX #$03             ; 63F1 
L63f3                   JSR L6414            ; 63F3 
                        BNE L6401            ; 63F6 
                        LSR $94              ; 63F8 
                        DEX                  ; 63FA 
                        BPL L63f3            ; 63FB 
                        STA $aa              ; 63FD 
                        SEC                  ; 63FF 
                        RTS                  ; 6400 

L6401                   LDY #$ff             ; 6401 
L6403                   LSR                  ; 6403 
                        INY                  ; 6404 
                        BCC L6403            ; 6405 
                        TXA                  ; 6407 
                        ASL                  ; 6408 
                        ASL                  ; 6409 
                        STY $94              ; 640A 
                        ADC $94              ; 640C 
                        TAX                  ; 640E 
                        LDA $6680,X          ; 640F 
                        CLC                  ; 6412 
                        RTS                  ; 6413 

L6414                   LDY #$00             ; 6414 
                        LDA ($94),Y          ; 6416 
                        AND #$1e             ; 6418 
                        LSR                  ; 641A 
                        LDY $a0,X            ; 641B 
                        STA $a0,X            ; 641D 
                        TYA                  ; 641F 
                        AND $a0,X            ; 6420 
                        ORA $a5,X            ; 6422 
                        STA $a5,X            ; 6424 
                        TYA                  ; 6426 
                        ORA $a0,X            ; 6427 
                        AND $a5,X            ; 6429 
                        STA $a5,X            ; 642B 
                        RTS                  ; 642D 

L642e                   LDX $81              ; 642E 
                        INX                  ; 6430 
                        CPX #$08             ; 6431 
                        BCC L6437            ; 6433 
                        LDX #$01             ; 6435 

L6437                   STX $81              ; 6437 
                        LDA #$00             ; 6439 
                        STA $2800            ; 643B 
                        TXA                  ; 643E 
                        ASL                  ; 643F 
                        ASL                  ; 6440 
                        ASL                  ; 6441 
                        ASL                  ; 6442 
                        ASL                  ; 6443 
                        ORA $9b              ; 6444 
                        STA DigitSelect      ; 6446 
                        LDA Switches         ; 6449 
                        ROR                  ; 644C 
                        ROR                  ; 644D 
                        ROR                  ; 644E 
                        AND #$80             ; 644F 
                        STA $ab              ; 6451 
                        CPX #$07             ; 6453 
                        BNE L6462            ; 6455 
                        LDA #$00             ; 6457 
                        ORA $96              ; 6459 
                        ORA $97              ; 645B 
                        ORA $98              ; 645D 
                        JMP L64b7            ; 645F 

L6462                   DEX                  ; 6462 
                        TXA                  ; 6463 
                        LSR                  ; 6464 
                        TAX                  ; 6465 
                        BNE L6475            ; 6466 
                        LDA $96              ; 6468 
                        BPL L6475            ; 646A 
                        LDA Switches         ; 646C 
                        AND #$10             ; 646F 
                        BEQ L6475            ; 6471 
                        LDX #$03             ; 6473 

L6475                   LDA $82,X            ; 6475 
                        BCS L647d            ; 6477 
                        AND #$0f             ; 6479 
                        BPL L6483            ; 647B 

L647d                   AND #$f0             ; 647D 
                        LSR                  ; 647F 
                        LSR                  ; 6480 
                        LSR                  ; 6481 
                        LSR                  ; 6482 

L6483                   CMP #$0a             ; 6483 
                        BCC L648f            ; 6485 
                        BIT $00AB            ; 6487 
                        BPL L648f            ; 648A 
                        CLC                  ; 648C 
                        ADC #$06             ; 648D 

L648f                   TAY                  ; 648F 
                        LDA $666a,Y          ; 6490 
                        LDX $81              ; 6493 
                        CPX #$03             ; 6495 
                        BCS L64a0            ; 6497 
                        BIT $00AB            ; 6499 
                        BPL L64a0            ; 649C 
                        LDA #$00             ; 649E 

L64a0                   BIT $00AB            ; 64A0 
                        BMI L64b7            ; 64A3 
                        CPX $9f              ; 64A5 
                        BEQ L64b5            ; 64A7 
                        BCC L64b5            ; 64A9 
                        DEX                  ; 64AB 
                        DEX                  ; 64AC 
                        BEQ L64b7            ; 64AD 
                        CPX $9e              ; 64AF 
                        BEQ L64b5            ; 64B1 
                        BCS L64b7            ; 64B3 

L64b5                   LDA #$00             ; 64B5 

L64b7                   STA $2800            ; 64B7 
                        RTS                  ; 64BA 

NormalOp                LDA #$20             ; 64BB 
                        STA DigitSelect      ; 64BD 
                        LDA #$00             ; 64C0 
                        STA $2800            ; 64C2 
                        LDY #$00             ; 64C5 
L64c7                   LDX #$00             ; 64C7 
L64c9                   TYA                  ; 64C9 
                        STA $0080,X          ; 64CA 
                        INY                  ; 64CD 
                        INX                  ; 64CE 
                        BPL L64c9            ; 64CF 
                        TXA                  ; 64D1 
                        CLC                  ; 64D2 
                        ADC #$80             ; 64D3 
                        TAX                  ; 64D5 
                        TYA                  ; 64D6 
                        CLC                  ; 64D7 
                        ADC #$80             ; 64D8 
                        TAY                  ; 64DA 
L64db                   TYA                  ; 64DB 
                        EOR $0080,X          ; 64DC 
                        STA $0080,X          ; 64DF 
                        BEQ L64e8            ; 64E2 
                        LDA #$06             ; 64E4 
                        BNE L6539            ; 64E6 

L64e8                   INY                  ; 64E8 
                        INX                  ; 64E9 
                        BPL L64db            ; 64EA 
                        TYA                  ; 64EC 
                        SEC                  ; 64ED 
                        ADC #$80             ; 64EE 
                        TAY                  ; 64F0 
                        BNE L64c7            ; 64F1 
                        LDA #$67             ; 64F3 
                        STA $95              ; 64F5 
                        LDY #$07             ; 64F7 
                        LDX #$00             ; 64F9 
                        TXA                  ; 64FB 
                        STA $94              ; 64FC 
L64fe                   EOR ($94,X)          ; 64FE 
                        DEC $94              ; 6500 
                        BNE L64fe            ; 6502 
                        DEC $95              ; 6504 
                        DEY                  ; 6506 
                        BPL L64fe            ; 6507 
                        STA $94              ; 6509 
                        CMP #$00             ; 650B 
                        BEQ L6513            ; 650D 
                        LDA #$5b             ; 650F 
                        BNE L6539            ; 6511 

L6513                   LDA RIOT_Reg5        ; 6513 
                        STA RIOT_RdTimer     ; 6515 
                        LDA #$2f             ; 6517 
                        STA RIOT_Wt_Div64_En ; 6519 
                        CLI                  ; 651B 
                        LDA #$00             ; 651C 
                        STA $94              ; 651E 
L6520                   INC $94              ; 6520 
                        LDA $94              ; 6522 
                        BIT $80              ; 6524 
                        BMI L652e            ; 6526 
                        CMP #$b0             ; 6528 
                        BCC L6520            ; 652A 
                        BCS L6532            ; 652C 

L652e                   CMP #$9f             ; 652E 
                        BCS L6536            ; 6530 

L6532                   LDA #$4f             ; 6532 
                        BNE L6539            ; 6534 

L6536                   JMP L6550            ; 6536 

L6539                   LDX #$05             ; 6539 
L653b                   DEX                  ; 653B 
                        BNE L6543            ; 653C 
                        STA $2800            ; 653E 
                        BEQ L6539            ; 6541 

L6543                   LDY #$00             ; 6543 
                        STY $2800            ; 6545 
                        BIT SelfTestSwitch   ; 6548 
                        BMI L653b            ; 654B 
                        JMP NMI              ; 654D 

L6550                   LDA SelfTestSwitch   ; 6550 
                        BMI L6558            ; 6553 
                        JMP NMI              ; 6555 

L6558                   LDY $98              ; 6558 
                        LDA $6599,Y          ; 655A 
                        STA $94              ; 655D 
                        LDA $659a,Y          ; 655F 
                        STA $95              ; 6562 
                        JMP ($0094)          ; 6564 
L6567                   BIT $80              ; 6567 
                        BPL L6567            ; 6569 
                        LDA #$00             ; 656B 
                        STA $80              ; 656D 
                        JSR L65a3            ; 656F 
                        LDA Switches         ; 6572 
                        AND #$0c             ; 6575 
                        BEQ L6550            ; 6577 
                        LDA #$00             ; 6579 
                        STA $2800            ; 657B 
L657e                   LDX #$00             ; 657E 
L6580                   LDA Switches         ; 6580 
                        AND #$0c             ; 6583 
                        BNE L657e            ; 6585 
                        DEX                  ; 6587 
                        BNE L6580            ; 6588 
                        LDX $98              ; 658A 
                        INX                  ; 658C 
                        INX                  ; 658D 
                        CPX #$09             ; 658E 
                        BCC L6594            ; 6590 
                        LDX #$00             ; 6592 

L6594                   STX $98              ; 6594 
                        JMP L6550            ; 6596 

                        !byte                $be,$65,$cd,$65,$db,$65,$f4                                     ; 6599
                        !byte                $65,$0e,$66                                                     ; 65a0


L65a3                   INC $96              ; 65A3 
                        BNE L65a9            ; 65A5 
                        INC $97              ; 65A7 

L65a9                   LDA $96              ; 65A9 
                        AND #$07             ; 65AB 
                        TAX                  ; 65AD 
                        LDA $9b,X            ; 65AE 
                        STA $2800            ; 65B0 
                        LDA $a3,X            ; 65B3 
                        ASL                  ; 65B5 
                        ASL                  ; 65B6 
                        ASL                  ; 65B7 
                        ASL                  ; 65B8 
                        ASL                  ; 65B9 
                        STA DigitSelect      ; 65BA 
                        RTS                  ; 65BD 

                        !byte                $a2,$07                                                         ; 65be
                        !byte                $a9,$ff,$95,$9b,$8a,$95,$a3,$ca,$10,$f6,$4c,$67,$65,$a2,$07,$a9 ; 65c0
                        !byte                $00,$95,$9b,$95,$a3,$ca,$10,$f9,$4c,$67,$65,$a2,$07,$a9,$ff,$85 ; 65d0
                        !byte                $9a,$95,$9b,$a9,$00,$95,$a3,$ca,$10,$f3,$a5,$97,$29,$07,$aa,$95 ; 65e0
                        !byte                $a3,$4c,$67,$65,$a5,$97,$29,$07,$aa,$a9,$00,$38,$2a,$ca,$10,$fc ; 65f0
                        !byte                $a8,$a2,$07,$94,$9b,$8a,$95,$a3,$ca,$10,$f8,$4c,$67,$65,$ad,$05 ; 6600
                        !byte                $40,$4d,$03,$40,$4d,$02,$40,$4d,$00,$40,$4d,$01,$40,$29,$80,$85 ; 6610
                        !byte                $99,$ad,$08,$40,$29,$10,$45,$99,$85,$99,$ad,$00,$41,$29,$04,$45 ; 6620
                        !byte                $99,$85,$99,$ad,$08,$40,$4d,$00,$41,$29,$02,$45,$99,$85,$99,$ad ; 6630
                        !byte                $10,$40,$4d,$20,$40,$4d,$40,$40,$4d,$80,$40,$29,$1e,$45,$99,$c5 ; 6640
                        !byte                $9a,$f0,$14,$85,$9a,$a0,$87,$a5,$9b,$10,$02,$a0,$79,$a2,$07,$94 ; 6650
                        !byte                $9b,$8a,$95,$a3,$ca,$10,$f8,$4c,$67,$65,$3f,$06,$5b,$4f,$66,$6d ; 6660
                        !byte                $7d,$07,$7f,$6f,$f7,$fc,$b9,$de,$f9,$f1,$77,$39,$71,$76,$73,$3e ; 6670
                        !byte                $0f,$0b,$07,$03,$0e,$0a,$06,$02,$0d,$09,$05,$01,$0c,$08,$04,$00 ; 6680
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 6690
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 66a0
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 66b0
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 66c0
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 66d0
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 66e0
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 66f0
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 6700
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 6710
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 6720
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 6730
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 6740
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 6750
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 6760
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 6770
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 6780
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 6790
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 67a0
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 67b0
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 67c0
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 67d0
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff ; 67e0
                        !byte                $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ce,$c7,$60,$c7,$60,$a8,$60 ; 67f0
