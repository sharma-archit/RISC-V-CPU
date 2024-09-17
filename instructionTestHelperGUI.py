import tkinter as tk
from tkinter import ttk

def update_grid(grid, grid_labels, memory, memory_grid_column, window):
    memory_items = list(memory.items())
    for address, value in memory_items:
        if value != 0:
            memory_grid_column += 1
            grid.append(value)
            frame = tk.Frame(window, bg='black', bd=1, relief="solid", highlightbackground="white", highlightcolor="white", highlightthickness=1)
            frame.grid(row=len(grid)//8, column=memory_grid_column%8, padx=5, pady=5, sticky="nsew")
            label = ttk.Label(frame, text=f"M{address}", style="TLabel")
            label.grid(row=0, column=0, sticky="ew", padx=10)

            separator = tk.Frame(frame, height=2, bd=0, bg="white")
            separator.grid(row=1, column=0, sticky="nsew", padx=5, pady=2)
            frame.grid_columnconfigure(0, weight=1)

            value_label = ttk.Label(frame, text="", style="TLabel")
            value_label.grid(row=2, column=0, sticky="nsew")
            grid_labels.append(value_label)

            memory.clear()

    for i in range(len(grid)):
        if grid[i] != 0:
            value = grid[i]
            style = "Highlighted.TLabel" if value != 0 else "TLabel"
            grid_labels[i].config(text=value, style=style)
            grid_labels[i].grid()

        else:
            grid_labels[i].grid_remove()

    grid_labels[0].config(text=0, style=style)

    return memory_grid_column, grid_labels

def create_grid_window(grid):
    window = tk.Tk()
    window.title("Register File and Data Memory Grid")
    window.configure(bg="black")

    window.maxsize(1080, 1872)

    style = ttk.Style()
    style.configure("TLabel", font=("Arial", 12), padding=5, borderwidth=0, relief="flat", background="black", foreground="white")
    style.configure("Highlighted.TLabel", font=("Arial", 12), padding=5, borderwidth=0, relief="flat", background="black", foreground="white")

    grid_labels = []
    for i in range(len(grid)):
        frame = tk.Frame(window, bg="black", bd=1, relief="solid", highlightbackground="white", highlightcolor="white", highlightthickness=1)
        frame.grid(row=i//8, column=i%8, padx=5, pady=5, sticky="nsew")
        label = ttk.Label(frame, text=f"R{i}", style="TLabel")
        label.grid(row=0, column=0, sticky="ew", padx=10)

        separator = tk.Frame(frame, height=2, bd=0, bg="white")
        separator.grid(row=1, column=0, sticky="nsew", padx=5, pady=2)
        frame.grid_columnconfigure(0, weight=1)

        value_label = ttk.Label(frame, text="", style="TLabel")
        value_label.grid(row=2, column=0, sticky="nsew")
        grid_labels.append(value_label)

    for i in range(8):
        window.grid_columnconfigure(i, weight=1)
    for i in range(4):
        window.grid_rowconfigure(i, weight=1)

    return window, grid_labels

def update_grid_values(instr, rs1, rs2, rd, imm, grid, grid_labels, memory):
# Update the registers based on the instruction
    if instr in ['ADDI', 'SLTI', 'SLTIU', 'ANDI', 'ORI', 'XORI']:
        grid[rd] = grid[rs1] + imm
    elif instr in ['SLLI', 'SRLI', 'SRAI']:
        grid[rd] = grid[rs1] << imm if instr == 'SLLI' else grid[rs1] >> imm
    elif instr == 'LUI':
        grid[rd] = (imm << 12) & 0xFFFFF000  # Ensure the result stays within 32 bits
    elif instr in ['AUIPC']:
        grid[rd] = imm + grid[rs1]
    elif instr in ['ADD', 'SLT', 'SLTU', 'AND', 'OR', 'XOR', 'SLL', 'SRL', 'SUB', 'SRA']:
        if instr == 'ADD':
            grid[rd] = grid[rs1] + grid[rs2]
        elif instr == 'SUB':
            grid[rd] = grid[rs1] - grid[rs2]
        elif instr == 'AND':
            grid[rd] = grid[rs1] & grid[rs2]
        elif instr == 'OR':
            grid[rd] = grid[rs1] | grid[rs2]
        elif instr == 'XOR':
            grid[rd] = grid[rs1] ^ grid[rs2]
        elif instr == 'SLL':
            grid[rd] = grid[rs1] << grid[rs2]
        elif instr == 'SRL':
            grid[rd] = grid[rs1] >> grid[rs2]
        elif instr == 'SRA':
            grid[rd] = grid[rs1] >> grid[rs2]
    elif instr in ['JAL', 'JALR']:
        grid[rd] = imm + grid[rs1]
    elif instr in ['BEQ', 'BNE', 'BLT', 'BLTU', 'BGE', 'BGEU']:
        if instr == 'BEQ' and grid[rs1] == grid[rs2]:
            grid[rd] = imm
        elif instr == 'BNE' and grid[rs1] != grid[rs2]:
            grid[rd] = imm
        elif instr == 'BLT' and grid[rs1] < grid[rs2]:
            grid[rd] = imm
        elif instr == 'BGE' and grid[rs1] >= grid[rs2]:
            grid[rd] = imm
    elif instr in ['LW', 'LH', 'LHU', 'LB', 'LBU']:
        grid[rd] = get_memory_value(imm + grid[rs1], grid_labels)
    elif instr in ['SW', 'SH', 'SB']:
        memory[rs1 + imm] = grid[rs2]

def get_memory_value(memory_address, grid_labels):
    target_address = f"M{memory_address}"
    for label in grid_labels:
        frame = label.master
        widgets = frame.winfo_children()
        for i, widget in enumerate(widgets):
            if isinstance(widget, ttk.Label) and widget.cget("text") == target_address:
                for j in range(i + 1, len(widgets)):
                    next_widget = widgets[j]
                    if isinstance(next_widget, ttk.Label) and next_widget.cget("text") != target_address:
                        value_text = next_widget.cget("text")
                        if value_text:
                            value = int(value_text)
                            return value

    return None