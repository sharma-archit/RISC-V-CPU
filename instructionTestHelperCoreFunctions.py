def create_instruction(instruction_set, instr, rs2=None, rs1=None, rd=None, imm=None):
    if instr not in instruction_set:
        raise ValueError(f"Instruction {instr} not supported")

    # instr_type = instruction_set[instr]['type']
    opcode = instruction_set[instr]['opcode']
    funct3 = instruction_set[instr].get('funct3', '')
    funct7 = instruction_set[instr].get('funct7', '')
    special = instruction_set[instr].get('special', False)

    if opcode == '0110011':                     # R-type
        rs2_bin = get_binary_string(rs2, 5)
        rs1_bin = get_binary_string(rs1, 5)
        rd_bin = get_binary_string(rd, 5)
        instruction = funct7 + rs2_bin + rs1_bin + funct3 + rd_bin + opcode

    elif opcode == '1100111':                   # I-type
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

    elif opcode == '0100011':                   # S-type
        imm_bin = get_binary_string(imm, 12)
        rs2_bin = get_binary_string(rs2, 5)
        rs1_bin = get_binary_string(rs1, 5)
        instruction = imm_bin[:7] + rs2_bin + rs1_bin + funct3 + imm_bin[7:] + opcode

    elif opcode == '1100011':                   # B-type
        imm_bin = get_binary_string(imm, 13)
        rs2_bin = get_binary_string(rs2, 5)
        rs1_bin = get_binary_string(rs1, 5)
        instruction = imm_bin[0] + imm_bin[2:8] + rs2_bin + rs1_bin + funct3 + imm_bin[8:12] + imm_bin[1] + opcode

    elif opcode == '0110111':                   # U-type
        imm_bin = get_binary_string(imm, 20)
        rd_bin = get_binary_string(rd, 5)
        instruction = imm_bin + rd_bin + opcode

    elif opcode == '0010111':                   # J-type
        imm_bin = get_binary_string(imm, 20)
        rd_bin = get_binary_string(rd, 5)
        instruction = imm_bin + rd_bin + opcode

    elif opcode == '1101111':                   # JALR
        imm_bin = get_binary_string(imm, 21)
        rd_bin = get_binary_string(rd, 5)
        instruction = imm_bin[0] + imm_bin[10:20] + imm_bin[9] + imm_bin[1:9] + rd_bin + opcode

    elif opcode == '0001111':                   # FENCE
        imm_bin = imm
        rs1_bin = get_binary_string(rs1, 5)
        rd_bin = get_binary_string(rd, 5)
        instruction = imm_bin + rs1_bin + funct3 + rd_bin + opcode

    elif opcode == '1110011':                   # ECB
        imm_bin = get_binary_string(imm, 12)
        rs1_bin = get_binary_string(rs1, 5)
        rd_bin = get_binary_string(rd, 5)
        instruction = imm_bin + rs1_bin + funct3 + rd_bin + opcode

    return instruction

def to_signed(value):
    if value & (1 << 31):  # Check if sign bit is set
        return value - (1 << 32)
    return value

def get_valid_input(prompt, min_value, max_value):
    while True:
        try:
            value = int(input(prompt))
            if min_value <= value <= max_value:
                return value
            else:
                print(f"Please enter a value between {min_value} and {max_value}.")
        except ValueError:
            print("Invalid input. Please enter an integer.")

def get_binary_string(value, bits):
    if value < 0:
        value = (1 << bits) + value

    return format(value, f'0{bits}b')