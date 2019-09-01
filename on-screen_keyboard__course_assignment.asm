xchg bx, bx                        ; Break point for BOCHS debugger                                   
mov ax, 7c0h                       ; Install data segment
mov ds, ax                                                  

main:
	call InitMem
	call setGraphics
	
	mov ax, 810h
	mov es, ax
	mov bx, 0
	mov ah, 2
	mov al, 1
	mov cl, 2
	mov ch, 0
	mov dh, 0
	mov dl, 80h
	int 13h
	
	mov ax, 910h
	mov es, ax
	mov bx, 0
	mov ah, 2
	mov al, 1
	mov cl, 3
	mov ch, 0
	mov dh, 0
	mov dl, 80h
	int 13h
	
	mov ax, 1110h
	mov es, ax
	mov bx, 0
	mov ah, 2
	mov al, 1
	mov cl, 4
	mov ch, 0
	mov dh, 0
	mov dl, 80h
	int 13h
	
	mov ax, 800h
	mov es, ax
	mov bx, 0
	insertion800h:
	mov cl, [letters+bx]
	mov byte[es:bx], cl
	inc bx
	cmp bx, 79
	jne insertion800h 

	mov ax, 1000h
	mov es, ax
	mov bx, 0
	insertion1000h:
	mov cl, [changesArr+bx]
	mov byte[es:bx], cl
	inc bx
	cmp bx, 53
	jne insertion1000h 
	
	call 810h:0000;call sector 2.

jmp $
	

InitMem:;initialize memory.
	mov ax, 1000h
	mov es, ax
	ret
	
	
setGraphics:;enter graphics mode.
	mov ax, 13h
	int 10h
	ret

bottomLinePointer db 0 ; pointer for the bottom line.
theLastchar db 0,0 ; slot 0 and 1 will use to save the ascii number from 'readChar'
colors db 9,11;array for colors we used in the code.
;this array arranges the rectangles coordinates
rectangles db 12,12,12,36,12,60,12,84,12,108,12,132,12,156,12,180,12,204,12,228,36,12,36,36,36,60,36,84,36,108,36,132,36,156,36,180,36,204,60,12,60,36,60,60,60,84,60,108,60,132,60,156
;this array arranges the three parimeters of a letter; symbol, x, y.
letters db 2,2,'Q',2,5,'W',2,8,'E',2,11,'R',2,14,'T',2,17,'Y',2,20,'U',2,23,'I',2,26,'O',2,29,'P',5,2,'A',5,5,'S',5,8,'D',5,11,'F',5,14,'G',5,17,'H',5,20,'J',5,23,'K',5,26,'L',8,2,'Z',8,5,'X',8,8,'C',8,11,'V',8,14,'B',8,17,'N',8,20,'M'
;array for changes made in the keyboard layout.
changesArr db 'QQWWEERRTTYYUUIIOOPPAASSDDFFGGHHJJKKLLZZXXCCVVBBNNMM'
messageFrom db 'Change the letter:';both this two lines are interface for user to insert and change key layout.
messageTo db 'To the letter: '
;the array for mass changing.
CoordinateForSuperChanger db 12,0,'Q',12,4,'W',12,8,'E',12,12,'R',12,16,'T',12,20,'Y',12,24,'U',13,0,'I',13,4,'O',13,8,'P',13,12,'A',13,16,'S',13,20,'D',13,24,'F',14,0,'G',14,4,'H',14,8,'J',14,12,'K',14,16,'L',14,20,'Z',14,24,'X',15,0,'C',15,4,'V',15,8,'B',15,12,'N',15,16,'M'



times 510 - ($-$$) db 0            ; Fill empty bytes to binary file
dw 0aa55h                          ; Define MAGIC number at byte 512

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;sector 2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; cleanning the bottom lines of the screen
mov dh, 12
call cleaner
mov dh, 13 
call cleaner
mov dh, 14 
call cleaner
mov dh, 15 
call cleaner

call keyboard ; print the keyboard.
call tyeping ; handle the input.

cleaner:;the bottom lines screen cleaner.
	mov ah, 2 
	mov dl, 0 
	int 10h
	mov bh, 0
	mov bl, 15
	mov ah, 9
	mov al, 32  
	mov cx, 28 ; number of prints
	int 10h
	ret	
	
tyeping:;intercepts the insertion of input from the user and handles this input properly, depends the input.
	Input:
		call readChar ; al=the typed char
		cmp al,01bh ; 01bh=esc  
		je escSector2
		
		cmp ah,3bh ; 3bh = f1 
		jne continue
		call 910h:0000 ; go to sector 3 
		continue:
		
		cmp ah, 3ch ; 3ch = f2
		jne continue2
		call 1100h:0000 ; go to sector 4 
		continue2:
		
		; check to know if it's a valid english letter
		cmp al, 97 
		jl Input
		cmp al, 122
		jg Input
		;the next few lines of code using theLastchar array are operating to find and fix the last key pressed.
		mov [theLastchar+1], al 
		mov al,0 
		cmp [theLastchar+0], al
		je continue3 ; if its equal to 0 it means, this is the first typing operation. 
		mov al, [theLastchar+0]
		sub al,32
		mov bx,0 ; pointer for color array, used for rectangle
		call findAndColor
		continue3:
		;this next few lines print to bottom line + save the current key value.
		mov al, [theLastchar+1]
		mov [theLastchar+0], al 
		call bottomLinePrint
		mov al, [theLastchar+0]
		sub al,32
		mov bx,1 ; pointer for color array, used for rectangle
		call findAndColor
		jmp Input
	ret	


findAndColor:;when called, finds the relevent letter(that is in al) in the array. 
	mov di,2
	mov si,0	
	search:
		cmp al,[letters+di]
		je colorRec
		add di,3 
		add si,2 
		jmp search
		
	colorRec: ;colors the rectangle.
		mov dx,0
		call printRec
		mov si, di
		sub si,2
		mov bx,0
		call printChar	
	ret
		
bottomLinePrint:;prints the letter to the display.
	mov ah, 2 
	mov dh, 10 
	mov dl, [bottomLinePointer+0]
	mov bl, [bottomLinePointer+0]
	inc bl
	mov [bottomLinePointer+0], bl 
	int 10h
	mov al, [theLastchar+0]
	sub al, 32
	mov bx, 0 
	call checksum
	mov bh, 0
	mov bl, 15
	mov ah, 9
	mov cx, 1 ; number of prints
	int 10h
	ret		
	
keyboard:;prints the visual keyboard on to the display.
	mov si,0
	mov di,0
	PrintRecTangle:;prints the part of the rectangles to the display.
		mov bx,0
		call printRec
		inc di
		inc si
		cmp di,26
		jne PrintRecTangle
	mov bx,0
	mov si,0
	mov di,0 
	PrintLetters:;prints the part of the letters to the display.
		inc di
		call printChar
		cmp di,26
		jne PrintLetters
	ret 	

escSector2:;this function reacts to esc key being pressed, exiting the program.
	call keyboard
	retf
	
printRec:;prints a single rectangle.
	mov ah, 0ch
	mov al, [colors+bx]	
	mov dh, 0 
	mov dl,[rectangles+si] 
	inc si
	mov bl, dl
	add bl, 15
	loopR:
		inc dl
		cmp dl, bl;height of rectangle.
		je endf
		mov cl,[rectangles+si]
		mov bh, cl
		add bh, 15
		loopC:
			cmp cl, bh;width of rectangle
			je loopR
			int 10h
			inc cl
			jmp loopC
	endf:
		ret

printChar:;prints a single character. letter.
	mov ah, 2 
	mov dh, [letters+si] ; row  
	inc si
	mov dl, [letters+si] ; col
	inc si
	int 10h
	mov al, [letters+si]
	mov bx, 0 
	call checksum
	mov bh, 0
	mov bl, 15
	mov ah, 9
	inc si
	mov cx, 1 ; number of prints
	int 10h
	ret	

checksum:;checks if a chosen letter been swaped, then prints the relevent symbol.
	cmp [changesArr+bx], al 
	jne keepSearch
	mov al, [changesArr+bx+1]
	ret 
	keepSearch:
		add bx, 2 
		jmp checksum
	
readChar:;reads the input from the user.
	mov ah, 0
	int 16h
	ret

times 1022 - ($-$$) db 0            ; Fill empty bytes to binary file
dw 0aa55h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;sector 3
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
mov si, 0 
printMesFrom:;prints the "'Change the letter:'" massage.
	mov ah, 2 
	mov dx, si
	mov dh, 12 
	int 10h
	mov bh, 0
	mov bl, 15
	mov ah, 9
	mov al, [messageFrom+si]
	inc si 
	mov cx, 1 ; number of prints
	int 10h
	cmp si, 18
	jne printMesFrom
	
mov ah, 2
mov dl, 19
mov dh, 12
int 10h	
retry:;if a key pressed isnt a letter, ignores and keeps on "listening" to user's input.	
	call readChar2
	; checks if it's a valid english letter
	cmp al, 97 
	jl retry
	cmp al, 122
	jg retry
	
mov bl, 2 ; color of letter inserted.
mov ah, 9
int 10h
mov ah, 0 
sub al, 32 
push ax ; puts al in the stack
	
mov si, 0 
printMesTo:;prints the "'To the letter:'" massage.
	mov ah, 2 
	mov dx, si
	mov dh, 13 
	int 10h
	mov bh, 0
	mov bl, 15
	mov ah, 9
	mov al, [messageTo+si]
	inc si 
	mov cx, 1 ; number of prints
	int 10h
	cmp si, 15
	jne printMesTo
	
mov ah, 2
mov dl, 15
mov dh, 13 
int 10h
retry1:	;if a key pressed isnt a letter, ignores and keeps on "listening" to user's input.	
	call readChar2
	; checks if it's a valid english letter
	cmp al, 97 
	jl retry1
	cmp al, 122
	jg retry1

mov bl, 2 ; color
mov ah, 9
mov bh,0  
int 10h 
mov ah, 0
sub al, 32 
push ax ; puts al in the stack

call switch

switch: ;manages the switch between two keys inserted.
	pop ax ; ax holds the ip address 
	pop bx ; bx holds the letter that will be coppyed
	pop cx ; cx holds the letter that will be change 
	push ax ; push back the ip address to the stack 
	
	mov si, 0  
	search2:
		cmp cl, [changesArr+si]
		je found
		add si, 2 
		jmp search2
		found:
			mov [changesArr+si+1], bl	
			call 810h:0000
retf

readChar2:
	mov ah, 0
	int 16h
	ret

times 1532 - ($-$$) db 0            ; Fill empty bytes to binary file
dw 0aa55h                          ; Define MAGIC number at byte 512

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;sector 4
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
call superChanger1

superChanger1:;resets di and si
mov di,0 
mov si, 0

superChanger:;this loop displays all the letters im going to change.
	mov bx, 0 
	call printCharTochange
	cmp si, 78
	jge escSector4
	jmp superChanger
ret
printCharTochange:;prints each letter and also handles the input replacement.
	mov cx,1
	mov bh, 0
	mov ah, 2
	mov dh, [CoordinateForSuperChanger+si] ; row 
	inc si 
	mov dl, [CoordinateForSuperChanger+si] ; col
	inc si 
	int 10h 
	mov al, [CoordinateForSuperChanger+si]
	mov bh, 0
	mov bl, 15 
	mov ah, 0eh 
	inc si 
	mov cx, 1 
	int 10h 

	mov bx, 0 
	mov ah,2 
	inc dl 
	int 10h
	mov al, 61 ; the ascii number for the '=' symbol 
	mov bh, 0
	mov bl, 15 
	mov ah, 9 
	int 10h 
	
	mov bx, 0 
	mov ah, 2
	inc dl
	int 10h
	
	retry2:	;if a key pressed isnt a letter, ignores and keeps on "listening" to user's input.	
	call readChar3	
		cmp al,01bh ; 01bh=esc - listens to esc key being pressed. 
		je escSector4
		
		; checks if it's a valid english letter
		cmp al, 97 
		jl retry2
		cmp al, 122
		jg retry2
	
	sub al, 32 
	mov bh, 0
	mov bl, 14 ; color  
	mov ah, 9 
	int 10h  
	
	mov di, 0  
	mov bl, [CoordinateForSuperChanger+si-1]
	search3:
		cmp bl, [changesArr+di]
		je found2
		add di, 2 
		jmp search3
		found2:
			mov [changesArr+di+1], al
	
	ret

readChar3:;waits for user's input.
	mov ah, 0
	int 16h
	ret	
	
escSector4:
	call 810h:0000
	
times 2*8*63*512 - ($-$$) db 0     ; We needed create HD or floopy drive 
								   ; 2=cylinders, 8=heads, 64=sectors, 512=bytes/sector