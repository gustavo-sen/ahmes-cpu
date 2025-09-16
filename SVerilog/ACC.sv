module accumulator (
    input logic         clk,       
    input logic         reset,     // Reset síncrono (High) 
    input logic         load_ac,   // Habilita a load de um novo dado 
    input logic [7:0]   data_in,   // 8-bit data to be loaded

    output logic [7:0]  ac_out     // Current accumulator value
);

    logic [7:0] ac_reg;

    always_ff @(posedge clk) begin
        if (reset) begin
            ac_reg <= 8'h00;
        end else if (load_ac) begin
            ac_reg <= data_in;
        end
    end

    assign ac_out = ac_reg;

endmodule