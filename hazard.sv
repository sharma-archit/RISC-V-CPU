module hazard (
    input instruction,
    input 
);
    
endmodule    
    
    if previous instruction[destination register] == instruction[source register 1] || previous instruction[destination register] == instruction[source register 2]
        if load enable
            if one cycle delay
                stall for a cycle
            memory output mux control signal
        else if one cycle delay 
            alu output mux control signal
        else                      
            alu output in memory access cycle mux control signal
    else
        internal previous pc - 1

    if (previous) begin
        
    end