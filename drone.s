section .data	     
	ans: dd 1
	isDes: dd 0
	maxDeltaAlpha: dd 120
	minAlpha: dd -60
	radiansAlpha: dd 0
	distMax: dd 50
	checkAngle: dd 360
	getRadians: dd 180
	boundry: dd 100
	boundryMin: dd 0
	helpAngle: dd 60

	MaxInt: dd 65535


section	.rodata
     win_format: db "Drone id %d: I am a winner",10,0      
section .bss 
	newAlpha: resb 4
	newDist: resb 4
	newX: resb 4
	newY: resb 4
	x: resb 4
	y: resb 4
	alpha: resb 4

section .text
	extern currDrone
	extern arrPointer
	global main2
	global drone
	extern seed
	extern CotargetPointer
	extern resume
	extern do_resume
	extern targetsToWin
	extern CoschedulerPointer
	extern printf
	extern targetX
	extern targetY
	extern distanceToDestroy
	extern beta
	extern seed
	extern LFSR_VAL

drone:
	mov 	eax, [currDrone]		; eac contains the cuur drone
	sub 	eax,1					
	mov 	esi,16		
	mul 	esi						; mul by the size of drone
	mov 	ebx, [arrPointer]		; ebx contains pointer to the drones arr
	add 	ebx, eax				; ebx contains arr[drone]
	mov 	ecx, [ebx]				; ecx contains the x value of drone
	mov 	[x], ecx				; save the value in x
	add 	ebx, 4					; ebx contains arr[drone + 4] 
	mov 	ecx, [ebx]				; ecx contains the x value of drone
	mov 	[y], ecx				; save the value in y
	add 	ebx, 4					; ebx contains arr[drone + 8] 
	mov 	ecx, [ebx]				; ecx contains the alpha value of drone 
	mov 	[alpha], ecx			; save the value in alpha
	finit 
	
	;; drones angle [-60,60]
	call    RandomNumberCalc		; calc random number
	fild    dword [seed]			; push the random number
	fimul   dword [maxDeltaAlpha]	; * 120
	fidiv   dword [MaxInt]			; scale to 0-120
	fiadd	dword [minAlpha]		; - 60
	
	;; drones distance [0,50]
	call    RandomNumberCalc		; calc random number
	fild    dword [seed]			; push the random number
	fidiv   dword [MaxInt]			; div by max int
	fimul   dword [distMax]			; mul by 50
	fstp    dword [newDist]			; put the value in newDist

	;; add angles
	fld		dword [alpha]			; push the value of alpha
	faddp	st1						

	;; keep in boundries
	fild 	dword [checkAngle]		; push 360
	fcomip	st0, st1				;comp st0 with st1 and pop st0 
	jnc		notBigAng
	
	fisub	dword [checkAngle]      ; if a greater than 360 -> a = a-360
	jmp 	_validAngle				; angle is valid
notBigAng:
	fild 	dword [boundryMin]		; push 0
	fcomip 	st1						; compare to check if the angle is lower than 0
	jz      _validAngle				; if 0, valid
	jc 		_validAngle				; if greater, valid
	fiadd dword [checkAngle]		; if lower than 0, add 360
_validAngle:	
	fstp	dword [newAlpha]		; put the new value of alpha in newAlpha
	;; convert newAlpha to radians
	fld		dword [newAlpha]		; push the value of new Alpha
	fidiv   dword [getRadians]      ; div by 180
	fldpi                      		; push pai
	fmulp	st1						; mul
	fstp	dword [radiansAlpha]	; put the value in readiansAlpha

	;; calculate delta_x
	fld		dword [radiansAlpha]	; push radiansAlpha
	fcos							; cos the value
	fld		dword [newDist]			; push the new distance
	fmulp	st1						; mul
	
	;; calc new x - keep in boundries
	fld		dword [x]				; push x
	faddp	st1						; add x wuth the distance
	fild		dword [boundry]		; psuh 100
	fcomip	st1						; compare to see if x is in boundry
	jnc		notBigX					; jump if x is not bigger than 100
	fisub	dword [boundry]			; if bigger, sub 100
	jmp 	_valid_X				; x is valid
	notBigX:
	fild		dword [boundryMin]	; push 0
	fcomip 	st1						; check if x is lower than zero
	jz 		_valid_X				; if x 0 is valid
	jc 		_valid_X				; if x bigger than 0 is valid
	fiadd dword [boundry]			; if x lower than 0, add 100
	_valid_X:
		fstp	dword [newX]		; put the value in newX
	;; calculate delta_y
	fld		dword [radiansAlpha]	; push radiansAlpha
	fsin							; sin the value
	fld		dword [newDist]			; push the new distance
	fmulp	st1						; mul
	
	;; calc new y - keep in boundries
	fld		dword [y]				; push y
	faddp	st1						; add y wuth the distance
	fild		dword [boundry]		; push 100
	fcomip	st1						; compare to see if y is in boundry
	jnc		notBigY					; jump if y is not bigger than 100
	fisub	dword [boundry]			; if bigger, sub 100
	jmp 	_valid_Y				; y is valid
	notBigY:
	fild		dword [boundryMin]	; push 0
	fcomip 	st1						; check if y is lower than zero
	jz 		_valid_Y				; if y 0 is valid
	jc 		_valid_Y				; if y bigger than 0 is valid
	fiadd dword [boundry]			; if y lower than 0, add 100

	_valid_Y:
	fstp	dword [newY]			; put the value in newY
	mov 	eax, [currDrone]		; eax contains the value of the currnent drone id
	sub 	eax,1					; sub 1 beacuse the array starts from 0
	mov 	esi,16					
	mul 	esi						; mul by 16, the size of drone
	mov 	ebx, [arrPointer]		; ebx contains the pointer to the drones array
	add 	ebx, eax				; add the current drone, ebx point to the x value in memory
	mov 	ecx, [newX]				; ecx contains the new x value
	mov 	[ebx], ecx				; put in the right place the x value
	add 	ebx, 4					; ebx point to the y value in memory
	mov 	ecx, [newY]				; ecx contains the new y value
	mov 	[ebx], ecx				; put in the right place the y value
	add 	ebx, 4					; ebx point to the alpha value in memory
	mov 	ecx, [newAlpha]			; ecx contains the new alpha value
	mov 	[ebx], ecx				; put in the right place the alpha value
	call 	mayDestroy				; call the function that checks if the drone can destroy the target

	cmp 	byte [isDes], 1			; check if the drone can destroy
	je 		toDestroy				; jump to destroy
	mov 	ebx, CoschedulerPointer	; ebx contains the schduler pointer 
	call 	resume
	jmp 	drone					; back to drone after resume
	toDestroy:
		mov 	byte [isDes],0		; move the flag back to 0
		mov 	eax, [currDrone]	; eax contains the current drone id
		sub 	eax,1				; sub 1 beacuse the arr starts with 0
		mov 	esi,16
		mul 	esi					; mul by 16, size of drone
		mov 	ebx, [arrPointer]	; ebx contains the pointer to the drone array
		add 	ebx, eax			; ebx contains the pointer to the current drone
		add 	ebx, 12				; ebx point to the destroyes value in memory
		mov 	edx, [ebx]			; edx contains the num of destroyes of the current drone
		add 	edx, 1				; add 1 destroy
		mov 	[ebx],edx			; put the new num of destroyes in the memory
		cmp 	dword edx, [targetsToWin]	; check if the drone finish the game
		je 		win					; if yes, jump to win
		mov 	ebx, CotargetPointer; if not, resume the target co routine
		call 	resume
		jmp 	drone				; jump to drone after resume
		win: 	
		push 	dword [currDrone]	; push the id of the winner drone
		push 	win_format			; push the format
		call 	printf				
		add 	esp,8				; add esp, 8 beacose of 2 pushes
		mov    eax,1
		int    0x80					; finish the program
		nop


mayDestroy:
push ebp            				
mov ebp, esp
pushad

finit
fld 	qword [targetY]				; push the y target
fsub 	dword [newY]				; sub by the new y
fld 	qword [targetX]				; push the x target
fsub 	dword [newX]				; sub by the new x
fpatan								; arctan
fimul 	dword [getRadians] 			; mul by 180
fldpi								; push pai
fdiv 	st1,st0						; div
fld 	st1							; push gamma

fild 	dword[boundryMin]			; push 0
a:
fcomip 	st1 						; check if gamma is lower than 0			
jc 		cond1 						; if not, jump to cond1
fiadd 	dword [checkAngle]			; if yes, add 360
cond1:
fsub 	dword [newAlpha]			; sub gamma by alpha
fabs								; do abs
fild 	dword [beta]				; push beta
fcomip 	st1							; check if the result is lower than beta
jnc 	checkCond2					; if yes, check the second condition
jmp 	canotDes					; if not, jump to canot destroy

checkCond2:
finit								; init the registers
fld 	qword [targetY]				; push y target
fsub 	dword [newY]				; sub the new y
fmul 	st0							; mul the result by itself
fld 	qword [targetX]				; push x target
fsub 	dword [newX]				; sub the new x
fmul 	st0							; mul the result by itself
faddp 	st1							; add the tow results
fsqrt								; do sqrt
fild 	dword [distanceToDestroy]	; push d
fcomip 	st1 						; check if the result is lower than d
jnc 	canDes						; if yes, jmp to can destroy
jmp 	canotDes					; if not, jump to cant destory

canDes:
	mov 	dword [isDes],1			; turn on the destroy flag
	finit							; init the registers
	popad                           
    mov 	esp, ebp
    pop     ebp                     
	ret                              
canotDes:
	finit
	popad                          
    mov 	esp, ebp
    pop     ebp                    
	ret                              

RandomNumberCalc:
push    ebp            
mov     ebp, esp
pushad
    

    mov     edx, 0                      ; edx is the counter for the rand loop
    mov     ax, [seed]                  ; ax contains the last lfsr

    RandLoop:
        mov     ecx,16                  
        cmp     edx,ecx                 ; check if need to finish the loop
        je      finishRandLoop          ; if yes, jump to the end
        push    edx                     ; save the counter value for using it

        mov     cx, 1                   ; cx contains 1
        and     cx, ax                  ; cx contains the 16 bit
        mov     bx, 4                   ; bx contians 4
        and     bx, ax                  ; bx contains the 14 bit
        shr     bx, 2                   ; shr by 2
        xor     cx, bx                  ; cx contains the xor between 16 and 14
        mov     dx, cx                  ; save the value in dx

        mov     bx, 8                   ; bx contains 8
        and     bx, ax                  ; bx contains the 13 bit
        shr     bx, 3                   ; shr by 3
        xor     cx, bx                  ; cx contains the xor between 16, 14 and 13
        mov     dx, cx                  ; save the value in dx

        mov     bx, 32                  ; bx contains 32       
        and     bx, ax                  ; bx contains the 11 bit
        shr     bx, 5                   ; shr by 5
        xor     cx, bx                  ; cx contains the xor between 16, 14, 13 and 11
        mov     dx, cx                  ; save the value in dx

        shl     dx, 15                  ; shl by 15    
        mov     cx, ax                  ; save ax in cx
        shr     cx, 1                   ; shr by 1
        or      cx, dx                  ; or between cx and dx
        mov     ax,cx                   ; put the final value in ax
        pop     edx                     ; pop edx to back to the counter
        
        inc     edx                     ; inc the counter
        jmp     RandLoop                ; jump back to loop

    finishRandLoop:
        mov     word [seed], ax         ; save the final value in seed

popad
mov esp, ebp
pop ebp
ret