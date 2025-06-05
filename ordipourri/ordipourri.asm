    org 0C009h
    jp init

init:
    di
    ld a, $F0
    out (040h),a        ; Switch to screen 4
    ld a, $FF
    ld ($6000), a
    ld hl, $6000
    ld de, $6001
    ld bc, $17FF
    ldir

    ; Print the top line
    ld hl, txt_preamble
    ld ix, $6201
    call print_text

    ; Print the labels
    ld hl, label_cpu
    ld de, $6708
    call print_label
    ld hl, label_ram
    ld de, $670E
    call print_label
    ld hl, label_gpu
    ld de, $6714
    call print_label

    ld hl, sprite_olipix
    ld de, $6D01
    call print_sprite

    ; Print the result
    ld hl, txt_olipix1
    ld ix, $7200
    call print_text
    ld hl, txt_olipix1b
    ld ix, $7400
    call print_text

    ; Set and print the initial slots
    ld hl, sprite_cpu
    ld (slot_cpu_ptr), hl
    ld de, $6A08
    call print

    ld hl, sprite_ram
    ld (slot_ram_ptr), hl
    ld de, $6A0E
    call print

    ld hl, sprite_gpu
    ld (slot_gpu_ptr), hl
    ld de, $6A14
    call print

    ld a, 0
    ld (stop), a
    call wait_for_space_key

start_game:
    call print_nothing
    ld a, 1
    ld (roll_cpu), a
    ld (roll_ram), a
    ld (roll_gpu), a
    ld a, 0
    ld (stop_msg), a
    ld (slot_cpu_id), a
    ld (slot_ram_id), a
    ld (slot_gpu_id), a

;    ld hl, sprite_cpu
;    ld (slot_cpu_ptr), hl
;    ld hl, sprite_ram
;    ld (slot_ram_ptr), hl
;    ld hl, sprite_gpu
;    ld (slot_gpu_ptr), hl

print_slot_loop:
    ld a, (slot_cpu_line)
    dec a                       ; slot_cpu_line--
    jp nz, print_slot           ; if slot_cpu_line == 0
    ld a, 48                    ; slot_cpu_line = 40
    ld hl, sprite_cpu
    ld (slot_cpu_ptr), hl
    ld hl, sprite_ram
    ld (slot_ram_ptr), hl
    ld hl, sprite_gpu
    ld (slot_gpu_ptr), hl    
print_slot:
    ld (slot_cpu_line), a

; ********************************************************************
read_keyboard:
    in a,(083h)
    bit 7, a
    jp z, process_space_key
    ld a, 0
    ld (space_key_down), a      ; If the space key is not pressed, space_key_down = 0
    jp check_space_end

process_space_key:              ; Space key is pressed
    ld a, (space_key_down)
    cp 0
    jp nz, check_space_end      ; if space_key_down == 1, skip

    ld a, 1
    ld (space_key_down), a      ; space_key_down = 1
    ld (stop_msg), a            ; stop_msg = 1

check_space_end:

    ld a, (slot_cpu_line)
    and 7
    cp 7
    jp nz, check_stop_end    ; if slop_cpu_line & 0x07 != 7, skip

    ld a, (slot_cpu_line)
    sra a
    sra a
    sra a
    ld b, a

    jp check_stop_msg

update_cpu_roll:
    ld a, (roll_cpu)
    cp 0
    jp z, update_ram_roll
    ld a, (slot_cpu_id)
    cp 5
    jp z, reset_slot_cpu_id
    inc a
    ld (slot_cpu_id), a
    jp update_ram_roll
reset_slot_cpu_id:
    ld a, 0
    ld (slot_cpu_id), a
update_ram_roll:
    ld a, (roll_ram)
    cp 0
    jp z, update_gpu_roll
    ld a, (slot_ram_id)
    cp 5
    jp z, reset_slot_ram_id
    inc a
    ld (slot_ram_id), a
    jp update_gpu_roll
reset_slot_ram_id:
    ld a, 0
    ld (slot_ram_id), a
update_gpu_roll:
    ld a, (roll_gpu)
    cp 0
    jp z, check_stop_msg
    ld a, (slot_gpu_id)
    cp 5
    jp z, update_slot_gpu_id
    inc a
    ld (slot_gpu_id), a
    jp check_stop_msg
update_slot_gpu_id:
    ld a, 0
    ld (slot_gpu_id), a
check_stop_msg:
    ld a, (stop_msg)
    cp 0
    jp z, check_stop_end

    ld a, 0
    ld (stop_msg), a            ; reset stop_msg = 0

    ld a, (roll_cpu)
    cp 0
    jp z, stop_roll_cpu_end     ; if roll_cpu == 0, look at roll_ram
    ld a, 0
    ld (roll_cpu), a
    ld a, b
    ld (slot_cpu_id), a
    jp check_stop_end
stop_roll_cpu_end:

    ld a, (roll_ram)
    cp 0
    jp z, stop_roll_ram_end
    ld a, 0
    ld (roll_ram), a
    ld a, b
    ld (slot_ram_id), a
    jp check_stop_end
stop_roll_ram_end:
    ld a, 0
    ld (roll_gpu), a
    ld a, b
    ld (slot_gpu_id), a
    ld a, 1
    ld (stop), a    
    jp gameover
check_stop_end:

; ********************************************************************
; * DRAW SLOTS
; ********************************************************************

    ld a, (roll_cpu)
    cp 0
    jp z, print_cpu_end
    ld de, $6A08
    ld hl, (slot_cpu_ptr)
    call print
    ld hl, (slot_cpu_ptr)
    ld bc, 0004h
    add hl, bc
    ld (slot_cpu_ptr), hl
print_cpu_end:

    ld a, (roll_ram)
    cp 0
    jp z, print_ram_end
    ld de, $6A0E
    ld hl, (slot_ram_ptr)
    call print
    ld hl, (slot_ram_ptr)
    ld bc, 0004h
    add hl, bc
    ld (slot_ram_ptr), hl
print_ram_end:

    ld a, (roll_gpu)
    cp 0
    jp z, print_gpu_end
    ld de, $6A14
    ld hl, (slot_gpu_ptr)
    call print
    ld hl, (slot_gpu_ptr)
    ld bc, 0004h
    add hl, bc
    ld (slot_gpu_ptr), hl
print_gpu_end:

    jp print_slot_loop

gameover:
    ld a, 0
    ld (stop), a

    ; If slot_cpu_id, slot_ram_id or slot_gpu_id == 0 => too underpowered
    ld a, (slot_cpu_id)
    cp 0
    jp z, print_too_underpowered
    ld a, (slot_ram_id)
    cp 0
    jp z, print_too_underpowered
    ld a, (slot_gpu_id)
    cp 0
    jp z, print_too_underpowered

    ; Otherwise, if slot_cpu_id, slot_ram_id or slot_gpu_id >= 4
    ; => overpowered
    ld a, (slot_cpu_id)
    cp 4
    jp z, print_overpowered
    cp 5
    jp z, print_overpowered
    ld a, (slot_ram_id)
    cp 4
    jp z, print_overpowered
    cp 5
    jp z, print_overpowered
    ld a, (slot_gpu_id)
    cp 4
    jp z, print_overpowered
    cp 5
    jp z, print_overpowered

    ; Otherwise => just right!
    jp print_underpowered
ready_for_next_game:
    call wait_for_space_key
    jp start_game

print_overpowered:
    ld hl, txt_olipix1
    ld ix, $7200
    call print_text
    ld hl, txt_olipix1b
    ld ix, $7400
    call print_text
    jp ready_for_next_game

print_underpowered:
    ld hl, txt_olipix2
    ld ix, $7200
    call print_text
    ld hl, txt_olipix2b
    ld ix, $7400
    call print_text
    jp ready_for_next_game

print_too_underpowered:
    ld hl, txt_olipix3
    ld ix, $7200
    call print_text
    ld hl, txt_olipix3b
    ld ix, $7400
    call print_text
    jp ready_for_next_game

print_nothing:
    ld a, $ff
    ld ($4180), a
    ld hl, 07180h
    ld de, 07181h
    ld bc, 00380h
    ldir
    ret

print:
    ldi
    ldi
    ldi
    ldi
    ld bc, 0001Ch
    ex de,hl
    add hl, bc
    ex de,hl
    ldi
    ldi
    ldi
    ldi
    ld bc, 0001Ch
    ex de,hl
    add hl, bc
    ex de,hl
    ldi
    ldi
    ldi
    ldi
    ld bc, 0001Ch
    ex de,hl
    add hl, bc
    ex de,hl
    ldi
    ldi
    ldi
    ldi
    ld bc, 0001Ch
    ex de,hl
    add hl, bc
    ex de,hl
    ldi
    ldi
    ldi
    ldi
    ld bc, 0001Ch
    ex de,hl
    add hl, bc
    ex de,hl
    ldi
    ldi
    ldi
    ldi
    ld bc, 0001Ch
    ex de,hl
    add hl, bc
    ex de,hl
    ldi
    ldi
    ldi
    ldi
    ld bc, 0001Ch
    ex de,hl
    add hl, bc
    ex de,hl
    ldi
    ldi
    ldi
    ldi
    ret

print_label:
    ld a, 15
print_label_loop:
    ldi
    ldi
    ldi
    ldi
    ld bc, 0001Ch
    ex de,hl
    add hl, bc
    ex de,hl
    dec a
    jp nz, print_label_loop
    ret

print_sprite:
    ld a, 31
print_sprite_loop:
    ldi
    ldi
    ldi
    ld bc, 0001Dh
    ex de,hl
    add hl, bc
    ex de,hl
    dec a
    jp nz, print_sprite_loop
    ret

print_text:
    ld iy, 04FECh
    ld a, (hl)
    cp 0
    jp z, print_test_end
    sla a
    sla a
    sla a
    ld c,a
    ld a, (hl)
    and $E0
    sra a
    sra a
    sra a
    sra a
    sra a
    ld b, a
    add iy, bc
    ld a, (hl)
    sla a
    sla a
    ld c,a
    ld a, (hl)
    and $C0
    sra a
    sra a
    sra a
    sra a
    sra a
    sra a
    ld b, a
    add iy, bc
    push ix
    ld a, (iy+0)
    cpl
    ld (ix-128), a
    ld a, (iy+1)
    cpl
    ld (ix-96), a
    ld a, (iy+2)
    cpl
    ld (ix-64), a
    ld a, (iy+3)
    cpl
    ld (ix-32), a
    ld a, (iy+4)
    cpl
    ld (ix+0), a
    ld a, (iy+5)
    cpl
    ld (ix+32), a
    ld a, (iy+6)
    cpl
    ld (ix+64), a
    ld a, (iy+7)
    cpl
    ld (ix+96), a
    ld bc, 00080h
    add ix, bc
    ld a, (iy+8)
    cpl
    ld (ix+0), a
    ld a, (iy+9)
    cpl
    ld (ix+32), a
    ld a, (iy+10)
    cpl
    ld (ix+64), a
    ld a, (iy+11)
    cpl
    ld (ix+96), a
    pop ix
    inc ix
    inc hl
    jp print_text
print_test_end:
    ret

wait_for_space_key:
    in a,(083h)
    bit 7, a
    jp z, wait_for_space_key    ; Make sure the space key is not pressed
wait_for_space_key_down:
    in a,(083h)
    bit 7, a
    jp nz, wait_for_space_key_down ; Make sure the space key is pressed
wait_for_space_key_up:
    in a,(083h)
    bit 7, a
    jp z, wait_for_space_key_up ; Make sure the space key is not pressed
    ret

random:
        push    hl
        push    de
        ld      hl,(rand_data)
        ld      a,r
        ld      d,a
        ld      e,(hl)
        add     hl,de
        add     a,l
        xor     h
        ld      (rand_data),hl
        pop     de
        pop     hl
        ret

roll_cpu:
    db 0
roll_ram:
    db 0
roll_gpu:
    db 0
slot_cpu_ptr:
    db 1, 1
stop_msg:
    db 0
slot_ram_ptr:
    db 1, 1
space_key_down:
    db 0
slot_gpu_ptr:
    db 1, 1
slot_cpu_id:
    db 0
slot_ram_id:
    db 0
slot_gpu_id:
    db 0
slot_cpu_line:
    db 48
font_ptr:
    db 0, 0
stop:
    db 0
rand_data:
    db 0x34, 0xFA

txt_preamble:
    db "Olipix a un probleme. Aidez-le",0

txt_olipix1:
    db "Mon ordinateur est sur-puissant ",0
txt_olipix1b:
    db "C'est nul!   ",0

txt_olipix2:
    db "Mon ordinateur est tout pourri  ",0
txt_olipix2b:
    db "C'est genial!",0

txt_olipix3:
    db "C'est trop pourri, meme pour moi",0
txt_olipix3b:
    db "C'est chiant",0

label_cpu:
    db $FD,$55,$55,$7F,$FD,$55,$55,$7F,$F8,$00,$00,$3F,$F8,$00,$00,$3F,$F8,$00,$00,$3F,$F8,$33,$92,$3F,$F8,$4A,$52,$3F,$F8,$43,$92,$3F
    db $F8,$4A,$12,$3F,$F8,$32,$0C,$3F,$F8,$00,$00,$3F,$F8,$00,$00,$3F,$F8,$00,$00,$3F,$FD,$55,$55,$7F,$FD,$55,$55,$7F
label_ram:
    db $80,$70,$0E,$01,$00,$20,$04,$00,$80,$70,$0E,$01,$00,$20,$04,$00,$80,$70,$0E,$01,$1C,$21,$84,$88,$92,$72,$4E,$D9,$1C,$23,$C4,$A8
    db $92,$72,$4E,$89,$12,$22,$44,$88,$80,$70,$0E,$01,$00,$20,$04,$00,$80,$70,$0E,$01,$00,$20,$04,$00,$80,$70,$0E,$01
label_gpu:
    db $FF,$55,$AA,$FF,$FE,$00,$00,$7F,$FC,$FF,$FF,$3F,$F9,$00,$00,$9F,$FD,$00,$00,$BF,$F9,$3B,$92,$9F,$FD,$42,$52,$BF,$F9,$5B,$92,$9F
    db $FD,$4A,$12,$BF,$F9,$3A,$0C,$9F,$FD,$00,$00,$BF,$F9,$00,$00,$9F,$FC,$FF,$FF,$3F,$FE,$00,$00,$7F,$FF,$55,$AA,$FF
sprite_cpu:
    db $00,$00,$00,$00,$31,$9C,$F0,$5E,$4A,$52,$80,$10,$42,$5C,$E0,$5C,$4A,$52,$80,$42,$31,$92,$F0,$5C,$00,$00,$00,$00,$FF,$FF,$FF,$FF
    db $00,$00,$00,$00,$07,$31,$8C,$60,$08,$4A,$52,$90,$0E,$32,$52,$90,$09,$4A,$52,$90,$06,$31,$8C,$60,$00,$00,$00,$00,$FF,$FF,$FF,$FF
    db $00,$00,$00,$00,$01,$CC,$63,$00,$02,$12,$94,$80,$03,$8C,$93,$80,$02,$52,$90,$80,$01,$8C,$67,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF
    db $00,$00,$00,$00,$00,$1E,$63,$00,$00,$02,$94,$80,$00,$04,$64,$80,$00,$08,$94,$80,$00,$1E,$63,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF
    db $00,$00,$00,$00,$01,$DE,$63,$00,$02,$10,$94,$80,$03,$9C,$91,$00,$02,$42,$92,$00,$01,$9C,$67,$80,$00,$00,$00,$00,$FF,$FF,$FF,$FF
    db $00,$00,$00,$00,$05,$06,$32,$00,$01,$49,$4A,$80,$05,$E9,$4B,$C0,$04,$49,$48,$80,$04,$46,$30,$80,$00,$00,$00,$00,$FF,$FF,$FF,$FF
    db $00,$00,$00,$00,$31,$9C,$F0,$5E,$4A,$52,$80,$10,$42,$5C,$E0,$5C,$4A,$52,$80,$42,$31,$92,$F0,$5C,$00,$00,$00,$00,$FF,$FF,$FF,$FF
sprite_ram:
    db $00,$00,$00,$00,$03,$A0,$77,$00,$04,$28,$84,$80,$07,$3C,$B7,$00,$04,$88,$94,$80,$03,$08,$77,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF
    db $00,$00,$00,$00,$00,$30,$8B,$80,$00,$48,$DA,$40,$00,$30,$AB,$80,$00,$48,$8A,$40,$00,$30,$8B,$80,$00,$00,$00,$00,$FF,$FF,$FF,$FF
    db $00,$00,$00,$00,$03,$A0,$97,$00,$04,$28,$A4,$80,$07,$3C,$C7,$00,$04,$88,$A4,$80,$03,$08,$97,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF
    db $00,$00,$00,$00,$01,$1C,$97,$00,$03,$20,$A4,$80,$01,$38,$C7,$00,$01,$24,$A4,$80,$03,$98,$97,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF
    db $00,$00,$00,$00,$00,$18,$97,$00,$00,$24,$A4,$80,$00,$18,$C7,$00,$00,$24,$A4,$80,$00,$18,$97,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF
    db $00,$00,$00,$00,$01,$18,$C7,$00,$03,$25,$24,$80,$01,$08,$C7,$00,$01,$11,$24,$80,$03,$BC,$C7,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF
    db $00,$00,$00,$00,$03,$A0,$77,$00,$04,$28,$84,$80,$07,$3C,$B7,$00,$04,$88,$94,$80,$03,$08,$77,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF
sprite_gpu:
    db $00,$00,$00,$00,$25,$17,$73,$98,$35,$12,$49,$24,$2C,$A2,$49,$3C,$24,$A2,$49,$24,$24,$47,$73,$A4,$00,$00,$00,$00,$FF,$FF,$FF,$FF
    db $00,$00,$00,$00,$06,$3A,$52,$70,$09,$43,$52,$80,$0F,$5A,$D2,$60,$09,$4A,$52,$10,$09,$3A,$4C,$E0,$00,$00,$00,$00,$FF,$FF,$FF,$FF
    db $00,$00,$00,$00,$44,$C7,$32,$1E,$6D,$28,$4A,$82,$55,$0E,$33,$C4,$45,$29,$48,$88,$44,$C6,$30,$88,$00,$00,$00,$00,$FF,$FF,$FF,$FF
    db $00,$00,$00,$00,$7B,$C6,$71,$DE,$42,$09,$0A,$10,$73,$87,$33,$9C,$42,$01,$0A,$42,$7A,$0E,$71,$9C,$00,$00,$00,$00,$FF,$FF,$FF,$FF
    db $00,$00,$00,$00,$00,$4A,$0C,$00,$00,$4A,$12,$00,$00,$4A,$1E,$00,$00,$4A,$12,$00,$00,$33,$D2,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF
    db $00,$00,$00,$00,$04,$98,$3A,$20,$06,$A4,$12,$20,$05,$A4,$11,$40,$04,$A4,$11,$40,$04,$98,$10,$80,$00,$00,$00,$00,$FF,$FF,$FF,$FF
    db $00,$00,$00,$00,$25,$17,$73,$98,$35,$12,$49,$24,$2C,$A2,$49,$3C,$24,$A2,$49,$24,$24,$47,$73,$A4,$00,$00,$00,$00,$FF,$FF,$FF,$FF
sprite_olipix:
    db $FF,$6D,$FF,$FE,$A2,$BF,$FC,$00,$7F,$F8,$A2,$8F,$F9,$FF,$0F,$D3,$FF,$D7,$E7,$FF,$EF,$D7,$FF,$EB,$AF,$FF,$F7,$DC,$3C,$3B,$BF,$FF
    db $F7,$D8,$00,$1B,$B7,$EB,$E7,$C6,$6A,$6B,$96,$5A,$69,$67,$DD,$E6,$58,$3E,$1A,$6F,$DB,$F6,$BF,$DB,$FE,$BF,$FF,$FD,$DF,$5A,$FD,$DE
    db $FF,$5B,$DF,$81,$F7,$ED,$FF,$A7,$F6,$FE,$CF,$F3,$7F,$AF,$F5,$7B,$4F,$F6,$BE,$AF,$F7,$55,$6F,$F7,$EB,$EF,$EF,$FF,$F7
