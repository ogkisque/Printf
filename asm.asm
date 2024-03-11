section .text

CodeEndStr      equ 0       ; '\0'
CodePercent     equ 37      ; '%'
CodeChar        equ 99      ; 'c'
CodeString      equ 115     ; 's'
CodeDec         equ 100     ; 'd'
CodeHex         equ 120     ; 'x'
CodeOct         equ 111     ; 'o'
CodeBin         equ 98      ; 'b'

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
    xor r11, r11                    ; r11 = 0

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

    cmp r11b, CodePercent       ; if == '%'
    jne .not_percent

    mov r10, [CurrOffsArg]
    sub r10, 8
    mov [CurrOffsArg], r10      ; don't change argument
    call putchar_inc_str

    jmp exit

    .not_percent:

    mov r12, r11
    and r12, 0xff                   ; 1 byte
    sub r12b, CodeBin   
    shl r12b, 3                     ; r12b *= 8
    mov r13, [SwitchChar + r12]
    jmp r13

    check_char:
        call parse_char
        jmp exit

    check_string:
        call parse_string
        jmp exit

    check_dec:
        call parse_dec
        jmp exit

    check_hex:
        call parse_hex
        jmp exit
        
    check_oct:
        call parse_oct
        jmp exit
        
    check_bin:
        call parse_bin
        jmp exit
        
    exit:
        
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
; Parse %d
; Entry:    rbx - address of current argument (number)
; Destr:    rdx, rax, r10, r11, rdi, rsi

parse_dec:

    xor rdx, rdx
    mov rax, [rbx]                  ; rax = number
    mov r10, 10
    mov r11, 21
    mov r12b, '0'

    cmp rax, 0
    jge .loop
    neg rax                         ; rax = |rax|
    mov r12b, '-'

    .loop:
        xor rdx, rdx
        div r10                     ; rax /= 10 ; rdx = rax % 10

        add rdx, '0'                ; convert to char
        mov byte [DecNum + r11], dl
        dec r11

        cmp rax, 0
        jne .loop

    mov byte [DecNum + r11], r12b   ; '-' or '0'

    mov rax, 0x01     
    mov rdi, 1        

    mov rdx, 21
    sub rdx, r11

    mov rsi, DecNum
    add rsi, r11
    inc rsi

    cmp r12b, '0'
    je .next
    inc rdx
    dec rsi

    .next:
    syscall                         ; print (DecNum + r11 + 1)

    mov r10, [Str]
    inc r10
    mov [Str], r10                  ; [Str]++

    ret
;--------------------------------------------------------------------------------
; Parse %x
; Entry:    rbx - address of current argument (number)
; Destr:    rdx, rax, r10, r11, rdi, rsi

parse_hex:

    xor rdx, rdx
    mov rax, [rbx]                  ; rax = number
    mov r10, 16
    mov r11, 17
    mov r12b, '0'

    cmp rax, 0
    jge .loop
    neg rax                         ; rax = |rax|
    mov r12b, '-'

    .loop:
        xor rdx, rdx
        div r10                     ; rax /= 10 ; rdx = rax % 10

        call convert_hex

        mov byte [HexNum + r11], dl
        dec r11

        cmp rax, 0
        jne .loop

    mov byte [HexNum + r11], r12b   ; '-' or '0'

    mov rax, 0x01     
    mov rdi, 1        

    mov rdx, 17
    sub rdx, r11

    mov rsi, HexNum
    add rsi, r11
    inc rsi

    cmp r12b, '0'
    je .next
    inc rdx
    dec rsi

    .next:
    syscall                         ; print (HexNum + r11 + 1)

    mov r10, [Str]
    inc r10
    mov [Str], r10                  ; [Str]++

    ret
;--------------------------------------------------------------------------------
; Convert digit to ASCII
; Entry:    rdx (dl) - digit
; Destr:    rdx

convert_hex:

    cmp dl, 10d 
    jge .letter
    add dl, 48d		; '0'
    jmp .exit

    .letter:
    add dl, 55d		; 'A' - 10

    .exit:
    ret
;--------------------------------------------------------------------------------
; Parse %o
; Entry:    rbx - address of current argument (number)
; Destr:    rdx, rax, r10, r11, rdi, rsi

parse_oct:

    xor rdx, rdx
    mov rax, [rbx]                  ; rax = number
    mov r10, 8
    mov r11, 33
    mov r12b, '0'

    cmp rax, 0
    jge .loop
    neg rax                         ; rax = |rax|
    mov r12b, '-'

    .loop:
        xor rdx, rdx
        div r10                     ; rax /= 10 ; rdx = rax % 10

        add rdx, '0'                ; convert to char
        mov byte [OctNum + r11], dl
        dec r11

        cmp rax, 0
        jne .loop

    mov byte [OctNum + r11], r12b   ; '-' or '0'

    mov rax, 0x01     
    mov rdi, 1        

    mov rdx, 33
    sub rdx, r11

    mov rsi, OctNum
    add rsi, r11
    inc rsi

    cmp r12b, '0'
    je .next
    inc rdx
    dec rsi

    .next:
    syscall                         ; print (OctNum + r11 + 1)

    mov r10, [Str]
    inc r10
    mov [Str], r10                  ; [Str]++

    ret
;--------------------------------------------------------------------------------
; Parse %b
; Entry:    rbx - address of current argument (number)
; Destr:    rdx, rax, r10, r11, rdi, rsi

parse_bin:

    xor rdx, rdx
    mov rax, [rbx]                  ; rax = number
    mov r10, 2
    mov r11, 65
    mov r12b, '0'

    cmp rax, 0
    jge .loop
    neg rax                         ; rax = |rax|
    mov r12b, '-'

    .loop:
        xor rdx, rdx
        div r10                     ; rax /= 10 ; rdx = rax % 10

        add rdx, '0'                ; convert to char
        mov byte [BinNum + r11], dl
        dec r11

        cmp rax, 0
        jne .loop

    mov byte [BinNum + r11], r12b   ; '-' or '0'

    mov rax, 0x01     
    mov rdi, 1        

    mov rdx, 65
    sub rdx, r11

    mov rsi, BinNum
    add rsi, r11
    inc rsi

    cmp r12b, '0'
    je .next
    inc rdx
    dec rsi

    .next:
    syscall                         ; print (BinNum + r11 + 1)

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
SwitchChar:     dq check_bin               ; 'b'
                dq check_char              ; 'c'
                dq check_dec               ; 'd'
                dq exit                    ; 'e'
                dq exit                    ; 'f'
                dq exit                    ; 'g'
                dq exit                    ; 'h'
                dq exit                    ; 'i'
                dq exit                    ; 'g'
                dq exit                    ; 'k'
                dq exit                    ; 'l'
                dq exit                    ; 'm'
                dq exit                    ; 'n'
                dq check_oct               ; 'o'
                dq exit                    ; 'p'
                dq exit                    ; 'q'
                dq exit                    ; 'r'
                dq check_string            ; 's'
                dq exit                    ; 't'
                dq exit                    ; 'u'
                dq exit                    ; 'v'
                dq exit                    ; 'w'
                dq check_hex               ; 'x'
BinNum:         db 65 dup 48
OctNum:         db 33 dup 48
DecNum:         db 21 dup 48
HexNum:         db 17 dup 48