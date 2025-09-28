@echo off
echo Assembling bootloader...
nasm -f bin bootloader.asm -o bootloader.bin

echo Assembling kernel...
nasm -f bin kernel.asm -o kernel.bin

echo Creating OS image...
copy /b bootloader.bin + kernel.bin os.img

echo Build complete. Use QEMU to run: qemu-system-i386 -fda os.img
