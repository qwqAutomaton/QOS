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

    ; copy kernel
    mov dword [gs:0x6e0], 0x74f0751
    mov dword [gs:0x6e4], 0x7200753
    mov dword [gs:0x6e8], 0x74b075b
    mov dword [gs:0x6ec], 0x720074c
    mov dword [gs:0x6f0], 0x73a075d
    mov dword [gs:0x6f4], 0x7430720
    mov dword [gs:0x6f8], 0x770076f
    mov dword [gs:0x6fc], 0x7690779
    mov dword [gs:0x700], 0x767076e
    mov dword [gs:0x704], 0x74b0720
    mov dword [gs:0x708], 0x7720765
    mov dword [gs:0x70c], 0x765076e
    mov dword [gs:0x710], 0x720076c
    mov dword [gs:0x714], 0x74c0745
    mov dword [gs:0x718], 0x7200746
    mov dword [gs:0x71c], 0x7690766
    mov dword [gs:0x720], 0x765076c
    mov dword [gs:0x724], 0x72e

    mov eax, KER_SEC
    mov ebx, KER_ADDR
    mov ecx, KER_SEC_CNT
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
    mov [ebx], ax
    add ebx, 2
    loop .read_disk


    ; page table settings
    mov dword [gs:0x780], 0x74f0751
    mov dword [gs:0x784], 0x7200753
    mov dword [gs:0x788], 0x74b075b
    mov dword [gs:0x78c], 0x720074c
    mov dword [gs:0x790], 0x73a075d
    mov dword [gs:0x794], 0x74b0720
    mov dword [gs:0x798], 0x7720765
    mov dword [gs:0x79c], 0x765076e
    mov dword [gs:0x7a0], 0x720076c
    mov dword [gs:0x7a4], 0x74c0745
    mov dword [gs:0x7a8], 0x7200746
    mov dword [gs:0x7ac], 0x76f0763
    mov dword [gs:0x7b0], 0x7690770
    mov dword [gs:0x7b4], 0x7640765
    mov dword [gs:0x7b8], 0x720072e
    mov dword [gs:0x7bc], 0x7720743
    mov dword [gs:0x7c0], 0x7610765
    mov dword [gs:0x7c4], 0x7690774
    mov dword [gs:0x7c8], 0x767076e
    mov dword [gs:0x7cc], 0x7700720
    mov dword [gs:0x7d0], 0x7670761
    mov dword [gs:0x7d4], 0x7200765
    mov dword [gs:0x7d8], 0x7610774
    mov dword [gs:0x7dc], 0x76c0762
    mov dword [gs:0x7e0], 0x7730765
    mov dword [gs:0x7e4], 0x000072e


.clear_pdt_space: ; reserve space for pdt
    mov ecx, 4096 ; 4K items
    mov esi, 0
.clear_pdt_space_loop:
    mov byte [PDT_ADDR + esi], 0
    inc esi
    loop .clear_pdt_space_loop
.insert_pde: ; insert page directory entries.
    ; first PDE
    mov eax, PDT_ADDR
    add eax, 0x1000
    mov ebx, eax
    or eax, PGE_USER | PGE_RWOK | PGE_P_OK
    ; put it into PDT
    mov [PDT_ADDR + 0x0000], eax
    mov [PDT_ADDR + 0x0c00], eax
    ; then virtual memory 0x0000_0000 and 0xc000_0000 refers the the same physical memory
    ; the last entry should be pdt itself
    sub eax, 0x1000
    mov [PDT_ADDR + 4092], eax
.insert_pte: ; insert first page table
; virtual addr.: 0x000_00000 ~ 0x000_fffff and 0xc00_00000 ~ 0xc00_fffff
; physical addr.: 0x000_00000 ~ 0x000_fffff
    mov ecx, 256 ; 1 pte for 1M mem, 4K per page -> 256 entries
    mov esi, 0 ; bias
    mov edx, PGE_USER | PGE_RWOK | PGE_P_OK ; control bits
.insert_pte_loop:
    mov [ebx + esi * 4], edx
    inc esi
    add edx, 4096 ; += 4K
    loop .insert_pte_loop
.create_kernel_pde: ; create other pde's reserved for kernel
    mov eax, PDT_ADDR
    add eax, 0x2000 ; 2nd page table, following the 1st
    or eax, PGE_USER | PGE_RWOK | PGE_P_OK ; ctrl bits
    mov esi, 769
    mov ecx, 254 ; 1024 - 2 (PDT, first PT) - 768
.create_kernel_pde_loop:
    mov [PDT_ADDR + esi * 4], eax
    inc esi
    add eax, 0x1000 ; next table
    loop .create_kernel_pde_loop

    mov dword [gs:0x820], 0x74f0751
    mov dword [gs:0x824], 0x7200753
    mov dword [gs:0x828], 0x74b075b
    mov dword [gs:0x82c], 0x720074c
    mov dword [gs:0x830], 0x73a075d
    mov dword [gs:0x834], 0x7500720
    mov dword [gs:0x838], 0x7670761
    mov dword [gs:0x83c], 0x7200765
    mov dword [gs:0x840], 0x7610774
    mov dword [gs:0x844], 0x76c0762
    mov dword [gs:0x848], 0x7730765
    mov dword [gs:0x84c], 0x7630720
    mov dword [gs:0x850], 0x7650772
    mov dword [gs:0x854], 0x7740761
    mov dword [gs:0x858], 0x7640765
    mov dword [gs:0x85c], 0x720072e
    mov dword [gs:0x860], 0x7650752
    mov dword [gs:0x864], 0x7720766
    mov dword [gs:0x868], 0x7730765
    mov dword [gs:0x86c], 0x7690768
    mov dword [gs:0x870], 0x767076e
    mov dword [gs:0x874], 0x7470720
    mov dword [gs:0x878], 0x7540744
    mov dword [gs:0x87c], 0x72e


    sgdt [gdt_ptr]
    mov ebx, [gdt_ptr + 2]
    or dword [ebx + 0x18 + 4], 0xc000_0000
    add dword [gdt_ptr + 2], 0xc000_0000
    add esp, 0xc000_0000

    mov eax, PDT_ADDR
    mov cr3, eax

    mov eax, cr0
    or eax, 0x8000_0000
    mov cr0, eax

    lgdt [gdt_ptr]

    mov dword [gs:0x8c0], 0x74f0751
    mov dword [gs:0x8c4], 0x7200753
    mov dword [gs:0x8c8], 0x74b075b
    mov dword [gs:0x8cc], 0x720074c
    mov dword [gs:0x8d0], 0x73a075d
    mov dword [gs:0x8d4], 0x7470720
    mov dword [gs:0x8d8], 0x7540744
    mov dword [gs:0x8dc], 0x7720720
    mov dword [gs:0x8e0], 0x7660765
    mov dword [gs:0x8e4], 0x7650772
    mov dword [gs:0x8e8], 0x7680773
    mov dword [gs:0x8ec], 0x7640765
    mov dword [gs:0x8f0], 0x720072e
    mov dword [gs:0x8f4], 0x76f074c
    mov dword [gs:0x8f8], 0x7640761
    mov dword [gs:0x8fc], 0x76e0769
    mov dword [gs:0x900], 0x7200767
    mov dword [gs:0x904], 0x765076b
    mov dword [gs:0x908], 0x76e0772
    mov dword [gs:0x90c], 0x76c0765
    mov dword [gs:0x910], 0x72e

    ; refresh assembly line
    ; just in case >w<
    jmp SEL_CODE:load_kernel
load_kernel:
    mov dword [gs:0x960], 0x74f0751
    mov dword [gs:0x964], 0x7200753
    mov dword [gs:0x968], 0x74b075b
    mov dword [gs:0x96c], 0x720074c
    mov dword [gs:0x970], 0x73a075d
    mov dword [gs:0x974], 0x7470720
    mov dword [gs:0x978], 0x720074f
    mov dword [gs:0x97c], 0x745074c
    mov dword [gs:0x980], 0x7530754
    mov dword [gs:0x984], 0x7460720
    mov dword [gs:0x988], 0x7430755
    mov dword [gs:0x98c], 0x749074b
    mov dword [gs:0x990], 0x747074e
    mov dword [gs:0x994], 0x7470720
    mov dword [gs:0x998], 0x72e074f
    mov dword [gs:0x99c], 0x73c073e
    ; copy kernel to ENTRY
    xor eax, eax
    xor ebx, ebx ; ebx: header addr
    xor ecx, ecx ; cx = program header count
    xor edx, edx ; dx = e_phentsize

    mov dx, [KER_ADDR + 42] ; e_phentsize
    mov ebx, [KER_ADDR + 28] ; e_phoff
    add ebx, KER_ADDR ; absolute addr
    mov cx, [KER_ADDR + 44] ; e_phnum

.load_kernel_segment:
    cmp byte [ebx + 0], 0 ; p_type == 0 => unused program
    je .program_type_null
    ; memcpy(dst, src, len)
    mov edi, [ebx + 16] ; dst
    mov eax, [ebx + 4] ; p_offset
    add eax, KER_ADDR ; segment addr
    mov esi, eax ; src
    mov eax, ecx
    mov ecx, [ebx + 8] ; cnt
.copy_loop:
    movsb
    loop .copy_loop
    mov ecx, eax
.program_type_null:
    add ebx, edx ; jmp to next descriptor
    loop .load_kernel_segment
    
    mov dword [gs:0xa00], 0x74f0751
    mov dword [gs:0xa04], 0x7200753
    mov dword [gs:0xa08], 0x74b075b
    mov dword [gs:0xa0c], 0x720074c
    mov dword [gs:0xa10], 0x73a075d
    mov dword [gs:0xa14], 0x74b0720
    mov dword [gs:0xa18], 0x7720765
    mov dword [gs:0xa1c], 0x765076e
    mov dword [gs:0xa20], 0x720076c
    mov dword [gs:0xa24], 0x76f0763
    mov dword [gs:0xa28], 0x7690770
    mov dword [gs:0xa2c], 0x7640765
    mov dword [gs:0xa30], 0x720072e
    mov dword [gs:0xa34], 0x76e0745
    mov dword [gs:0xa38], 0x7650774
    mov dword [gs:0xa3c], 0x7690772
    mov dword [gs:0xa40], 0x767076e
    mov dword [gs:0xa44], 0x76b0720
    mov dword [gs:0xa48], 0x7720765
    mov dword [gs:0xa4c], 0x765076e
    mov dword [gs:0xa50], 0x72e076c
    mov esp, 0xc009f000
    jmp KER_ENTRY

    str11 db "QOS[KL ]: KL running.", 0x0d, 0x0a, "$"
    str12 db "QOS[KL ]: Enabling A20 Gate.", 0x0d, 0x0a, "$"
    str13 db "QOS[KL ]: Loading global descriptor table.", 0x0d, 0x0a, "$"
    str14 db "QOS[KL ]: Entering protected mode.", 0x0d, 0x0a, "$"
    str14_ db "QOS[KL ]: Checking memory.", 0x0d, 0x0a, "$"
    str15 db "QOS[KL ]: Memory check failed.", 0x0d, 0x0a, "$"
    str16 db "QOS[KL ]: Memory check finished.", 0x0d, 0x0a, "$"




;memcpyy:
; 	pushl	%ebp
; 	movl	%esp, %ebp
; 	cmpl	$0, 16(%ebp)
; 	je	.L4
; .L2:
; 	subl	$1, 16(%ebp)
; 	movl	12(%ebp), %edx
; 	movl	16(%ebp), %eax
; 	addl	%edx, %eax
; 	movl	8(%ebp), %ecx
; 	movl	16(%ebp), %edx
; 	addl	%ecx, %edx
; 	movzbl	(%eax), %eax
; 	movb	%al, (%edx)
; 	cmpl	$0, 16(%ebp)
; 	jne	.L2
; 	jmp	.L1
; .L4:
; 	nop
; .L1:
; 	popl	%ebp
; 	ret

