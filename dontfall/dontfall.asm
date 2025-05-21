    jp init

tileset:
    db 0, 0, $7F, $FC
    db 0, 0, $CE, $A2
    db 0, 0, $BD, $72
    db 0, 0, $B5, $FA

    db 0, 0, $B5, $FA
    db 0, 0, $DB, $EE
    db 0, 0, $B7, $FA
    db 0, 0, $DB, $FC

    db 0, 0, $F7, $FA
    db 0, 0, $DB, $DA
    db 0, 0, $F7, $F4
    db 0, 0, $AF, $FA

    db 0, 0, $DB, $D4
    db 0, 0, $F5, $AA
    db 0, 0, $7F, $54
    db 0, 0, $00, $00

init:
    ld a, $F0
    out (040h),a        ; Switch to screen 4

splash:
    ld a, 0
    ld ($6000), a
    ld hl, $6000
    ld de, $6001
    ld bc, $17FF
    ldir
    ld hl, txt_dont_fall
    ld ix, $660B
    call print
    ld hl, txt_ecdhe
    ld ix, $680C
    call print
    ld hl, txt_keyboard_left
    ld ix, $720F
    call print
    ld hl, txt_keyboard_right
    ld ix, $740F
    call print
    ld hl, txt_keyboard_jump
    ld ix, $700B
    call print
    call wait_for_space_key

; sprite_screen_ptr: where to draw the sprite. Used to detect top collisions and ceiling collision when jumping
; sprite_bitmap_ptr: sprite bitmap
; iy: pointer at the bottom of the sprite (one byte left). Used to detect bottom collisions and the ground
; ix: pointer to the next tile to draw from the tilemap
init_game:
    ld a, 1
    ld (key_space_down), a  ; key_space_down = 1
    ld (sprite_x), a
    ld a, 16
    ld (tile_line_left), a
    ld a, 12
    ld (row), a
    ld a, 192
    ld (init_lines), a
    ld a, $30
    ld (score), a
    ld (score+1), a
    ld (score+2), a
    ld a, 0
    ld (sprite_dir), a
    ld (sprite_jump), a
    ld (sprite_jump_shift), a
    ld (sprite_falling), a
    ld (sprite_4line_offset), a

    ld hl, tileset       ; HL = tile to draw
    push hl
    ld ix, tilemap       ; IX = pointer to the tilemap
    ld hl, sprite_right0
    ld (sprite_bitmap_ptr), hl
;    ld hl, 06202h
    ld hl, 06C06h
    ld (sprite_screen_ptr), hl
    ld iy, 06E05h
    ld de, 07800h
game_loop:
    ld a, (init_lines)
    cp 0
    jp z, scroll_screen_up
draw_initial_screen:
    dec a
    ld (init_lines), a
    ex de,hl
    ld bc, $FFC0
    add hl,bc
    ex de,hl
    ld bc, $0020             ; C = number of tiles to display
    pop hl
    jp draw_tile_line

scroll_screen_up:
    ld a, 191
    ld hl,077dfh
    ld de,077FFh
scroll_loop:
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    ldd
    dec a
    jp nz, scroll_loop

move_sprite_ptr_down_one_line:
    ld hl,(sprite_screen_ptr)
    ld bc, 00020h
    add hl,bc
    ld (sprite_screen_ptr),hl
    add iy,bc

    call erase_bottom

    ld a, (sprite_4line_offset)
    sub a, $20
    cp $80
    jp nz, update_4line_offset
    ld a, 0
update_4line_offset:
    ld (sprite_4line_offset), a

; **************** READ KEYBOARD
; $83, bit 7: space
; $87, bit 3: <
; $87, bit 7: >
read_keyboard:
    in a,(083h)
keyboard_check_jump:
    bit 7, a                    ; Check if the space key is pressed
    jp z, try_to_jump
    ld a, 0
    ld (key_space_down), a      ; If no jump, key_space_down = 0
    jp keyboard_check_jump_end
try_to_jump:
    ld a, (key_space_down)
    cp 0
    jp nz, keyboard_check_jump_end    ; if key_space_down != 0, skip the jump
    ld a, (sprite_jump)
    cp 0
    jp nz, keyboard_check_jump_end    ; If the player is already jumping, skip
    ld a, (iy+33)
    cp 0
    jp nz, check_above_player       ; Make sure there is some ground underneath
    ld a, (iy+34)
    cp 0
    jp nz, check_above_player
    jp keyboard_check_jump_end
check_above_player:
    ld hl,(sprite_screen_ptr)
    dec h
    ld a, (hl)
    cp 0
    jp nz, keyboard_check_jump_end
    inc l
    ld a, (hl)
    cp 0
    jp nz, keyboard_check_jump_end
    ld a, 1
    ld (key_space_down), a      ; key_space_down = 1
    ld a, 6
    ld (sprite_jump),a
    ld a, 000h
    ld (sprite_jump_shift), a
keyboard_check_jump_end:

keyboard_check_left:
    in a,(087h)
    ld b, a
    bit 3, a
    jp nz, keyboard_check_right
    ld a, 2
    ld (sprite_dir), a
    jp keyboard_end
keyboard_check_right:
    ld a, b
    bit 7, a
    jp nz, keyboard_end
    ld a, 1
    ld (sprite_dir), a
keyboard_end:

; **************** SPRITE
sprite_start:
    ld a, (sprite_falling)
    cp 0
    jp nz, check_fall
    ld a, (sprite_jump)
    cp 0
    jp z, end_sprite_jump     ; Is the player jumping?
; *** JUMP
    dec a
    ld (sprite_jump), a
    call erase_sprite               ; Erase current
    ld a, (sprite_jump_shift)
    ld hl,(sprite_screen_ptr)
    ld b, 0ffh
    ld c, a
    add hl,bc                       ; HL = new address of sprite_screen_ptr
    ld a, (hl)
    cp 0
    jp nz, abort_jump               ; if *HL != 0, abort jump
    inc l                           ; HL++
    ld a, (hl)                      
    dec l                           ; HL--
    cp 0                            ; if *(HL+1) != 0, abort jump
    jp nz, abort_jump
    jp sprite_move_screen_ptr       ; We're ready to store HL
abort_jump:
    ld a, 0
    ld (sprite_jump), a             ; sprite_jump = 0
    ld hl,(sprite_screen_ptr)
    ld a, (sprite_4line_offset)
    add a, l
    and $60
    cp 0
    jp z, end_sprite_jump
    ld b, a
    ld a, $0
    sbc a,b
    ld b, $FF
    ld c, a                         ; Make sure HL is on a 4-line block
    add hl,bc
    ld (sprite_screen_ptr),hl
    add iy,bc
    jp end_sprite_jump
sprite_move_screen_ptr:
    ld (sprite_screen_ptr),hl       ; screen_screen_ptr += sprite_jump_shift
    add iy,bc
    ld a, (sprite_jump)
    cp 1
    jp nz, normal_jump_shift
    ld a, (sprite_jump_shift)
    add 040h                        ; if ???, sprite_jump_shift += $20
    ld (sprite_jump_shift), a       ; sprite_jump_shift += $20
    jp end_check_fall
normal_jump_shift:
    ld a, (sprite_jump_shift)
    add 020h                        ; if ???, sprite_jump_shift += $20
    ld (sprite_jump_shift), a       ; sprite_jump_shift += $20
    jp end_check_fall
end_sprite_jump:

check_fall:
    ld a, 0
    ld (sprite_falling), a
    ld a, (iy+33)
    cp 0
    jp nz, end_check_fall
    ld a, (iy+34)
    cp 0
    jp nz, end_check_fall
falling:
    ld a, 1
    ld (sprite_falling), a
    call erase_sprite
    ld hl, (sprite_screen_ptr)
    ld bc, 00080h
    add hl, bc
    ld (sprite_screen_ptr), hl
    add iy, bc
end_check_fall:

draw_sprite:            ; Draw the sprite
    ld a, 16
    ld hl,(sprite_bitmap_ptr)
    ld de,(sprite_screen_ptr)
draw_sprite_loop:
    ldi
    ldi
    ld bc, 0001eh
    ex de,hl
    add hl,bc
    ex de,hl            ; DE += 30 (next screen line)
    dec a
    jp nz, draw_sprite_loop

; *****************************************************
; * MOVE SPRITE
; *****************************************************
check_sprite_direction:
    ld a, (sprite_dir)
    cp 1
    jp z, move_sprite_right     ; if sprite_dir == 1, jump to move_sprite_right
    cp 2
    jp z, move_sprite_left      ; if sprite_dir == 2, jump to move_sprite_left
    jp end_move_sprite

; ******** MOVE RIGHT
move_sprite_right:
    ld a, (sprite_x)
    cp 3
    jp nz, shift_sprite_right   ; if sprite_x == 3
move_sprite_ptr_right:          ; We need to move the screen ptr of one byte and reset the bitmap ptr
    ld hl,(sprite_screen_ptr)
    inc l
    inc l
    ld a, (hl)
    cp 0
    jp nz, end_move_sprite      ; If the byte right top of the sprite is !=, skip
    ld bc, 001E0h
    add hl, bc
    ld a, (hl)
    cp 0
    jp nz, end_move_sprite      ; If the byte bottom right of the sprite is != 0, skip

    ld a, 16
    ld hl,(sprite_screen_ptr)
    ld bc,0020h
erase_left_side:
    ld (hl),0
    add hl,bc
    dec a
    jp nz, erase_left_side

    ld hl, sprite_right
    ld (sprite_bitmap_ptr), hl  ; reset sprite_bitmap_ptr
    ld hl,(sprite_screen_ptr)
    inc hl
    ld (sprite_screen_ptr), hl  ; sprite_screen_ptr++
    inc iy
    ld a, 0
    ld (sprite_x), a            ; sprite_x = 0
    ld a, (sprite_col)
    inc a
    ld (sprite_col), a
    jp end_move_sprite
shift_sprite_right:
    inc a
    ld (sprite_x), a        ; sprite_x++
    cp 1
    jp z, keep_moving_right ; if sprite_x == 1, sprite_dir = 0
    ld a, 0
    ld (sprite_dir), a
keep_moving_right:
    ld hl,(sprite_bitmap_ptr)
    ld bc, 32
    add hl,bc
    ld (sprite_bitmap_ptr),hl      ; sprite_bitmap_ptr += 32 (switch to the next frame)
    jp end_move_sprite

; ********* MOVE LEFT
move_sprite_left:
    ld a, (sprite_x)
    cp 0
    jp nz, shift_sprite_left   ; if sprite_x == 0
move_sprite_ptr_left:          ; We need to move the screen ptr of one byte and reset the bitmap ptr
    ld hl,(sprite_screen_ptr)
    dec l
    ld a, (hl)
    cp 0
    jp nz, end_move_sprite      ; If the byte left top of the sprite is !=, skip
    ld bc, 001E0h
    add hl, bc
    ld a, (hl)
    cp 0
    jp nz, end_move_sprite      ; If the byte bottom left of the sprite is != 0, skip
    
    ld a, 16
    ld hl,(sprite_screen_ptr)
    inc l
    ld bc,0020h
erase_right_side:
    ld (hl),0
    add hl,bc
    dec a
    jp nz, erase_right_side

    ld hl, sprite_left
    ld (sprite_bitmap_ptr), hl  ; reset sprite_bitmap_ptr
    ld hl,(sprite_screen_ptr)
    dec hl
    ld (sprite_screen_ptr), hl  ; sprite_screen_ptr--
    dec iy
    ld a, 3
    ld (sprite_x), a            ; sprite_x = 3
    jp end_move_sprite
shift_sprite_left:
    dec a
    ld (sprite_x), a                ; sprite_x--
    cp 2
    jp z, keep_moving_left ; if sprite_x == 1, sprite_dir = 0
    ld a, 0
    ld (sprite_dir), a
keep_moving_left:
    ld hl,(sprite_bitmap_ptr)
    ld bc, 0FFE0h
    add hl,bc
    ld (sprite_bitmap_ptr),hl       ; sprite_bitmap_ptr -= 32 (switch to the next frame)

end_move_sprite:
    jp draw_new_line

erase_sprite:
    ld a, 16
    ld hl,(sprite_screen_ptr)
    ld b, 0
erase_sprite_loop:
    ld (hl), b
    inc hl
    ld (hl), b
    ld bc, 0001fh
    add hl,bc
    dec a
    jp nz, erase_sprite_loop
    ret

; *********************************************************
; * DRAW NEW LINE
; *********************************************************

draw_new_line:
	ld de, 06000h        ; DE = top of the screen
    ld bc, $0020             ; C = number of tiles to display
    pop hl
draw_tile_line:
    ld a, (ix+0)
    add a, l
    ld l, a
    ldi
    ldi
    inc ix
    ld a, c
    cp 0
    jp nz, draw_tile_line   ; Keep drawing all the tiles until B == 0
    ld a, (tile_line_left)  ; tile_line_left--
    dec a
    jp nz, next_tile_line   ; If tile_line_left > 0, align the the next tile line
next_tile_row:
    ld hl, tileset          ; Resets the tileset
    push hl                 ; Save HL (tileset pointer)
    ld a, 16
    ld (tile_line_left), a  ; tile_line_left = 16
    ld a, 0
    ld (sprite_4line_offset), a
    ld a, (row)
    dec a
    ld (row), a             ; row--
    jp nz, end_of_loop            ; if row != 0, back to the top (scroll up)
    ; Reset tilemap
    ld ix, levels          ; Resets the tilemap
    call random
    and $3                  ; A = random level (0-3)
    ld c, a
    ld hl, level_offset_high
    add a, l
    ld l, a
    ld b, (hl)              ; B = level_offset_high[A]
    ld a, c
    ld hl, level_offset_low
    add a, l
    ld l, a
    ld c, (hl)              ; C = level_offset_low[A]
    add ix, bc              ; ix += 192*A
    ld a, 12
    ld (row), a             ; row = 12
    call increase_score

end_of_loop:
    ld a, (sprite_screen_ptr+1)
    cp $77
    jp z, game_over

    jp game_loop

next_tile_line:
    ld (tile_line_left), a
;    ld a, (sprite_4line_offset)
;    sub a, $20
;    cp $80
;    jp nz, update_4line_offset
;    ld a, 0
;update_4line_offset:
;    ld (sprite_4line_offset), a
    push hl

    ld bc, $FFF0    ; Repoints IX to the beginning of the tilemap row (IX -= 16)
    add ix, bc
    jp end_of_loop

game_over:
    ld hl, txt_game_over
    ld ix, 06A8Bh
    call print
    ld hl, txt_score
    ld ix, 06C0Bh
    call print
    call wait_for_space_key
    jp splash

print:
    ld iy, 04FECh
    ld a, (hl)
    cp 0
    jp z, print_end
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
    ld (ix-128), a
    ld a, (iy+1)
    ld (ix-96), a
    ld a, (iy+2)
    ld (ix-64), a
    ld a, (iy+3)
    ld (ix-32), a
    ld a, (iy+4)
    ld (ix+0), a
    ld a, (iy+5)
    ld (ix+32), a
    ld a, (iy+6)
    ld (ix+64), a
    ld a, (iy+7)
    ld (ix+96), a
    ld bc, 00080h
    add ix, bc
    ld a, (iy+8)
    ld (ix+0), a
    ld a, (iy+9)
    ld (ix+32), a
    ld a, (iy+10)
    ld (ix+64), a
    ld a, (iy+11)
    ld (ix+96), a
    pop ix
    inc ix
    inc hl
    jp print
print_end:
    ret

increase_score:
    ld a, (init_lines)
    cp 0
    jp z, increase_first_digit
    ret
increase_first_digit:
    ld a, (score+2)
    cp $39
    jp z, reset_first_digit
    inc a
    ld (score+2), a
    ret
reset_first_digit:
    ld a, $30
    ld (score+2), a
    ld a, (score+1)
    cp $39
    jp z, reset_second_digit
    inc a
    ld (score+1), a
    ret
reset_second_digit:
    ld a, $30
    ld (score+1), a
    ld a, (score)
    inc a
    ld (score), a
    ret

	djnz $-6
	ret

; *********************************************************
; * ERASE BOTTOM OF THE SCREEN
; *********************************************************
fade_shape:
    db $7F
fade_dir:
    db $00

erase_bottom:
    push iy
    ld a, (fade_dir)
    cp 0
    jp z, fade_left
fade_right:
    ld a, (fade_shape)
    rrc a
    ld (fade_shape),a
    ld b,a
    cp $FE
    jp nz, erase_bottom_ready
    ld a, 0
    ld (fade_dir), a
    jp erase_bottom_ready
fade_left:
    ld a, (fade_shape)
    rlc a
    ld (fade_shape),a
    ld b,a
    cp $7F
    jp nz, erase_bottom_ready
    ld a, 1
    ld (fade_dir), a
erase_bottom_ready:
    ld c, 8
    ld iy, 07700h
erase_bottom_line:
    ld a, (iy+0)
    and b
    ld (iy+0), a
    ld a, (iy+1)
    and b
    ld (iy+1), a
    ld a, (iy+2)
    and b
    ld (iy+2), a
    ld a, (iy+3)
    and b
    ld (iy+3), a
    ld a, (iy+4)
    and b
    ld (iy+4), a
    ld a, (iy+5)
    and b
    ld (iy+5), a
    ld a, (iy+6)
    and b
    ld (iy+6), a
    ld a, (iy+7)
    and b
    ld (iy+7), a
    ld a, (iy+8)
    and b
    ld (iy+8), a
    ld a, (iy+9)
    and b
    ld (iy+9), a
    ld a, (iy+10)
    and b
    ld (iy+10), a
    ld a, (iy+11)
    and b
    ld (iy+11), a
    ld a, (iy+12)
    and b
    ld (iy+12), a
    ld a, (iy+13)
    and b
    ld (iy+13), a
    ld a, (iy+14)
    and b
    ld (iy+14), a
    ld a, (iy+15)
    and b
    ld (iy+15), a
    ld a, (iy+16)
    and b
    ld (iy+16), a
    ld a, (iy+17)
    and b
    ld (iy+17), a
    ld a, (iy+18)
    and b
    ld (iy+18), a
    ld a, (iy+19)
    and b
    ld (iy+19), a
    ld a, (iy+20)
    and b
    ld (iy+20), a
    ld a, (iy+21)
    and b
    ld (iy+21), a
    ld a, (iy+22)
    and b
    ld (iy+22), a
    ld a, (iy+23)
    and b
    ld (iy+23), a
    ld a, (iy+24)
    and b
    ld (iy+24), a
    ld a, (iy+25)
    and b
    ld (iy+25), a
    ld a, (iy+26)
    and b
    ld (iy+26), a
    ld a, (iy+27)
    and b
    ld (iy+27), a
    ld a, (iy+28)
    and b
    ld (iy+28), a
    ld a, (iy+29)
    and b
    ld (iy+29), a
    ld a, (iy+30)
    and b
    ld (iy+30), a
    ld a, (iy+31)
    and b
    ld (iy+31), a
    push bc
    ld bc,00020h
    add iy,bc
    pop bc
    dec c
    ld a, c
    cp 0
    jp nz, erase_bottom_line
    pop iy
    ret

; ************************************************
wait_for_space_key:
    in a,(083h)
    bit 7, a
    jp z, wait_for_space_key    ; Make sure the space key is not pressed
wait_for_space_key_down:
    call random
    in a,(083h)
    bit 7, a
    jp nz, wait_for_space_key_down ; Make sure the space key is not pressed
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

; ************************************************
    include "dontfall_tilemap.asm"

counter:
    db 10

sprite_right:
    db $00,$00,$00,$00,$07,$00,$08,$80,$11,$40,$15,$40,$10,$40,$10,$40,$08,$80,$07,$00,$10,$80,$1F,$80,$1F,$00,$0F,$40,$29,$00,$09,$00
sprite_right0:
    db $00,$00,$00,$00,$01,$C0,$02,$20,$04,$50,$05,$50,$04,$10,$04,$10,$02,$20,$01,$C0,$04,$20,$07,$E0,$07,$C0,$03,$D0,$0A,$40,$02,$40
    db $00,$00,$00,$70,$00,$88,$01,$14,$01,$54,$01,$04,$01,$04,$00,$88,$00,$70,$01,$08,$01,$F8,$01,$F0,$00,$F4,$02,$90,$00,$90,$00,$00
    db $00,$00,$00,$1C,$00,$22,$00,$45,$00,$55,$00,$41,$00,$41,$00,$22,$00,$1C,$00,$42,$00,$7E,$00,$7C,$00,$3D,$00,$A4,$00,$24,$00,$00

    db $00,$00,$00,$00,$38,$00,$44,$00,$A2,$00,$AA,$00,$82,$00,$82,$00,$44,$00,$38,$00,$42,$00,$7E,$00,$3E,$00,$BC,$00,$25,$00,$24,$00
sprite_left0:
    db $00,$00,$00,$00,$0E,$00,$11,$00,$28,$80,$2A,$80,$20,$80,$20,$80,$11,$00,$0E,$00,$10,$80,$1F,$80,$0F,$80,$2F,$00,$09,$40,$09,$00
    db $00,$00,$03,$80,$04,$40,$0A,$20,$0A,$A0,$08,$20,$08,$20,$04,$40,$03,$80,$04,$20,$07,$E0,$03,$E0,$0B,$C0,$02,$50,$02,$40,$00,$00
sprite_left:
    db $00,$00,$00,$E0,$01,$10,$02,$88,$02,$A8,$02,$08,$02,$08,$01,$10,$00,$E0,$01,$08,$01,$F8,$00,$F8,$02,$F0,$00,$94,$00,$90,$00,$00


level_offset_high:
    db 0x00, 0x00, 0x01, 0x02
level_offset_low:
    db 0x00, 0xC0, 0x80, 0x40
rand_data:
    db 0x34, 0xFA
locate_bas:
    db $31,$30,$2C,$31,$30,$00
txt_dont_fall:
    db "DON'T FALL",0
txt_ecdhe:
    db "by ECDHE",0
txt_keyboard_left:
    db "<: Left",0
txt_keyboard_right:
    db ">: Right",0
txt_keyboard_jump:
    db "Space: Jump",0
txt_game_over:
    db "Game Over!",0
txt_score:
    db "Score: "
score:
    db "000",0

tile_line_left:
    db 16
sprite_4line_offset:
    db 0
row:
    db 12
sprite_screen_ptr:
    db 0, 0
sprite_bitmap_ptr:
    db 0, 0
sprite_x:
    db 1
init_lines:
    db 192
sprite_col:
    db 1
sprite_dir:
    db 0
sprite_jump:
    db 0
sprite_jump_shift:
    db 0
key_space_down:
    db 0
sprite_falling:
    db 0
