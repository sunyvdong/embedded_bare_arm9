/*
* 串口uart 统一使用8bit数据位,没有校验位,1bit停止位
* GPH2、3、4、5、6、7分别是TXD0、RXD0、TXD1、RXD1、TXD2、RXD2
* 默认使用PCLK时钟源
* 波特率公式 UBRDIVn = (int)( UART clock / ( buad rate x 16) ) –1
*/

.text
.global uart_init  
/*输入参数:
* r0 表示使用哪个uart串口共有三个0、1、2。
* r1 UBRDIVn
* 默认参数一般设置为 r0:0 r1:26
*/
.global uart_putc  
/*
* 输入参数:
* r0 表示使用哪个uart串口共有三个0、1、2。
* r1 要发送的字节
*/
.global uart_getc  
/*
* 输入参数:
* r0 表示使用哪个uart串口共有三个0、1、2。
* 输出参数:
* r0 获取的字节
*/
//GPHCON 0x56000070
//GPHDAT 0x56000074
//GPHUP 0x56000078

//ULCON0 0x50000000
//ULCON1 0x50004000 设置串口传输格式
//ULCON2 0x50008000
//UCON0 0x50000004
//UCON1 0x50004004 设置时钟源
//UCON2 0x50008004
//UBRDIV0 0x50000028
//UBRDIV1 0x50004028  设置UBRDIVn
//UBRDIV2 0x50008028

//UTRSTAT0 0x50000010
//UTRSTAT1 0x50004010
//UTRSTAT2 0x50008010
//UTXH0 0x50000020
//UTXH1 0x50004020
//UTXH2 0x50008020
//URXH0 0x50000024
//URXH1 0x50004024
//URXH2 0x50008024

uart_init:
	push {r2-r6, lr}
        //设置引脚用于串口
	ldr r5, =#0x56000070
	ldr r6, [r5]
	mov r3, #0xf0
	mov r4, #0xa0
	mov r2, r0, LSL #0x2
	mov r3, r3, LSL r2	
	mov r4, r4, LSL r2
	bic r6, r6, r3
	orr r6, r6, r4
	str r6, [r5]
	//设置引脚的内部上拉
	ldr r5, =#0x56000078
	ldr r6, [r5]
	mov r4, #0xc
	mov r3, r0, LSL #0x1
	mov r4, r4, LSL r3
	bic r6, r6, r4
	str r6, [r5]
	//设置串口格式,时钟源以及UBRDIV
	ldr r5, =#0x50000000
	ldr r4, =#0x50000004
	ldr r3, =#0x50000028
	mov r6, r0, LSL #0x14
	add r5, r5, r6
	add r4, r4, r6
	add r3, r3, r6
	//串口格式
	mov r6, #0x3
	str r6, [r5]
	//时钟源
	mov r6, #0x5
	str r6, [r4]
	//UBRDIV
	str r1, [r3]
	pop {r2-r6, pc}

uart_putc:
	push {r4-r6, lr}
	ldr r5, =#0x50000010
	ldr r4, =#0x50000020
	mov r6, r0, LSL #0x14
	add r5, r5, r6
	add r4, r4, r6
putc_loop:
	ldr r6, [r5]
	and r6, r6, #0x2
	cmp r6, #0x0
	beq putc_loop
	strb r1, [r4]
	pop {r4-r6, pc}

uart_getc:
	push {r4-r6, lr}
	ldr r5, =#0x50000010
	ldr r4, =#0x50000024
	mov r6, r0, LSL #0x14
	add r5, r5, r6
	add r4, r4, r6
getc_loop:
	ldr r6, [r5]
	and r6, r6, #0x1
	cmp r6, #0x0
	beq getc_loop
	ldrb r0, [r4]
	pop {r4-r6, pc}

