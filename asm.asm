section .text

CodeEndStr      equ 0       ; '\0'
CodePercent     equ 37      ; '%'
CodeChar        equ 99      ; 'c'
CodeString      equ 115     ; 's'

global myprintf    

;--------------------------------------------------------------------------------
; Printf (like in c)
; Entry:    rsi - format string, ...
; Destr:    all

myprintf:  

    pop r10
    sub rsp, 48                     ; allocate memory for first 6 parameters
    push r10                        ; shifting the return address
    push rbp                        ; save rbp

    mov rbp, rsp
    add rbp, 16
    
    mov [rbp], rdi
    mov [rbp+8], rsi
    mov [rbp+16], rdx
    mov [rbp+24], rcx
    mov [rbp+32], r8
    mov [rbp+40], r9

    mov [Str], rdi

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
        call putchar_inc_str

        jmp .loop

    .endloop:

    pop rbp
            
    ret
;--------------------------------------------------------------------------------
; Parse char after percent
; Entry:    
; Destr:    r10, rsi, r11, rbx

parse_percent:

    push rbp
    mov rbp, rsp

    add rbp, 32
    add rbp, [CurrOffsArg]          ; [rbp] = current argument
    mov rbx, rbp

    mov r10, [Str]
    inc r10
    mov [Str], r10                  ; [Str]++

    mov rsi, [Str]
    mov r11b, byte [rsi]            ; r11b = char after percent

    .check_percent:
        cmp r11b, CodePercent       ; if == '%'
        jne .check_char

        mov r10, [CurrOffsArg]
        sub r10, 8
        mov [CurrOffsArg], r10      ; don't change argument
        call putchar_inc_str

        jmp .exit

    .check_char:
        cmp r11b, CodeChar          ; if == 'c'
        jne .check_string

        call parse_char

        jmp .exit

    .check_string:
        cmp r11b, CodeString          ; if == 'c'
        jne .check_dec

        call parse_string

        jmp .exit

    .check_dec:

    .exit:
        
    mov r10, [CurrOffsArg]
    add r10, 8
    mov [CurrOffsArg], r10          ; next argument

    pop rbp

    ret
;--------------------------------------------------------------------------------
; Parse %c
; Entry:    rbx - address of current argument (char)
; Destr:    

parse_char:

    mov rsi, rbx
    call putchar_inc_str

    ret
;--------------------------------------------------------------------------------
; Parse %s
; Entry:    rbx - address of current argument (string)
; Destr:    r10, rsi, r11

parse_string:

    mov rsi, [rbx]

    .loop:
        mov r11b, byte [rsi]        ; r11b = current char
        cmp r11b, CodeEndStr        ; if == '\0'
        je .endloop                 
    
        call putchar
        inc rsi

        jmp .loop

    .endloop:
    mov r10, [Str]
    inc r10
    mov [Str], r10                  ; [Str]++

    ret
;--------------------------------------------------------------------------------
; Print char to stdout, increase [Str]
; Entry:    rsi - pointer to char
; Destr:    r10

putchar_inc_str:

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
;--------------------------------------------------------------------------------
; Print char to stdout
; Entry:    rsi - pointer to char
; Destr:    

putchar:

    push rax
    push rdi
    push rdx

    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall             ; putchar

    pop rdx
    pop rdi
    pop rax
    ret
;--------------------------------------------------------------------------------
            
section     .data
            
Str:            dq 0
CurrOffsArg:    dq 8