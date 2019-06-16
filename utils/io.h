#ifndef UTILS_IO_H
#define UTILS_IO_H
typedef void (*utils_putc_type)(const char ch);
int utils_printf(const utils_putc_type callback, const char *format, ...);
#endif
