/*
* 中断
*/

.text
//以下是按键中断
.global key_int_init //无输入参数，使能4个按键中断
/*
* EINT0, 2, 11, 19分别对应GPF0,2和GPG3,11
* GPFCON 0x56000050
* GPGCON 0x56000060
* GPGDAT 0x56000064
* EXTINT0 0x56000088
* EXTINT1 0x5600008c
* EXTINT2 0x56000090
* EINTMASK 0x560000a4
*/


//以下是公共使用
.global enable_cpu_irq  //无输入输出参数
.global disable_cpu_irq  //无输入输出参数
.global int_crl_mask_able //r0表示设置哪个中断控制器，r1表示是否使能控制器
//INTMSK 0X4A000008
.global sub_int_crl_mask_able //r0表示设置哪个中断控制器，r1表示是否使能控制器
//INTSUBMSK 0X4A00001C
.global int_get_offset //r0返回中断值
//INTOFFSET 0x4A000014
.global clear_int_pnd  //r0表示清除哪一位的中断
//SRCPND 0X4A000000
//INTPND 0X4A000010
//EINTPEND 0x560000a8
key_int_init:
	push {r1-r5, lr}
	/* 配置GPIO为中断引脚 */
	ldr r5, =#0x56000050
	ldr r4, =#0x56000060
	ldr r3, [r5]
	ldr r2, [r4]
	bic r3, r3, #((3<<0) | (3<<4))
	ldr r1, =#((3<<6) | (3<<22))
	bic r2, r2, r1
	orr r3, r3, #((2<<0) | (2<<4))
	ldr r1, =#((2<<6) | (2<<22))
	orr r2, r2, r1
	str r3, [r5]
	str r2, [r4]
	/* 设置中断触发方式: 双边沿触发 */
	ldr r5, =#0x56000088
	ldr r4, =#0x5600008c
	ldr r3, =#0x56000090
	ldr r2, [r5]
	ldr r1, =#(7<<0) | (7<<8)
	orr r2, r2, r1
	str r2, [r5]
	ldr r2, [r4]
	orr r2, r2, #(7<<12)
	str r2, [r4]
	ldr r2, [r3]
	orr r2, r2, #(7<<12)
	str r2, [r3]
	/* 设置EINTMASK使能eint11,19 */
	ldr r5, =#0x560000a4
	ldr r2, [r5]
	ldr r1, =#((1<<11) | (1<<19))
	bic r2, r2, r1
	str r2, [r5]
	pop {r1-r5, pc}

enable_cpu_irq:
	push {r0, lr}
	mrs r0, cpsr
	bic r0, r0, #0x80
	msr cpsr, r0
	pop {r0, pc}
disable_cpu_irq:
	push {r0, lr}
	mrs r0, cpsr
	orr r0, r0, #0x80
	msr cpsr, r0
	pop {r0, pc}
int_crl_mask_able:
	push {r1-r3, lr}
	ldr r3, =#0X4A000008
	ldr r2, [r3]
	bic r2, r2, r0
	and r1, r1, r0
	orr r2, r2, r1
	str r2, [r3]
	pop {r1-r3, pc}
sub_int_crl_mask_able:
	push {r1-r3, lr}
	ldr r3, =#0X4A00001C
	ldr r2, [r3]
	bic r2, r2, r0
	and r1, r1, r0
	orr r2, r2, r1
	str r2, [r3]
	pop {r1-r3, pc}
int_get_offset:
	push {r1, lr}
	ldr r1, =#0x4A000014
	ldr r0, [r1]
	pop {r1, pc}
clear_int_pnd:
	push {r1-r5, lr}
	ldr r1, =#0X4A000000
	ldr r2, =#0X4A000010
	//ldr r5, =#0x560000a8
	ldr r3, [r1]
	ldr r4, [r2]
	orr r3, r3, r0
	orr r4, r4, r0
	str r3, [r1]
	str r4, [r2]
	//ldr r3, [r5]
	//str r3, [r5]
	pop {r1-r5, pc}
