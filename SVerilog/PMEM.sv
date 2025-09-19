module memoria_ram (
    input logic clk,              // Clock
    input logic wr_en,            // Habilitação de escrita
    input logic [7:0] address,   // Endereço de 11 bits (máximo de 2048 endereços)
    input logic [7:0] data_in,    // Dados de entrada (8 bits)
    output logic [7:0] data_out   // Dados de saída (8 bits)
);

    // Definição da memória com 2048 posições e 8 bits por posição
    logic [7:0] mem [255:0];     // 2048 endereços, 8 bits cada

    // Leitura da memória
    always_ff @(posedge clk) begin
        if (!wr_en) begin
            data_out <= mem[address];
        end
        if (wr_en) begin
            mem[address] <= data_in;
        end
    end

endmodule
