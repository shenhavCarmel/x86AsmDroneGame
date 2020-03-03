section .data

section .rodata
section .bss

section .text
	global startSchedular
	global scheduler
	extern dronesNum
	extern stepsToPrint
	extern CoPrinterPointer
	extern resume
	extern do_resume
	extern printf
	extern currDrone
	extern drone
	extern dronesCorArray
scheduler:
	mov		edi,0								; edi counter for K (steps to print)
	mov 	esi,1								; esi counter for N (num of drones)
	startSchedLoop:
		mov 	edx,[stepsToPrint]				; edx contains K
		cmp 	edi, edx						; check if need to print
		jne 	noPrint							; if not equal, not print
		mov 	edi, 0							; if yes, zero the counter
		mov 	ebx, CoPrinterPointer			; resume the printer co routine
		call 	resume
		noPrint:
		mov 	[currDrone], esi				; the current drone id is the drones counter
		mov 	ecx, esi						; ecx cotains the N counter
		sub 	ecx,1							; sub by one beacuse the co routine arr starts by 0
		mov 	eax, [dronesCorArray]			; eax points to the co routine arr
		add 	ecx,ecx							
		add 	ecx,ecx							; mul ecx by 4, the size of the pointer to function
		add 	eax,ecx							; add to the current drone co routine pointer
		mov 	eax, [eax]						; mov eax, the value in eax
		mov 	ebx, eax						; resume the current drone co routine
		call 	resume
		mov 	edx, [dronesNum]				; edx contians N
		cmp 	edx, esi						; check if finish all the drones (a loop)
		je 		finishDrones					; if yes end the loop
		inc 	edi								; if not, inc the K counter
		inc 	esi								; inc the N counter
		jmp startSchedLoop						; jump back to the start loop
		finishDrones:
			mov 	esi, 1						; if finish loop, return to the first drone
			inc 	edi							; inc the K counter
			jmp 	startSchedLoop				; jump back to the start loop


		
	

