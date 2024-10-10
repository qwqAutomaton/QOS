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

; total mem: gdt(8) + code desc(8) + data desc(8) + video desc(8) + empty desc(8 * 60 = 480) = 512B

gdt_ptr dw GDT_LIM
        dq GDT_BASE

; additional mem for ards(20B): gdt_ptr(6) + ards_cnt(2, unsigned short) + ards(remaining 504 for 25 ARDS) = 512B.
ards_cnt dw 0
ards times 504 db 0
; _TMP_STR_BUF times 16 db "$"

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
    ; 检查内存
    mov ax, 0x0300
    mov bx, 0x0000
    int 0x10
    mov ax, str14_
    mov bp, ax
    mov ax, 0x1301
    mov bx, 0x000f
    mov cx, 0x1c
    int 0x10
    xor ebx, ebx
    mov edx, 0x534d4150
    mov di, ards
.check_mem:
    mov eax, 0x0000_e820
    mov ecx, 20
    int 0x15
    jc .check_mem_fail
    inc word [ards_cnt]
    add di, cx
    cmp ebx, 0
    jnz .check_mem
    jmp .check_mem_finished
.check_mem_fail:
    mov ax, 0x0300
    mov bx, 0x0000
    int 0x10
    mov ax, str15
    mov bp, ax
    mov ax, 0x1301
    mov bx, 0x000f
    mov cx, 0x20
    int 0x10
.check_mem_finished:
    mov ax, 0x0300
    mov bx, 0x0000
    int 0x10
    mov ax, str16
    mov bp, ax
    mov ax, 0x1301
    mov bx, 0x000f
    mov cx, 0x22
    int 0x10
    ; 打印总内存
    ; mov eax, [ards_cnt]
    ; call print_number
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

; protected mode, embark!
[bits 32]
pe_start:
    mov ax, SEL_DATA
    mov ds, ax
    mov es, ax
    mov esp, LOADER_ADDR
    mov ax, SEL_VDEO
    mov gs, ax
    mov dword [gs:0x640], 0x24f0251
    mov dword [gs:0x644], 0x25b0253
    mov dword [gs:0x648], 0x24c024b
    mov dword [gs:0x64c], 0x25d0220
    mov dword [gs:0x650], 0x220023a
    mov dword [gs:0x654], 0x2720250
    mov dword [gs:0x658], 0x274026f
    mov dword [gs:0x65c], 0x2630265
    mov dword [gs:0x660], 0x2650274
    mov dword [gs:0x664], 0x2200264
    mov dword [gs:0x668], 0x26f024d
    mov dword [gs:0x66c], 0x2650264
    mov dword [gs:0x670], 0x2610220
    mov dword [gs:0x674], 0x2740263
    mov dword [gs:0x678], 0x2760269
    mov dword [gs:0x67c], 0x2740261
    mov dword [gs:0x680], 0x2640265
    mov dword [gs:0x684], 0x22e

    jmp $

; ; print decimal number
; ; number: ax
; print_number:
;     mov di, _TMP_STR_BUF
;     add di, 15
;     mov byte [di], 48
;     ; ax = 0?
;     mov cx, 1
;     cmp ax, 0
;     mov bp, di
;     jnz .print_zero
;     mov cx, 10
; .decomp_loop:
;     div cx
;     add dx, 48
;     mov [di], dx
;     dec di
;     cmp ax, 0
;     jnz .decomp_loop
;     mov bp, _TMP_STR_BUF
;     mov cx, 16
;     cmp bp, di
;     jz .print_zero
; .count_loop:
;     inc bp
;     dec cx
;     cmp bp, di
;     jnz .count_loop
; .print_zero:
;     mov ax, 0x0300
;     mov bx, 0x0000
;     int 0x10
;     mov ax, 0x1301
;     mov bx, 0x000f
;     int 0x10
;     ret

    str11 db "QOS[KL ]: KL running.", 0x0d, 0x0a, "$"
    str12 db "QOS[KL ]: Enabling A20 Gate.", 0x0d, 0x0a, "$"
    str13 db "QOS[KL ]: Loading global descriptor table.", 0x0d, 0x0a, "$"
    str14 db "QOS[KL ]: Entering protected mode.", 0x0d, 0x0a, "$"
    str14_ db "QOS[KL ]: Checking memory.", 0x0d, 0x0a, "$"
    str15 db "QOS[KL ]: Memory check failed.", 0x0d, 0x0a, "$"
    str16 db "QOS[KL ]: Memory check finished.", 0x0d, 0x0a, "$"