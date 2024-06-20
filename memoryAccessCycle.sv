module memoryAccessCycle #(
    parameter XLEN = 32,
    parameter BYTE = 8,
    parameter HALFWORD = 16
) (
    input  dm_read_enable,
    input  dm_write_enable,
    input [XLEN-1:0] alu_data_out,
    input  [XLEN - 1:0] dm_write_data,
    input [2:0] dm_load_type,
    output logic [XLEN - 1:0] dm_read_data,
    output logic [XLEN - 1:0] dm_data_bypass
);

enum {LOAD_B, LOAD_H, LOAD_W, LOAD_BU, LOAD_HU} LOAD_OP;

logic [XLEN-1:0] dm_read_addr, dm_write_addr;
logic [XLEN-1:0] read_data;

dataMemory data_memory (
    .read_enable(dm_read_enable),
    .write_enable(dm_write_enable),
    .read_addr(dm_read_addr),
    .write_addr(dm_write_addr),
    .write_data(dm_write_data),
    .read_data(read_data)
);

always_comb begin

    if (dm_read_enable && !dm_write_enable) begin

        dm_write_addr = '0;
        dm_read_addr = alu_data_out; // read address is computed by ALU for load
        dm_data_bypass = '0;

        // size memory read data for load operations
        case (dm_load_type)

            LOAD_B : dm_read_data = { {(XLEN - BYTE){read_data[BYTE - 1]}}, read_data[BYTE - 1:0]};

            LOAD_H : dm_read_data = { {(XLEN - HALFWORD){read_data[HALFWORD - 1]}}, read_data[HALFWORD - 1:0]};

            LOAD_W : dm_read_data = read_data;

            LOAD_BU : dm_read_data = { {(XLEN - BYTE){0}}, read_data[BYTE - 1:0]};

            LOAD_HU : dm_read_data = {{(XLEN - HALFWORD){0}}, read_data[HALFWORD - 1:0]};

            default : dm_read_data = '0;

        endcase

    end

    if (dm_write_enable && !dm_read_enable) begin

        dm_read_addr = '0;
        dm_write_addr = alu_data_out; // write address is computed by ALU for store
        dm_data_bypass = '0;
        dm_read_data = '0;
        
    end

    if (!dm_read_enable && !dm_write_enable) begin
        
        dm_read_addr = '0;
        dm_write_addr = '0;
        dm_read_data = '0;
        dm_data_bypass = alu_data_out; // if neither load or store, bypass the ALU data to the writeback stage

    end

    if (dm_read_enable && dm_write_enable) begin
        dm_read_addr = '0;
        dm_write_addr = '0;
        dm_read_data = '0;
        dm_data_bypass = '0;
        // raise error 
    end

end

endmodule