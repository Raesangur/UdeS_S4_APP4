# TestProcesseurs.asm
# Code pour tester les architectures mips
# M-A Tetrault Mars 2020
# Dept. GE & GI U. de S. 
#
# Reference laboratoire No 1 APP 4 S4 g. info 2020 b
#
# Fonction: 
# Execution: 
#
# Ce code contient les pseudo instructions deja developpees en instructions normales
.data 0x10010000

vec_entree: .word 1,2,3,4
mat_entree: .word 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
vec_sortie: .word 0,0,0,0


.text 0x400000
.eqv N 4

main:
    li $s0, 0 # i = 0
    li $s2, N
    la $t5  vec_entree
    la $t6  vec_sortie
    la $t7  mat_entree

boucle_externe:
    beq  $s0, $s2, finBoucleExterne
    add  $t0, $zero, $zero       # y[i] = 0
    li   $s1, 0                  # j = 0

    boucle_interne:
        beq $s1, $s2, finBoucleInterne # for j < 4
        
        sll $t4, $s1, 2          # decalage en octets de x[j]

        add $at  $t4  $t5
        lw  $t1, 0($at)          # lecture de x[j]
        # nop
        
        # Lecture de A[i][j]
                                 # indice == i + j*N et N == 4
        sll $t4, $s1, 2          # i*4
        add $t4, $t4, $s0        # i*4+j
        sll $t4, $t4, 2          # decalage i*4+j (en octets)

        add $at  $t4  $t7
        lw  $t2, 0($at)          #lecture de A[i][j]
        # nop
        
        multu $t1, $t2           # A[i][j] * x[j]
        mflo $t1
        
        add $t0, $t0, $t1        # y[i] = y[i] + A[i][j] * x[j]
        
        addi $s1, $s1, 1         # j++

        j boucle_interne         # 2 instructions + forward
        # nop
        # nop
        # nop


finBoucleInterne:
    sll $t1, $s0, 2         # decalage en octets de y[i]

    add $at  $t4  $t6
    sw  $t0, 0($at) # ecriture de y[i]

    addi $s0, $s0, 1        # i++

    j boucle_externe
    # nop
    # nop
    # nop

finBoucleExterne:
    addi $v0, $zero, 10     # fin du programme
    syscall
    # nop
    # nop
    # nop
    # nop



