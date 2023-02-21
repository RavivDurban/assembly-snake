IDEAL
MODEL small
STACK 100h
DATASEG
;set length and direction
	snake db 2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	reset_snake db 2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

	apple_backup dw 174,298,193,854,824,758,874,568,703,464,579,347,576,603,457,436,789,374,687,298,476,980,823,746,987,234,678,347,698,347,697,347,873,727,872,356,433,447,835,807,837,623,456,789,876,543,456,782,375,946,776,123,146,771,346,764,138,769,006,713,467,984,762,389,768,324,768,093,276,098,837,463,7468,479,857,667,454,235,678,904,978,523,794,856,014,568,347,653,427,634,576,734,553,146,763,124,562,135,753,421,348,213,463,457,045,360,345,67,673,145,001,345,613,456,704,135,670,513,468,413,600,869,631,870,641,386,041,368,674,678,041,367,831,468,713,468,791,346,804,136,864,167,046,746,416,413,064,317,064,146

	color db ?
	x dw ? ;320 max
	y dw ? ;200 max

	return_color db ?

;set to the middle of the screen
	head_x dw 160
	head_y dw 100

	apple_x dw ?
	apple_y dw ?

	start_time db ?
	
	filename db 'snake.bmp',0
	filehandle dw ?
	Header db 54 dup (0)
	Palette db 256*4 dup (0)
	ScrLine db 320 dup (0)
	ErrorMsg db 'Error', 13, 10 ,'$'

CODESEG


proc OpenFile
; Open file
	mov ah, 3Dh
	xor al, al
	mov dx, offset filename
	int 21h
	jc openerror
	mov [filehandle], ax
	ret
openerror :
	mov dx, offset ErrorMsg
	mov ah, 9h
	int 21h
	ret
endp OpenFile

proc ReadHeader
	; Read BMP file header, 54 bytes
	mov ah,3fh
	mov bx, [filehandle]
	mov cx,54
	mov dx,offset Header
	int 21h
	ret
endp ReadHeader

proc ReadPalette
	; Read BMP file color palette, 256 colors * 4 bytes (400h)
	mov ah,3fh
	mov cx,400h
	mov dx,offset Palette
	int 21h
	ret
endp ReadPalette
proc CopyPal
	; Copy the colors palette to the video memory
	; The number of the first color should be sent to port 3C8h
	; The palette is sent to port 3C9h
	mov si,offset Palette
	mov cx,256
	mov dx,3C8h
	mov al,0
	; Copy starting color to port 3C8h
	out dx,al
	; Copy palette itself to port 3C9h
	inc dx
PalLoop:
	; Note: Colors in a BMP file are saved as BGR values rather than RGB .
	mov al,[si+2] ; Get red value .
	shr al,2 ; Max. is 255, but video palette maximal
	; value is 63. Therefore dividing by 4.
	out dx,al ; Send it .
	mov al,[si+1] ; Get green value .
	shr al,2
	out dx,al ; Send it .
	mov al,[si] ; Get blue value .
	shr al,2
	out dx,al ; Send it .
	add si,4 ; Point to next color .
	; (There is a null chr. after every color.)
	loop PalLoop
	ret
endp CopyPal
	
proc CopyBitmap
	; BMP graphics are saved upside-down .
	; Read the graphic line by line (200 lines in VGA format),
	; displaying the lines from bottom to top.
	mov ax, 0A000h
	mov es, ax
	mov cx,200
PrintBMPLoop :
	push cx
	; di = cx*320, point to the correct screen line
	mov di,cx
	shl cx,6
	shl di,8
	add di,cx
	; Read one line
	mov ah,3fh
	mov cx,320
	mov dx,offset ScrLine
	int 21h
	; Copy one line into video memory
	cld ; Clear direction flag, for movsb
	mov cx,320
	mov si,offset ScrLine
	rep movsb ; Copy line to the screen
	 ;rep movsb is same as the following code :
	 ;mov es:di, ds:si
	 ;inc si
	 ;inc di
	 ;dec cx
	;loop until cx=0
	pop cx
	loop PrintBMPLoop
	ret
endp CopyBitmap





proc print_4x4
;prints a 4x4 area to the screen
	push ax
	push bx
	push cx
	push dx

	xor bh, bh
	mov al, [color]
	mov cx, [x]
	mov dx, [y]

	mov ah, 0Ch
	int 10h
	inc cx
	mov ah, 0Ch
	int 10h
	inc cx
	mov ah, 0Ch
	int 10h
	inc cx
	mov ah, 0Ch
	int 10h

	dec dx
	mov ah, 0Ch
	int 10h
	dec cx
	mov ah, 0Ch
	int 10h
	dec cx
	mov ah, 0Ch
	int 10h
	dec cx
	mov ah, 0Ch
	int 10h

	dec dx
	mov ah, 0Ch
	int 10h
	inc cx
	mov ah, 0Ch
	int 10h
	inc cx
	mov ah, 0Ch
	int 10h
	inc cx
	mov ah, 0Ch
	int 10h

	dec dx
	mov ah, 0Ch
	int 10h
	dec cx
	mov ah, 0Ch
	int 10h
	dec cx
	mov ah, 0Ch
	int 10h
	dec cx
	mov ah, 0Ch
	int 10h

	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp print_4x4





proc print_apple
;like print_4x4 but without corners
	push ax
	push bx
	push cx
	push dx

	xor bh, bh
	mov al, [color]
	mov cx, [x]
	mov dx, [y]

	inc cx
	mov ah, 0Ch
	int 10h
	inc cx
	mov ah, 0Ch
	int 10h
	inc cx

	dec dx
	mov ah, 0Ch
	int 10h
	dec cx
	mov ah, 0Ch
	int 10h
	dec cx
	mov ah, 0Ch
	int 10h
	dec cx
	mov ah, 0Ch
	int 10h

	dec dx
	mov ah, 0Ch
	int 10h
	inc cx
	mov ah, 0Ch
	int 10h
	inc cx
	mov ah, 0Ch
	int 10h
	inc cx
	mov ah, 0Ch
	int 10h

	dec dx
	dec cx
	mov ah, 0Ch
	int 10h
	dec cx
	mov ah, 0Ch
	int 10h
	dec cx

	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp print_apple





proc get_pixel
;reads a pixel from the screen
	push ax
	push bx
	push cx
	push dx

	mov cx, [x]
	mov dx, [y]
	xor bh, bh
	mov ah, 0Dh
	int 10h
	mov [return_color], al

	pop dx
	pop cx
	pop bx
	pop ax
	ret
endp get_pixel





proc get_input
;change snake at index 0 based on the last input
	cmp al, 0
	jz mid_jump

	cmp [snake], 1
	je faces_south

	cmp [snake], 2
	je faces_east

	cmp [snake], 3
	je faces_north
	
	cmp [snake], 4
	je faces_west
	
faces_north:
	cmp al, 'a'
	je face_west

	cmp al, 'd'
	je face_east_mid

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

mid_jump:
	jmp no_input

face_north:
	mov [snake], 3
	jmp no_input

face_east_mid:
	jmp face_east

face_west:
	mov [snake], 4
	jmp no_input

face_south:
	mov [snake], 1
	jmp no_input

face_east:
	mov [snake], 2
	jmp no_input

no_input:
	mov ah, 0Ch
	int 21h
	ret
endp get_input





proc update_snake
;update the rest of the snake based on get_input
	cmp [snake], 1
	je move_down

	cmp [snake], 2
	je move_right

	cmp [snake], 3
	je move_up

	cmp [snake], 4
	je move_left

move_up:
	sub [head_y], 4
	jmp update_snake_next

move_left:
	sub [head_x], 4
	jmp update_snake_next

move_down:
	add [head_y], 4
	jmp update_snake_next

move_right:
	add [head_x], 4
	jmp update_snake_next

update_snake_next:
	xor si, si
	mov dh, [snake]
update_snake_loop:
	cmp dh, 0
	je update_snake_done
	mov dl, [snake+si+1]
	cmp dl, 0
	je update_snake_done
	mov [snake+si+1], dh
	mov dh, dl
	inc si
	jmp update_snake_loop

update_snake_done:
	ret
endp update_snake





proc print_snake
;prints the snake to the screen
	mov [color], 0Ah
	mov ax, [head_x]
	mov bx, [head_y]

	xor si, si
draw_snake:
	inc si
	
	cmp [snake+si], 0
	je print_snake_done

	mov [x], ax
	mov [y], bx
	call print_4x4
	cmp [snake+si], 1
	je draw_north 
	cmp [snake+si], 2
	je draw_west
	cmp [snake+si], 3
	je draw_south
	cmp [snake+si], 4
	je draw_east

	jmp draw_snake

draw_north:
	sub bx, 4
	jmp draw_snake

draw_west:
	sub ax, 4
	jmp draw_snake

draw_south:
	add bx, 4
	jmp draw_snake

draw_east:
	add ax, 4
	jmp draw_snake

print_snake_done:
	mov [color], 9
	call print_4x4
	ret
endp print_snake





proc create_apple
;a ton of randomizers that generate an apple to the screen
	mov [color], 4

	mov ax, [es:6Ch]
	mov bx, cx
	mov cx, [cs:bx]
	xor ax, cx
	and ax, 10000b
	add ax, ax
	add ax, ax
	add ax, ax
	add ax, 76
	mov [apple_x], ax
	mov [x], ax
	mov ax, [es:6Ch]
	mov bx, dx
	mov dx, [cs:bx]
	xor ax, dx
	and ax, 1000b
	add ax, ax
	add ax, ax
	add ax, ax
	add ax, 20
	mov [apple_y], ax
	mov [y], ax

	call get_pixel
	cmp [return_color], 9
	je done_apple

	mov si, es
new_apple:
	mov ax, [apple_backup+si]
	and ax, 10100b
	add ax, ax
	add ax, ax
	add ax, ax
	add ax, 76
	mov [apple_x], ax
	mov [x], ax
	mov ax, [apple_backup+si+1]
	and bx, 1100b
	add bx, bx
	add bx, bx
	add bx, bx
	add bx, 20
	mov [apple_y], bx
	mov [y], bx
	inc si

	call get_pixel
	cmp [return_color], 9
	jne new_apple

done_apple:
	call print_apple
	ret
endp create_apple





proc apple_collision
;checks if the snake is colliding with the apple
	mov bx, [head_x]
	cmp [apple_x], bx
	jne no_collision

	mov bx, [head_y]
	cmp [apple_y], bx
	jne no_collision

	call create_apple

	xor si, si
apple_collision_search:
	cmp [snake+si+1], 0
	je apple_collision_found
	inc si
jmp apple_collision_search

apple_collision_found:
	mov dh, [snake+si]
	mov [snake+si+1], dh
	jmp no_collision

no_collision:
	ret
endp apple_collision





proc structure
;print the borders and background of the game
	mov [color], 9
	mov [y], 8

loop_y:
	mov [x], 68
	loop_x:
	call print_4x4
	add [x], 4
	cmp [x], 252
	jne loop_x
	add [y], 4
	cmp [y], 196
	jne loop_y


	mov [color], 1

	mov [y], 8
	mov [x], 68
north_border:
	call print_4x4
	add [x], 4
	cmp [x], 252
	jne north_border

	mov [x], 68
	mov [y], 8
west_border:
	call print_4x4
	add [y], 4
	cmp [y], 196
	jne west_border

	mov [y], 192
	mov [x], 68
south_border:
	call print_4x4
	add [x], 4
	cmp [x], 252
	jne south_border

	mov [x], 252
	mov [y], 8
east_border:
	call print_4x4
	add [y], 4
	cmp [y], 196
	jne east_border

	ret
endp structure





proc is_colliding
;check if the player messed up
	mov bh, 0
	mov cx, [head_x]
	mov dx, [head_y]
	mov ah, 0Dh

	cmp [snake], 1
	je looking_down

	cmp [snake], 2
	je looking_right

	cmp [snake], 3
	je looking_up

	cmp [snake], 4
	je looking_left

looking_up:
	dec dx
	jmp finish

looking_left:
	dec cx
	jmp finish

looking_down:
	inc dx
	jmp finish

looking_right:
	inc cx
	jmp finish

finish:
	mov [x], cx
	mov [y], dx
	call get_pixel
	cmp [return_color], 0Ah
	je callthat
	cmp [return_color], 1
	je callthat

	ret

callthat:
	call print_screen
endp is_colliding





proc reset
;reset the game
	xor si, si
reset_loop:
	mov ah, [reset_snake+si]
	mov [snake+si], ah
	inc si
	cmp si, 50
	jne reset_loop

	mov [head_x], 160
	mov [head_y], 100

	ret
endp reset





proc print_screen
;does the magic for the starting screen
print_screen_continue:
; Process BMP file
	mov ax, 13h
	int 10h
	call OpenFile
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap

print_screen_loop:
	mov ah, 8
	int 21h
	
	cmp al, "p"
	je start_game
	
	cmp al, "q"
	je exit
	
	jmp print_screen_loop

	ret
endp print_screen





start:
;calls everything and delays
	mov ax, @data
	mov ds, ax

	call print_screen
start_game:
	mov ax, 13h
	int 10h
	call reset
	call structure
	call create_apple
	call print_snake
	mov ah, 8
	int 21h
	call get_input
snake_loop:
	mov dl, 0FFh
	mov ah, 6
	int 21h
	call get_input
;get initial time (dl = 1/100 sec)
	mov ah, 2Ch
	int 21h
	mov [start_time], dl
counter:
	mov ah, 2Ch
	int 21h
	sub dl, [start_time]
	add dl, dl
	add dl, dl
	add dl, dl
	cmp dl, 25
	jb counter
	call update_snake
	call is_colliding
	call print_snake
	call apple_collision
	jmp snake_loop


exit:
	mov ax, 4c00h
	int 21h
END start