arch snes.cpu

HiRom

// Game vars
define GAME_MODE $0036

define MODE_7_PARAMS_1 $0644
define MODE_7_PARAMS_2 $0651
define MODE_7_PARAMS_3 $065e
define MODE_7_PARAMS_4 $066b

define LAKITU_STATUS $1c35
// Game vars

// Hack vars
define TEMP_VAR $7FDE5C
// Hack vars

//Set rom size to 1mb
org $00FFD7
	db $0A

// Disable the window modifying HDMA
org $808ac5
	LDA #$7E
	
org $84ea2e
	LDA #$00
	
// Dont apply x/y mode 7 changes for bottom screen
org $808b67
	NOP
	NOP
	NOP
	
// Disable color window
org $808bda
	STZ $2125

// Disable window enable
org $808be0
	STZ $212e
	
// Disable color mask
org $808be3
	NOP
	LDA #$30

// Disable setting brightness level to 0 at half way point of drawing screen
org $808b42
	NOP
	NOP
	NOP

org $808bc2
	STZ $2131

org $80805c
	JML main
	
org $81fad6
	JML Override_Mode_7_Index_Params_1_And_4
	
org $81fae8
	JML Override_Mode_7_Index_Params_2_And_3

// Never load bottom screen OAM table
org $808b6f
	NOP
	NOP
	NOP

// Disable adding offset to y position
org $80c86e
	ADC $e0

// Fix object ratio for new perspective	
org $80c87c
	JML Hijack_Object_Ratio
	
// Make it so calculation for displayable objects extends beyond middle of screen
org $80c88a
	CMP #$0180
	
// Stop changing the OBSEL and INIDISP register after the middle of the screen
org $808b42
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	
// Stop modifying the M7SEL register after middle of screen
org $808b4f
	NOP
	NOP
	NOP

// Disable bottom screen hdma table updates
org $81faf6
	RTS
	
// Fix lakitu start Y position when showing lap count
org $85dc03
	db $FF
	
// Fix lakitu start Y position when showing reverse message
org $85dc2b
	db $FF

// Fix lakitu start y position for win flag
org $85dc5f
	db $FF
	
// Fix lakitu lap count shown timer start value
org $85dd6c
	db $90
		
// Fix lakitu leaving the screen after showing reverse message
org $85df6b
	CMP #$FF00
	
org $80c93a 
	JML Hijack_Height_Calc

org $888000

//====================================
//====================================
main:

.wait_for_rti:
	LDA $44 // Original code from $80805c
	BEQ .wait_for_rti

	PHP
	PHA
	PHX
	PHY
	
	SEP #$30
	
	LDA {GAME_MODE}
	CMP #$02
	BEQ .continue_main
	
	CMP #$0E
	BNE .exit

.continue_main:
	STZ $212c
	
	LDA #$07
	STA $0679
	
	LDA #$11
	STA $0682
	
	JSR Fix_Coin_Position
	JSR Setup_HDMA_For_New_Tables
	JSR Set_New_Perspective_Params
	
.exit:
	REP #$30
	
	PLY
	PLX
	PLA
	PLP
	
	JML $808060
//====================================

//====================================
//====================================
Fix_Coin_Position:

	LDA #$BC
	STA $0251
	STA $0255
	STA $0259
	STA $025D

	RTS
//====================================

//====================================
//====================================
Setup_HDMA_For_New_Tables:

	//Setup fullscreen indirect hdma
	LDA #$E0
	
	STA $0643
	STA $0650
	STA $065D
	STA $066A
	
	LDA #$E0
	
	STA $0646
	STA $0653
	STA $0660
	STA $066D

	
	//End hdma after applying fullscreen
	LDA #$00
	
	STA $0649
	STA $0656
	STA $0663
	STA $0670

	// Setup hdma banks
	LDA #$C9
	STA $4317
	STA $4337
	
	LDA #$CA
	STA $4327
	STA $4347
	
	RTS
//====================================

//====================================
//====================================
Override_Mode_7_Index_Params_1_And_4:
	PHA
	
	STA {MODE_7_PARAMS_1}
	
	CLC
	ADC #$8000
	STA {MODE_7_PARAMS_1} + 3
	
	PLA
	
	STA {MODE_7_PARAMS_4}

	CLC
	ADC #$8000
	STA {MODE_7_PARAMS_4} + 3

	JML $81fae2
//====================================

//====================================
//====================================
Override_Mode_7_Index_Params_2_And_3:
	STA {MODE_7_PARAMS_3}

	CLC
	ADC #$8000
	STA {MODE_7_PARAMS_3} + 3
	
	LDA $4216
	
	STA {MODE_7_PARAMS_2}

	CLC
	ADC #$8000
	STA {MODE_7_PARAMS_2} + 3
	
	JML $81faf5
//====================================

//====================================
//====================================
Set_New_Perspective_Params:

	LDA #$60
	STA $007C
	
	LDA #$6A
	STA $00E0

	RTS
//====================================

//====================================
//====================================
Hijack_Object_Ratio:
	STA {TEMP_VAR}
	CLC
	ROR
	CLC
	ADC {TEMP_VAR}

	cmp #$0300
	sta $18
	sta $06,x

	JML $80c883
//====================================

//====================================
//====================================
Hijack_Height_Calc:
	SBC $6000
	
	PHA
	
	AND #$FF00

	CMP #$FE00
	BNE .on_screen
	
	PLA
	
	LDA #$FFFF

	PHA
	
.on_screen:
	PLA

	STA $1e
	STA $2e,x

	JML $80c941
//====================================

org $490000
	//incbin HDMA_Mode_7_Tables_Lo.bin
	incbin HDMA_Mode_7_Tables_Lo_Lo.bin

org $498000
	incbin HDMA_Mode_7_Tables_Lo_Hi.bin
	
org $4A0000
	//incbin  HDMA_Mode_7_Tables_Hi.bin
	incbin HDMA_Mode_7_Tables_Hi_Lo.bin
	
org $4A8000
	incbin HDMA_Mode_7_Tables_Hi_Hi.bin