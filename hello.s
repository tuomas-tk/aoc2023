# .section .init
.global _start

.equ UART_BASE_ADDR, 0x10000000

_start:
  # set s1 to the output address
  li s1, UART_BASE_ADDR # s1 := 0x1000_0000
  # set s2 to the input address
  la s2, message    # s2 := <message>
  # add to s3 the length of message
  # addi s3, s2, 14   # s3 := s2 + 14
loop:
  # load byte to s4 from the address in s2 (the input address)
  lb s3, 0(s2)      # s4 := (s2)
  # store byte from s4 to the address in s1 (the output address)
  sb s3, 0(s1)      # (s1) := s4
  # add one to the input address
  addi s2, s2, 1    # s2 := s2 + 1
  # loop back if s2<s3 (literally in the compiled code loop is replaced with -12 = 3*4 bytes = 3 instructions back)
  bne s3, x0, loop    # if s2 < s3, branch back to 1
  la s2, message

  addi s4, x0, 0
  # addi s4, x0, 0
  lui s5, 0x3ffff
sleep:
  addi s4, s4, 1
  blt s4, s5, sleep

  j loop

  li a7, 93
  li a0, 13
  ecall

# .section .rodata
message:
  .string "Hello, world!\n"
