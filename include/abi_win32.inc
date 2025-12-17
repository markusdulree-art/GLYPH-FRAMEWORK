;; =============================================================================
;; GLYPH - Windows x86 (32-bit) ABI Definitions
;; =============================================================================
;; Windows x86 Calling Convention (cdecl):
;;   - Arguments: Stack [ESP+4], [ESP+8], [ESP+12], [ESP+16]...
;;   - Return: EAX
;;   - Caller cleans stack
;;   - Stack alignment: 4 bytes (16 preferred for SSE)
;;   - Volatile: EAX, ECX, EDX
;;   - Non-volatile: EBX, EBP, ESI, EDI
;; =============================================================================

%ifndef ABI_WIN32_INC
%define ABI_WIN32_INC

;; -----------------------------------------------------------------------------
;; Architecture Constants
;; -----------------------------------------------------------------------------
%define BITS_32         1
%define PTR_SIZE        4
%define STACK_ALIGN     4
%define SHADOW_SPACE    0       ; No shadow space on Win32

;; -----------------------------------------------------------------------------
;; Logical Argument Access (Stack-based on Win32)
;; These are MEMORY references, not registers!
;; After standard prologue (push ebp; mov ebp, esp):
;;   [ebp+8]  = arg0
;;   [ebp+12] = arg1
;;   etc.
;; Without frame pointer:
;;   [esp+4]  = arg0 (after return address)
;; -----------------------------------------------------------------------------

;; For use AFTER function prologue with frame pointer
%define A0      dword [ebp+8]
%define A1      dword [ebp+12]
%define A2      dword [ebp+16]
%define A3      dword [ebp+20]

;; For loading into registers (common pattern)
;; mov eax, ARG0 etc.
%define ARG0    dword [ebp+8]
%define ARG1    dword [ebp+12]
%define ARG2    dword [ebp+16]
%define ARG3    dword [ebp+20]

;; -----------------------------------------------------------------------------
;; Logical Return Register
;; -----------------------------------------------------------------------------
%define R0      eax
%define R0W     ax
%define R0B     al

;; -----------------------------------------------------------------------------
;; Logical Scratch Registers (VOLATILE)
;; -----------------------------------------------------------------------------
%define TMP0    ecx
%define TMP1    edx

;; -----------------------------------------------------------------------------
;; Preserved Registers (callee must save/restore)
;; -----------------------------------------------------------------------------
;; EBX, EBP, ESI, EDI

;; -----------------------------------------------------------------------------
;; Stack/Frame Pointers
;; -----------------------------------------------------------------------------
%define SP      esp
%define BP      ebp

;; -----------------------------------------------------------------------------
;; Function Prologue/Epilogue Macros
;; -----------------------------------------------------------------------------

;; FUNC name - Begin a function with frame pointer setup
%macro FUNC 1
    global _%1
    _%1:
    push ebp
    mov ebp, esp
%endmacro

;; FUNC_NOFRAME - Begin without frame pointer (smaller, faster)
%macro FUNC_NOFRAME 1
    global _%1
    _%1:
%endmacro

;; FUNC_LOCALS name, bytes - Begin function with local stack space
%macro FUNC_LOCALS 2
    global _%1
    _%1:
    push ebp
    mov ebp, esp
    sub esp, %2
%endmacro

;; ENDFUNC - End a function (with frame pointer)
%macro ENDFUNC 0
    mov esp, ebp
    pop ebp
    ret
%endmacro

;; ENDFUNC_NOFRAME - End without frame pointer
%macro ENDFUNC_NOFRAME 0
    ret
%endmacro

;; ENDFUNC_LOCALS bytes - End function with local stack cleanup
%macro ENDFUNC_LOCALS 1
    mov esp, ebp
    pop ebp
    ret
%endmacro

;; -----------------------------------------------------------------------------
;; Call Helper Macros  
;; -----------------------------------------------------------------------------

;; PUSH_ARG value - Push argument for function call (right to left!)
%macro PUSH_ARG 1
    push %1
%endmacro

;; CALL_CLEANUP bytes - Clean up stack after cdecl call
%macro CALL_CLEANUP 1
    add esp, %1
%endmacro

;; CALL_EXTERN symbol - Call external function
%macro CALL_EXTERN 1
    call _%1
%endmacro

;; PRESERVE reg - Push a non-volatile register
%macro PRESERVE 1
    push %1
%endmacro

;; RESTORE reg - Pop a non-volatile register
%macro RESTORE 1
    pop %1
%endmacro

;; -----------------------------------------------------------------------------
;; Local Variable Access
;; After FUNC_LOCALS prologue: [ebp-4] = first local, [ebp-8] = second, etc.
;; -----------------------------------------------------------------------------
%define LOCAL(n) dword [ebp - 4*(n)]

%endif ; ABI_WIN32_INC
