# example assembly program
#
# syntax
#   register names $0 - $31 ($0 should always have 0 value)
#   one instruction per line, empty lines ignored
#   R-type: opcode reg, reg, reg
#   I-type: opcode reg, reg, immediate (immediate = offset in case of beq)
#   LW/SW special syntax:  opcode reg, offset(reg)
#   comments should have the first character as #

add $1, $2, $3
sub $3, $2, $1
lw $1, 16($3)
sw $0, 8($4)
beq $2, $3, 3
