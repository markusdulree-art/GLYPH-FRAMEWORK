;; =============================================================================
;; GLYPH - Master Include Header
;; =============================================================================
;; Include this ONCE at the top of every source file.
;; It brings in all framework definitions.
;;
;; Usage:
;;   %define WIN64      ; or WIN32
;;   %include "glyph.inc"
;; =============================================================================

%ifndef GLYPH_INC
%define GLYPH_INC

;; Framework version
%define GLYPH_VERSION_MAJOR 0
%define GLYPH_VERSION_MINOR 1
%define GLYPH_VERSION_PATCH 0

;; Include order matters!
%include "config.inc"
%include "abi.inc"
%include "input.inc"

%endif ; GLYPH_INC
