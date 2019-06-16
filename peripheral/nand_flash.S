/*
* nand_flash 接口
*/

.text
.global nand_flash_init
.global nand_flash_attr //输入参数:r0指向连续5个数据的指针。无输出参数
.global nand_flash_maker //输入参数:r0指向连续5个数据的指针。输出参数:r0
.global nand_flash_device //输入参数:r0指向连续5个数据的指针。输出参数:r0
.global nand_flash_page_size //输入参数:r0指向连续5个数据的指针。输出参数:r0
.global nand_flash_block_size //输入参数:r0指向连续5个数据的指针。输出参数:r0
.global nand_flash_read //输入参数:r0表示要读取的地址，r1表示要读取的字节大小，r2表示nand_flash页大小，r3指定返回数据的起始地址。无输出参数
.global nand_flash_erase//输入参数:r0表示要檫除的地址，r1表示nand_flash页大小。无输出参数
.global nand_flash_write//输入参数:r0表示要写入的地址，r1表示写入数据的首地址，r2表示要写入的字节大小，r3表示nand_flash页大小。无输出参数
//NFCONF 0x4E000000
//NFCONT 0x4E000004
//NFCMMD 0x4E000008
//NFADDR 0x4E00000C
//NFDATA 0x4E000010
//NFSTAT 0x4E000020
nand_flash_delay:
	push {r0, lr}
	mov r0, #0x0
delay_loop:
	add r0, r0, #0x1
	cmp r0, #0x10
	bne delay_loop
	pop {r0, pc}
nand_flash_enable:
	push {r0-r1, lr}
	ldr r1, =#0x4E000004
	ldr r0, [r1]
	bic r0, r0, #(1<<1)
	str r0, [r1]
	pop {r0-r1, pc}

nand_flash_disable:
	push {r0-r1, lr}
	ldr r1, =#0x4E000004
	ldr r0, [r1]
	orr r0, r0, #(1<<1)
	str r0, [r1]
	pop {r0-r1, pc}
nand_flash_cmd:        //输入参数:r0的低8位是命令位，其余保留。无输出参数
	push {r0-r1, lr}
	ldr r1, =#0x4E000008
	strb r0, [r1]
	bl nand_flash_delay
	pop {r0-r1, pc}
nand_flash_addr_byte:  //输入参数:r0的低8位是地址位，其余保留。无输出参数
	push {r0-r1, lr}
	ldr r1, =#0x4E00000C
	strb r0, [r1]
	bl nand_flash_delay
	pop {r0-r1, pc}
nand_flash_read_byte:  //无输入参数。输出参数是r0的低8位(数据位)，其余保留
	push {r1, lr}
	ldr r1, =#0x4E000010
	ldrb r0, [r1]
	pop {r1, pc}
nand_flash_write_byte: //输入参数:r0的低8位(数据位)，其余保留。无输出参数
	push {r0-r1, lr}
	ldr r1, =#0x4E000010
	strb r0, [r1]
	pop {r0-r1, pc}
nand_flash_wait_ready:
	push {r0-r1, lr}
	ldr r1, =#0x4E000020
wait_ready_loop:
	ldr r0, [r1]
	and r0, r0, #0x1
	cmp r0, #0x0
	beq wait_ready_loop
	pop {r0-r1, pc}

nand_flash_init:
	push {r0-r1, lr}
	/*设置NAND FLASH的时序*/
	ldr r1, =#0x4E000000
	ldr r0, =#((0<<12) | (1<<8) | (0<<4))
	str r0, [r1]
	/*使能NAND FLASH控制器,初始化ECC，禁止片选*/
	ldr r1, =#0x4E000004
	ldr r0, =#((1<<4) | (1<<1) | (1<<0))
	str r0, [r1]
	pop {r0-r1, pc}
nand_flash_attr:
	push {r0-r2, lr}
	bl nand_flash_enable

	mov r1, r0
	ldr r0, =#0x90
	bl nand_flash_cmd
	ldr r0, =#0x0
	bl nand_flash_addr_byte

	ldr r2, =#0x0
attr_loop:
	add r2, r2, #0x1
	bl nand_flash_read_byte
	str r0, [r1]
	add r1, r1, #0x4
	cmp r2, #0x5
	bne attr_loop

	bl nand_flash_disable
	pop {r0-r2, pc}
nand_flash_maker: //输入参数:r0指向连续5个数据的指针。输出参数:r0
	push {r1, lr}
	mov r1, r0
	ldr r0, [r1]
	pop {r1, pc}
nand_flash_device: //输入参数:r0指向连续5个数据的指针。输出参数:r0
	push {r1, lr}
	mov r1, r0
	add r1, r1, #0x4
	ldr r0, [r1]
	pop {r1, pc}
nand_flash_page_size: //输入参数:r0指向连续5个数据的指针。输出参数:r0
	push {r1, lr}
	add r0, r0, #12
	ldr r1, [r0]

	and r1, r1, #0x3
	ldr r0, =#1024
	mov r0, r0, LSL r1
	pop {r1, pc}
nand_flash_block_size: //输入参数:r0指向连续5个数据的指针。输出参数:r0
	push {r1, lr}
	add r0, r0, #12
	ldr r1, [r0]

	mov r1, r1, LSR #0x4
	and r1, r1, #0x3
	ldr r0, =#(1024<<6)
	mov r0, r0, LSL r1
	pop {r1, pc}
read_data:
	.string "0000 0000"
.align 4
nand_flash_read: //输入参数:r0表示要读取的地址，r1表示要读取的字节大小，r2表示nand_flash页大小，r3指定返回数据的起始地址。无输出参数
	push {r0-r7, lr}
	mov r4, r0
	mov r5, r1
	mov r6, r2
	mov r7, r3

	mov r1, r2
	ldr r2, =read_data
	add r3, r2, #0x4
	bl utils_operator_divid
	ldr r2, [r2]  //页地址(行地址)
	ldr r3, [r3]  //(列地址)
	//片选
	bl nand_flash_enable
read_loop:
	/* 发出00h命令 */
	ldr r0, =#0x0
	bl nand_flash_cmd
	//col地址
	and r0, r3, #0xff
	bl nand_flash_addr_byte
	mov r1, r3, LSR #0x8
	and r0, r1, #0xff
	bl nand_flash_addr_byte
	//row/页地址
	and r0, r2, #0xff
	bl nand_flash_addr_byte
	mov r1, r2, LSR #0x8
	and r0, r1, #0xff
	bl nand_flash_addr_byte
	mov r1, r2, LSR #0x10
	and r0, r1, #0xff
	bl nand_flash_addr_byte
	/* 发出30h命令 */
	ldr r0, =#0x30
	bl nand_flash_cmd

	bl nand_flash_wait_ready
read_len_loop:
	cmp r5, #0x0
	beq read_return
	cmp r3, r6
	bcc read_next_col
	add r2, r2, #0x1
	mov r3, #0x0
	b read_loop
read_next_col:
	bl nand_flash_read_byte
	strb r0, [r7]
	add r3, r3, #0x1
	add r7, r7, #0x1
	sub r5, r5, #0x1
	bl read_len_loop
read_return:
	//关闭片选
	bl nand_flash_disable
	pop {r0-r7, pc}
erase_data:
        .string "0000 0000"
.align 4
nand_flash_erase://输入参数:r0表示要檫除的地址，r1表示nand_flash页大小。无输出参数
	push {r0-r3, lr}
	ldr r2, =erase_data
	add r3, r2, #0x4
	bl utils_operator_divid
	ldr r2, [r2] //页地址(行地址)
	//片选
	bl nand_flash_enable
	/* 发出60h命令 */
	ldr r0, =#0x60
	bl nand_flash_cmd
	//row/页地址
	and r0, r2, #0xff
	bl nand_flash_addr_byte
	mov r1, r2, LSR #0x8
	and r0, r1, #0xff
	bl nand_flash_addr_byte
	mov r1, r2, LSR #0x10
	and r0, r1, #0xff
	bl nand_flash_addr_byte
	/* 发出d0h命令 */
	ldr r0, =#0xd0
	bl nand_flash_cmd
	bl nand_flash_wait_ready
	//关闭片选
	bl nand_flash_disable
	pop {r0-r3, pc}
write_data:
        .string "0000 0000"
.align 4
nand_flash_write://输入参数:r0表示要写入的地址，r1表示写入数据的首地址，r2表示要写入的字节大小，r3表示nand_flash页大小。无输出参数
	push {r0-r7, lr}
	mov r4, r0
	mov r5, r1
	mov r6, r2
	mov r7, r3

	mov r1, r3
	ldr r2, =write_data
	add r3, r2, #0x4
	bl utils_operator_divid
	ldr r2, [r2]  //页地址(行地址)
	ldr r3, [r3]  //(列地址)
	//片选
	bl nand_flash_enable
write_loop:
	/* 发出80h命令 */
	ldr r0, =#0x80
	bl nand_flash_cmd
	//col地址
	and r0, r3, #0xff
	bl nand_flash_addr_byte
	mov r1, r3, LSR #0x8
	and r0, r1, #0xff
	bl nand_flash_addr_byte
	//row/页地址
	and r0, r2, #0xff
	bl nand_flash_addr_byte
	mov r1, r2, LSR #0x8
	and r0, r1, #0xff
	bl nand_flash_addr_byte
	mov r1, r2, LSR #0x10
	and r0, r1, #0xff
	bl nand_flash_addr_byte

	//写入数据
write_len_loop:
	cmp r6, #0x0
	beq write_return
	cmp r3, r7
	bcc write_next_col
	add r2, r2, #0x1
	mov r3, #0x0
	/* 发出10h命令 */
	ldr r0, =#0x10
	bl nand_flash_cmd
	bl nand_flash_wait_ready
	b write_loop
write_next_col:
	ldrb r0, [r5]
	bl nand_flash_write_byte
	add r3, r3, #0x1
	add r5, r5, #0x1
	sub r6, r6, #0x1
	bl write_len_loop
write_return:
	/* 发出10h命令 */
	ldr r0, =#0x10
	bl nand_flash_cmd
	bl nand_flash_wait_ready
	//关闭片选
	bl nand_flash_disable
	pop {r0-r7, pc}
