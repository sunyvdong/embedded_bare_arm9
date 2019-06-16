#include "io.h"
#include <stdarg.h>

extern void utils_operator_divid(unsigned int dividend, unsigned int divid, unsigned int *quot_ptr, unsigned int *remain_ptr);

#define MAX_NUMBER_BYTES 32
static char hex_tab[]={'0','1','2','3','4','5','6','7',\
		'8','9','a','b','c','d','e','f'};
static int put_str(const utils_putc_type callback, const char *str)
{
	while (*str != '\0')
		callback(*str++);
	return 0;
}
static int put_num(const utils_putc_type callback, const int n, const int base, const char lead,const int maxwidth) 
{
	unsigned int m=0;
	char buf[MAX_NUMBER_BYTES], *s = buf + sizeof(buf);
	int count=0,i=0;
			
	*--s = '\0';
	
	if (n < 0){
		m = -n;
	}
	else{
		m = n;
	}

	unsigned int quot = 0;
	unsigned int remain = 0;
	do{
		utils_operator_divid(m, base, &quot, &remain);
		*--s = hex_tab[remain];
		count++;
	}while (0 != (m = quot));
	
	if( maxwidth && count < maxwidth){
		for (i=maxwidth - count; i; i--)	
			*--s = lead;
	}

	if (n < 0)
		*--s = '-';
	
	return put_str(callback, s);
}
//暂时取消十进制的打印只支持八进制和十六进制
static int inner_printf(const utils_putc_type callback, const char *fmt, va_list ap) 
{
	char lead=' ';
	int maxwidth=0;
	
	for(; *fmt != '\0'; fmt++)
	{
		if (*fmt != '%') {
			callback(*fmt);
			continue;
		}
			
		//format : %08d, %8d,%d,%u,%x,%f,%c,%s 
		++fmt;
		lead=' ';
		if(*fmt == '0'){
			lead = '0';
			fmt++;	
		}

		maxwidth=0;
		while(*fmt >= '0' && *fmt <= '9'){
			maxwidth *=10;
			maxwidth += (*fmt - '0');
			fmt++;
		}
		
		switch (*fmt) 
		{
		case 'd': 
			put_num(callback, va_arg(ap, int), 10,lead,maxwidth); 
			break;
		case 'o': 
			put_num(callback, va_arg(ap, unsigned int), 8,lead,maxwidth); 
			break;				
		case 'u': 
			put_num(callback, va_arg(ap, unsigned int), 10,lead,maxwidth); 
			break;
		case 'x': 
			put_num(callback, va_arg(ap, unsigned int), 16,lead,maxwidth); 
			break;
		case 'c': 
			callback(va_arg(ap, int)); 
			break;		
		case 's': 
			put_str(callback, va_arg(ap, char *)); 
			break;		  			
		default:  
			callback(*fmt);
			break;
		}
	}
	return 0;
}
int utils_printf(const utils_putc_type callback, const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	inner_printf(callback, fmt, ap);
	va_end(ap);
	return 0;
}
