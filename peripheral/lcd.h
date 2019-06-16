#ifndef LCD_H
#define LCD_H

void lcd_init();
void get_lcd_params(unsigned int *base_addr, int *xres, int *yres, int *bpp);
void lcd_enable();
void lcd_disable();

#endif
