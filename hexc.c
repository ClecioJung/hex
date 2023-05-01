#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static size_t min(const size_t a, const size_t b)
{
    return ((a > b) ? b : a);
}

static char printable_char(const char c)
{
    if ((c < 32) || (c > 126)) {
        return '.';
    }
    return c;
}

int main(const int argc, const char *const argv[])
{
    const size_t number_of_columns = 16;
    if (argc < 2) {
        fprintf(stderr, "Usage: %s filename\n", argv[0]);
        return EXIT_FAILURE;
    }
    FILE *const file = fopen(argv[1], "rb");
    if (file == NULL) {
        fprintf(stderr, "Couldn't open file: %s\n", strerror(errno));
        return EXIT_FAILURE;
    }
    size_t address = 0;
    while (1) {
        char buffer[1024];
        const size_t size = fread(buffer, 1, sizeof(buffer), file);
        if (ferror(file)) {
            fprintf(stderr, "Got the following error while reading from file: %s\n", strerror(errno));
            fclose(file);
            return EXIT_FAILURE;
        }
        for (size_t buf_address = 0; buf_address < size; buf_address += number_of_columns, address += number_of_columns) {
            printf("%08lX  ", address);
            const size_t max_column = min(number_of_columns, (size - buf_address));
            for (size_t column = 0; column < max_column; column++) {
                printf("%02X ", (unsigned char)buffer[buf_address + column]);
                if (column == (number_of_columns/2-1)) {
                    putchar(' ');
                }
            }
            const int spaces = (int)(3*(number_of_columns-max_column) + ((max_column < (number_of_columns/2)) ? 1 : 0));
            printf("%*s  |", spaces, "");
            for (size_t column = 0; column < max_column; column++) {
                putchar(printable_char(buffer[buf_address + column]));
            }
            printf("|\n");
        }
        if (feof(file)) {
            break;
        }
    }
    fclose(file);
    return EXIT_SUCCESS;
}
