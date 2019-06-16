#include "interrupt.h"

extern void int_crl_mask_able(unsigned int ctl, unsigned int mask); //r0表示设置哪个中断控制器，r1表示是否使能控制器
extern unsigned int int_get_offset(); //r0返回中断值
extern void clear_int_pnd(unsigned int clear_bits);  //r0表示清除哪一位的中断

static irq_func_type irq_func_array[32] = {0};

void register_irq(int irq, irq_func_type fp)
{
	irq_func_array[irq] = fp;

	int_crl_mask_able((1<<irq), 0);
}

void handle_irq_c()
{
	unsigned int offset = int_get_offset();
	if(0 != irq_func_array[offset])
	{
		irq_func_array[offset](offset);
	}
	clear_int_pnd(1 << offset);
}

