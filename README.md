# hex

## Overview

**hex** is a copy of the `hexdump -C` command of the POSIX terminal. It allows users to view the contents of any file in hexadecimal and ascii format, making it a useful tool for debugging and analysis.

This project was developed as a simple exercise for learning assembly programming (Linux x86-64 using the GAS Assembler). First, a C version was developed, named `hexc`. This code was later ported to assembly, version that was called `hexs`.

## Usage

To compile this project, clone this repository and type `make` on the terminal. To run the C version, run the command `hexc [file]`. Analogously, to run the assembly x86-64 version of the code, run `hexs [file]`.

## License

This project is released under the MIT license. See the LICENSE file for more information.