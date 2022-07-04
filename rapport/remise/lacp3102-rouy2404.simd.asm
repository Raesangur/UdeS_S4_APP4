.data 0x10010000
si:   .word   2, 0, 2, 2
so:   .word   0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
met:  .word   4, 3, 3, 2,   0, 3, 5, 4,   4, 3, 3, 2,   2, 5, 3, 2 

.text
.globl main

main:
    la      $a0     met     # 2 instructions
    la      $a1     si
    la      $a2     so

    jal     acs             # acs(met, si, so)

    li      $v0     10
    syscall 


acs:
    li      $t0     4                   # N = 4
    li      $t1     0                   # i = 0
    
    lwv     $s1     0($a1)              # get value of sInput

acs_loop:
    bgeu    $t1     $t0     acs_end     # for i < N

    lwv     $s0     0($a0)              # get value of met[i]
    addu    $s0     $s0     $s1         # temp = met[i] + sInput[i]

    sml     $t2     $s0                 # new instruction: extracts smallest value from vector

    sw      $t2     0($a2)              # sOutput = overwritten values

    addiu   $a0     $a0     16          # update address of met[i]
    addiu   $a2     $a2     4           # update address of so
    addiu   $t1     $t1     1           # i++
    j       acs_loop

acs_end:
    jr      $ra
