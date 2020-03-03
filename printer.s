section .data
	id: dd 0
	numOfDes: dd 0
	temp: dd 0
section .rodata
	format_float: db "%.2f",10,0
	format_psik: db ",",0
	format_int: db "%d",10,0  
	format_string: db "%s",10,0
	printTargetFormat: db "%.2f,%.2f" , 10 ,0
	drone_format: db "%d,%.2f,%.2f,%.2f,%d",10,0
section .bss
	x: resb 4
	y: resb 4
	alfa: resb 4
section .text
	global printer
	extern printf
	extern targetX
	extern targetY
	extern dronesNum
	extern arrPointer
	extern CoschedulerPointer
	extern resume
	extern do_resume
	extern stdout
	extern fflush

printer:
	pushad
	fld 	qword [targetY]					; push y target value
	sub 	esp,8							; sub esp by 8, beacuse of pushing qword
	fstp 	qword [esp]						; put the value in esp

	fld 	qword [targetX]					; same in x
	sub 	esp,8							; same in x
	fstp 	qword [esp]						; same in x

	push 	dword printTargetFormat			; push the target format
	call 	printf				
	add 	esp,20							; add 20 to esp, beacuse of 2 qword and 1 dword
	popad

	mov 	edi, 0							; edi will be the counter
	mov     ebx, [arrPointer]				; ebx contains pointer to the drone array
	startPrintLoop:
		mov 	edx, [dronesNum]			; edx contians the num of drones
		cmp		edi, edx					; check if we printed all the drones
		je 		finishPrintLoop				; if yes, jump to the end of printer

		add 	edi,1						
		mov 	[id], edi					; id contains the id of the drone
		sub 	edi,1

		mov     [temp], edi					; save the counter in temp
        mov     eax, 16			
        mul     edi							; mul the counter by the size of drone
        mov     edi, [temp]					
        mov     ecx,ebx             		; ecx points to the drone array
        add     ecx,eax                     ; ecx contains arr[drone], points to its x value
		mov 	eax, [ecx]					; eax contains the x value of the drone
		mov 	[x], eax					; save the value in x
		add 	ecx, 4						; ecx contains arr[drone], points to its y value
		mov 	eax, [ecx]					; eax contains the y value of the drone
		mov 	[y], eax					; save the value in y

		add 	ecx, 4						; ecx contains arr[drone], points to its alpha value
		mov 	eax, [ecx]					; eax contains the alpha value of the drone
		mov 	[alfa], eax					; save the value in alfa

		add 	ecx, 4						; ecx contains arr[drone], points to its num of destroyes value 
		mov 	eax, [ecx]					; eax contains the num of destroyes value of the drone
		mov 	[numOfDes], eax				; save the value in numOfDes

		pushad
		push 	dword [numOfDes]			; push the num of des

		fld 	dword [alfa]				; push alfa
		sub 	esp,8
		fstp 	qword [esp]


		fld 	dword [y]					; push y
		sub 	esp,8
		fstp 	qword [esp]


		fld 	dword [x]					; push x
		sub 	esp,8
		fstp 	qword [esp]
		push 	dword [id]					; push id
		push 	dword drone_format			; push the drone format
		call 	printf
		add 	esp,36	
		popad

		inc 	edi							; inc the counter
		jmp startPrintLoop					; jump to the start of loop


	finishPrintLoop:
		mov 	ebx, CoschedulerPointer		; resume the scedluer co rutine
		call 	resume
		jmp 	printer						; after resume jump back to printer


