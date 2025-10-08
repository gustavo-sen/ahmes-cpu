module memoria_ram (
    input logic clk,                
    input logic wr_en,              
    input logic [7:0] address,      
    input logic [7:0] data_in,      
    output logic [7:0] data_out     
);

    logic [7:0] mem [255:0];

    always_ff @(posedge clk) begin
        if (!wr_en) begin
            data_out <= mem[address];
        end
        if (wr_en) begin
            mem[address] <= data_in;
        end
    end

endmodule
