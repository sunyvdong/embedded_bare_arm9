/*
*设置时钟FCLK,HCLK,PCLK
*/

.text
.global clock_mpll_init  
//.global clock_upll_init  

/*
* 输入参数
* r0 MDIV[19:12]
* r1 PDIV[9:4]
* r2 SDIV[1:0]
* r3 [~:2]FCLK:HCLK 可取的值为1,2,3,4,6,8 [1:0]HCLK:PCLK 可取的值为1,2
*/
//默认参数一般设置为r0:0x5c r1:0x1 r2:0x1 r3:18
//LOCKTIME 0x4C000000
//CLKDIVN 0x4C000014 设置FCLK:HCLK:PCLK
//CAMDIVN 0x4C000018
//MPLLCON 0x4C000004
//UPLLCON 0x4C000008
clock_mpll_init:
	push {r3-r6, lr}
	ldr r5, =#0x4C000000
	ldr r6, =#0xFFFFFFFF
	str r6, [r5]
	and r4, r3, #0x3
	mov r4, r4, LSR #1
	mov r3, r3, LSR #2
	cmp r3, #0x1
	beq str_clkdivn
	cmp r3, #0x2
	beq fh2
	cmp r3, #0x3
	beq fh3
	cmp r3, #0x4
	beq fh4
	cmp r3, #0x6
	beq fh6
	cmp r3, #0x8
	beq fh8
	b return	
fh2:
	orr r4, r4, r3
	beq str_clkdivn
fh3:	
	orr r4, r4, #0x6
	ldr r5, =#0x4C000018
	ldr r6, [r5]
	bic r6, r6, #0x100
	str r6, [r5]
	beq str_clkdivn
fh4:
	orr r4, r4, #0x4
	ldr r5, =#0x4C000018
	ldr r6, [r5]
	bic r6, r6, #0x200
	str r6, [r5]
	beq str_clkdivn
fh6:
	orr r4, r4, #0x6
	ldr r5, =#0x4C000018
	ldr r6, [r5]
	orr r6, r6, #0x100
	str r6, [r5]
	beq str_clkdivn
fh8:
	orr r4, r4, #0x4
	ldr r5, =#0x4C000018
	ldr r6, [r5]
	orr r6, r6, #0x200
	str r6, [r5]
	beq str_clkdivn
str_clkdivn:
	ldr r5, =#0x4C000014
	str r4, [r5]
	bl asycn_set
//设置MPLL
	ldr r5, =#0x4C000004
	mov r6, #0
	orr r6, r6, r2
	mov r4, r1, LSL #4
	orr r6, r6, r4
	mov r4, r0, LSL #12
	orr r6, r6, r4
	str r6, [r5]
return:
	pop {r3-r6, pc}


asycn_set:
	push {r0, lr}
	mrc p15,0,r0,c1,c0,0
	orr r0,r0,#0xc0000000
	mcr p15,0,r0,c1,c0,0
	pop {r0, pc}
