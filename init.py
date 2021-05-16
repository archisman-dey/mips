# initialize instruction memory, data memory, and register files with zeros
zeros32 = "0" * 32 + "\n"
with open("instruction.mem", 'wb') as instruction_file:
    instruction_file.write(bytes(zeros32 * 256, 'utf-8'))

with open("data.mem", 'wb') as data_file: 
    data_file.write(bytes(zeros32 * 256, 'utf-8'))

with open("registers.mem", 'wb') as register_file:
    register_file.write(bytes(zeros32 * 32, 'utf-8'))

# parse assembly from test.asm and write to instruction file
asm = open("test.asm")
instruction_file = open("instruction.mem", 'r+b')

opcodes = {
    "add": b"000000",
    "sub": b"000000",
    "and": b"000000",
    "or" : b"000000",
    "slt": b"000000",
    "lw" : b"100011",
    "sw" : b"101011",
    "beq": b"000100"
}

functs = {
    "add": b"100000",
    "sub": b"100010",
    "and": b"100100",
    "or" : b"100101",
    "slt": b"101010"
}

def reg_to_5bit(reg):
    # $31 -> b"11111"
    return bytes("{:0>5b}".format(int(reg[1:])), 'utf-8')

def int_to_16bit(offset):
    return bytes("{:0>16b}".format(int(offset)), 'utf-8')

instructions = asm.readlines()
for instr in instructions:
    instr = instr.strip()

    if instr == "":
        continue
    if instr[0] == "#":
        continue

    instr = instr.replace(',', ' ').replace('(', ' ').replace(')', ' ').split()
    instr[0] = instr[0].lower()

    instruction_file.write(opcodes[instr[0]])

    if instr[0] in functs.keys():
        instruction_file.write(reg_to_5bit(instr[1]))
        instruction_file.write(reg_to_5bit(instr[2]))
        instruction_file.write(reg_to_5bit(instr[3]))
        instruction_file.write(b'00000')
        instruction_file.write(functs[instr[0]])

    if instr[0] in ["lw", "sw"]:
        instruction_file.write(reg_to_5bit(instr[3]))
        instruction_file.write(reg_to_5bit(instr[1]))
        instruction_file.write(int_to_16bit(instr[2]))

    if instr[0] == "beq":
        instruction_file.write(reg_to_5bit(instr[1]))
        instruction_file.write(reg_to_5bit(instr[2]))
        instruction_file.write(int_to_16bit(instr[3]))

    instruction_file.write(bytes("\n", 'utf=8'))

asm.close()
instruction_file.close()
