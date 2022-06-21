.data

si:  .word   0, 0, 0, 0
so:  .word   0, 0, 0, 0
met: .word   4, 3, 3, 2,   0, 3, 5, 4,   4, 3, 3, 2,   2, 5, 3, 2   # valeurs trouvees en executant le programme initial



.text
.globl main

main:  
    # Avec la metrique initiale, le programme devrait retourner en sortie les valeurs 2, 0, 2, 2

    # Chargement des params pour appel de fonction
    la      $a0     met
    la      $a1     si
    la      $a2     so

    jal     CalculSurvivant             # CalculSurvivant(met, si, so)

    # Comparaison des donnees avec les donnees prevues
    li      $v0     1                   # print integer
    la      $t0     so
    lw      $a0     0($t0)
    syscall                             # print (met[0])
    li      $a0     32
    li      $v0     11
    syscall                             # print(" ")
    li      $v0     1
    lw      $a0     4($t0)
    syscall                             # print (met[1])
    li      $a0     32
    li      $v0     11
    syscall                             # print(" ")
    li      $v0     1
    lw      $a0     8($t0)
    syscall                             # print (met[2])
    li      $a0     32
    li      $v0     11
    syscall                             # print(" ")
    li      $v0     1
    lw      $a0     12($t0)
    syscall                             # print (so[3])
    li      $v0     11
    li      $a0     10
    syscall                             # print(\n)


    # Avec la sortie précédente, le programme devrait retourner en sortie les valeurs 3, 2, 3, 4
    # Chargement des params pour appel de fonction
    la      $a0     met
    la      $a1     si
    la      $a2     so

    # Chargement de l'entrée
    li      $t0     2
    sw      $t0     0($a1)
    li      $t0     0
    sw      $t0     4($a1)
    li      $t0     2
    sw      $t0     8($a1)
    li      $t0     2
    sw      $t0     12($a1)

    jal     CalculSurvivant             # CalculSurvivant(met, si, so)

    # Comparaison des donnees avec les donnees prevues
    li      $v0     1                   # print integer
    la      $t0     so
    lw      $a0     0($t0)
    syscall                             # print (so[0])
    li      $a0     32
    li      $v0     11
    syscall                             # print(" ")
    li      $v0     1
    lw      $a0     4($t0)
    syscall                             # print (so[1])
    li      $a0     32
    li      $v0     11
    syscall                             # print(" ")
    li      $v0     1
    lw      $a0     8($t0)
    syscall                             # print (so[2])
    li      $a0     32
    li      $v0     11
    syscall                             # print(" ")
    li      $v0     1
    lw      $a0     12($t0)
    syscall                             # print (so[3])
    li      $v0     11
    li      $a0     10
    syscall                             # print(\n)
    
    # Avec la metrique decalee, le programme devrait retourner en sortie les valeurs 5, 3, 5, 5
    # Chargement des params pour appel de fonction
    la      $a0     met
    la      $a1     si
    la      $a2     so

    # Chargement de l'entrée
    li      $t0     3
    sw      $t0     0($a1)
    li      $t0     2
    sw      $t0     4($a1)
    li      $t0     3
    sw      $t0     8($a1)
    li      $t0     4
    sw      $t0     12($a1)

    jal     CalculSurvivant             # CalculSurvivant(met, si, so)

    # Comparaison des donnees avec les donnees prevues
    li      $v0     1                   # print integer
    la      $t0     so
    lw      $a0     0($t0)
    syscall                             # print (so[0])
    li      $a0     32
    li      $v0     11
    syscall                             # print(" ")
    li      $v0     1
    lw      $a0     4($t0)
    syscall                             # print (so[1])
    li      $a0     32
    li      $v0     11
    syscall                             # print(" ")
    li      $v0     1
    lw      $a0     8($t0)
    syscall                             # print (so[2])
    li      $a0     32
    li      $v0     11
    syscall                             # print(" ")
    li      $v0     1
    lw      $a0     12($t0)
    syscall                             # print (so[3])
    li      $v0     11
    li      $a0     10
    syscall                             # print(\n)
        

    # exit(1)
    li      $v0     10
    syscall 





# Utilise $t0, $t1, $t2, $t3
acs:
    li      $t0     4                   # uint32_t N = 4
    li      $t1     0                   # uint32_t j = 0

acs_loop:
    bgeu    $t1     $t0     acs_end     # for i < N

    lw      $t2     0($a0)              # get value of met[j]
    lw      $t3     0($a1)              # get value of sInput[j]

    addu    $t2     $t2     $t3         # temp = met[j] + sInput[j]

    lw      $t3     0($a2)              # t3 = *sOutput

    bleu    $t3     $t2     acs_eol     # if (t3 >= t2): goto eol
                                        # else:
    sw      $t2     0($a2)              # sOutput = temp


acs_eol:
    addiu   $a0     $a0     4           # update address of met[j]
    addiu   $a1     $a1     4           # update address of sInput[j]
    addiu   $t1     $t1     1           # j++
    j       acs_loop

acs_end:
    jr      $ra
    


# Utilise $t0, $t1, $t2, $t3, $t4, $t5 & $t6
CalculSurvivant:
    move    $t4     $a0                 # met
    move    $t5     $a1                 # sInput
    move    $t6     $a2                 # sOutput

    li      $t0     4                   # uint32_t N = 4
    li      $t1     0                   # uint32_t i = 0

cs_loop:
    bgeu    $t1     $t0     cs_end      # for i < N

    li      $t2     250                 # $t2 = 250
    sw      $t2     0($t6)              # sOutput[i] = $t2

    move    $t2     $t4                 # $t2 = $a0
    sll     $t3     $t1     4           # i * N * sizeof(uint32_t)
    addu    $a0     $t2     $t3         # &met[i * N * sizeof(uint32_t)]

    # push $t0 & $t1 + $ra on stack
    subiu   $sp     $sp     12           # Allocate space on the stack for 3 32-bits variables
    sw      $t0     0($sp)
    sw      $t1     4($sp)
    sw      $ra     8($sp)

    # push arguments
    move    $a1     $t5                 # sInput
    move    $a2     $t6                 # sOutput

    jal     acs                         # acs()

    # load $t0, $t1, $t2 & $ra from stack
    lw      $ra     8($sp)
    lw      $t1     4($sp)
    lw      $t0     0($sp)
    addiu   $sp     $sp     12           # Free space on the stack

    addiu   $t6     $t6     4           # update address of sOutput

    addiu   $t1     $t1     1           # i++
    j       cs_loop

cs_end:
    jr      $ra

