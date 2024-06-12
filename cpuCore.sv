module cpuCore #(
    parameters
) (
    ports
);

enum {FETCH, DECODE, EXECUTE, MEMORYACCESS, WRITEBACK} CPU_PIPELINE_STAGES;

wire clk,
wire rst,

// FETCH CYCLE // 

wire [WRITEBACK:0] [] PC_in;
wire [WRITEBACK:0] [] PC_out;
wire [DECODE:0] [] instruction; 

logic [WRITEBACK:0] [] PC_in_d;
logic [WRITEBACK:0] [] PC_out_d;
logic [DECODE:0] [] instruction_d;

//instantiate signals needed in different cycles only

fetchCycle temp (
    .PC_in(PC_in[FETCH]),
    .PC_out(PC_out[FETCH]),
    .instruction(instruction[FETCH])
);

// Fetch-Decode Flop
always_ff @(posedge(clk)) begin

    PC_in_d[DECODE] <= PC_in[FETCH];
    PC_out_d[DECODE] <= PC_out[FETCH];
    instruction_d[DECODE] <= instruction[FETCH];

end


// DECODE CYCLE //



decodeCycle temp (

);
// PC_in ------> [] ------> PC_in_d ---> [DECODE BLOCK] ---> PC_out[DECODE] --> [] --> PC_in_d[EXECUTE]

// execute cycle

// memory access cycle

// writeback cycle

















































endmodule
