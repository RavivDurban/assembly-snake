IDEAL
MODEL small
STACK 100h
DATASEG
	snake db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	input db 4
	color db 0Fh
	x dw ? ;320 max
	y dw ? ;200 max
	head_x dw 160
	head_y dw 100
	temp_x dw ?
	temp_y dw ?
	apple_x dw ?
	apple_y dw ?

CODESEG

proc print
	mov bh, 0h
	mov dx, [y]
	mov cx, [x]
	mov al, [color]
	mov ah, 0Ch
	int 10h 
	ret
endp print


proc get_input
	mov ah, 1
	int 21h

	cmp [input], 1
	je faces_north

	cmp [input], 2
	je faces_west

	cmp [input], 3
	je faces_south
	
	cmp [input], 4
	je faces_east
	
faces_north:
	cmp al, 'a'
	je face_west

	cmp al, 'd'
	je face_east

	jmp face_north

faces_west:
	cmp al, 'w'
	je face_north
	
	cmp al, 's'
	je face_south

	jmp face_west

faces_south:
	cmp al, 'a'
	je face_west

	cmp al, 'd'
	je face_east

	jmp face_south

faces_east:
	cmp al, 'w'
	je face_north
	
	cmp al, 's'
	je face_south

	jmp face_east

face_north:
	mov [input], 1
	mov [snake], 3
	dec [head_y]
	jmp no_input

face_west:
	mov [input], 2
	mov [snake], 4
	dec [head_x]
	jmp no_input

face_south:
	mov [input], 3
	mov [snake], 1
	inc [head_y]
	jmp no_input

face_east:
	mov [input], 4
	mov [snake], 2
	inc [head_x]
	jmp no_input

no_input:
	ret
endp get_input


proc update_snake
	xor si, si
	mov dh, [snake]
loop_snake:
	cmp dh, 0
	je stop_update
	mov dl, [snake+si+1]
	cmp dl, 0
	je stop_update
	mov [snake+si+1], dh
	mov dh, dl
	inc si
jmp loop_snake

stop_update:
	ret
endp update_snake


proc print_snake
	mov bx, [head_x]
	mov [temp_x], bx
	mov bx, [head_y]
	mov [temp_y], bx

	xor si, si
draw_snake:
	inc si
	
	cmp [snake+si], 0
	je exit_loop
	
	mov bx, [temp_x]
	mov [x], bx
	mov bx, [temp_y]
	mov [y], bx
	mov [color], 0Fh
	call print
	cmp [snake+si], 1
	je draw_north 
	cmp [snake+si], 2
	je draw_west
	cmp [snake+si], 3
	je draw_south
	cmp [snake+si], 4
	je draw_east

	jmp exit_loop

draw_north:
	dec [temp_y]
	jmp draw_snake

draw_west:
	dec [temp_x]
	jmp draw_snake

draw_south:
	inc [temp_y]
	jmp draw_snake

draw_east:
	inc [temp_x]
	jmp draw_snake

exit_loop:
	mov [color], 0h
	call print
	ret
endp print_snake


proc create_apple
	mov ax, [es:6Ch]
	mov bx, cx
	mov cx, [cs:bx]
	xor ax, cx
	and ax, 100111100b
	add ax, 2
	mov [apple_x], ax
	mov [x], ax
	mov ax, [es:6Ch]
	mov bx, dx
	mov dx, [cs:bx]
	xor ax, dx
	and ax, 11000100b
	add ax, 2
	mov [apple_y], ax
	mov [y], ax
	mov [color], 4h
	call print
	ret
endp create_apple


proc apple_collision
	mov bx, [head_x]
	cmp [apple_x], bx
	jne no_collision

	mov bx, [head_y]
	cmp [apple_y], bx
	jne no_collision

	call create_apple

	xor si, si
find_index:
	cmp [snake+si+1], 0
	je found
	inc si
jmp find_index

found:
	mov dh, [snake+si]
	mov [snake+si+1], dh
	jmp no_collision

no_collision:
	ret
endp apple_collision


proc clean_plate
	mov ax, 13h
	int 10h
	
	mov cx, [apple_x]
	mov [x], cx
	
	mov dx, [apple_y]
	mov [y], dx
	
	mov [color], 4h
	call print
	
	call print_snake
	ret
endp clean_plate


start:
	mov ax, @data
	mov ds, ax

	mov ax, 13h
	int 10h

	call create_apple

snake_loop:
	call clean_plate
	call print_snake
	call get_input
	call update_snake
	call apple_collision
jmp snake_loop


exit:
	mov ax, 4c00h
	int 21h
END start