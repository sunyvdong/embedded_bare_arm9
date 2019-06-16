
OUTPUT_NAME = lcd

#all: start.o main.o led.o watch_dog.o clock.o uart.o sdram.o io.o relocate.o
all: start.o main.o led.o watch_dog.o clock.o sdram.o mmu_cache.o mmu_cache_c.o relocate.o io.o uart.o interrupt.o interrupt_c.o base.o nand_flash.o timer.o lcd.o lcd_utils.o
	arm-linux-ld -T relocate.lds $^ -o $(OUTPUT_NAME).elf
	arm-linux-objcopy -O binary -S $(OUTPUT_NAME).elf $(OUTPUT_NAME).bin
	arm-linux-objdump -D $(OUTPUT_NAME).elf > $(OUTPUT_NAME).dis
clean:
	rm *.bin *.o *.elf *.dis
	
%.o : %.c
	arm-linux-gcc -march=armv4 -c -o $@ $< -fno-stack-protector

%.o : %.S
	arm-linux-gcc -march=armv4 -c -o $@ $< -fno-stack-protector
	
