def get_binary_string(value, bits):
    return format(value, f'0{bits}b')

def create_instruction(instruction_set, instr, rs2=None, rs1=None, rd=None, imm=None):
    if instr not in instruction_set:
        raise ValueError(f"Instruction {instr} not supported")

    instr_type = instruction_set[instr]['type']
    opcode = instruction_set[instr]['opcode']
    funct3 = instruction_set[instr].get('funct3', '')
    funct7 = instruction_set[instr].get('funct7', '')
    special = instruction_set[instr].get('special', False)

    if instr_type == 'R':
        rs2_bin = get_binary_string(rs2, 5)
        rs1_bin = get_binary_string(rs1, 5)
        rd_bin = get_binary_string(rd, 5)
        instruction = funct7 + rs2_bin + rs1_bin + funct3 + rd_bin + opcode

    elif instr_type == 'I':
        if special:
            if instr == 'SRAI':
                imm_bin = '0100000' + get_binary_string(imm, 5)
            else:
                imm_bin = '0000000' + get_binary_string(imm, 5)
        else:
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

# Function to convert a 32-bit unsigned integer to a signed integer
def to_signed(value):
    if value & (1 << 31):  # Check if the MSB is set
        return value - (1 << 32)
    return value

def get_valid_input(prompt, min_value, max_value):
    # Function to get a valid input within a specified range
    while True:
        try:
            value = int(input(prompt))
            if min_value <= value <= max_value:
                return value
            else:
                print(f"Please enter a value between {min_value} and {max_value}.")
        except ValueError:
            print("Invalid input. Please enter an integer.")