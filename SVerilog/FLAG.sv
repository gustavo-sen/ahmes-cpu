module status_register (
    input  logic clk,        
    input  logic reset,      
    input  logic load_flags_en,

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

    // 5 bits: {N,Z,C,B,V}
    logic [4:0] flags;

    always_ff @(posedge clk) begin
        if (reset)
            flags <= 5'b0;
        else if (load_flags_en)
            flags <= {n_in, z_in, c_in, b_in, v_in};
    end

    assign {n_out, z_out, c_out, b_out, v_out} = flags;

endmodule
