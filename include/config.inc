;; =============================================================================
;; GLYPH - Configuration Header
;; =============================================================================
;; Compile-time constants. Change these to configure the framework.
;; These values are FIXED at assembly time - no runtime changes.
;; =============================================================================

%ifndef CONFIG_INC
%define CONFIG_INC

;; -----------------------------------------------------------------------------
;; Framebuffer Configuration
;; -----------------------------------------------------------------------------
%define FRAME_WIDTH     80      ; Characters per row
%define FRAME_HEIGHT    25      ; Rows
%define FRAME_CELLS     (FRAME_WIDTH * FRAME_HEIGHT)
%define CELL_SIZE       4       ; Bytes per cell (glyph, fg, bg, flags)
%define BUFFER_SIZE     (FRAME_CELLS * CELL_SIZE)

;; -----------------------------------------------------------------------------
;; Timing Configuration
;; -----------------------------------------------------------------------------
%define TARGET_FPS      60
%define FRAME_TIME_US   16666   ; Microseconds per frame (~60 FPS)
%define MAX_FRAME_TIME  250000  ; Cap to prevent spiral of death

;; -----------------------------------------------------------------------------
;; Input Configuration
;; -----------------------------------------------------------------------------
%define MAX_KEYS        256     ; Number of key states tracked

;; -----------------------------------------------------------------------------
;; Memory Configuration
;; -----------------------------------------------------------------------------
%define MAX_SNAKE_LEN   500     ; For snake game example

;; -----------------------------------------------------------------------------
;; Color Palette (Standard 16-color console)
;; -----------------------------------------------------------------------------
%define COLOR_BLACK         0
%define COLOR_BLUE          1
%define COLOR_GREEN         2
%define COLOR_CYAN          3
%define COLOR_RED           4
%define COLOR_MAGENTA       5
%define COLOR_BROWN         6
%define COLOR_LGRAY         7
%define COLOR_DGRAY         8
%define COLOR_LBLUE         9
%define COLOR_LGREEN        10
%define COLOR_LCYAN         11
%define COLOR_LRED          12
%define COLOR_LMAGENTA      13
%define COLOR_YELLOW        14
%define COLOR_WHITE         15

;; Default colors
%define DEFAULT_FG          COLOR_LGRAY
%define DEFAULT_BG          COLOR_BLACK

;; -----------------------------------------------------------------------------
;; Cell Structure Offsets
;; -----------------------------------------------------------------------------
%define CELL_GLYPH      0
%define CELL_FG         1
%define CELL_BG         2
%define CELL_FLAGS      3

%endif ; CONFIG_INC
