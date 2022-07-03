.data 0x10010000
si:   .word   2, 0, 2, 2
so:   .word   0, 0, 0, 0
met:  .word   4, 3, 3, 2,   0, 3, 5, 4,   4, 3, 3, 2,   2, 5, 3, 2 
init: .word   0xfa, 0xfa, 0xfa, 0xfa

.text
.globl main

main:  
    # Avec la metrique initiale, le programme devrait retourner en sortie les valeurs 2, 0, 2, 2
    # Avec 2, 0, 2, 2 en entree, le programme devrait retourner en sortie les valeurs 3, 2, 3, 4

    # Chargement des params pour appel de fonction
    la      $a0     met
    la      $a1     si
    la      $a2     so

    jal     CalculSurvivant             # CalculSurvivant(met, si, so)

    li      $v0     10
    syscall 

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


acs:
    li      $t0     4                   # uint32_t N = 4
    li      $t1     0                   # uint32_t i = 0
    
    lw      $s1     0($a1)              # get value of sInput

acs_loop:
    bgeu    $t1     $t0     acs_end     # for i < N

    lw      $s0     0($a0)              # get value of met[i]
    addu    $s0     $s0     $s1         # temp = met[i] + sInput[i]

    lw      $t2     0($s0)              # lw à remplacer par le opcode du sml : 
    #sml     $t2     $s0                 # new instruction: extracts smallest value from vector

    sw      $t2     0($a2)              # sOutput = overwritten values


acs_eol:
    addiu   $a0     $a0     16          # update address of met[i]
    addiu   $a2     $a2     4
    addiu   $t1     $t1     1           # i++
    j       acs_loop

acs_end:
    jr      $ra




