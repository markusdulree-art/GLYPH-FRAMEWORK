;; =============================================================================
;; GLYPH - ABI Normalization Layer
;; =============================================================================
;; This is the SPINE of cross-platform portability.
;; All core code uses logical registers, never physical ones.
;;
;; Supported Platforms:
;;   WIN64 - Windows x64 (64-bit)
;;   WIN32 - Windows x86 (32-bit)
;;
;; Usage:
;;   %define WIN64  ; or WIN32
;;   %include "abi.inc"
;; =============================================================================

%ifndef ABI_INC
%define ABI_INC

;; =============================================================================
;; Platform Detection & Dispatch
;; =============================================================================

%ifdef WIN64
    %include "abi_win64.inc"
%elifdef WIN32
    %include "abi_win32.inc"
%else
    %error "Unsupported platform. Define WIN64 or WIN32."
%endif

%endif ; ABI_INC
