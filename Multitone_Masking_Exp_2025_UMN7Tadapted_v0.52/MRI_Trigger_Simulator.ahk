; AutoHotkey 2.0 
; Press 't' every 2 sec
; Ctrl+8 enable/stop auto press
; Ctrl+9 fully exit

#Requires AutoHotkey v2.0

;
SendMode "Event"  ;
SetKeyDelay 50, 50  ;

;
global isRunning := false

;
^8:: {
    global isRunning
    isRunning := !isRunning
    
    if isRunning {
        ToolTip "enalbe auto trigger"
        SetTimer () => ToolTip(), -1500  ; 
        SetTimer PressT, 2000  ; 
    } else {
        ToolTip "disable auto trigger"
        SetTimer () => ToolTip(), -1500
        SetTimer PressT, 0  ; 
    }
}

; Ctrl+9: 
^9::ExitApp

; 
PressT() {
    global isRunning
    if isRunning {
        ; 
        Send "{t}"  ; 
        ; try: SendEvent "{t}"
        ; try: SendPlay "{t}"
    }
}