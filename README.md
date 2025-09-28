 # QubitOS

A minimal operating system written in NASM assembly with a simple shell.

## Files

- `bootloader.asm`: The bootloader that loads the kernel.
- `kernel.asm`: The kernel that prints a welcome message and provides a command prompt.
- `build.bat`: Script to assemble and create the OS image.

## Building

Run `build.bat` to assemble the code and create `os.img`.

## Running

Use QEMU: `qemu-system-i386 -fda os.img`

This will boot QubitOS, display "Welcome to QubitOS!", and present a command prompt.

## Shell Commands

- `help`: Display available commands.
- `echo <text>`: Print the specified text.
- `halt`: Halt the system.
- `clear`: Clear the screen.
- `time`: Display the current time (fake).
- `draw`: Switch to graphics mode and draw a pixel.
- `ls`: List created files.
- `create <file>`: Create a file with the given name.
- `delete <file>`: Delete a file with the given name.
