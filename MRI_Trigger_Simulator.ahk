; AutoHotkey 2.0 脚本
; 每2秒自动按一次 't' 键
; Ctrl+8 启用/停止自动按键
; Ctrl+9 完全退出脚本

#Requires AutoHotkey v2.0

; 设置发送模式以提高兼容性
SendMode "Event"  ; 尝试 Event 模式，更接近真实按键
SetKeyDelay 50, 50  ; 设置按键延迟

; 全局变量控制是否运行
global isRunning := false

; Ctrl+8: 启用/停止自动按键
^8:: {
    global isRunning
    isRunning := !isRunning
    
    if isRunning {
        ToolTip "自动按键已启用"
        SetTimer () => ToolTip(), -1500  ; 1.5秒后隐藏提示
        SetTimer PressT, 2000  ; 每2秒执行一次
    } else {
        ToolTip "自动按键已停止"
        SetTimer () => ToolTip(), -1500
        SetTimer PressT, 0  ; 停止定时器
    }
}

; Ctrl+9: 完全退出脚本
^9::ExitApp

; 按键函数
PressT() {
    global isRunning
    if isRunning {
        ; 尝试多种发送方式
        Send "{t}"  ; 使用大括号格式
        ; 或者尝试：SendEvent "{t}"
        ; 或者尝试：SendPlay "{t}"
    }
}