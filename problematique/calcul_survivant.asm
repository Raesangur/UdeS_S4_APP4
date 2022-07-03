.data 0x10010000
si:   .word   0, 0, 0, 0
so:   .word   0, 0, 0, 0
met:  .word   4, 0, 4, 2,   3, 3, 3, 5,   3, 5, 3, 3,   2, 4, 2, 2
init: .word   0xfa, 0xfa, 0xfa, 0xfa



.text
.globl main

main:  
    # Avec la metrique initiale, le programme devrait retourner en sortie les valeurs 2, 0, 2, 2

    # Chargement des params pour appel de fonction
    la      $a0     met
    la      $a1     si
    la      $a2     so

    jal     CalculSurvivant             # CalculSurvivant(met, si, so)

    li      $v0     10
    syscall 


acs:
    li      $t0     4                   # uint32_t N = 4
    li      $t1     0                   # uint32_t i = 0

acs_loop:
    bgeu    $t1     $t0     acs_end     # for i < N

    lw      $s0     0($a0)              # get value of met[i]
    lw      $s1     0($a1)              # get value of sInput[i]

    addu    $s0     $s0     $s1         # temp = met[i] + sInput[i]

    lw      $s2     0($a2)              # t3 = *sOutput

    slt     $s1     $s0     $s2         # mask (1 when $s0 < $s2)
    movn    $s2     $s0     $s1         # overwrite masked values of $s2 with values from $s0
    sw      $s2     0($a2)              # sOutput = overwritten values


acs_eol:
    addiu   $a0     $a0     16          # update address of met[i]
    #addiu   $a1     $a1     16          # update address of sInput[i]
    addiu   $t1     $t1     1           # i++
    j       acs_loop

acs_end:
    jr      $ra
    

CalculSurvivant:
    la      $t0     init
    lw      $s0     0($t0)
    sw      $s0     0($a2)		#so = [250, 250, 250, 250]

    # push $t0 & $t1 + $ra on stack
    subi    $sp     $sp     4           # allocate space on the stack for 1 32-bits variable
    sw      $ra     0($sp)

    # push arguments
    jal     acs                         # acs()

    # load $t0, $t1, $t2 & $ra from stack
    lw      $ra     0($sp)
    addiu   $sp     $sp     4           # Free space on the stack

    # return
    jr      $ra

