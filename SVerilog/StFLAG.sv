module status_register (
    // --- Controle ---
    input  logic clk,        
    input  logic reset,      
    input  logic load_flags_en, 

    // --- input From ALU Output ---
    input  logic n_in,       
    input  logic z_in,       
    input  logic c_in,       
    input  logic b_in,       
    input  logic v_in,       

    output logic n_out,      
    output logic z_out,      
    output logic c_out,      
    output logic b_out,      
    output logic v_out       
);

    logic n_reg, z_reg, c_reg, b_reg, v_reg;

    always_ff @(posedge clk) begin
        if (reset) begin
            n_reg <= 1'b0;
            z_reg <= 1'b0;
            c_reg <= 1'b0;
            b_reg <= 1'b0;
            v_reg <= 1'b0;
        end else if (load_flags_en) begin
            n_reg <= n_in;
            z_reg <= z_in;
            c_reg <= c_in;
            b_reg <= b_in;
            v_reg <= v_in;
        end
    end

    assign n_out = n_reg;
    assign z_out = z_reg;
    assign c_out = c_reg;
    assign b_out = b_reg;
    assign v_out = v_reg;

endmodule