; src/mbr.s
; 主引导记录
;*-----------------------*;
%include "boot.inc"
SECTION MBR vstart=0x7c00 ; 表示起始地址为 0x7c00
; 初始化/
    mov ax, cs ; 此时 cs 是 0x00，把它当零寄存器用用
    mov dx, ax
    mov es, ax
    mov ss, ax
    mov fs, ax ; 清空这些寄存器
    mov ax, 0xb800
    mov gs, ax ; 显存段地址
    mov sp, 0x7c00 ; 当前栈指针指向 0x7c00
    
    mov ax, 0x0600
    mov bx, 0x0700
    mov cx, 0x0000
    mov dx, 0x184f
    int 0x10
    mov ax, 0x0200
    mov bx, 0x0000
    mov dx, 0x0000
    int 0x10
    mov ax, str1
    mov bp, ax
    mov ax, 0x1301
    mov bx, 0x000f
    mov cx, 0x0018
    int 0x10
    mov ax, 0x0300
    mov bx, 0x0000
    int 0x10
    mov ax, str2
    mov bp, ax
    mov ax, 0x1301
    mov bx, 0x000f
    mov cx, 0x0017
    int 0x10

    mov eax, LOADER_SECT
    mov bx, LOADER_ADDR
    mov cx, 16
    ; 读取硬盘
    mov esi, eax
    mov di, cx
    ; 设置扇区数量
    mov dx, 0x1f2
    mov al, cl
    out dx, al
    mov eax, esi
    ; 设置 LBA 地址 0-23b
    mov dx, 0x1f3
    out dx, al
    mov cl, 8
    shr eax, cl
    mov dx, 0x1f4
    out dx, al
    shr eax, cl
    mov dx, 0x1f5
    out dx, al
    ; 设置 0x1f6 一堆东西
    shr eax, cl
    and al, 0x0f
    or al, 0xe0
    mov dx, 0x1f6
    out dx, al
    ; 设置 0x1f7 为读入（0x20）
    mov dx, 0x1f7
    mov al, 0x20
    out dx, al
.not_ready:
    nop
    in al, dx
    and al, 0x88
    cmp al, 0x08
    jnz .not_ready

    ; 准备好读入了
    mov ax, di
    mov dx, DISK_SECT_DIV2
    mul dx
    mov cx, ax
    mov dx, 0x1f0
.read_disk:
    in ax, dx
    mov [bx], ax
    add bx, 2
    loop .read_disk

    mov ax, 0x0300
    mov bx, 0x0000
    int 0x10
    mov ax, str4
    mov bp, ax
    mov ax, 0x1301
    mov bx, 0x000f
    mov cx, 0x0019
    int 0x10
    mov ax, 0x0300
    mov bx, 0x0000
    int 0x10
    mov ax, str3
    mov bp, ax
    mov ax, 0x1301
    mov bx, 0x000f
    mov cx, 0x0018
    int 0x10
    jmp LOADER_ADDR
    str1 db "QOS[MBR]: MBR running.", 0x0d, 0x0a, "$"
    str2 db "QOS[MBR]: Loading KL.", 0x0d, 0x0a, "$"
    str3 db "QOS[MBR]: Starting KL.", 0x0d, 0x0a, "$"
    str4 db "QOS[MBR]: MBR finished.", 0x0d, 0x0a, "$"
; 把剩下的填充为 0
    times 510 - ($ - $$) db 0 ; $$ 表示当前节的开始位置，那么 $-$$ 就是已经写了多少
    db 0x55, 0xaa ; 填充最后两个字节。注意端序问题

