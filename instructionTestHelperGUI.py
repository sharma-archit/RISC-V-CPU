import tkinter as tk
from tkinter import ttk

def update_register_grid(registers, grid_labels, written_registers):
    for i in range(32):
        if i in written_registers:
            value = registers[i]
            style = "Highlighted.TLabel" if value != 0 else "TLabel"
            grid_labels[i].config(text=value, style=style)
            grid_labels[i].grid()  # Show the label
        else:
            grid_labels[i].grid_remove()  # Hide the label

def update_memory_grid(memory, memory_labels, memory_frame, window, updated_addr=None):
    if updated_addr is not None:
        value = memory.get(updated_addr, "0")
        style = "Highlighted.TLabel" if value != "0" else "TLabel"
        memory_labels[updated_addr].config(text=value, style=style)
        memory_labels[updated_addr].grid()
    else:
        for addr, label in memory_labels.items():
            value = memory.get(addr, "0")
            style = "Highlighted.TLabel" if value != "0" else "TLabel"
            label.config(text=value, style=style)
            if value != "0":
                label.grid()
            else:
                label.grid_remove()

    if any(memory.values()):
        memory_frame.grid()
        window.geometry("")  # Reset the window size to fit both grids
    else:
        memory_frame.grid_remove()

def create_grid_window(registers, memory):
    window = tk.Tk()
    window.title("Register File and Data Memory Grid")
    window.configure(bg="black")

    style = ttk.Style()
    style.configure("TLabel", font=("Arial", 12), padding=5, borderwidth=0, relief="flat", background="black", foreground="white")
    style.configure("Highlighted.TLabel", font=("Arial", 12), padding=5, borderwidth=0, relief="flat", background="black", foreground="white")

    register_labels = []
    for i in range(32):
        frame = tk.Frame(window, bg="black", bd=1, relief="solid", highlightbackground="white", highlightcolor="white", highlightthickness=1)
        frame.grid(row=i//8, column=i%8, padx=3, pady=2, sticky="nsew")
        label = ttk.Label(frame, text=f"R{i}", style="TLabel")
        label.grid(row=0, column=0, sticky="ew", padx=10)  # Center the register name with padding

        separator = tk.Frame(frame, height=2, bd=0, bg="white")
        separator.grid(row=1, column=0, sticky="nsew", padx=5, pady=2)  # Use grid to center the separator within the frame
        frame.grid_columnconfigure(0, weight=1)

        value_label = ttk.Label(frame, text="", style="TLabel")
        value_label.grid(row=2, column=0, sticky="nsew")
        register_labels.append(value_label)

    memory_frame = tk.Frame(window, bg="black")
    memory_labels = {}
    row = 0
    for addr, value in memory.items():
        frame = tk.Frame(memory_frame, bg="black", bd=1, relief="solid", highlightbackground="white", highlightcolor="white", highlightthickness=1)
        frame.grid(row=row, column=0, padx=3, pady=2, sticky="nsew")
        label = ttk.Label(frame, text=f"Addr {addr}", style="TLabel")
        label.grid(row=0, column=0, sticky="ew", padx=10)  # Center the address name with padding
        
        # Create a separator with a fixed width and padding to avoid touching the walls
        separator = tk.Frame(frame, height=2, bd=0, bg="white")  # Set a fixed width for the separator
        separator.grid(row=1, column=0, sticky="nsew", padx=5, pady=2)
        
        value_label = ttk.Label(frame, text="", style="TLabel")
        value_label.grid(row=2, column=0, sticky="nsew")
        memory_labels[addr] = value_label
        value_label.grid_remove()  # Initially hide all memory addresses
        row += 1

    memory_frame.grid_remove()

    for i in range(8):
        window.grid_columnconfigure(i, weight=1)
    for i in range(4):
        window.grid_rowconfigure(i, weight=1)

    return window, register_labels, memory_labels, memory_frame

def update_register_values(instr, rs2, rs1, rd, imm, registers, memory, written_registers):
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
        registers[rd] = memory.get(imm + registers[rs1], 0)
        written_registers.add(rd)
    elif instr in ['SW', 'SH', 'SB']:
        memory[imm + registers[rs1]] = registers[rs2]
    registers[0] = 0