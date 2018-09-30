.586 ; rdtsc...                                    
.model flat, stdcall                     
option casemap :none                    

include \masm32\include\windows.inc          
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc         
include \masm32\macros\ucmacros.asm
        
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib


PAGE_SIZE equ 4096

.data
    szCaption   db  'No debugger attached', 0
    szText      db  'No debugger attached', 0
    ntdll       db  'ntdll.dll', 0
    allocate    db  'NtAllocateVirtualMemory', 0
    query       db  'NtQueryVirtualMemory',0

.code

start:
ASSUME FS:NOTHING
    push eax
loop_detected:
    push ebx
    mov eax, fs:[30h]
    mov al, [eax + 2h]
    test al, al
    jnz loop_detected ; breaking...
    pop ebx
    pop eax

; NtAllocateVirtualMemory
 ;local:
    ; BaseAddress
    push 0
    
    ; RegionSize:
    push PAGE_SIZE * 2

 ;params:
    ; Protect:
    push PAGE_EXECUTE_READWRITE
    
    ; AllocationType:
    push MEM_COMMIT or MEM_RESERVE

    ; ptr to RegionSize
    push esp
    add dword ptr [esp], 8h

    ; ZeroBits
    push 0

    ; ptr to BaseAddress
    push esp
    add dword ptr [esp], 14h

    ; ProcessHandle
    push -1

    ; call to NtAllocateVirtualMemory
    push offset ntdll
    call GetModuleHandleA
    push offset allocate
    push eax
    call GetProcAddress
    call eax

    ; restore stack and eax = BaseAddress
    pop eax
    pop eax
; end NtAllocateVirtualMemory


push eax
add eax, PAGE_SIZE - 4
mov [eax], dword ptr 03CDC300h ; ret + long int3 
pop eax

call NtQueryVirtualMemory

sub eax, 2

PUSH  OFFSET SEH
PUSH  FS:[0]
MOV  FS:[0], ESP
  
call eax

NtQueryVirtualMemory:
 ;local:
    ; MEMORY_WORKING_SET_EX_INFORMATION
    push 0

    push eax
    add [esp], dword ptr PAGE_SIZE


 ;params:

    push 0

    push 8 ; sizeof MEMORY_WORKING_SET_EX_INFORMATION
    
    ; ptr to MEMORY_WORKING_SET_EX_INFORMATION
    push esp
    add dword ptr [esp], 08h

    push 4 ; MemoryWorkingSetExInformation 

    push 0

    push -1

    ; call to NtQueryVirtualMemory
    push offset ntdll
    call GetModuleHandleA
    push offset query
    push eax
    call GetProcAddress
    call eax

    breaking:
    pop eax
    xchg eax, [esp]
    test al, al
    jnz breaking; breaking...
    pop eax

    ret
; end NtQueryVirtualMemory


SafeOffset:
add eax, 2
sub eax, PAGE_SIZE
call NtQueryVirtualMemory
invoke MessageBox, NULL, offset szText, offset szCaption, MB_OK
invoke ExitProcess, NULL 

SEH PROC PROC C pExcept:DWORD, pFrame:DWORD, pContext:DWORD, pDispatch:DWORD
  MOV EAX, pContext
  MOV [EAX].CONTEXT.regEip, OFFSET SafeOffset 
  MOV EAX,ExceptionContinueExecution 
  RET 
SEH ENDP


end start

