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

  # Reset the storage here
  
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
    bge s4, s10, handle_letter

    # update last and first number variables
    addi t2, s4, 0
    bne t1, x0, loop_chars
    addi t1, s4, 0
    j loop_chars

    handle_letter:
      la t3, numbers
      loop_numbers:
        # t3 points to the beginning of the current number part
        # load how far we are already to the string, t4 points to the char that needs to be checked
        sb s4, 0(s1) # debug
        lb t4, 0(t3)
        sb t4, 0(s1) # debug
        add t4, t4, t3
        addi t4, t4, 1
        lb t4, 0(t4) # t4 is the actual character
        sb t4, 0(s1) # debug
        sb s11, 0(s1) # debug
        beq t4, s4, correct
          # incorrect, set counter to 0
          sb x0, 0(t3)
          j end_of_number
        correct:
          sb t4, 0(s1) # debug
          sb s11, 0(s1) # debug
          # correct, increase counter
          lb t4, 0(t3)
          addi t4, t4, 1
          sb t4, 0(t3)
          # check if the number is done now
          add t4, t4, t3 # t4 is pointer to next char
          addi t4, t4, 1
          lb t5, 0(t4)
          sb t5, 0(s1) # debug
          sb t5, 0(s1) # debug
          sb t5, 0(s1) # debug
          sb s11, 0(s1) # debug
          bne t5, x0, end_of_number
            # number is done
            # reset counter
            sb x0, 0(t3)
            # load the numeric value and update t1/t2
            lb t5, 1(t4)
            addi t2, t5, 0
            bne t1, x0, end_of_number
            addi t1, t5, 0

        end_of_number:
          # move forward until 0x00 char, t4 will be the char after
          addi t4, t3, 1
          loop_until_at_end:
            lb t5, 0(t4)
            addi t4, t4, 1
            bne t5, x0, loop_until_at_end
          addi t3, t4, 0
          lb t4, 0(t3)
          addi t3, t3, 1
          bne t4, s11, loop_numbers

      j loop_chars

  end_of_line:
    # print calibration value for the line
    sb s10, 0(s1)
    sb s10, 0(s1)
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

# this part of memory is used both as reference and variable storage
# format: Atexttext0BAtexttext0BAtexttext0B
# A = 1 byte, counter of how far in the string we are. Initially 0b0000
# text = arbitrary length ASCII string: the characters of the name
# 0 = 1 byte, always 0b0000
# B = 1 byte, uint of the numeric value for the name
# alignment not necessary, just making it easier to see where the stuff is
.balign 16, 0
numbers:
  .string "", "one", "1", "two", "2", "three", "3", "four", "4", "five", "5", "six", "6", "seven", "7", "eight", "8", "nine", "9", "\n"
  .string "two\x02"
  .string "three\x03"
  .string "four\x04"
  .string "five\x05"
  .string "six\06"
  .string "seven\07"
  .string "eight\08"
  .string "nine\09\0\n" # line break at the end

stack:
.skip 32, 0
# reserve 16 characters of space to store the number to output in reverse order

message:
  .string "two1nine
eightwothree
abcone2threexyz
xtwone3four
4nineeightseven2
zoneight234
7pqrstsixteen
"

