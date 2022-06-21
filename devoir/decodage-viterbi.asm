.data

# Message de test pre-encode
bitsrc .word 5, 6, 2, 3, 1, 7, 0, 5, 3, 1, 2, 6

# Metriques pour le trilli serre
pr1 .word 0, 7, 6, 1,   5, 2, 3, 4,   0, 7, 6, 1,   5, 2, 3, 4
pr2 .word 0, 0, 7, 7,   6, 6, 1, 1,   5, 5, 2, 2,   3, 3, 4, 4



.text
.globl main


# Utilise $t0, $t1
popcount4:
    srl     $t0     $a0     3       # a >> 3
    andi    $t0     $t0     1       # (a >> 3) & 1

    srl     $t1     $a0     2       # a >> 2
    andi    $t1     $t1     1       # (a >> 2) & 1

    addu    $t0     $t0     $t2     # ((a >> 3) & 1) + ((a >> 2) & 1)

    srl     $t1     $a0     1       # a >> 1
    andi    $t1     $t1     1       # (a >> 1) & 1

    addu    $t0     $t0     $t2     # ((a >> 3) & 1) + ((a >> 2) & 1) + ((a >> 1) & 1)

    andi    $a0     $a0     1       # a & 1
    
    addu    $v0     $t0     $a0     # ((a >> 3) & 1) + ((a >> 2) & 1) + ((a >> 1) & 1) + (a & 1)

	jr      $ra                     # return



