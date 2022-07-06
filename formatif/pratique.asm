.eqv ARRAY_SIZE 7

.data
arr:    .word 1, 5, 7, 0, 3, 2, 6      # short arr[7]


.text
.globl main

main:
    # load parameters array and size of array
    la      $a0     arr
    li      $a1     ARRAY_SIZE

    # sort array
    jal     bubble_sort                 # bubble_sort(arr, ARRAY_SIZE)

    # exit program
    li      $v0     10
    syscall



# Swap two values pointed by input pointers
swap:
    lw      $t0     0($a0)              # data of first  pointer in temporary
    lw      $t1     0($a1)              # data of second pointer in temporary

    sw      $t1     0($a0)              # data of second temporary in first  pointer
    sw      $t0     0($a1)              # data of first  temporary in second pointer

    jr      $ra                         # return


bubble_sort:
    li      $t0     0                   # i = 0
    subi    $t2     $a1     1           # l = n - 1

sort_out:
    beq     $t0     $t2     sort_end    # for (i = 0; i < n - 1; i++)

    # prepare for inner loop
    li      $t1     0                   # j = 0
    subu    $t3     $t2     $t1         # k = n - 1 - i

    addiu   $t0     $t0     1           # i++

sort_in:
    beq     $t1     $t3     sort_in_end # for (j = 0; j < n - 1 - i; j++)

    # get addresses of the elements to compare
    sll     $t4     $t1     2
    addu    $t4     $a0     $t4         # &arr[j]
    
    addiu   $t1     $t1     1           # j++

    # compare elements
    lw      $t6     0($t4)
    lw      $t7     4($t4)

    ble     $t6     $t7     sort_in     # need to swap:
    addiu   $t5     $t4     4           # &arr[j + 1] ; address of second element
    # fill stack
    # need to save $ra, $a0 & $a1, and $t0 to $t3; $t4 to $t7 are no longer needed
    subiu   $sp     $sp     28          # allocate space on stack for 7 variables
    sw      $ra     24($sp)
    sw      $a1     20($sp)
    sw      $a0     16($sp)
    sw      $t3     12($sp)
    sw      $t2      8($sp)
    sw      $t1      4($sp)
    sw      $t0      0($sp)

    # push parameters
    move    $a0     $t4
    move    $a1     $t5

    jal     swap                        # swap elements

    # pop stack elements
    lw      $t0      0($sp)
    lw      $t1      4($sp)
    lw      $t2      8($sp)
    lw      $t3     12($sp)
    lw      $a0     16($sp)
    lw      $a1     20($sp)
    lw      $ra     24($sp)
    addiu   $sp     $sp     28          # free space on stack

    j       sort_in


sort_in_end:
    j       sort_out

sort_end:
    jr      $ra                         # return