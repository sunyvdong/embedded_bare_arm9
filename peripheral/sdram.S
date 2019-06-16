/*
* s3c2440 sdram初始化
* 配置后可操作该范围0x3000_0000-0x3800_0000的内存地址
* 又因为该sdram只有64MB，所以可访问的范围是0x3000_0000-0X33FF_FFFF
*/

//BWSCON 0x48000000
//BANKCON6 0x4800001C
//BANKCON7 0x48000020
//REFRESH 0x48000024
//BANKSIZE 0x48000028
//MRSRB6 0x4800002C
//MRSRB7 0x48000030
.text
.global sdram_init //输入参数：无，输出参数：无
sdram_init:
	push {r4-r6, lr}
	ldr r5, =#0x48000000
	ldr r4, [r5]
	bic r4, r4, #0xff000000
	orr r4, r4, #0x22000000
	str r4, [r5]
	
	ldr r5, =#0x4800001C
	ldr r6, =#0x48000020
	ldr r4, =#0x18001
	str r4, [r5]
	str r4, [r6]

	ldr r5, =#0x48000024
	ldr r4, =#0x8404f5
	str r4, [r5]
	
	ldr r5, =#0x48000028
	ldr r4, =#0xb1
	str r4, [r5]
	
	ldr r5, =#0x4800002C
	ldr r6, =#0x48000030
	ldr r4, =#0x20
	str r4, [r5]
	str r4, [r6]
	
	pop {r4-r6, pc}
