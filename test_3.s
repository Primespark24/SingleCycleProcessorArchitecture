
main:
    addi $2, $0, 2
    addi $3, $0, 2
    # Comment out line 6 to test bgtz
    nor $2, $2, $3
    bgtz $2, end
    addi $3, $0, 3
end:xori $2, $3, 1 
    