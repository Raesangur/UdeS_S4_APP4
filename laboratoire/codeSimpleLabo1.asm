# calculs_de_base.asm
# Programme servant d'exemple pour organisation avec instructions R seules
# M.-A. Tétrault
# Dept. GE & GI U. de S. 
#
# Reference laboratoire No 1 APP 4 S4 g. info 2021
#
# Programme servant à valider la procédure d'encodage en langage machine et 
# comme comportement initial au processeur simplifié.
# 
# Il n'y a pas d'objectifs particulier, autre que changer les valeurs
# dans le banc de registres.
# 
# Code limité aux instruction supportées au laboratoire 1:
# and
# or
# nor
# add
# sll
# srl
#

# Debut de la section code
.text
.globl main
main:
    # Initialisation sans instructions immédates
    nor $t0, $zero, $zero # mettre $t0 à 0xFFFF_FFFF
    srl $t1, $t0, 31	  # mettre 0x01 dans $t1
    srl $t2, $t0, 29	  # mettre 0x07 dans $t2
    sll $t3, $t2, 5		  # valeur 0xE0 dans $t3

    # Instructions R pour valider le processeur du labo 1
    add $t4, $t1, $t2
    or  $t5, $t1, $t3
    and $t6, $t5, $t2

    nor $a0, $zero, $zero

    # Syscall, pour arrêter le simulateur MARS, et compatible
    # avec le VHDL.
    # mettre $v0 à 10 et appeler syscall
    # addiu  $v0, $zero, 10 # non supporté au labo 1...
    add $v0, $t2, $t1	# 7+1 = 0x08
    add $v0, $v0, $t1	# 8+1 = 0x09
    add $v0, $v0, $t1	# 9+1 = 0x0A.. valeur voulue
    syscall             # fin du programme
