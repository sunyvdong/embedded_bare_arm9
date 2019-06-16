/*
*soc2440一共有三个灯，分别用r0的[0:2]表示这三个灯
*/
.text
.global led_init  //输入参数:r0[0:2]控制要配置哪个灯,r1[0:2]表示把灯对应的GPIO配置成输入0还是输出1。输出参数:无
.global led_set   //输入参数:r0[0:2]控制要设置哪个灯,输出参数:无
.global led_get   //输出参数:r0[0:2]表示返回灯的状态

//配置寄存器GPFCON的地址是0x56000050,GPF4、5、6控制led灯，00表示输入01表示输出
//数据寄存器GPFDAT的地址是0x56000054

led_init:
	push {r4-r7, lr}
	ldr r5, =#0x56000050	
	ldr r7, [r5]
	mov r4, #0x1
	mov r6, #0x8
init_loop:
	and r5, r0, r4
	cmp r5, #0x0
	beq init_continue
	mov r5, #0x3
	mov r5, r5, LSL r6
	bic r7, r7, r5
	and r5, r1, r4
	cmp r5, #0
	beq init_continue
	mov r5, #0x1
	mov r5, r5, LSL r6
	orr r7, r7, r5
init_continue:
	add r6, r6, #2
	mov r4, r4, LSL #1
	cmp r4, #0x8
	beq init_ret
	b init_loop
init_ret:
	ldr r5, =#0x56000050	
	str r7,[r5]
	pop {r4-r7, pc}
led_set:
	push {r4-r6, lr}
	ldr r5, =#0x56000054	
	ldr r6, [r5]
	bic r6, r6, #0x70
	and r4, r0, #0x7
	mov r4, r4, LSL #4
	orr r6, r6, r4
	str r6, [r5]
	pop {r4-r6, pc}
led_get:
	push {r1, lr}
	ldr r1, =#0x56000054	
	ldr r0, [r1]
	and r0, r0, #0x70
	mov r0, r0, LSR #4
	pop {r1, pc}
