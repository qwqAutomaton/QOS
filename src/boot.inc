LOADER_ADDR equ 0x8000
LOADER_SECT equ 0x01
DISK_SECT_DIV2 equ 0x0100

;------- GDT constant -------;
; GDT 中段界限单位为 4K
GDT_hi_G_4K equ 00000000_10000000_00000000_00000000b
; 有效地址，操作数 32 位
GDT_hi_D_32 equ 00000000_01000000_00000000_00000000b
GDT_hi_L_32 equ 00000000_00000000_00000000_00000000b
; 保留位 ; 代码段 32 位
GDT_hi_AVAL equ 00000000_00000000_00000000_00000000b
; 存在位
GDT_hi_P_OK equ 00000000_00000000_10000000_00000000b
; 特权级 0
GDT_hi_DPL0 equ 00000000_00000000_00000000_00000000b
; 特权级 1
GDT_hi_DPL1 equ 00000000_00000000_00100000_00000000b
; 特权级 2
GDT_hi_DPL2 equ 00000000_00000000_01000000_00000000b
; 特权级 3
GDT_hi_DPL3 equ 00000000_00000000_01100000_00000000b
; 是数据段（不是系统段）
GDT_hi_SGDT equ 00000000_00000000_00010000_00000000b
; 是代码段（不是系统段）
GDT_hi_SGCD equ 00000000_00000000_00010000_00000000b
; 是系统段
GDT_hi_SGSY equ 00000000_00000000_00000000_00000000b
; 代码段可执行，不可读，非一致性，已访问位 a 清 0 (x=1, r=0, c=0, a=0)
GDT_hi_TPCD equ 00000000_00000000_00001000_00000000b
; 数据段不可执行，向上扩展，可写，已访问位 a 清 0 (x=0, e=0, w=1, a=0)
GDT_hi_TPDT equ 00000000_00000000_00000010_00000000b
; 内核代码段描述符高 32 位
GDT_hi_CODE equ 00000000_1_1_0_0_1111_1_00_1_1000_00000000b
; 内核数据段描述符高 32 位
GDT_hi_DATA equ 00000000_1_1_0_0_1111_1_00_1_0010_00000000b
; 内核视频段描述符高 32 位。段基址中 8 位: 0x0b = 00001011b
GDT_hi_VDEO equ 00000000_1_1_0_0_0000_1_00_1_0010_00001011b
;------- GDT constant -------;

;---- Selector  constant ----;
SEL_RPL0 equ 00b  ; 请求特权级 0
SEL_RPL1 equ 01b  ; 请求特权级 1
SEL_RPL2 equ 10b  ; 请求特权级 2
SEL_RPL3 equ 11b  ; 请求特权级 3
SEL_TI_G equ 000b ; 表指示器：GDT
SEL_TI_L equ 100b ; 表指示器：LDT
;---- Selector  constant ----;

;------- Page constant ------;
PDT_ADDR equ 0x100000 ; 页目录表地址

PGE_P_OK equ 1b   ; 存在内存中
PGE_RWOK equ 00b  ; 可读写
PGE_RWNO equ 10b  ; 不可读写
PGE_USER equ 100b ; 用户级
PGE_SPVS equ 000b ; 特权级
;------- Page constant ------;

;------- Kernel ------;
KER_SEC equ 20
KER_SEC_CNT equ 32
KER_ADDR equ 0x70000
KER_ENTRY equ 0xc0001500
;------- Kernel ------;
