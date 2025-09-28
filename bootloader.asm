[bits 16]
[org 0x7c00]

start:
    ; Set up segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    ; Load kernel from disk
    mov ax, 0x1000
    mov es, ax
    mov bx, 0x0000
    mov ah, 0x02        ; BIOS read sector
    mov al, 4           ; Number of sectors to read
    mov ch, 0           ; Cylinder
    mov cl, 2           ; Sector (kernel starts at sector 2)
    mov dh, 0           ; Head
    mov dl, 0           ; Drive (floppy)
    int 0x13
    jc load_error

    ; Jump to kernel
    jmp 0x1000:0x0000

load_error:
    ; Simple error handling: print 'E' and halt
    mov ah, 0x0e
    mov al, 'E'
    int 0x10
    hlt

; Pad to 512 bytes and add boot signature
times 510 - ($ - $$) db 0
dw 0xaa55
