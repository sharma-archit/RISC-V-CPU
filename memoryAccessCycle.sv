module memoryAccessCycle #(
    parameter XLEN = 32;
    parameter BYTE = 8;
    parameter HALFWORD = 16;
) (
    input  dm_read_enable,
    input  dm_write_enable,
    input  [XLEN - 1:0] dm_read_addr,
    input  [XLEN - 1:0] dm_write_addr,
    input  [XLEN - 1:0] dm_write_data,
    output logic [XLEN - 1:0] dm_read_data,
    input [2:0] dm_load_type
);

enum {LOAD_B, LOAD_H, LOAD_W, LOAD_BU, LOAD_HU} LOAD_OP;

dataMemory data_memory (
    .read_enable(dm_read_enable),
    .write_enable(dm_write_enable),
    .read_addr(dm_read_addr),
    .write_addr(dm_write_addr),
    .write_data(dm_write_data),
    .read_data(dm_read_data)
);

always_comb begin

    // size memory read data for load operations
    if (read_enable) begin

        case (dm_load_type)

            LOAD_B : dm_read_data = { {(XLEN - BYTE){dm_read_data[BYTE - 1]}}, dm_read_data[BYTE - 1:0]};

            LOAD_H : dm_read_data = { {(XLEN - HALFWORD){dm_read_data[HALFWORD - 1]}}, dm_read_data[HALFWORD - 1:0]};

            LOAD_W : dm_read_data = dm_read_data;

            LOAD_BU : dm_read_data = { {(XLEN - BYTE){0}}, dm_read_data[BYTE - 1:0]};

            LOAD_HU : dm_read_data = {{(XLEN - HALFWORD){0}}, dm_read_data[HALFWORD - 1:0]};

            default : dm_read_data = '0;

        endcase

    end

end

endmodule