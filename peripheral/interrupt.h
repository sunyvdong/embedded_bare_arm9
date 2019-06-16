#ifndef INTERRUPT_H
#define INTERRUPT_H
typedef void (*irq_func_type)(unsigned int offset);

void register_irq(int irq, irq_func_type fp);
//void handle_irq_c();
#endif
