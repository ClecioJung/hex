# Constants
.equ BUFFER_SIZE, 1024
.equ COLUMNS, 16
.equ SPACE_COLUMN, 7
.equ SPACE_ASCII, 32
.equ DOT_ASCII, 46
.equ MIN_VISIBLE_ASCII, 32
.equ MAX_VISIBLE_ASCII, 126
.equ EXIT_SUCCESS, 0
.equ EXIT_FAILURE, 1

# Strings
.data
usage:
    .string "Usage: %s filename\n"
fopen_mode:
    .string "rb"
error_fopen:
    .string "Couldn't open file: %s\n"
error_fread:
    .string "Got the following error while reading from file: %s\n"
line_address:
    .string "%08lX  "
hex_value:
    .string "%02X "
string_spaces:
    .string "%*s  |"
empty_string:
    .string ""
new_line:
    .string "|\n"

# Global variables
file:
    .quad 0
buf_address:
    .quad 0
max_column:
    .quad 0
column:
    .quad 0
address:
    .quad 0
buffer_size:
    .quad 0
buffer:
    .space BUFFER_SIZE

# Linux syscalls use the following registers to receive their arguments:
#    %rax, %rdi, %rsi, %rdx, %r10, %r8, %r9
# For C functions (x86_64 ABI), the first six integer or pointer arguments to a function are passed in registers,
# and any additional arguments are passed on the stack. Yhe registers used are:
#    %rdi, %rsi, %rdx, %rcx, %r8, %r9

.text
.global main
main:
    pushq   %rax
    # If we got only one command line argument, we got an error
    dec     %rdi # decrement argc
    jnz     open_file
    # Print a error message and exit with an error code
    mov     (%rsi), %rdx # move argv[0] to rdx
    movq    stderr(%rip), %rdi
    mov     $usage, %rsi
    call    fprintf
    popq    %rdx
    mov     $EXIT_FAILURE, %rax
    ret
open_file:
    movq    8(%rsi), %rdi # first argument is filename given by argv[1]
    mov     $fopen_mode, %rsi # second argument: mode
    call    fopen
    movq    %rax, file
    # Check if the file was opened correctly
    testq   %rax, %rax
    jne     initialize_address
    # Print a error message and exit with an error code
    call    __errno_location
    mov     (%rax), %rdi
    call    strerror
    movq    stderr(%rip), %rdi
    mov     $error_fopen, %rsi
    movq    %rax, %rdx
    call    fprintf
    popq    %rdx
    mov     $EXIT_FAILURE, %rax
    ret
initialize_address:
    movq    $0, address
read_file:
    movq    $buffer, %rdi
    movq    $1, %rsi
    movq    $BUFFER_SIZE, %rdx
    movq    file, %rcx
    call    fread
    movq    %rax, buffer_size
    # Check if there was an error while reading the file
    movq    file, %rdi
    call    ferror
    testq   %rax, %rax
    je      start_loop_lines
    # Print a error message, close the file and exit with an error code
    call    __errno_location
    mov     (%rax), %rdi
    call    strerror
    movq    stderr(%rip), %rdi
    mov     $error_fread, %rsi
    movq    %rax, %rdx
    call    fprintf
    movq    file, %rdi
    call    fclose
    popq    %rdx
    mov     $EXIT_FAILURE, %rax
    ret
start_loop_lines:
    movq    $0, buf_address
iterate_lines:
    movq    buf_address, %rax
    cmpq    %rax, buffer_size
    jbe      check_eof
    # Print the address
    mov     $line_address, %rdi
    movq    address, %rsi
    call    printf
    # Calculates the quantity of columns
    movq    $COLUMNS, max_column
    movq    buffer_size, %rax
    subq    buf_address, %rax
    cmpq    $COLUMNS, %rax
    ja      start_loop_columns
    movq    %rax, max_column
start_loop_columns:
    movq    $0, column
iterate_columns:
    movq    column, %rax
    cmpq    %rax, max_column
    jna     finish_loop_lines
    # Print the value of the buffer in hexadecimal
    addq    buf_address, %rax
    mov     $buffer, %rbx
    xorq    %rsi, %rsi
    movb    (%rbx, %rax), %sil
    mov     $hex_value, %rdi
    call    printf
    # Put a space in the middle of the columns
    movq    column, %rax
    cmpq    $SPACE_COLUMN, %rax
    jne     finish_loop_columns
    movl    $SPACE_ASCII, %edi
    call    putchar
finish_loop_columns:
    # Increment the column and repeat the loop
    incq    column
    jmp     iterate_columns
finish_loop_lines:
    # Computes the quantity of spaces required to align the columns,
    # and stores it at %rax
    movq    $COLUMNS, %rax
    subq    max_column, %rax
    movq    $3, %rbx
    mulq    %rbx
    cmpq    $8, max_column
    jae     print_spaces
    incq    %rax
print_spaces:
    # Print spaces to align the columns
    mov     $string_spaces, %rdi
    mov     %rax, %rsi
    mov     $empty_string, %rdx
    call    printf
start_loop_columns_2:
    movq    $0, column
iterate_columns_2:
    movq    column, %rax
    cmpq    %rax, max_column
    jna     print_new_line
    # Print the value of the buffer in ascii
    addq    buf_address, %rax
    mov     $buffer, %rbx
    xorq    %rsi, %rsi
    movl    (%rbx, %rax), %edi
    cmpb    $MIN_VISIBLE_ASCII, %dil
    jl      print_dot
    cmpb    $MAX_VISIBLE_ASCII, %dil
    jl      print_readable_char
print_dot:
    movl    $DOT_ASCII, %edi
print_readable_char:
    call    putchar
finish_loop_columns_2:
    # Increment the column and repeat the loop
    incq    column
    jmp     iterate_columns_2
print_new_line:
    mov     $new_line, %rdi
    call    printf
    # Increment buf_address and address. Then repeat the loop
    addq    $COLUMNS, address
    addq    $COLUMNS, buf_address
    jmp     iterate_lines
check_eof:
    # Check if the end of file was reached
    movq    file, %rdi
    call    feof
    testq   %rax, %rax
    je      read_file
    # Close the file
    movq    file, %rdi
    call    fclose
    # Exit with zero exit code (success)
    popq    %rdx
    mov     $EXIT_SUCCESS, %rax
    ret
