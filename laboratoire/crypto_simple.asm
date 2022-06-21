# crypto_simple.s
# Programme exemple programmation architecture MIPS
# D. Dalle révision août 2015
# Dept. GE & GI U. de S. 
#
# Reference laboratoire No 1 APP 4 S4 g. info 2020 b
#
# Programme concu pour execution dans un simulateur uniquement.
# Fonction: code assembleur MIPS de demonstration d'une
#           fonction de cryptage simple par des fonction XOR
#           appliquees bit a bit, mots par mot entre les donnees
#           et des valeurs (la table de cryptage) dans un tableau.
#           (Méthode "one time pad")
# Execution: le programme affiche la chaine ascii avant le cryptage
#           et repete l'affichage apres cryptage-decryptage: la chaine
#           affichee sera la meme.
#           Voir les structures de données dans les fenetres du simulateur
#           pour observer les données cryptees.
#           changer les valeurs au besoin.
# Revision  22 aout 2013, 27 aout 2015 commentaires
#
# Notes sur les donnees:
# Les directive .align 5 sont presentes pour  aligner lisiblement les debuts de structures
# dans la fenetre d'affichage du simulateur MARS.
# Les donnees  telles que .word 0x00000100,  0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF
# sont inseree uniquement pour assurer un caractere nul et 
# afficher un patron reconnaissable dans la fenetre du simulateur
# (ne sont pas necessaires pour la fonctionnalite du programme...)
#
# Notes sur le code:
# Ce code est volontairement ecrit sans utiliser le recours aux appels de fonctions
# Un codage avec appel de fonction pour le cryptage reduirait la longueur du code.
# (exercice suggere..)

.data
# codes ascii du message a crypter dans un format de chaine delimitee par caractere nul
chaine:
.asciiz  "Chaine de caractere cryptee par la methode <<one-time pad>> \n"

.align  5
delimiteur1:   .word 0x00000100,  0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF 
.align  5
# Espace pour contenir le message clair a crypter
messageclair:  .space  64
.align 5
delimiteur2:     .word 0x00000200,  0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF  
.align 5
# Espace pour contenir le message apres cryptage
messagecrypte:  
#initialement nulle pour tests (64 octets)
.byte 0,0,0,0, 0,0,0,0,    0,0,0,0, 0,0,0,0,   0,0,0,0, 0,0,0,0,   0,0,0,0, 0,0,0,0
.byte 0,0,0,0, 0,0,0,0,    0,0,0,0, 0,0,0,0,   0,0,0,0, 0,0,0,0,   0,0,0,0, 0,0,0,0

.align 5
delimiteur3:     .word 0x00000300,  0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF  
.align 5
# Espace pour contenir le message apres decryptage
messagedecrypte: .space  64

.align 5
delimiteur4:     .word 0x00000400,  0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF  
.align 5
# Espace pour contenir la table de donnees aleatoires
tabalea_test:
#initialement nulle pour tests (64 octets) ne fait aucyn cryptage...
.byte 0,0,0,0,   0,0,0,0,   0,0,0,0,   0,0,0,0,   0,0,0,0, 0,0,0,0,   0,0,0,0,   0,0,0,0
.byte 0,0,0,0,   0,0,0,0,   0,0,0,0,   0,0,0,0,   0,0,0,0, 0,0,0,0,   0,0,0,0,   0,0,0,0

tabalea:
#valeurs provenant d'un tirage pseudo aleatoire (64 octets, soit 16 mots)
.word    0x861B6DB6, 0x8F88F8A2, 0x3C4E68E9, 0x8D007E7D, 0x464D097B, 0x2C1F5E08, 0x4CC77329, 0x7D2AC0FC
.word    0x314A83AF, 0xACB79DD9, 0x9BC43DBF, 0xEAE0F43D, 0x811E19B6, 0xA2121FBD, 0x1CFE33D3, 0x7CE5D9A9
.align  5
.word 0x77777777, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF,

# Debut de la section code
    .text
    .globl main
main:
    li   $v0 4           # code pour syscall (4: afficher chaîne) 
    la   $a0 chaine      # chaine entree
    syscall              # invoque directive pour afficher chaine

# transfert de la chaine (delimitee par 0) dans l'espage message
    la   $t0 chaine      # initialise pointeur  caracteres entree
    la   $t1 messageclair # initialise pointeur  espace message clair
    lb   $t3 0($t0)      # charge un premier caractere
while1:                  # transfert de la chaine dans l'espage message
    beq  $t3 $zero finwh1
    sb   $t3 0($t1)      # memorise la sortie		
    addi $t0 $t0 1       # increment indice chaine
    addi $t1 $t1 1       # increment indice message
    lb   $t3 0($t0)      # charge caractere suivant
    j while1
finwh1:
    sb  $t3 0($t1)       # transfert dernier caractere (nul)
	
    
# cryptage de tout l'espage message
    la   $t0 messageclair  # initialise pointeur message a crypter
    la   $t1 messagecrypte # initialise pointeur message crypte
    la   $t2 tabalea       # initialise pointeur  tabalea
    

    addi $t3 $0, -64    # charge decompteur pour controle de boucle	
while2:
    beq  $t3 $zero finwh2
    lb   $t4 0($t0)      # caractere a crypter
    lb   $t5 0($t2)      # code aleatoire
    xor  $t6, $t4, $t5   # evaluer valeur cryptee
    sb   $t6 0($t1)      # memoriser la sortie cryptee	
	
    addi $t0 $t0 1       # increment indice entree
    addi $t1 $t1 1       # increment indice sortie
    addi $t2 $t2 1       # increment indice tabalea
    addi $t3 $t3 1       # increment compteur 
    j while2
finwh2:


# decryptage de tout l'espage message crypte
# cet algorithme revient a appliquer le meme algorithme que le cryptage

    la   $t0 messagecrypte   # initialise pointeur message a crypter
    la   $t1 messagedecrypte # initialise pointeur message crypte
    la   $t2 tabalea         # initialise pointeur  tabalea
 
    addi   $t3 $0, -64       # charge decompteur pour controle de boucle	
while3:
    beq  $t3 $zero finwh3
    lb   $t7 0($t0)      # caractere a decrypter
    lb   $t4 0($t2)      # code aleatoire
    xor  $t5, $t7, $t4   # evaluer valeur cryptee
    sb   $t5 0($t1)      # memoriser la sortie decryptee
	
    addi $t0 $t0 1       # increment indice entree
    addi $t1 $t1 1       # increment indice sortie
    addi $t2 $t2 1       # increment indice tabalea
    addi $t3 $t3 1       # increment compteur 
    j while3
finwh3:
   
    li  $v0  4           # code pour syscall (4: afficher chaîne)
    la  $a0  messagedecrypte
    syscall 
    
    li  $v0  10          # exit
    syscall
    
#   fin du code
    
    
    
