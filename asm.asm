section .text

CodeEndStr      equ 0       ; '\0'
CodePercent     equ 37      ; '%'

global myprintf    

;----------------------------------------
; Printf (like in c)
; Entry:    rsi - format string, ...
; Destr:    all
myprintf:  

    sub rsp, 48
    push rbp

    mov rbp, rsp
    add rbp, 8
    
    mov [rbp], rdi
    mov [rbp+8], rsi
    mov [rbp+16], rdx
    mov [rbp+24], rcx
    mov [rbp+32], r8
    mov [rbp+40], r9

    mov r10, [rbp]
    mov [Str], r10

    .loop:
        mov rsi, [Str]
        mov r11b, byte [rsi]        ; r11b = current char
        cmp r11b, CodeEndStr        ; if == '\0'
        je .endloop                 

        cmp r11b, CodePercent       ; if == '%'
        jne .no_percent
        call parse_percent
        jmp .loop

        .no_percent:      
        call putchar

        jmp .loop

    .endloop:

    pop rbp
    add rsp, 48
            
    ret
;----------------------------------------
; Parse char after percent
; Entry:    
; Destr:    r10, rsi, r11

parse_percent:

    mov r10, [Str]
    inc r10
    mov [Str], r10                  ; [Str]++

    mov rsi, [Str]
    mov r11b, byte [rsi]            ; r11b = char after percent

    .check_percent:
        cmp r11b, CodePercent       ; if == '%'
        jne .check_char
        call putchar
        jmp .exit

    .check_char:


    .exit:
        
    
    ret
;----------------------------------------
; Print char to stdout, increase [Str]
; Entry:    rsi - pointer to char
; Destr:    r10

putchar:

    push rax
    push rdi
    push rdx

    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall             ; putchar

    mov r10, [Str]
    inc r10
    mov [Str], r10      ; [Str]++

    pop rdx
    pop rdi
    pop rax
    ret
;----------------------------------------
            
section     .data
            
Str:        dq 0