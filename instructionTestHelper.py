from instructionTestHelperCoreFunctions import create_instruction, get_valid_input
from instructionTestHelperGUI import update_grid, create_grid_window, update_grid_values
import configparser

# Define the RISC-V instruction set with proper values
instruction_set = {
    'ADDI': {'type': 'I', 'funct3': '000', 'opcode': '0010011',
             'imm': 'Enter the first number to ADD: ',
             'rs1': 'Enter the register location of the second number to ADD: '},
    'SLTI': {'type': 'I', 'funct3': '010', 'opcode': '0010011',
             'imm': 'Enter the immediate value: ',
             'rs1': 'Enter the register location of the value you want to compare to the immediate value: '},
    'SLTIU': {'type': 'I', 'funct3': '011', 'opcode': '0010011',
             'imm': 'Enter the immediate value: ',
             'rs1': 'Enter the register location of the value you want to compare to the immediate value: '},
    'ANDI': {'type': 'I', 'funct3': '000', 'opcode': '0010011',
             'imm': 'Enter the first number to AND: ',
             'rs1': 'Enter the second number to AND: '},
    'ORI': {'type': 'I', 'funct3': '000', 'opcode': '0010011',
             'imm': 'Enter the first number to OR: ',
             'rs1': 'Enter the second number to OR: '},
    'XORI': {'type': 'I', 'funct3': '000', 'opcode': '0010011',
             'imm': 'Enter the first number to XOR: ',
             'rs1': 'Enter the second number to XOR: '},
    'SLLI': {'type': 'I', 'funct3': '001', 'opcode': '0010011', 'special': True,
             'imm': 'Enter amount to shift by: ',
             'rs1': 'Enter register location of value to shift: '},
    'SRLI': {'type': 'I', 'funct3': '101', 'opcode': '0010011', 'special': True,
             'imm': 'Enter amount to shift by: ',
             'rs1': 'Enter register location of value to shift: '},
    'SRAI': {'type': 'I', 'funct3': '101', 'opcode': '0010011', 'special': True,
             'imm': 'Enter amount to shift by: ',
             'rs1': 'Enter register location of value to shift: '},
    'LUI':  {'type': 'U', 'opcode': '0110111',
             'imm': 'Enter immediate value: '},
    'AUIPC':{'type': 'U', 'opcode': '0010111',
             'imm': 'Enter immediate value: '},
    'ADD': {'type': 'R', 'funct7': '0000000', 'funct3': '000', 'opcode': '0110011',
             'rs1': 'Enter the register location of the first value to ADD: ',
             'rs2': 'Enter the register location of the second value of ADD: '},
    'SLT': {'type': 'R', 'funct7': '0000000', 'funct3': '010', 'opcode': '0110011',
             'rs1': 'Enter the register location of the value to compare to: ',
             'rs2': 'Enter the register location of the value to compare: '},
    'SLTU': {'type': 'R', 'funct7': '0000000', 'funct3': '011', 'opcode': '0110011',
             'rs1': 'Enter the register location of the value to compare to: ',
             'rs2': 'Enter the register location of the value to compare: '},
    'AND': {'type': 'R', 'funct7': '0000000', 'funct3': '111', 'opcode': '0110011',
             'rs1': 'Enter the register location of the first value to AND: ',
             'rs2': 'Enter the register location of the second value to AND: '},
    'OR':  {'type': 'R', 'funct7': '0000000', 'funct3': '110', 'opcode': '0110011',
             'rs1': 'Enter the register location of the first value to OR: ',
             'rs2': 'Enter the register location of the second value to OR: '},
    'XOR': {'type': 'R', 'funct7': '0000000', 'funct3': '100', 'opcode': '0110011',
             'rs1': 'Enter the register location of the first value to XOR: ',
             'rs2': 'Enter the register location of the second value to XOR: '},
    'SLL': {'type': 'R', 'funct7': '0000000', 'funct3': '001', 'opcode': '0110011',
             'rs1': 'Enter the register location of the value to shift: ',
             'rs2': 'Enter the register location of the amount to shift by: '},
    'SRL': {'type': 'R', 'funct7': '0000000', 'funct3': '101', 'opcode': '0110011',
             'rs1': 'Enter the register location of the value to shift: ',
             'rs2': 'Enter the register location of the amount to shift by: '},
    'SUB': {'type': 'R', 'funct7': '0100000', 'funct3': '000', 'opcode': '0110011',
             'rs1': 'Enter the register location of the value to subtract by: ',
             'rs2': 'Enter the register location of the value to subtract: '},
    'SRA': {'type': 'R', 'funct7': '0100000', 'funct3': '101', 'opcode': '0110011',
             'rs1': 'Enter the register location of the value to shift: ',
             'rs2': 'Enter the register location of the amount to shift by: '},
    'JAL':  {'type': 'J', 'opcode': '1101111',
             'imm': 'Enter the value to calculate the jump address: '},
    'JALR': {'type': 'I', 'funct3': '000', 'opcode': '1100111',
             'imm': 'Enter the first value to calculate the jump address: ',
             'rs1': 'Enter the register location of the second value to calculate the jump address: '},
    'BEQ':  {'type': 'B', 'funct3': '000', 'opcode': '1100011',
             'imm': 'Enter the value to calculate the jump address: ',
             'rs1': 'Enter the register location of the value to compare: ',
             'rs2': 'Enter the register location of the value to compare to: '},
    'BNE':  {'type': 'B', 'funct3': '001', 'opcode': '1100011',
             'imm': 'Enter the value to calculate the jump address: ',
             'rs1': 'Enter the register location of the value to compare: ',
             'rs2': 'Enter the register location of the value to compare to: '},
    'BLT':  {'type': 'B', 'funct3': '100', 'opcode': '1100011',
             'imm': 'Enter the value to calculate the jump address: ',
             'rs1': 'Enter the register location of the value to compare: ',
             'rs2': 'Enter the register location of the value to compare to: '},
    'BLTU': {'type': 'B', 'funct3': '110', 'opcode': '1100011',
             'imm': 'Enter the value to calculate the jump address: ',
             'rs1': 'Enter the register location of the value to compare: ',
             'rs2': 'Enter the register location of the value to compare to: '},
    'BGE':  {'type': 'B', 'funct3': '101', 'opcode': '1100011',
             'imm': 'Enter the value to calculate the jump address: ',
             'rs1': 'Enter the register location of the value to compare: ',
             'rs2': 'Enter the register location of the value to compare to: '},
    'BGEU': {'type': 'B', 'funct3': '111', 'opcode': '1100011',
             'imm': 'Enter the value to calculate the jump address: ',
             'rs1': 'Enter the register location of the value to compare: ',
             'rs2': 'Enter the register location of the value to compare to: '},
    'LW':   {'type': 'I', 'funct3': '010', 'opcode': '0000011',
             'imm': 'Enter the first value to calculate the memory address: ',
             'rs1': 'Enter the register location of the second value to calculate the memory address: '},
    'LH':   {'type': 'I', 'funct3': '001', 'opcode': '0000011',
             'imm': 'Enter the first value to calculate the memory address: ',
             'rs1': 'Enter the register location of the second value to calculate the memory address: '},
    'LHU':  {'type': 'I', 'funct3': '101', 'opcode': '0000011',
             'imm': 'Enter the first value to calculate the memory address: ',
             'rs1': 'Enter the register location of the second value to calculate the memory address: '},
    'LB':   {'type': 'I', 'funct3': '000', 'opcode': '0000011',
             'imm': 'Enter the first value to calculate the memory address: ',
             'rs1': 'Enter the register location of the second value to calculate the memory address: '},
    'LBU':  {'type': 'I', 'funct3': '100', 'opcode': '0000011',
             'imm': 'Enter the first value to calculate the memory address: ',
             'rs1': 'Enter the register location of the second value to calculate the memory address: '},
    'SW':   {'type': 'S', 'funct3': '010', 'opcode': '0100011',
             'imm': 'Enter the first value to calculate the memory address: ',
             'rs1': 'Enter the register location of the second value to calculate the memory address: ',
             'rs2': 'Enter the register location of the value to move to memory'},
    'SH':   {'type': 'S', 'funct3': '001', 'opcode': '0100011',
             'imm': 'Enter the first value to calculate the memory address: ',
             'rs1': 'Enter the register location of the second value to calculate the memory address: ',
             'rs2': 'Enter the register location of the value to move to memory'},
    'SB':   {'type': 'S', 'funct3': '000', 'opcode': '0100011',
             'imm': 'Enter the first value to calculate the memory address: ',
             'rs1': 'Enter the register location of the second value to calculate the memory address: ',
             'rs2': 'Enter the register location of the value to move to memory'},
}

# Read the configuration file
config = configparser.ConfigParser()
config.read('config.ini')
testbench_file = config['Paths']['testbench_file']

# Initialize registers and memory
grid = [0] * 32
memory = {}

memory_grid_column = -1

# Initialize the instructions list
instructions = []

# Initialize a set to keep track of written registers
written_registers = set()

# Create the grid window
window, grid_labels = create_grid_window(grid)

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
        imm = get_valid_input(instruction_set[instr]['imm'], -2048, 2047)  # 12-bit signed immediate
    elif instruction_set[instr]['type'] in ['U', 'J']:
        imm = get_valid_input(instruction_set[instr]['imm'], 0, 1048575)  # 20-bit unsigned immediate
    if instruction_set[instr]['type'] in ['R', 'I', 'S', 'B']:
        rs1 = get_valid_input(instruction_set[instr]['rs1'], 0, 31)
    if instruction_set[instr]['type'] in ['R', 'S', 'B']:
        rs2 = get_valid_input(instruction_set[instr]['rs2'], 0, 31)
    if instruction_set[instr]['type'] in ['R', 'I', 'U', 'J']:
        rd = get_valid_input("Enter the register location to store the output: ", 0, 31)

    binary_instruction = create_instruction(instruction_set, instr, rs2, rs1, rd, imm)
    instructions.append(binary_instruction)

    update_grid_values(instr, rs1, rs2, rd, imm, grid, grid_labels, memory)

    memory_grid_column, grid_labels = update_grid(grid, grid_labels, memory, memory_grid_column, window)

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

window.mainloop()