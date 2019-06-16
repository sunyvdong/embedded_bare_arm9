/*
* 指令缓存和数据缓存
* MMU使能
*/

.global enable_icache      //无输入输出参数
.global enable_dcache      //无输入输出参数
.global mmu_set_base_addr  //输入参数r0:页表基地址。无输出参数
.global mmu_set_domain     //输入参数r0:域的权限。无输出参数。 共16个域，每个域占2bit，00:No Access 01:Client 10:Reserved 11:Manager
.global enable_mmu         //无输入输出参数
.global set_and_enable_mmu //无输入输出参数

set_and_enable_mmu: //无输入输出参数
	push {r0, lr}
	/* 把页表基址告诉cp15 */
	ldr r0, =#0x32000000
	bl mmu_set_base_addr
	/* 设置域为0xffffffff, 不进行权限检查 */
	ldr r0, =#0xffffffff
	bl mmu_set_domain
	/* 使能icache,dcache,mmu */
	bl enable_icache
	bl enable_dcache
	bl enable_mmu
	pop {r0, pc}

enable_icache:      //无输入输出参数
	push {r0, lr}
	mrc p15, 0, r0, c1, c0, 0
	orr r0, r0, #(1<<12)  /* r0 = r0 or (1<<12) */
	mcr p15, 0, r0, c1, c0, 0
	pop {r0, pc}
enable_dcache:      //无输入输出参数
	push {r0, lr}
	mrc p15, 0, r0, c1, c0, 0
	orr r0, r0, #(1<<2)  /* r0 = r0 or (1<<12) */
	mcr p15, 0, r0, c1, c0, 0
	pop {r0, pc}
mmu_set_base_addr:  //输入参数r0:页表基地址。无输出参数
	push {lr}
	mcr p15, 0, r0, c2, c0, 0
	pop {pc}
mmu_set_domain:     //输入参数r0:域的权限。无输出参数。 共16个域，每个域占2bit，00:No Access 01:Client 10:Reserved 11:Manager
	push {lr}
	mcr p15, 0, r0, c3, c0, 0
	pop {pc}
enable_mmu:         //无输入输出参数
	push {r0, lr}
	mrc p15, 0, r0, c1, c0, 0
	orr r0, r0, #(1<<0)  /* r0 = r0 or (1<<12) */
	mcr p15, 0, r0, c1, c0, 0
	pop {r0, pc}
