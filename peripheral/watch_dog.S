/*
*看门狗
*/
#WTCON 0x53000000 配置
#WTDAT 0x53000004 计时器
#WTCNT 0x53000008 计数器
.text
.global watch_dog_disable
watch_dog_disable:
	push {r0-r1,lr}
	ldr r1, =#0x53000000
	ldr r0, [r1]
	bic r0, r0, #0x1
	str r0, [r1]
	pop {r0-r1,pc}
