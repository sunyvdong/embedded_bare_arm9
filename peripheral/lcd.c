#include "lcd.h"
#include "s3c2440_soc.h"
enum {
	NORMAL = 0,
	INVERT = 1,
};

/* NORMAL : 正常极性
 * INVERT : 反转极性
 */
typedef struct pins_polarity {
	int de;    /* normal: 高电平时可以传输数据 */
	int pwren; /* normal: 高电平有效 */
	int vclk;  /* normal: 在下降沿获取数据 */
	int rgb;   /* normal: 高电平表示1 */
	int hsync; /* normal: 高脉冲 */
	int vsync; /* normal: 高脉冲 */
}pins_polarity, *p_pins_polarity;

typedef struct time_sequence {
	/* 垂直方向 */
	int tvp; /* vysnc脉冲宽度 */
	int tvb; /* 上边黑框, Vertical Back porch */
	int tvf; /* 下边黑框, Vertical Front porch */

	/* 水平方向 */
	int thp; /* hsync脉冲宽度 */
	int thb; /* 左边黑框, Horizontal Back porch */
	int thf; /* 右边黑框, Horizontal Front porch */

	int vclk;
}time_sequence, *p_time_sequence;


typedef struct lcd_params {
	char *name;
	
	/* 引脚极性 */
	pins_polarity pins_pol;
	
	/* 时序 */
	time_sequence time_seq;
	
	/* 分辨率, bpp */
	int xres;
	int yres;
	int bpp;
	
	/* framebuffer的地址 */
	unsigned int fb_base;
}lcd_params, *p_lcd_params;

static lcd_params lcd_4_3_params = {
	.name = "lcd_4.3",
	.pins_pol = {
		.de    = NORMAL,	/* normal: 高电平时可以传输数据 */
		.pwren = NORMAL,    /* normal: 高电平有效 */
		.vclk  = NORMAL,	/* normal: 在下降沿获取数据 */
		.rgb   = NORMAL,	/* normal: 高电平表示1 */
		.hsync = INVERT,    /* normal: 高脉冲 */
		.vsync = INVERT, 	/* normal: 高脉冲 */
	},
	.time_seq = {
		/* 垂直方向 */
		.tvp=	10, /* vysnc脉冲宽度 */
		.tvb=	2,  /* 上边黑框, Vertical Back porch */
		.tvf=	2,  /* 下边黑框, Vertical Front porch */

		/* 水平方向 */
		.thp=	41, /* hsync脉冲宽度 */
		.thb=	2,  /* 左边黑框, Horizontal Back porch */
		.thf=	2,  /* 右边黑框, Horizontal Front porch */

		.vclk=	9,  /* MHz */
	},
	.xres = 480,
	.yres = 272,
	.bpp  = 32,  /* 16, no 24bpp */
	.fb_base = 0x33c00000,//LCD_FB_BASE,
};

static p_lcd_params plcdparams = &lcd_4_3_params;

static void lcd_pin_init(void)
{
	/* 初始化引脚 : 背光引脚 */
	GPBCON &= ~0x3;
	GPBCON |= 0x01;

	/* LCD专用引脚 */
	GPCCON = 0xaaaaaaaa;
	GPDCON = 0xaaaaaaaa;

	/* PWREN */
	GPGCON |= (3<<8);
}

void lcd_init()
{
	int pixelplace;
	unsigned int addr;

	lcd_pin_init();
	
	/* [17:8]: clkval, vclk = HCLK / [(CLKVAL+1) x 2]
	 *                   9   = 100M /[(CLKVAL+1) x 2], clkval = 4.5 = 5
	 *                 CLKVAL = 100/vclk/2-1
	 * [6:5]: 0b11, tft lcd
	 * [4:1]: bpp mode
	 * [0]  : LCD video output and the logic enable/disable
	 */
	//int clkval = (double)HCLK/plcdparams->time_seq.vclk/2-1+0.5;
	int clkval = 5;
	int bppmode = plcdparams->bpp == 8  ? 0xb :\
				  plcdparams->bpp == 16 ? 0xc :\
				  0xd;  /* 0xd: 24,32bpp */
	LCDCON1 = (clkval<<8) | (3<<5) | (bppmode<<1) ;

	/* [31:24] : VBPD    = tvb - 1
	 * [23:14] : LINEVAL = line - 1
	 * [13:6]  : VFPD    = tvf - 1
	 * [5:0]   : VSPW    = tvp - 1
	 */
	LCDCON2 = ((plcdparams->time_seq.tvb - 1)<<24) | \
			((plcdparams->yres - 1)<<14)   | \
			((plcdparams->time_seq.tvf - 1)<<6)  | \
			((plcdparams->time_seq.tvp - 1)<<0);

	/* [25:19] : HBPD	 = thb - 1
	 * [18:8]  : HOZVAL  = 列 - 1
	 * [7:0]   : HFPD	 = thf - 1
	 */
	LCDCON3 = ((plcdparams->time_seq.thb - 1)<<19) | \
			((plcdparams->xres - 1)<<8) | \
			((plcdparams->time_seq.thf - 1)<<0);

	/* 
	 * [7:0]   : HSPW	 = thp - 1
	 */
	LCDCON4 = ((plcdparams->time_seq.thp - 1)<<0);

    /* 用来设置引脚极性, 设置16bpp, 设置内存中象素存放的格式
     * [12] : BPP24BL
	 * [11] : FRM565, 1-565
	 * [10] : INVVCLK, 0 = The video data is fetched at VCLK falling edge
	 * [9]  : HSYNC是否反转
	 * [8]  : VSYNC是否反转
	 * [7]  : INVVD, rgb是否反转
	 * [6]  : INVVDEN
	 * [5]  : INVPWREN
	 * [4]  : INVLEND
	 * [3]  : PWREN, LCD_PWREN output signal enable/disable
	 * [2]  : ENLEND
	 * [1]  : BSWP
	 * [0]  : HWSWP
	 */

	pixelplace = plcdparams->bpp == 32 ? (0) : \
	             plcdparams->bpp == 16 ? (1) : \
	             (1<<1);  /* 8bpp */
	
	LCDCON5 = (plcdparams->pins_pol.vclk<<10) |\
	          (plcdparams->pins_pol.rgb<<7)   |\
	          (plcdparams->pins_pol.hsync<<9) |\
	          (plcdparams->pins_pol.vsync<<8) |\
 		  (plcdparams->pins_pol.de<<6)    |\
		  (plcdparams->pins_pol.pwren<<5) |\
		  (1<<11) | pixelplace;

	/* framebuffer地址 */
	/*
	 * [29:21] : LCDBANK, A[30:22] of fb
	 * [20:0]  : LCDBASEU, A[21:1] of fb
	 */
	addr = plcdparams->fb_base & ~(1<<31);
	LCDSADDR1 = (addr >> 1);

	/* 
	 * [20:0] : LCDBASEL, A[21:1] of end addr
	 */
	addr = plcdparams->fb_base + plcdparams->xres*plcdparams->yres*plcdparams->bpp/8;
	addr >>=1;
	addr &= 0x1fffff;
	LCDSADDR2 = addr;//	
}

void get_lcd_params(unsigned int *base_addr, int *xres, int *yres, int *bpp)
{
	*base_addr = plcdparams->fb_base;
	*xres = plcdparams->xres;
	*yres = plcdparams->yres;
	*bpp = plcdparams->bpp;
}

void lcd_enable()
{
	/* 背光引脚 : GPB0 */
	GPBDAT |= (1<<0);
	
	/* pwren    : 给LCD提供AVDD  */
	LCDCON5 |= (1<<3);
	
	/* LCDCON1'BIT 0 : 设置LCD控制器是否输出信号 */
	LCDCON1 |= (1<<0);
}

void lcd_disable()
{
	/* 背光引脚 : GPB0 */
	GPBDAT &= ~(1<<0);

	/* pwren	: 给LCD提供AVDD  */
	LCDCON5 &= ~(1<<3);

	/* LCDCON1'BIT 0 : 设置LCD控制器是否输出信号 */
	LCDCON1 &= ~(1<<0);
}
