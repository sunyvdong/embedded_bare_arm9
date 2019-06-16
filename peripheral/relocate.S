/*
* 重定位
* 有个隐含条件 必须四字节对齐
*/

.text
.global relocate_copy  //输入参数 r0:目的地址 r1:源地址 r2:拷贝的大小
.global relocate_clear //输入参数 r0:清零的起始地址 r1:清零的大小
relocate_copy:
	push {lr}

	cmp r0, r1
	beq copy_return
	cmp r2, #0x0
	beq copy_return

	push {r0-r3}
	cmp r0, r1
	bhi copy_back_start
copy_loop:
	sub r2, r2, #0x4
	ldr r3, [r1]
	str r3, [r0]
	add r0, r0, #0x4
	add r1, r1, #0x4
	cmp r2, #0x0
	bne copy_loop
	b copy_return
copy_back_start:
	add r0, r0, r2	
	sub r0, r0, #0x4
	add r1, r1, r2	
	sub r1, r1, #0x4
copy_back_loop:
	sub r2, r2, #0x4
	ldr r3, [r1]
	str r3, [r0]
	sub r0, r0, #0x4
	sub r1, r1, #0x4
	cmp r2, #0x0
	bne copy_back_loop
	pop {r0-r3}
copy_return:
	pop {pc}
relocate_clear:
	push {lr}

	cmp r1, #0x0
	beq clear_return

	push {r0-r2}
	mov r2, #0x0
clear_loop:
	str r2, [r0]
	add r0, r0, #0x4
	sub r1, r1, #0x4
	cmp r1, #0x0
	bne clear_loop
	pop {r0-r2}
clear_return:
	pop {pc}
