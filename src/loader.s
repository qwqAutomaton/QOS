%include "boot.inc"
SECTION LOADER vstart=LOADER_ADDR
    jmp loader_start
GDT_BASE: ; 空描述符，防越界; 也是 GDT 基址
    dq 0 ; dq: define quad-word, 1 word = 2 byte
GDT_CODE_DESC: ; 代码段描述符
    dd 0x0000ffff ; 代码段的基址低 8 位为 0x0000，界限低 8 位为 0x02fff
    dd GDT_hi_CODE ; 代码段高 32 位
GDT_DATA_DESC: ; 数据段描述符
    dd 0x0000ffff
    dd GDT_hi_DATA
GDT_DATA_VDEO: ; 视频段描述符
    dd 0x80000007 ; 视频端大小 0xbffff-0xb8000 +1 = 0x8000, 单位为 4K 则界限为 0x8000 / 4K - 1 = 0x07（注意要减 1）
    dd GDT_hi_VDEO
GDT_SIZ equ $ - GDT_BASE ; 计算当前 GDT 大小
GDT_LIM equ GDT_SIZ - 1  ; GDT 界限
times 60 dq 0 ; 填充 60 个空描述符

gdt_ptr dw GDT_LIM
        dq GDT_BASE
;--- selector ---;
; 代码段的选择子
SEL_CODE equ (0x01 << 3) + SEL_TI_G + SEL_RPL0
; 数据段的选择子
SEL_DATA equ (0x02 << 3) + SEL_TI_G + SEL_RPL0
; 视频段的选择子
SEL_VDEO equ (0x03 << 3) + SEL_TI_G + SEL_RPL0
;--- selector ---;
loader_start:
    mov ax, 0x0300 ; 查光标位置，0x03
    mov bx, 0x0000
    int 0x10
    mov ax, str11
    mov bp, ax
    mov ax, 0x1301 ; 输出字符串
    mov bx, 0x000f
    mov cx, 0x0017
    int 0x10
    mov ax, 0x0300
    mov bx, 0x0000
    int 0x10
    mov ax, str12
    mov bp, ax
    mov ax, 0x1301
    mov bx, 0x000f
    mov cx, 0x001e
    int 0x10
    ; 开启 A20 地址线
    mov dx, 0x92
    in al, dx ; 读入原来的值
    or al, 0x02 ; 第 1 位设为 1
    out dx, al ; 写入
    ; 加载 GDT，设置 GDTR
    mov ax, 0x0300
    mov bx, 0x0000
    int 0x10
    mov ax, str13
    mov bp, ax
    mov ax, 0x1301
    mov bx, 0x000f
    mov cx, 0x2c
    int 0x10
    lgdt [gdt_ptr]
    ; 设置 CR0 寄存器，进入保护模式
    mov ax, 0x0300
    mov bx, 0x0000
    int 0x10
    mov ax, str14
    mov bp, ax
    mov ax, 0x1301
    mov bx, 0x000f
    mov cx, 0x24
    int 0x10
    mov eax, cr0
    or eax, 0x01
    mov cr0, eax
    jmp dword SEL_CODE:pe_start

[bits 32]
pe_start:
    mov ax, SEL_DATA
    mov ds, ax
    mov es, ax
    mov esp, LOADER_ADDR
    mov ax, SEL_VDEO
    mov gs, ax
    mov dword [gs:0x500], 0x24f0251
    mov dword [gs:0x504], 0x25b0253
    mov dword [gs:0x508], 0x24c024b
    mov dword [gs:0x50c], 0x25d0220
    mov dword [gs:0x510], 0x220023a
    mov dword [gs:0x514], 0x2630241
    mov dword [gs:0x518], 0x2690274
    mov dword [gs:0x51c], 0x2610276
    mov dword [gs:0x520], 0x2650274
    mov dword [gs:0x524], 0x2200264
    mov dword [gs:0x528], 0x2720250
    mov dword [gs:0x52c], 0x274026f
    mov dword [gs:0x530], 0x2630265
    mov dword [gs:0x534], 0x2650274
    mov dword [gs:0x538], 0x2200264
    mov dword [gs:0x53c], 0x26e0245
    mov dword [gs:0x540], 0x2690276
    mov dword [gs:0x544], 0x26f0272
    mov dword [gs:0x548], 0x26d026e
    mov dword [gs:0x54c], 0x26e0265
    mov dword [gs:0x550], 0x22e0274
    jmp $


    str11 db "QOS[KL ]: KL running.", 0x0d, 0x0a, "$"
    str12 db "QOS[KL ]: Enabling A20 Gate.", 0x0d, 0x0a, "$"
    str13 db "QOS[KL ]: Loading global descriptor table.", 0x0d, 0x0a, "$"
    str14 db "QOS[KL ]: Entering protected mode.", 0x0d, 0x0a, "$"