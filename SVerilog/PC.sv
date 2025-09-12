module PC (
    input  logic        clk,
    input  logic        reset,
    input  logic        load,    // carrega valor de operação em pc_in
    input  logic        inc,     // incrementa contador
    input  logic [7:0] pc_in,    // operação 
    output logic [7:0] pc_out     
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            pc_out <= 8'd0;
        else if (load)
            pc_out <= pc_in;
        else if (inc)
            pc_out <= pc_out + 8'd1;
    end

endmodule
