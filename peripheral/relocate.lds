SECTIONS
{
	. = 0xB0000000;

	_code_start = .;

	. = ALIGN(4);
	.text      :
	{
	  start.o(.text)
	  watch_dog.o(.text)
	  clock.o(.text)
	  sdram.o(.text)
	  mmu_cache.o(.text)
	  mmu_cache_c.o(.text)
	  relocate.o(.text)
	  base.o(.text)
	  nand_flash.o(.text)
	  interrupt.o(.text)
	  interrupt_c.o(.text)
	  uart.o(.text)
	  *(.text)
	}

	. = ALIGN(4);
	.rodata : { *(.rodata) }

	. = ALIGN(4);
	.data : { *(.data) }

	. = ALIGN(4);
	_bss_start = .;
	.bss : { *(.bss) *(.COMMON) }
	_bss_end = .;
}
