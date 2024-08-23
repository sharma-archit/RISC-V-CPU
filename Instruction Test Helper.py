# Define the RISC-V instruction set with funct and opcode values
instruction_set = {
    'ADD': {'type': 'R', 'funct7': '0000000', 'funct3': '000', 'opcode': '0110011'},
    'SUB': {'type': 'R', 'funct7': '0100000', 'funct3': '000', 'opcode': '0110011'},
    'AND': {'type': 'R', 'funct7': '0000000', 'funct3': '111', 'opcode': '0110011'},
    'OR':  {'type': 'R', 'funct7': '0000000', 'funct3': '110', 'opcode': '0110011'},
    'ADDI': {'type': 'I', 'funct3': '000', 'opcode': '0010011'},
    'LW':   {'type': 'I', 'funct3': '010', 'opcode': '0000011'},
    'LH':   {'type': 'I', 'funct3': '001', 'opcode': '0000011'},
    'LB':   {'type': 'I', 'funct3': '000', 'opcode': '0000011'},
    'LHU':  {'type': 'I', 'funct3': '101', 'opcode': '0000011'},
    'LBU':  {'type': 'I', 'funct3': '100', 'opcode': '0000011'},
    'SW':   {'type': 'S', 'funct3': '010', 'opcode': '0100011'},
    'SH':   {'type': 'S', 'funct3': '001', 'opcode': '0100011'},
    'SB':   {'type': 'S', 'funct3': '000', 'opcode': '0100011'},
    'BEQ':  {'type': 'B', 'funct3': '000', 'opcode': '1100011'},
    'BNE':  {'type': 'B', 'funct3': '001', 'opcode': '1100011'},
    'BLT':  {'type': 'B', 'funct3': '100', 'opcode': '1100011'},
    'BGE':  {'type': 'B', 'funct3': '101', 'opcode': '1100011'},
    'BLTU': {'type': 'B', 'funct3': '110', 'opcode': '1100011'},
    'BGEU': {'type': 'B', 'funct3': '111', 'opcode': '1100011'},
    'LUI':  {'type': 'U', 'opcode': '0110111'},
    'AUIPC':{'type': 'U', 'opcode': '0010111'},
    'JAL':  {'type': 'J', 'opcode': '1101111'},
    'JALR': {'type': 'I', 'funct3': '000', 'opcode': '1100111'},
    # Add more instructions as needed
}

def get_binary_string(value, bits):
    return format(value, f'0{bits}b')

def create_instruction(instr, rs2=None, rs1=None, rd=None, imm=None):
    if instr not in instruction_set:
        raise ValueError(f"Instruction {instr} not supported")

    instr_type = instruction_set[instr]['type']
    opcode = instruction_set[instr]['opcode']
    funct3 = instruction_set[instr].get('funct3', '')
    funct7 = instruction_set[instr].get('funct7', '')

    if instr_type == 'R':
        rs2_bin = get_binary_string(rs2, 5)
        rs1_bin = get_binary_string(rs1, 5)
        rd_bin = get_binary_string(rd, 5)
        instruction = funct7 + rs2_bin + rs1_bin + funct3 + rd_bin + opcode

    elif instr_type == 'I':
        imm_bin = get_binary_string(imm, 12)
        rs1_bin = get_binary_string(rs1, 5)
        rd_bin = get_binary_string(rd, 5)
        instruction = imm_bin + rs1_bin + funct3 + rd_bin + opcode

    elif instr_type == 'S':
        imm_bin = get_binary_string(imm, 12)
        rs2_bin = get_binary_string(rs2, 5)
        rs1_bin = get_binary_string(rs1, 5)
        instruction = imm_bin[:7] + rs2_bin + rs1_bin + funct3 + imm_bin[7:] + opcode

    elif instr_type == 'B':
        imm_bin = get_binary_string(imm, 13)
        rs2_bin = get_binary_string(rs2, 5)
        rs1_bin = get_binary_string(rs1, 5)
        instruction = imm_bin[0] + imm_bin[2:8] + rs2_bin + rs1_bin + funct3 + imm_bin[8:12] + imm_bin[1] + opcode

    elif instr_type == 'U':
        imm_bin = get_binary_string(imm, 20)
        rd_bin = get_binary_string(rd, 5)
        instruction = imm_bin + rd_bin + opcode

    elif instr_type == 'J':
        imm_bin = get_binary_string(imm, 21)
        rd_bin = get_binary_string(rd, 5)
        instruction = imm_bin[0] + imm_bin[10:20] + imm_bin[9] + imm_bin[1:9] + rd_bin + opcode

    return instruction

# Get user input for multiple instructions
instructions = []
while True:
    instr = input("Enter the RISC-V instruction (or 'done' to finish): ").upper()
    if instr == 'DONE':
        break
    rs2 = rs1 = rd = imm = None

    if instruction_set[instr]['type'] in ['R', 'S', 'B']:
        rs2 = int(input("Enter the address for the second source register (0-31): "))
    if instruction_set[instr]['type'] in ['R', 'I', 'S', 'B']:
        rs1 = int(input("Enter the address for the first source register (0-31): "))
    if instruction_set[instr]['type'] in ['R', 'I', 'U', 'J']:
        rd = int(input("Enter the address for the destination register (0-31): "))
    if instruction_set[instr]['type'] in ['I', 'S', 'B', 'U', 'J']:
        imm = int(input("Enter the immediate value: "))

    binary_instruction = create_instruction(instr, rs2, rs1, rd, imm)
    instructions.append(binary_instruction)

# Write the binary instructions to the testbench file
testbench_file = "S:/RISC-V CPU/Project Files/cpuCore_tb.sv"
with open(testbench_file, 'r') as file:
    lines = file.readlines()

# Find the "initial begin" and "end" lines and overwrite anything between them
dbg_addr = 0
inside_initial_block = False
new_lines = []
for line in lines:
    if 'initial begin' in line:
        inside_initial_block = True
        new_lines.append(line)
        new_lines.append('\n    rst = 1;\n    dbg_wr_en = 0;\n    dbg_addr = 0;\n')
        new_lines.append(f'    dbg_instr = 32\'b{instructions[0]};\n')
        new_lines.append('    #(2*CLK_PERIOD)\n    dbg_wr_en = 1;\n    #CLK_PERIOD\n    dbg_wr_en = 0;\n    #CLK_PERIOD\n')
    elif 'end' in line and inside_initial_block:
        for instruction in instructions[1:]:
            dbg_addr += 4
            new_lines.append(f'    dbg_addr = {dbg_addr};\n')
            new_lines.append(f'    dbg_instr = 32\'b{instruction};\n')
            new_lines.append('    #(2*CLK_PERIOD)\n    dbg_wr_en = 1;\n    #CLK_PERIOD\n    dbg_wr_en = 0;\n    #CLK_PERIOD\n')
        new_lines.append('    rst = 0;\n\n')
        new_lines.append(line)
        inside_initial_block = False
    elif inside_initial_block:
        continue
    else:
        new_lines.append(line)

# Write the modified lines back to the file
with open(testbench_file, 'w') as file:
    file.writelines(new_lines)

print("Instructions written to the testbench file.")
