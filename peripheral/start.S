/*
* 机器启动时初始化
* 1.关闭看门狗
* 2.设置时钟
* 3.设置SDRAM
* 4.重定位
*/

.text
.global _start
_start:
	b reset
	ldr pc, =entry_und_addr
	ldr pc, =entry_swi_addr
	b halt//ldr pc, =entry_abrt_prefetch_addr
	b halt//ldr pc, =entry_abrt_data_addr
	b halt//ldr pc, =entry_reserverd_addr
	ldr pc, =entry_irq_addr
	b halt//ldr pc, =entry_fiq_addr

reset:
	//设置栈
	ldr sp, =(_start + 0x3f00000)
	/* 设置内存: sp 栈 */
	/* 分辨是nor/nand启动
	 * 写0到0地址, 再读出来
	 * 如果得到0, 表示0地址上的内容被修改了, 它对应ram, 这就是nand启动
	 * 否则就是nor启动
	 */
	//mov r1, #0
	//ldr r0, [r1] /* 读出原来的值备份 */
	//str r1, [r1] /* 0->[0] */ 
	//ldr r2, [r1] /* r2=[0] */
	//cmp r1, r2   /* r1==r2? 如果相等表示是NAND启动 */
	//ldr sp, =0x40000000+4096 /* 先假设是nor启动 */
	//moveq sp, #4096  /* nand启动 */
	//streq r0, [r1]   /* 恢复原来的值 */

	//关闭看门狗
	//bl watch_dog_disable
	ldr r1, =#0x53000000
	ldr r0, [r1]
	bic r0, r0, #0x1
	str r0, [r1]

	//设置时钟
	//ldr r0, =#0x5c
	//ldr r1, =#1
	//ldr r2, =#1
	//ldr r3, =#18
	//bl clock_mpll_init
	/* 设置MPLL, FCLK : HCLK : PCLK = 400m : 100m : 50m */
	/* LOCKTIME(0x4C000000) = 0xFFFFFFFF */
	ldr r0, =0x4C000000
	ldr r1, =0xFFFFFFFF
	str r1, [r0]

	/* CLKDIVN(0x4C000014) = 0X5, tFCLK:tHCLK:tPCLK = 1:4:8  */
	ldr r0, =0x4C000014
	ldr r1, =0x5
	str r1, [r0]

	/* 设置CPU工作于异步模式 */
	mrc p15,0,r0,c1,c0,0
	orr r0,r0,#0xc0000000   //R1_nF:OR:R1_iA
	mcr p15,0,r0,c1,c0,0

	/* 设置MPLLCON(0x4C000004) = (92<<12)|(1<<4)|(1<<0) 
	 *  m = MDIV+8 = 92+8=100
	 *  p = PDIV+2 = 1+2 = 3
	 *  s = SDIV = 1
	 *  FCLK = 2*m*Fin/(p*2^s) = 2*100*12/(3*2^1)=400M
	 */
	ldr r0, =0x4C000004
	ldr r1, =(92<<12)|(1<<4)|(1<<0)
	str r1, [r0]

	/* 一旦设置PLL, 就会锁定lock time直到PLL输出稳定
	 * 然后CPU工作于新的频率FCLK
	 */

	//设置SDRAM
	bl sdram_init

	//mmu和cache的相关设置
	bl enable_icache
	//bl create_page_table
	//bl set_and_enable_mmu

	//重定位
	/*ldr r0, =_code_start
	ldr r1, =#0x0
	ldr r2, =_bss_start
	sub r2, r2, r0
	bl relocate_copy*/
	bl nand_flash_init
	ldr r0, =nand_attr_ptr
	bl nand_flash_attr
	bl nand_flash_page_size
	ldr r3, =_code_start
	mov r2, r0
	ldr r1, =_bss_start
	sub r1, r1, r3
	mov r0, #0x0
	bl nand_flash_read

	ldr r0, =_bss_start
	ldr r1, =_bss_end
	sub r1, r1, r0
	bl relocate_clear

	bl enable_cpu_irq
	/* 复位之后, cpu处于svc模式
	 * 现在, 切换到usr模式
	 */
	mrs r0, cpsr      /* 读出cpsr */
	bic r0, r0, #0xf  /* 修改M4-M0为0b10000, 进入usr模式 */
	msr cpsr, r0

	ldr sp, =0x33f00000
	ldr pc, =usr_mod //用户模式只能在重定位之后的地方运行，所以这里用到了绝对跳转。自己猜的
usr_mod:
	mov r0, #0
	mov r1, #26
	bl uart_init
	
	/* 故意加入一条未定义指令 */
//und_code:
//	.word 0xdeadc0de  /* 未定义指令 */
//	swi 0x123  /* 执行此命令, 触发SWI异常, 进入0x8执行 */
	
	//进入主函数
	ldr pc, =main
	//bl main
halt:
	b halt
nand_attr_ptr:
        .string "0000 0000 0000 0000 0000"
.align 4
entry_und_addr:
	/* 执行到这里之前:
	 * 1. lr_und保存有被中断模式中的下一条即将执行的指令的地址
	 * 2. SPSR_und保存有被中断模式的CPSR
	 * 3. CPSR中的M4-M0被设置为11011, 进入到und模式
	 * 4. 跳到0x4的地方执行程序 
	 */

	/* sp_und未设置, 先设置它 */
	ldr sp, =0x34000000

	/* 在und异常处理函数中有可能会修改r0-r12, 所以先保存 */
	/* lr是异常处理完后的返回地址, 也要保存 */
	stmdb sp!, {r0-r12, lr}  /* ^会把spsr的值恢复到cpsr里 */
	
	/* 保存现场 */
	/* 处理und异常 */
	mrs r0, cpsr
	ldr r1, =und_string
	bl printException
	
	/* 恢复现场 */
	ldmia sp!, {r0-r12, pc}^  /* ^会把spsr的值恢复到cpsr里 */
	
und_string:
	.string "undefined instruction exception"

.align 4

entry_swi_addr:
	/* 执行到这里之前:
	 * 1. lr_svc保存有被中断模式中的下一条即将执行的指令的地址
	 * 2. SPSR_svc保存有被中断模式的CPSR
	 * 3. CPSR中的M4-M0被设置为10011, 进入到svc模式
	 * 4. 跳到0x08的地方执行程序 
	 */

	/* sp_svc未设置, 先设置它 */
	ldr sp, =0x33e00000

	/* 保存现场 */
	/* 在swi异常处理函数中有可能会修改r0-r12, 所以先保存 */
	/* lr是异常处理完后的返回地址, 也要保存 */
	stmdb sp!, {r0-r12, lr}  

	mov r4, lr
	
	/* 处理swi异常 */
	mrs r0, cpsr
	ldr r1, =swi_string
	bl printException

	sub r0, r4, #4
	bl printSWIVal
	
	/* 恢复现场 */
	ldmia sp!, {r0-r12, pc}^  /* ^会把spsr的值恢复到cpsr里 */
	
swi_string:
	.string "swi exception"

.align 4

//entry_abrt_prefetch_addr:
//entry_abrt_data_addr:
//entry_reserverd_addr:
entry_irq_addr:
	/* 执行到这里之前:
	 * 1. lr_irq保存有被中断模式中的下一条即将执行的指令的地址
	 * 2. SPSR_irq保存有被中断模式的CPSR
	 * 3. CPSR中的M4-M0被设置为10010, 进入到irq模式
	 * 4. 跳到0x18的地方执行程序 
	 */

	/* sp_irq未设置, 先设置它 */
	ldr sp, =0x33d00000

	/* 保存现场 */
	/* 在irq异常处理函数中有可能会修改r0-r12, 所以先保存 */
	/* lr-4是异常处理完后的返回地址, 也要保存 */
	sub lr, lr, #4
	stmdb sp!, {r0-r12, lr}  

	/* 处理irq异常 */
	bl handle_irq_c

	/* 恢复现场 */
	ldmia sp!, {r0-r12, pc}^  /* ^会把spsr_irq的值恢复到cpsr里 */
//entry_fiq_addr:

