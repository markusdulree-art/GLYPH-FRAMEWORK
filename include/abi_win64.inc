;; =============================================================================
;; GLYPH - Windows x64 ABI Definitions
;; =============================================================================
;; Windows x64 Calling Convention:
;;   - Arguments: RCX, RDX, R8, R9 (then stack)
;;   - Return: RAX
;;   - Shadow space: 32 bytes (MANDATORY)
;;   - Stack alignment: 16 bytes
;;   - Volatile: RAX, RCX, RDX, R8, R9, R10, R11
;;   - Non-volatile: RBX, RBP, RDI, RSI, R12-R15
;; =============================================================================

%ifndef ABI_WIN64_INC
%define ABI_WIN64_INC

;; -----------------------------------------------------------------------------
;; Architecture Constants
;; -----------------------------------------------------------------------------
%define BITS_64         1
%define PTR_SIZE        8
%define STACK_ALIGN     16
%define SHADOW_SPACE    32

;; -----------------------------------------------------------------------------
;; Logical Argument Registers → Physical Mapping
;; -----------------------------------------------------------------------------
%define A0      rcx
%define A1      rdx
%define A2      r8
%define A3      r9
%define A0D     ecx     ; 32-bit versions
%define A1D     edx
%define A2D     r8d
%define A3D     r9d
%define A0B     cl      ; 8-bit versions
%define A1B     dl
%define A2B     r8b
%define A3B     r9b

;; -----------------------------------------------------------------------------
;; Logical Return Register
;; -----------------------------------------------------------------------------
%define R0      rax
%define R0D     eax
%define R0B     al

;; -----------------------------------------------------------------------------
;; Logical Scratch Registers (ALWAYS VOLATILE - never rely across calls)
;; -----------------------------------------------------------------------------
%define TMP0    r10
%define TMP1    r11
%define TMP0D   r10d
%define TMP1D   r11d

;; -----------------------------------------------------------------------------
;; Preserved Registers (callee must save/restore)
;; -----------------------------------------------------------------------------
;; RBX, RBP, RDI, RSI, R12, R13, R14, R15
;; Use these for loop counters, persistent state within a function

;; -----------------------------------------------------------------------------
;; Stack Pointer
;; -----------------------------------------------------------------------------
%define SP      rsp
%define BP      rbp

;; -----------------------------------------------------------------------------
;; Function Prologue/Epilogue Macros
;; -----------------------------------------------------------------------------

;; FUNC name - Begin a function with proper prologue
%macro FUNC 1
    global %1
    %1:
    sub rsp, SHADOW_SPACE
%endmacro

;; FUNC_LOCALS name, bytes - Begin function with local stack space
%macro FUNC_LOCALS 2
    global %1
    %1:
    %assign %%total_stack (%2 + SHADOW_SPACE + 15) & ~15
    sub rsp, %%total_stack
%endmacro

;; ENDFUNC - End a function with proper epilogue
%macro ENDFUNC 0
    add rsp, SHADOW_SPACE
    ret
%endmacro

;; ENDFUNC_LOCALS bytes - End function with local stack cleanup
%macro ENDFUNC_LOCALS 1
    %assign %%total_stack (%1 + SHADOW_SPACE + 15) & ~15
    add rsp, %%total_stack
    ret
%endmacro

;; -----------------------------------------------------------------------------
;; Call Helper Macros
;; -----------------------------------------------------------------------------

;; CALL_EXTERN symbol - Call external function (shadow space already reserved)
%macro CALL_EXTERN 1
    call %1
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
;; Stack Argument Access (for args beyond A0-A3)
;; After FUNC prologue: [rsp+32+8*N] for Nth stack arg (0-indexed)
;; -----------------------------------------------------------------------------
%define STACK_ARG(n) [rsp + SHADOW_SPACE + 8 + 8*(n)]

%endif ; ABI_WIN64_INC
