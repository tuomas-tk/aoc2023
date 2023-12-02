default:
	rm -rf hello.linked.elf
	rm -rf hello.elf
	riscv64-unknown-elf-as hello.s -o hello.elf
	riscv64-unknown-elf-ld -T qemu-riscv64-virt.ld -o hello.linked.elf hello.elf

# riscv64-linux-gnu-as hello2.s -o hello.o
# riscv64-linux-gnu-gcc -o hello hello.o -nostdlib -static

devicetree:
	qemu-system-riscv64 -machine virt -bios none -machine dumpdtb=riscv64-virt.dtb
	dtc -I dtb -O dts -o riscv64-virt.dts riscv64-virt.dtb

disas:
	hd hello.linked.elf
	riscv64-unknown-elf-objdump -dsx hello.linked.elf

# Run first `make gui` and there memsave 0x80000000 1000 memory
disas-raw:
	hd memory
	riscv64-unknown-elf-objdump -D memory -b binary -m riscv --adjust-vma=0x80000000

run:
	qemu-system-riscv64 -machine virt -bios none -kernel hello.linked.elf -nographic
# exit with CTRL+A, X

gui:
	qemu-system-riscv64 -machine virt -bios none -kernel hello.linked.elf