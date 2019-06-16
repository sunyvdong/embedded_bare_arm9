/*
*基础函数
*/

.global utils_operator_divid //输入参数:r0被除数，r1除数，r2商的指针，r3余数的指针。无输出参数

utils_operator_divid:
	push {r0-r6, lr}
	mov r4, r2
	mov r5, r3
	mov r6, #0x0

inner_loop:
	bl divid_inner
	add r6, r2
	cmp r2, #0x0
	bne inner_loop

	str r6, [r4]
	str r0, [r5]
	pop {r0-r6, pc}

divid_inner: //输入参数:r0被除数(返回<!--r0 - (r1 * r2)-->)，r1除数，r2商(只能是2的n次方)。无输出参数
	push {lr}
	mov r2, #0x0
	cmp r0, r1
	bcc divid_return

	push {r3}
	mov r2, #0x1
	mov r3, r1

divid_inner_loop:
	mov r3, r3, LSL #0x1
	cmp r0, r3
	bcc divid_inner_break_loop
	mov r2, r2, LSL #0x1
	b divid_inner_loop
divid_inner_break_loop:
	mov r3, r3, LSR #0x1
	sub r0, r0, r3
	pop {r3}

divid_return:
	pop {pc}
