module writeBackCycle #(
    parameter XLEN=32;
) (
    input [1:0] writeback_data_sel,
    output [XLEN-1:0] writeback_data,
    input [XLEN-1:0] alu_data_out,
    input [XLEN-1:0] writeback_PC,
    input [XLEN-1:0] dm_read_data
);

    enum {ALU, DATA_MEM, PC} WRITEBACK_DATA_SEL;
    
    //NOTE make sure to implement the mux for data to write back to destination register
    //This is where the bundle of register right signals are required
    if (writeback_data_sel == ALU) begin

        writeback_data = alu_data_out;
        
    end
    else if (writeback_data_sel == DATA_MEM) begin
    
        writeback_data = dm_read_data;

    end
    else if (writeback_data_sel == PC) begin

        writeback_data = writeback_PC + 4;
        
    end
endmodule