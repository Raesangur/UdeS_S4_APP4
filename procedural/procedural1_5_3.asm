.data
valeurs: .word 4, 20, 6, 2, 1, 1, 10, 15, 8, 36, 5, 7
bornes:  .word 2, 5	# 4 bytes per word



.text

.globl main
main:
	add  $t2, $zero, $zero	# s = 0
	la   $t0, valeurs
	la   $t1, bornes
	lw   $t3, 0($t1)	# n = bornes[0]
	sll  $t6, $t3, 2
	add  $t0, $t0, $t6
	lw   $t6, 4($t1)
	
boucle:
	bgt  $t3, $t6, exit	# while (n <= bornes[1])
	lw   $t5, 0($t0)
	add  $t2, $t2, $t5	# s += valeurs[n]
	addi $t0, $t0, 4	# n += 1
	addi $t3, $t3, 1
	j    boucle
	
exit:
	move $a0, $t2
	li   $v0, 10		# exit program
	syscall
	
	
	
