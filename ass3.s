; --------------------------------------
; Main file. which responseble to init the game
; --------------------------------------

; --------------------------------------
;datas
; --------------------------------------
section	.rodata			        ; define read-only vars
	format_string: db "%s", 0   
    format_int: db "%d", 0    
    format_float: db "%f", 0  
	taps: dd 11, 13, 14, 16     ; LFSR taps
    CODEP	equ	0	            ; offset of pointer to co-routine function in co-routine struct 
    SPP	    equ	4	            ; offset of pointer to co-routine stack in co-routine struct 


section .data					; define initialized vars
    global currDrone,dronesNum,seed,MaxInt,MaxBoard,currThreadPointer,stepsToPrint,CotargetPointer,CoschedulerPointer,CoPrinterPointer,targetsToWin,distanceToDestroy,beta
	seed: dd 0                  ; seed
	distanceToDestroy: dd 0     ; d
	beta: dd 0                  ; β
	stepsToPrint: dd 0          ; K
	targetsToWin: dd 0			; T
    dronesNum: dd 0				; N
    currThreadPointer: dd 0     ;the main routine

    high: dd 0      
    low: dd 0
    randNum: dd 0
    alfa: dd 0
    delta_alfa: dd 0
    sin_alfa: dd 0
    cos_alfa: dd 0
    delta_d: dd 0
    x1: dd 0
    y1: dd 0
    d: dd 0
    temp: dd 0
    currDrone: dd 0
    MaxInt: dd 65535
    MaxBoard: dd 100
    MaxAngle: dd 360
    tempPointer: dd 4
    CotargetPointer: dd target
                     dd STK1 + STKSZ
    CoschedulerPointer: dd scheduler
                        dd STK2 + STKSZ
    CoPrinterPointer: dd printer
                      dd STK3 + STKSZ

section .bss			        ; define uninitialized vars
    global arrPointer,targetX,targetY,dronesCorArray

    SPT: resd 1                 ; temporary stack pointer

    LFSR: resw 1                ; randon numbers register
    arrPointer: resb 4

    STKSZ	equ	    16*1024	     ; co-routine stack size
    STK1:	resb	STKSZ
    STK2:	resb	STKSZ
    STK3:	resb	STKSZ

    targetX: resb 8
    targetY: resb 8
    droneSize: resb 4
    dronesCorArray: resb 4
    offsetStack: resb 4

section .text

global RandomNumberCalc
global main
global resume
global do_resume
extern printf
extern fflush
extern malloc
extern calloc
extern free
extern fgets
extern stdout
extern stdin
extern sscanf
extern drone
extern target
extern scheduler
extern printer

main:
  
    mov     ebx, [esp + 8]                  ; ebx now contains argv
    mov     ecx, [esp + 4]                  ; ecx now contains argc  
    push    dword ebx                       ; char **argv
    push    dword ecx                       ; int argc
    call    _main                           ; call main
    mov    eax,1
    int    0x80
    nop

_main:
    push    ebp            
    mov     ebp, esp
    pushad  
    mov     dword ecx, [ebp + 8]            ; int argc
    mov     dword esi, [ebp + 12]           ; ebx contains (char**) argv
    mov     ebx, [esi + 4]                  ; ebx contains argv[1]
    
    pushad							        ; save the state of regs before sscanf
    push    edx						        ; the register to save the number sscanf returns
    push    format_int				        ; we want sscanf to ret int
    push    ebx						        ; argv[1] which we want to convert to int
    call    sscanf
    mov     edx, [edx]                      ; edx contains N
    mov     dword [dronesNum], edx	        ; save the result in the global var
    add     esp, 12                 
    popad							        ; ret the regs to the previus state
    
    mov     ebx, [esi + 8]                  ; ebx contains argv[2]
    pushad							        ; save the state of regs before sscanf
    push    edx						        ; the register to save the number sscanf returns
    push    format_int				        ; we want sscanf to ret int
    push    ebx						        ; argv[2] which we want to convert to int
    call    sscanf
    mov     edx, [edx]                      ; edx contains T
    mov     dword [targetsToWin], edx       ; save the result in the global var
    add     esp, 12       
    popad							        ; ret the regs to the previus state

    mov     ebx, [esi + 12]                 ; ebx contains argv[3]
    pushad							        ; save the state of regs before sscanf
    push    edx						        ; the register to save the number sscanf returns
    push    format_int				        ; we want sscanf to ret int
    push    ebx						        ; argv[3] which we want to convert to int
    call    sscanf
    mov     edx, [edx]                      ; edx contains K
    mov     dword [stepsToPrint], edx       ; save the result in the global var
    add     esp, 12       
    popad

    mov     ebx, [esi + 16]                 ; ebx contains argv[4]
    pushad							        ; save the state of regs before sscanf
    push    edx						        ; the register to save the number sscanf returns
    push    format_int				        ; we want sscanf to ret int
    push    ebx						        ; argv[4] which we want to convert to int
    call    sscanf
    mov     edx, [edx]                      ; edx contains β
    mov     dword [beta], edx               ; save the result in the global var
    add     esp, 12       
    popad
    mov     ebx, [esi + 20]                 ; ebx contains argv[5]
    pushad							        ; save the state of regs before sscanf
    push    edx						        ; the register to save the number sscanf returns
    push    format_int				        ; we want sscanf to ret int
    push    ebx						        ; argv[5] which we want to convert to int
    call    sscanf
    mov     edx, [edx]                      ; edx contains d
    mov     dword [distanceToDestroy], edx  ; save the result in the global var
    add     esp, 12       
    popad
    mov     ebx, [esi + 24]                 ; ebx contains argv[6]
    pushad							        ; save the state of regs before sscanf
    push    edx						        ; the register to save the number sscanf returns
    push    format_int				        ; we want sscanf to ret int
    push    ebx						        ; argv[6] which we want to convert to int
    call    sscanf
    mov     edx, [edx]                      ; edx contains seed
    mov     dword [seed], edx               ; save the result in the global var
    add     esp, 12       
    popad
    call    BoardInit                       ; call the function that inits the board
    call    CoInit                          ; call the function that inits the co routins
    call    targetInit                      ; call the function that inits the target
    call    dronesArrInit                   ; call the function that inits the drones
    mov     ebx,CoschedulerPointer          ; put the pointer to the sched in ebx
    jmp     do_resume                       ; call do resume for moving to sched
    
    popad
    mov esp, ebp
    pop     ebp            
	ret                        

BoardInit:

    push    ebp            
    mov     ebp, esp
    pushad
    mov     dword eax, [dronesNum]      ; eax contains the number of drones
    add     eax,4
    mov     esi, 4             
	mul     esi	                        ; mul N with the size of one drone

    pushad	                            ; save the registers status before malloc		
	push    eax	
    	                                ; push the number of bytes we want to malloc				
	call    malloc
	add     esp,4
    mov     [dronesCorArray], eax       ; save the pointer to the new array int the global var
    popad

    mov ecx,0

    _dronesLoop:
        mov     dword edx, [dronesNum]  ; edx contians the number of drones
        cmp     ecx,edx                 ; cmp the counter wuth edx
        je      _dronesLoopEnd          ; in case equal, jump to the end of loop
        mov     edx, [dronesCorArray]   ; edx contains pointer to the dronesCorArray
        mov     edi, edx                ; edi contains pointer to the dronesCorArray
        mov     eax, ecx                ; eax contains the counter
        mov     esi, 4                  
        mul     esi                     ; mul the counter with 4
        mov     edx, edi                ; edx contains pointer to the dronesCorArray
        add     edx, eax                ; add edx the counter
        pushad
        push    8
        call    malloc                  ; malloc the func and stack pointer
        add     esp,4
        mov     [tempPointer], eax      ; save the adrres in temp
        popad
        mov     eax, [tempPointer]      ; eax contains the adrres malloced
        mov     [edx], eax              ; put in the cores stuck the pointer to the malloced addres
        mov     dword [eax], drone      ; put int the func the drone func
        add     eax, 4                  ; eax contains the stack pointer
        mov     esi, eax
        pushad
        push    16*1024 
        call    malloc                  ; malloc the stack which contains the drone values 
        add     esp,4
        mov     [tempPointer], eax      ; save the address in temp
        popad
        mov     eax, [tempPointer]      ; eax contains the address malloced
        mov     [esi], eax              ; put int the stack pointer the pointr to the malloced address
        mov     edx, [dronesCorArray]   ; pointer to the array
        mov     ebx, [edx + 4*ecx]
        mov     eax, [ebx]
        mov     [SPT], esp
        mov     esp, [ebx+4]            ; get initial ESP value – pointer to COi stack
	    push    eax 	                ; push initial “return” address
	    pushfd		                    ; push flags
	    pushad		                    ; push all other registers
	    mov     [ebx+4], esp            ; save new SPi value (after all the pushes)
	    mov     esp, [SPT]
        inc     ecx
        jmp _dronesLoop
    _dronesLoopEnd:
        popad
        mov     esp, ebp
        pop     ebp
        ret     


dronesArrInit:
    push    ebp            
    mov     ebp, esp
    pushad
    mov     dword eax, [dronesNum]      ; eax contains the number of drones
    mov     esi, 16             
	mul     esi	                        ; mul N with the size of one drone

    pushad	                            ; save the registers status before malloc		
	push    eax			                ; push the number of bytes we want to malloc				
	call    malloc
	add     esp,4
    mov     [arrPointer], eax           ; save the pointer to the new array int the global var
	popad
    call    dronesInit
    popad
	mov     esp, ebp
	pop     ebp
	ret

dronesInit:
    push ebp
	mov ebp, esp
	pushad

    mov     edx, 0
    mov     ebx, [arrPointer]           ; ebx contains pointer to the array of drones values
    initDroneLoop:                      
        cmp     dword edx, [dronesNum]  ; check if need to finish the loop
        je      endDronesInitLoop       
        mov     edi, edx                ; save dex in edi
        mov     eax, 16                 
        mul     edx                     ; mul eax by 16, the size of drone
        mov     edx, edi
        mov     ecx,ebx                 ; ecx contains arr
        add     ecx,eax                 ; ecx contains arr[eax]
        call    RandomNumberCalc        ; calc random number
        
        fild    dword [seed]            ; push the random number
        fidiv   dword [MaxInt]          ; div by max int
        fimul   dword [MaxBoard]        ; mul by 100
        fstp    dword [ecx]             ; put the value of x in the right place in the array
        add     ecx, 4                  ; ecx contains arr[eax +4]
        call    RandomNumberCalc        ; calc random number
        fild    dword [seed]            ; push the random number
        fidiv   dword [MaxInt]          ; div by max int
        fimul   dword [MaxBoard]        ; mul by 100
        fstp    dword [ecx]             ; put the value of y in the right place in the array
        add     ecx, 4                  ; ecx contains arr[eax +8]
        call    RandomNumberCalc        ; calc random number
        fild    dword [seed]            ; push the random number
        fidiv   dword [MaxInt]          ; div by max int
        fimul   dword [MaxAngle]        ; mul by 360
        fstp    dword [ecx]             ; put the value of alpha in the right place in the array
        add     ecx, 4                  ; ecx contains arr[eax +12]
        mov     dword [ecx], 0          ; put the value of destroys in the right place in the array
        inc edx
        jmp initDroneLoop

    endDronesInitLoop:   
    popad
	mov esp, ebp
	pop ebp
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


 

CoInit:
    push    ebp            
    mov     ebp, esp
    pushad
    mov     edx, CotargetPointer
    mov     eax, [CotargetPointer]  ; pointer to the array
    mov     [SPT], esp
    mov     esp, [edx+4]            ; get initial ESP value – pointer to COi stack
    push    eax 	                ; push initial “return” address
    pushfd		                    ; push flags
    pushad		                    ; push all other registers
    mov     [edx+4], esp            ; save new SPi value (after all the pushes)
    mov     esp, [SPT]

    mov     edx, CoPrinterPointer
    mov     eax, [CoPrinterPointer]  ; pointer to the array
    mov     [SPT], esp
    mov     esp, [edx+4]            ; get initial ESP value – pointer to COi stack
    push    eax 	                ; push initial “return” address
    pushfd		                    ; push flags
    pushad		                    ; push all other registers
    mov     [edx+4], esp            ; save new SPi value (after all the pushes)
    mov     esp, [SPT]
    mov     edx, CoschedulerPointer
    mov     eax, [CoschedulerPointer]  ; pointer to the array
    mov     [SPT], esp
    mov     esp, [edx+4]            ; get initial ESP value – pointer to COi stack
    push    eax 	                ; push initial “return” address
    pushfd		                    ; push flags
    pushad		                    ; push all other registers
    mov     [edx+4], esp            ; save new SPi value (after all the pushes)
    mov     esp, [SPT]

    popad
    mov     esp, ebp
    pop     ebp
    ret    

targetInit:
    push    ebp            
    mov     ebp, esp
    pushad

    call    RandomNumberCalc        ; calc random number
    fild    dword [seed]            ; push the random number
    fidiv   dword [MaxInt]          ; div by max int
    fimul   dword [MaxBoard]        ; mul by 100
    fstp    qword [targetX]         ; put the value of x in the right place in the memory

    call    RandomNumberCalc        ; calc random number
    fild    dword [seed]            ; push the random number
    fidiv   dword [MaxInt]          ; div by max int
    fimul   dword [MaxBoard]        ; mul by 100
    fstp    qword [targetY]         ; put the value of x in the right place in the memory

    popad                           
    mov esp, ebp
    pop     ebp                     
	ret                                 


resume: 
pushfd                              
pushad
mov edx,[currThreadPointer]         ; edx contains pointer to the current co routine
mov [edx+4],esp                     ; keep the current stack position

do_resume:                          
mov esp,[ebx+4]                     ; esp contains the resumed co-routine
mov dword [currThreadPointer],ebx   ; put in the pointer the resumed co-routine
popad
popfd
ret