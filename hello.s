.global _start

# Compile-time constants
.equ UART_BASE_ADDR, 0x10000000
# QEMU Test Finisher interface
# https://github.com/qemu/qemu/blob/master/include/hw/misc/sifive_test.h
.equ VIRT_TEST, 0x100000
.equ FINISHER_PASS, 0x5555

_start:
  # set s1 to the output address
  li s1, UART_BASE_ADDR
  # set s2 to the input address
  la s2, message    # s2 := <message>
  # s3 is the sum counter, set to zero
  addi s3, x0, 0

  # newline char code to s11, also the 10 base
  addi s11, x0, 10
  # first char after numbers
  addi s10, x0, 58

loop_lines:

  addi t1, x0, 0 # will be first number
  addi t2, x0, 0 # will be last number
  
  loop_chars:
    # load byte to s4 from the address in s2 (the input address)
    lb s4, 0(s2)      # s4 := (s2)
    # add one to the input address
    addi s2, s2, 1    # s2 := s2 + 1
    # finish processing if at the end of input
    beq s4, x0, end_of_input
    # finish processing if at the end of line
    beq s4, s11, end_of_line
    # skip if not a number
    bge s4, s10, loop_chars

    # update last and first number variables
    addi t2, s4, 0
    bne t1, x0, loop_chars
    addi t1, s4, 0
    j loop_chars

  end_of_line:
    # print calibration value for the line
    sb t1, 0(s1)
    sb t2, 0(s1)
    sb s11, 0(s1)
    
    # convert to numbers
    addi t1, t1, -48 # 48 = '0'
    addi t2, t2, -48

    # t3 = 10 * t1 + t2
    mul t1, t1, s11
    add t3, t1, t2

    # add to the sum
    add s3, s3, t3
    j loop_lines

end_of_input:
  # Print the result by calculating it into "stack" backwards first

  la t2, stack
  addi s2, t2, 0

  inputloop:
    remu t1, s3, s11
    addi t1, t1, 48
    sb   t1, 0(s2)
    addi s2, s2, 1
    divu s3, s3, s11
    bne  s3, x0, inputloop

  outputloop:
    addi s2, s2, -1
    lb   t1, 0(s2)
    sb   t1, 0(s1)
    bne  s2, t2, outputloop

  sb s11, 0(s1)

  # exit gracefully
  li s0, FINISHER_PASS
  li s1, VIRT_TEST
  sw s0, 0(s1)

message:
  .string "1abc2
pqr3stu8vwx
a1b2c3d4e5f
treb7uchet
"

stack:
