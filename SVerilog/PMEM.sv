module memoria_ram (
    input logic clk,              // Clock
    input logic rst_n,            // Reset ativo baixo
    input logic wr_en,            // Habilitação de escrita
    input logic [10:0] address,   // Endereço de 11 bits (máximo de 2048 endereços)
    input logic [7:0] data_in,    // Dados de entrada (8 bits)
    output logic [7:0] data_out   // Dados de saída (8 bits)
);

    // Definição da memória com 2048 posições e 8 bits por posição
    logic [7:0] mem [2047:0];     // 2048 endereços, 8 bits cada

    // Inicialização da memória para simulação
    initial begin
        for (int i = 0; i < 2048; i++) begin
            mem[i] = 8'b0;  // Inicializa a memória com 0
        end
    end

    // Processamento do clock para leitura e escrita
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reseta a memória
            for (int i = 0; i < 2048; i++) begin
                mem[i] <= 8'b0;
            end
            data_out <= 8'b0;
        end else if (wr_en) begin
            // Escrita na memória
            mem[address] <= data_in;
        end
    end

    // Leitura da memória
    always_ff @(posedge clk) begin
        if (!wr_en) begin
            data_out <= mem[address];
        end
    end

endmodule
