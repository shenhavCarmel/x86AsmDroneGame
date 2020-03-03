section .data
section .rodata

section .bss

section .text
	global target
	extern targetX
	extern targetY
	extern seed
	extern MaxInt
	extern MaxBoard
	extern CoschedulerPointer
	extern resume
	extern seed

target:
	
	call 	createTarget                    ; call the fucntion that creats new target
	mov 	ebx,CoschedulerPointer          ; resume the scheduler co routine
	call 	resume
	jmp 	target                          ; after resume back to target


createTarget:
	push ebp            
	mov ebp, esp
	pushad
	call    RandomNumberCalc                ; calc random number 
    fild    dword [seed]                    ; push the random number
    fidiv   dword [MaxInt]                  ; div by max int
    fimul   dword [MaxBoard]                ; mul by 100
    fstp    qword [targetX]                 ; put the value of x in targetX
    call    RandomNumberCalc                ; calc random number 
    fild    dword [seed]                    ; push the random number
    fidiv   dword [MaxInt]                  ; div by max int
    fimul   dword [MaxBoard]                ; mul by 100
    fstp    qword [targetY]                 ; put the value of x in targetY

	popad                                   
    mov esp, ebp
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