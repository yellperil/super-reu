
	.export initmmc64, selectmmc64, deselectmmc64, checkcardmmc64
	.export blockread1, blockreadn, blockreadmulticmd, stopcmd
	.exportzp mmcptr, blknum


	.zeropage

mmcptr:	.res 2
blknum:	.res 4
blkcnt:	.res 1
sdtype: .res 1

	.code

	
; Initialize a flash card plugged into the MMC64
; C: output, 0 ok, 1 fail
; A: output, 1=SD1, 2=SD2, 3=SDHC, 8=no card, 0=communication failure
	
initmmc64:
	lda #0
	sta sdtype
	lda $de11	;get contents of MMC64 control register
	and #%10111011	;set 250khz & write trigger mode
	ora #%00000010	;disable card select
	sta $de11	;update control register
	ldx #$50	;initialize counter (80*8 pulses)
	ldy #$ff	;initialize value to be written (bits must be all high)
@mmcinitloop:	
	sty $de10	;send 8 pulses to the card
@busywait:	
	lda $de12	;we catch the status register
	and #$01	;all bits shiftet out?
	bne @busywait	;nope, so wait
	dex		;decrement counter
	bne @mmcinitloop;until 640 pulses sent
	lda $de12		;is there a card at all ?
	and #$08		
	bne @error		;nope, bail out
	lda $de11	;pull card chip select line down for SPI communication
	and #%11111101
	sta $de11
	ldy #$06		;we send 6 command bytes to the card
@mmc64resetloop:
	lda @resetcmd-1,y	;grab command byte
	sta $de10		;and fire it to the card
@resetbusy:	
	lda $de12		;we check the busy bit
	and #$01		;to ensure that the transfer is safe
	bne @resetbusy
	dey			;decrease command counter
	bne @mmc64resetloop	;until the entire command has been sent
	jsr @readr1slow
	cmp #$01		;did it accept the command ?
	beq @done		;ok, everything is fine !

@commfail:
	lda #0
@error:
	tay
	sec
	bcs @leave

@done:
	ldy #$06		;try to send CMD8
@sendifcondloop:	
	lda @sendifcondcmd-1,y	;grab command byte
	sta $de10		;and fire it to the card
@ifcondbusy:
	lda $de12		;we check the busy bit
	and #$01		;to ensure that the transfer is safe
	bne @ifcondbusy
	dey			;decrease command counter	
	bne @sendifcondloop	;until entire command has been sent
	jsr @readr1slow
	bmi @commfail
	and #$04		;did the card accept the command
	bne @issd1
	jsr @getbyteslow
	jsr @getbyteslow
	jsr @getbyteslow
	cmp #$01
	bne @commfail
	jsr @getbyteslow
	cmp #$aa
	bne @commfail

	ldy #$40	; request HC mode
@issd1:
	jsr deselectmmc64
	lda $de11		;switch to 8Mhz
	ora #%00000100
	sta $de11
	jsr selectmmc64

@activate:
	lda #$77	; CMD55, application command follows
	jsr mmc64cmd
	lda #$69	; ACMD41, SEND_OP_COND
	jsr mmc64cmdparam1
	cmp #$01
	beq @activate
	cmp #$00
	bne @commfail
	iny
	cpy #1
	beq @done2
	ldy #2
	lda #$7a
	jsr mmc64cmd	; CMD58, READ_OCR
	bne @commfail
	stx $de10
	lda $de10
	and #$40
	beq @nohc
	iny
@nohc:
	stx $de10
	stx $de10
	stx $de10
@done2:
	sty sdtype
	clc
@leave:
	jsr deselectmmc64
	tya
@done3:
	rts

@readr1slow:
	ldx #6
@waitr1slow:
	lda $de10		;now we check the card response
	bpl @done3		;got R1
	dex
	bmi @r1fail
	lda #$ff
	sta $de10
@waitr1busy:	
	lda $de12		;we check the busy bit
	and #$01		;to ensure that the transfer is safe
	bne @waitr1busy
	beq @waitr1slow
@r1fail:
	txa
	rts

@getbyteslow:
	lda #$ff
	sta $de10
@waitbyte:	
	lda $de12		;we check the busy bit
	and #$01		;to ensure that the transfer is safe
	bne @waitbyte
	lda $de10
	rts

@resetcmd:	
	.byte $95,$00,$00,$00,$00,$40	;CMD0

@sendifcondcmd:
	.byte $87,$aa,$01,$00,$00,$48	;CMD8


selectmmc64:
	lda #$ff
	sta $de10
@waitselect:
	lda $de12
	and #$01
	bne @waitselect
	lda $de11
	and #%11111101  ;enable card select
	sta $de11
	rts

deselectmmc64:
	lda $de11
	ora #%00000010	;disable card select
	sta $de11
	rts


	;; Read 1-256 blocks
	;; A - in: number of blocks (0 == 256)
	;; X,Y:	scratch
	;; C - out: 0=ok, 1=fail
blockreadn:
	cmp #1
	beq blockread1
	sta blkcnt
	jsr blockreadmulticmd
	bne loopreadnblocks
@moreblocks:
	jsr blockread
	bcs readfail
	dec blkcnt
	bne @moreblocks	
	jsr stopcmd
	bne readfail
	clc
	rts

loopreadnblocks:	
	jsr blockreadcmd
	bne readfail
	jsr blockread
	bcs readfail
	dec blkcnt
	bne loopreadnblocks
	clc
	rts
	
readfail:
	sec
	rts

	;; Read one block
blockread1:
	jsr blockreadcmd
	bne readfail
	; fallthrough to blockread
		
; Transfer 512 bytes from card into memory

blockread:	
@waitformmcdata:
	lda #$ff	
	sta $de10		;write all high bits
	lda $de10		;to give the possibility to respond
	cmp #$ff		;has it started?
	beq @waitformmcdata 	;nop, so we continue waiting
	cmp #$fe
	bne readfail

	lda $de11		;set MMC64 into read trigger mode
	ora #%01000000		;which means every read triggers a SPI transfer
	sta $de11

	lda $de10		;we have to start with one dummy read here

	ldx #$02		;set up counters
	ldy #$00
@sectorcopyloop:	
	lda $de10		;get data byte from card
	sta (mmcptr),y		;store it into memory ( mmcptr has to be initialized)
	iny			;have we copied 256 bytes ?
	bne @sectorcopyloop	;nope, so go on!
	inc mmcptr+1		;increase memory pointer for next 256 bytes
	dex			;have we copied 512 bytes ?
	bne @sectorcopyloop

	lda $de10		;we have to end the data transfer with one dummy read
	
	lda $de11		;now we put the hardware back into write trigger mode again
	and #%10111111	
	sta $de11
	inc blknum
	bne @nowrap
	inc blknum+1
	bne @nowrap
	inc blknum+2
	bne @nowrap
	inc blknum+3
@nowrap:
	clc
	rts



;Stop the data transfer

stopcmd:	
	lda #$4c		; CMD12
	bne mmc64cmd


;Block read commands

blockreadmulticmd:
	lda #$52		; CMD18
	bne mmc64cmdparamblk
	
blockreadcmd:	
	lda #$51		;  CMD17

	;; Send a command with the block number as parameter
	;; A - in: command number + $40, out: R1
	;; X - out: $ff
	;; Y - preserved
mmc64cmdparamblk:
	ldx #$ff
	sta $de10
	lda sdtype
	cmp #3
	bcc @byte_addressed
	lda blknum+3
	sta $de10
	lda blknum+2
	sta $de10
	lda blknum+1
	sta $de10
	lda blknum
	sta $de10
	jmp mmc64cmdcommon2

@byte_addressed:
	lda blknum+1
	asl
	lda blknum+2
	rol
	sta $de10
	lda blknum
	asl
	lda blknum+1
	rol
	sta $de10
	lda blknum
	asl
	sta $de10
	lda #0
	sta $de10
	beq mmc64cmdcommon2


	;; Send a command with a single byte parameter (in the high 8 bits)
	;; A - in: command number + $40, out: R1
	;; X - out: $ff
	;; Y - in: parameter byte, preserved
mmc64cmdparam1:
	ldx #$ff
	sta $de10
	sty $de10
	inx
	beq mmc64cmdcommon1
	
	;; Send a command with an all zeros parameter
	;; A - in: command number + $40, out: R1
	;; X - out: $ff
	;; Y - preserved
mmc64cmd:
	ldx #$ff
	sta $de10
	inx
	stx $de10
mmc64cmdcommon1:
	stx $de10
	stx $de10
	stx $de10
	dex
mmc64cmdcommon2:	
	stx $de10 ; CRC7
	stx $de10 ; dummy
	stx $de10 ; R1?
	lda $de10
	bpl @gotr1
	stx $de10
	lda $de10
	bpl @gotr1
	stx $de10
	lda $de10
	bpl @gotr1
	stx $de10
	lda $de10
@gotr1:	
	rts

	;; Check if card present
	;; A - scratch
	;; X - preserved
	;; Y - preserved
	;; Z - out: 1=present 0=not present
checkcardmmc64:
	lda $de12
	and #$08
	rts
