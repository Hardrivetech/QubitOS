[bits 16]
[org 0x0000]

start:
    ; Set up data segment
    mov ax, 0x1000
    mov ds, ax
    mov es, ax

    ; Print welcome message
    mov si, msg
    call print_string
    call print_newline

    ; Start shell
    call shell_loop

    ; Halt (if shell exits)
    hlt

print_string:
    lodsb
    or al, al
    jz done
    mov ah, 0x0e
    int 0x10
    jmp print_string
done:
    ret

read_string:
    mov di, input_buffer
.read_loop:
    mov ah, 0x00
    int 0x16
    cmp al, 0x0d  ; Enter key
    je .done
    cmp al, 0x08  ; Backspace
    je .backspace
    stosb
    mov ah, 0x0e
    int 0x10
    jmp .read_loop
.backspace:
    cmp di, input_buffer
    je .read_loop
    dec di
    mov ah, 0x0e
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp .read_loop
.done:
    mov al, 0
    stosb
    call print_newline
    ret

print_newline:
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10
    ret

strcmp:
    ; si = str1, di = str2
    .loop:
        lodsb
        cmp al, [di]
        jne .not_equal
        cmp al, 0
        je .equal
        inc di
        jmp .loop
    .not_equal:
        mov ax, 1
        ret
    .equal:
        xor ax, ax
        ret

shell_loop:
    .loop:
        mov si, prompt
        call print_string
        call read_string
        call parse_command
        jmp .loop

parse_command:
    mov si, input_buffer
    mov di, cmd_help
    call strcmp
    test ax, ax
    jz .help
    mov si, input_buffer
    mov di, cmd_echo
    call strcmp_prefix
    test ax, ax
    jz .echo
    mov si, input_buffer
    mov di, cmd_halt
    call strcmp
    test ax, ax
    jz .halt
    mov si, input_buffer
    mov di, cmd_clear
    call strcmp
    test ax, ax
    jz .clear
    mov si, input_buffer
    mov di, cmd_time
    call strcmp
    test ax, ax
    jz .time
    mov si, input_buffer
    mov di, cmd_draw
    call strcmp
    test ax, ax
    jz .draw
    mov si, input_buffer
    mov di, cmd_ls
    call strcmp
    test ax, ax
    jz .ls
    mov si, input_buffer
    mov di, cmd_create
    call strcmp_prefix
    test ax, ax
    jz .create
    mov si, input_buffer
    mov di, cmd_delete
    call strcmp_prefix
    test ax, ax
    jz .delete
    mov si, input_buffer
    mov di, cmd_edit
    call strcmp_prefix
    test ax, ax
    jz .edit
    mov si, input_buffer
    mov di, cmd_cat
    call strcmp_prefix
    test ax, ax
    jz .cat
    mov si, input_buffer
    mov di, cmd_calc
    call strcmp
    test ax, ax
    jz .calc
    mov si, input_buffer
    mov di, cmd_ver
    call strcmp
    test ax, ax
    jz .ver
    mov si, unknown_cmd
    call print_string
    call print_newline
    ret
.help:
    mov si, help_msg
    call print_string
    call print_newline
    ret
.echo:
    mov si, input_buffer
    add si, 5  ; Skip "echo "
    call print_string
    call print_newline
    ret
.halt:
    hlt

.clear:
    call clear_screen
    ret

.time:
    mov si, fake_time
    call print_string
    call print_newline
    ret

.draw:
    call draw_graphics
    ret

.ls:
    call list_files
    ret

.create:
    mov si, input_buffer
    add si, 7  ; Skip "create "
    call create_file
    ret

.delete:
    mov si, input_buffer
    add si, 7  ; Skip "delete "
    call delete_file
    ret

.edit:
    mov si, input_buffer
    add si, 5  ; Skip "edit "
    call edit_file
    ret

.cat:
    mov si, input_buffer
    add si, 4  ; Skip "cat "
    call cat_file
    ret

.calc:
    call calc
    ret

.ver:
    mov si, ver_msg
    call print_string
    call print_newline
    ret

strcmp_prefix:
    ; Check if input starts with prefix in di
    .loop:
        lodsb
        cmp al, [di]
        jne .not_equal
        inc di
        cmp byte [di], 0
        je .equal
        jmp .loop
    .not_equal:
        mov ax, 1
        ret
    .equal:
        xor ax, ax
        ret

clear_screen:
    mov ah, 0x00
    mov al, 0x03  ; 80x25 text mode
    int 0x10
    ret

draw_graphics:
    ; Switch to mode 13h
    mov ah, 0x00
    mov al, 0x13
    int 0x10
    ; Draw pixel at 100,100 color 4 (red)
    mov ah, 0x0c
    mov al, 4
    mov cx, 100
    mov dx, 100
    int 0x10
    ; Wait for key
    mov ah, 0x00
    int 0x16
    ; Switch back to text mode
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    ret

create_file:
    ; si points to file name
    mov di, files
    mov al, [file_count]
    mov bl, 16
    mul bl
    add di, ax
    .copy_loop:
        lodsb
        stosb
        cmp al, 0
        jne .copy_loop
    inc byte [file_count]
    ret

list_files:
    mov cl, [file_count]
    mov ch, 0
    mov di, files
    .list_loop:
        cmp cl, 0
        je .done
        mov si, di
        call print_string
        call print_newline
        add di, 16
        dec cl
        jmp .list_loop
    .done:
        ret

delete_file:
    ; si points to file name
    push si  ; save si
    mov cx, [file_count]
    mov di, files
.find_loop:
    cmp cx, 0
    je .not_found
    pop si  ; restore si
    push si  ; save again
    push di  ; save di
    call strcmp
    pop di  ; restore di
    test ax, ax
    jz .found
    add di, 256
    dec cx
    jmp .find_loop
.found:
    ; shift the rest
    mov al, [file_count]
    dec al
    mov [file_count], al
    ; number of files after: cx - 1
    mov ax, cx
    dec ax
    mov cx, ax
    ; bytes: cx * 256
    mov ax, cx
    mov bx, 256
    mul bx
    mov cx, ax
    mov si, di
    add si, 256
    rep movsb
    pop si  ; clean stack
    mov si, deleted_msg
    call print_string
    call print_newline
    ret
.not_found:
    pop si  ; clean stack
    mov si, not_found_msg
    call print_string
    call print_newline
    ret

edit_file:
    ; si points to file name
    push si  ; save si
    mov cx, [file_count]
    mov di, files
.find_loop:
    cmp cx, 0
    je .not_found
    pop si  ; restore si
    push si  ; save again
    push di  ; save di
    call strcmp
    pop di  ; restore di
    test ax, ax
    jz .found
    add di, 256
    dec cx
    jmp .find_loop
.found:
    ; di points to file
    mov bx, di  ; save di
    ; display current content
    mov si, bx
    add si, 16
    call print_string
    call print_newline
    ; prompt for new content
    mov si, edit_prompt
    call print_string
    call read_string
    ; copy to content
    mov si, input_buffer
    mov di, bx
    add di, 16
.copy_loop:
    lodsb
    stosb
    cmp al, 0
    jne .copy_loop
    pop si  ; clean stack
    ret
.not_found:
    pop si  ; clean stack
    mov si, not_found_msg
    call print_string
    call print_newline
    ret

cat_file:
    ; si points to file name
    push si  ; save si
    mov cx, [file_count]
    mov di, files
.find_loop:
    cmp cx, 0
    je .not_found
    pop si  ; restore si
    push si  ; save again
    push di  ; save di
    call strcmp
    pop di  ; restore di
    test ax, ax
    jz .found
    add di, 256
    dec cx
    jmp .find_loop
.found:
    ; di points to file
    mov si, di
    add si, 16
    call print_string
    call print_newline
    pop si  ; clean stack
    ret
.not_found:
    pop si  ; clean stack
    mov si, not_found_msg
    call print_string
    call print_newline
    ret

calc:
    ; Simple calculator: prompt for expression like "1 + 2"
    mov si, calc_prompt
    call print_string
    call read_string
    ; Parse input_buffer: num1 op num2
    mov si, input_buffer
    call atoi  ; ax = num1
    mov bx, ax  ; save num1
    ; skip spaces
.skip_space1:
    lodsb
    cmp al, ' '
    je .skip_space1
    cmp al, 0
    je .error
    mov dl, al  ; op
    ; skip spaces
.skip_space2:
    lodsb
    cmp al, ' '
    je .skip_space2
    cmp al, 0
    je .error
    dec si  ; back
    call atoi  ; ax = num2
    ; now compute
    cmp dl, '+'
    je .add
    cmp dl, '-'
    je .sub
    cmp dl, '*'
    je .mul
    cmp dl, '/'
    je .div
    jmp .error
.add:
    add ax, bx
    jmp .print_result
.sub:
    sub bx, ax
    mov ax, bx
    jmp .print_result
.mul:
    mul bx
    jmp .print_result
.div:
    xchg ax, bx
    xor dx, dx
    div bx
    jmp .print_result
.print_result:
    call itoa
    call print_string
    call print_newline
    ret
.error:
    mov si, calc_error
    call print_string
    call print_newline
    ret

atoi:
    ; si points to string, return ax = number
    xor ax, ax
    xor bx, bx
.loop:
    lodsb
    cmp al, '0'
    jb .done
    cmp al, '9'
    ja .done
    sub al, '0'
    push ax
    mov ax, bx
    mov bx, 10
    mul bx
    mov bx, ax
    pop ax
    add bx, ax
    jmp .loop
.done:
    mov ax, bx
    ret

itoa:
    ; ax = number, print it
    ; simple for small numbers
    cmp ax, 10
    jb .single
    ; two digits
    mov bl, 10
    div bl
    push ax
    mov al, ah
    add al, '0'
    mov ah, 0x0e
    int 0x10
    pop ax
    mov al, al
    add al, '0'
    mov ah, 0x0e
    int 0x10
    ret
.single:
    add al, '0'
    mov ah, 0x0e
    int 0x10
    ret

msg db 'Welcome to QubitOS!', 0
prompt db 'QubitOS> ', 0
help_msg db 'Commands: help, echo <text>, halt, clear, time, draw, ls, create <file>, delete <file>, edit <file>, cat <file>, calc', 0
unknown_cmd db 'Unknown command', 0
not_found_msg db 'File not found', 0
deleted_msg db 'File deleted', 0
cmd_help db 'help', 0
cmd_echo db 'echo ', 0
cmd_halt db 'halt', 0
cmd_clear db 'clear', 0
cmd_time db 'time', 0
cmd_draw db 'draw', 0
cmd_ls db 'ls', 0
cmd_create db 'create ', 0
cmd_delete db 'delete ', 0
cmd_edit db 'edit ', 0
cmd_cat db 'cat ', 0
cmd_calc db 'calc', 0
fake_time db '12:00:00', 0
edit_prompt db 'Enter new content: ', 0
calc_prompt db 'Enter expression (e.g. 1 + 2): ', 0
calc_error db 'Invalid expression', 0
files times 10*256 db 0
file_count db 0
input_buffer times 256 db 0
