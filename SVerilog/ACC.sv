module accumulator (
    input logic         clk,       // Sinal de clock (Clock signal)
    input logic         reset,     // Reset síncrono, ativo em alto (Synchronous active-high reset)
    input logic         load_ac,   // Habilita a carga de um novo dado (Enable loading new data)
    input logic [7:0]   data_in,   // Dado de 8 bits a ser carregado (8-bit data to be loaded)

    output logic [7:0]  ac_out     // Valor atual do acumulador (Current accumulator value)
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