import tkinter as tk
from tkinter import ttk

def update_register_grid(registers, grid_labels, written_registers):
    for i in range(32):
        if i in written_registers:
            value = registers[i]
            style = "Highlighted.TLabel" if value != 0 else "TLabel"
            grid_labels[i].config(text=value, style=style)
            grid_labels[0] = 0
            grid_labels[i].grid()
        else:
            grid_labels[i].grid_remove()

def create_grid_window():
    window = tk.Tk()
    window.title("Register File and Data Memory Grid")
    window.configure(bg="black")

    window.maxsize(1080, 1872)

    style = ttk.Style()
    style.configure("TLabel", font=("Arial", 12), padding=5, borderwidth=0, relief="flat", background="black", foreground="white")
    style.configure("Highlighted.TLabel", font=("Arial", 12), padding=5, borderwidth=0, relief="flat", background="black", foreground="white")

    register_labels = []
    for i in range(32):
        frame = tk.Frame(window, bg="black", bd=1, relief="solid", highlightbackground="white", highlightcolor="white", highlightthickness=1)
        frame.grid(row=i//8, column=i%8, padx=5, pady=5, sticky="nsew")
        label = ttk.Label(frame, text=f"R{i}", style="TLabel")
        label.grid(row=0, column=0, sticky="ew", padx=10)

        separator = tk.Frame(frame, height=2, bd=0, bg="white")
        separator.grid(row=1, column=0, sticky="nsew", padx=5, pady=2)
        frame.grid_columnconfigure(0, weight=1)

        value_label = ttk.Label(frame, text="", style="TLabel")
        value_label.grid(row=2, column=0, sticky="nsew")
        register_labels.append(value_label)

    for i in range(8):
        window.grid_columnconfigure(i, weight=1)
    for i in range(4):
        window.grid_rowconfigure(i, weight=1)

    return window, register_labels

def update_grid_values(instr, rs2, rs1, rd, imm, registers, register_labels, memory, written_registers):
# Update the registers based on the instruction and track written registers
    if instr in ['ADDI', 'SLTI', 'SLTIU', 'ANDI', 'ORI', 'XORI']:
        registers[rd] = registers[rs1] + imm
        written_registers.add(rd)
    elif instr in ['SLLI', 'SRLI', 'SRAI']:
        registers[rd] = registers[rs1] << imm if instr == 'SLLI' else registers[rs1] >> imm
        written_registers.add(rd)
    elif instr == 'LUI':
        registers[rd] = (imm << 12) & 0xFFFFF000  # Ensure the result stays within 32 bits
        written_registers.add(rd)
    elif instr in ['AUIPC']:
        registers[rd] = imm + registers[rs1]
        written_registers.add(rd)
    elif instr in ['ADD', 'SLT', 'SLTU', 'AND', 'OR', 'XOR', 'SLL', 'SRL', 'SUB', 'SRA']:
        if instr == 'ADD':
            registers[rd] = registers[rs1] + registers[rs2]
        elif instr == 'SUB':
            registers[rd] = registers[rs1] - registers[rs2]
        elif instr == 'AND':
            registers[rd] = registers[rs1] & registers[rs2]
        elif instr == 'OR':
            registers[rd] = registers[rs1] | registers[rs2]
        elif instr == 'XOR':
            registers[rd] = registers[rs1] ^ registers[rs2]
        elif instr == 'SLL':
            registers[rd] = registers[rs1] << registers[rs2]
        elif instr == 'SRL':
            registers[rd] = registers[rs1] >> registers[rs2]
        elif instr == 'SRA':
            registers[rd] = registers[rs1] >> registers[rs2]
        written_registers.add(rd)
    elif instr in ['JAL', 'JALR']:
        registers[rd] = imm + registers[rs1]
        written_registers.add(rd)
    elif instr in ['BEQ', 'BNE', 'BLT', 'BLTU', 'BGE', 'BGEU']:
        if instr == 'BEQ' and registers[rs1] == registers[rs2]:
            registers[rd] = imm
        elif instr == 'BNE' and registers[rs1] != registers[rs2]:
            registers[rd] = imm
        elif instr == 'BLT' and registers[rs1] < registers[rs2]:
            registers[rd] = imm
        elif instr == 'BGE' and registers[rs1] >= registers[rs2]:
            registers[rd] = imm
        written_registers.add(rd)
    elif instr in ['LW', 'LH', 'LHU', 'LB', 'LBU']:
        registers[rd] = get_register_value(imm + registers[rs1], register_labels)
        written_registers.add(rd)
    elif instr in ['SW', 'SH', 'SB']:
        memory['address'] = imm + registers[rs1]
        memory['value'] = registers[rs2]

def get_register_value(register_number, register_labels):
    value_label = register_labels[register_number]
    value_text = value_label.cget("text")
    if value_text:
        value = int(value_text)
        return value
    return None