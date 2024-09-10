from instructionTestHelperCoreFunctions import create_instruction, get_valid_input
from instructionTestHelperGUI import update_register_grid, update_memory_grid, create_grid_window, update_register_values
import configparser

# Define the RISC-V instruction set with proper values
instruction_set = {
    'ADDI': {'type': 'I', 'funct3': '000', 'opcode': '0010011'},
    'SLTI': {'type': 'I', 'funct3': '010', 'opcode': '0010011'},
    'SLTIU': {'type': 'I', 'funct3': '011', 'opcode': '0010011'},
    'ANDI': {'type': 'I', 'funct3': '000', 'opcode': '0010011'},
    'ORI': {'type': 'I', 'funct3': '000', 'opcode': '0010011'},
    'XORI': {'type': 'I', 'funct3': '000', 'opcode': '0010011'},
    'SLLI': {'type': 'I', 'funct3': '001', 'opcode': '0010011', 'special': True},
    'SRLI': {'type': 'I', 'funct3': '101', 'opcode': '0010011', 'special': True},
    'SRAI': {'type': 'I', 'funct3': '101', 'opcode': '0010011', 'special': True},
    'LUI':  {'type': 'U', 'opcode': '0110111'},
    'AUIPC':{'type': 'U', 'opcode': '0010111'},
    'ADD': {'type': 'R', 'funct7': '0000000', 'funct3': '000', 'opcode': '0110011'},
    'SLT': {'type': 'R', 'funct7': '0000000', 'funct3': '010', 'opcode': '0110011'},
    'SLTU': {'type': 'R', 'funct7': '0000000', 'funct3': '011', 'opcode': '0110011'},
    'AND': {'type': 'R', 'funct7': '0000000', 'funct3': '111', 'opcode': '0110011'},
    'OR':  {'type': 'R', 'funct7': '0000000', 'funct3': '110', 'opcode': '0110011'},
    'XOR': {'type': 'R', 'funct7': '0000000', 'funct3': '100', 'opcode': '0110011'},
    'SLL': {'type': 'R', 'funct7': '0000000', 'funct3': '001', 'opcode': '0110011'},
    'SRL': {'type': 'R', 'funct7': '0000000', 'funct3': '101', 'opcode': '0110011'},
    'SUB': {'type': 'R', 'funct7': '0100000', 'funct3': '000', 'opcode': '0110011'},
    'SRA': {'type': 'R', 'funct7': '0100000', 'funct3': '101', 'opcode': '0110011'},
    'JAL':  {'type': 'J', 'opcode': '1101111'},
    'JALR': {'type': 'I', 'funct3': '000', 'opcode': '1100111'},
    'BEQ':  {'type': 'B', 'funct3': '000', 'opcode': '1100011'},
    'BNE':  {'type': 'B', 'funct3': '001', 'opcode': '1100011'},
    'BLT':  {'type': 'B', 'funct3': '100', 'opcode': '1100011'},
    'BLTU': {'type': 'B', 'funct3': '110', 'opcode': '1100011'},
    'BGE':  {'type': 'B', 'funct3': '101', 'opcode': '1100011'},
    'BGEU': {'type': 'B', 'funct3': '111', 'opcode': '1100011'},
    'LW':   {'type': 'I', 'funct3': '010', 'opcode': '0000011'},
    'LH':   {'type': 'I', 'funct3': '001', 'opcode': '0000011'},
    'LHU':  {'type': 'I', 'funct3': '101', 'opcode': '0000011'},
    'LB':   {'type': 'I', 'funct3': '000', 'opcode': '0000011'},
    'LBU':  {'type': 'I', 'funct3': '100', 'opcode': '0000011'},
    'SW':   {'type': 'S', 'funct3': '010', 'opcode': '0100011'},
    'SH':   {'type': 'S', 'funct3': '001', 'opcode': '0100011'},
    'SB':   {'type': 'S', 'funct3': '000', 'opcode': '0100011'}
}

# Read the configuration file
config = configparser.ConfigParser()
config.read('config.ini')
testbench_file = config['Paths']['testbench_file']

# Initialize registers and memory
registers = [0] * 32
memory = {i: 0 for i in range(0, 1024, 4)}  # Example memory initialization

# Initialize the instructions list
instructions = []

# Initialize a set to keep track of written registers
written_registers = set()

# Create the grid window
window, register_labels, memory_labels, memory_frame = create_grid_window(registers, memory)

# Get user input for multiple instructions
while True:
    instr = input("Enter the RISC-V instruction (or 'done' to finish): ").upper()
    if instr == 'DONE':
        window.destroy()
        break
    if instr not in instruction_set:
        print("Invalid instruction. Please enter a valid RISC-V instruction.")
        continue

    rs2 = rs1 = rd = imm = None

    if instruction_set[instr]['type'] in ['I', 'S', 'B']:
        imm = get_valid_input("Enter the immediate value: ", -2048, 2047)  # 12-bit signed immediate
    elif instruction_set[instr]['type'] in ['U', 'J']:
        imm = get_valid_input("Enter the immediate value: ", 0, 1048575)  # 20-bit unsigned immediate

    if instruction_set[instr]['type'] in ['R', 'I', 'S', 'B']:
        rs1 = get_valid_input("Enter the address for the first source register (0-31): ", 0, 31)
    if instruction_set[instr]['type'] in ['R', 'S', 'B']:
        rs2 = get_valid_input("Enter the address for the second source register (0-31): ", 0, 31)
    if instruction_set[instr]['type'] in ['R', 'I', 'U', 'J']:
        rd = get_valid_input("Enter the address for the destination register (0-31): ", 0, 31)

    binary_instruction = create_instruction(instruction_set, instr, rs2, rs1, rd, imm)
    instructions.append(binary_instruction)

    update_register_values(instr, rs2, rs1, rd, imm, registers, memory, written_registers)

    # Update the grid with the new register values
    update_register_grid(registers, register_labels, written_registers)
    update_memory_grid(memory, memory_labels, memory_frame, window)

    # Example usage: update a specific address
    update_memory_grid(memory, memory_labels, memory_frame, window, updated_addr=0)

# Ensure the instructions list is not empty before writing to the testbench file
if instructions:
    # Write the binary instructions to the testbench file
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
else:
    print("No instructions to write to the testbench file.")

# Start the Tkinter main loop
window.mainloop()