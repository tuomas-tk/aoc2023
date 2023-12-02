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
  la s2, message - 1    # s2 := <message>
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
    # add one to the input address (initial value is -1)
    addi s2, s2, 1    # s2 := s2 + 1
    # load byte to s4 from the address in s2 (the input address)
    lb s4, 0(s2)      # s4 := (s2)
    # finish processing if at the end of input
    beq s4, x0, end_of_input
    # finish processing if at the end of line
    beq s4, s11, end_of_line
    # special handling for letters
    bge s4, s10, handle_letter

    # update last and first number variables
    addi t2, s4, 0
    bne t1, x0, loop_chars
    addi t1, s4, 0
    j loop_chars

    handle_letter:

    la s5, numbers
    loop_numbers:
      # s5 points to the beginning of the current number part
      # t3 is 0..n counter of how far into the string we have looped
      addi t3, x0, 0
      loop_name:
        # t4 is the charcode from target string
        add t4, t3, s5
        lb t4, 0(t4)
        # t5 is the charcode from input string
        add t5, t3, s2
        lb t5, 0(t5)

        # when they match, move to next char
        bne t4, t5, no_match
          addi t3, t3, 1
          j loop_name
        no_match:

        # when the target ends, we have found the whole name
        bne t4, x0, incorrect
          # load the numeric value and update t1/t2
          add t4, t3, s5
          lb t4, 1(t4)
          addi t2, t4, 0
          bne t1, x0, end_of_number
          addi t1, t4, 0
          j end_of_number

        # target and input were different, just move to next number candidate
        incorrect:
          j end_of_number

      end_of_number:
        # here we can assume that
        #  s5 points to the beginning of the current number part
        #  t3 is a 0..n counter somewhere in the current number, might be at the zero char at the end
        # move forward until 0x00 char, t4 will be the char after
        add t4, s5, t3
        loop_until_at_end:
          lb t5, 0(t4)
          addi t4, t4, 1
          bne t5, x0, loop_until_at_end
        # now t4 is pointer to the value char after the string
        # set s5 to the start of the next number section
        addi s5, t4, 1
        # check if the next sections starts with \n instead of a letter char
        lb t4, 0(s5)
        bne t4, s11, loop_numbers

    j loop_chars

  end_of_line:
    # debug: print calibration value for the line
    sb t1, 0(s1)
    sb t2, 0(s1)
    sb s11, 0(s1)
    
    # convert chars to numbers
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

# format: texttext0Dtexttext0Dtexttext0D
# text = n bytes, arbitrary length ASCII string: the characters of the name
# 0    = 1 byte,  always 0b0000, i.e. zero-termination char for the name
# D    = 1 byte,  ASCII digit corresponding to the name before it
# alignment not necessary, just making it easier to see where the stuff is in memory dump
.balign 16, 0
numbers:
  .string "one", "1two", "2three", "3four", "4five", "5six", "6seven", "7eight", "8nine", "9\n" # line break at the end

# reserve 16 characters of space to store the number to output in reverse order
stack:
  .skip 16, 0

# The input to the puzzle, also compiled into the program
# There needs to be a line break at the end of the last line
message:
  .string "two1nine
eightwothree
abcone2threexyz
xtwone3four
4nineeightseven2
zoneight234
7pqrstsixteen
"

