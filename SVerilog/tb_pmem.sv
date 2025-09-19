module tb_memoria_ram();

    logic clk;
    logic wr_en;
    logic [7:0] address;
    logic [7:0] data_in;
    logic [7:0] data_out;

    // Instância do DUT (Device Under Test)
    memoria_ram dut (
        .clk(clk),
        .wr_en(wr_en),
        .address(address),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Geração do clock: alterna a cada 5 unidades de tempo
    initial clk = 0;
    always #5 clk = ~clk;

    // Processo principal de teste
    initial begin
        // Inicialização
        wr_en = 0;
        address = 0;
        data_in = 0;

        $display("Ram Test");
        #10;

        // Teste 1: Escrita no address 10
        address = 8'd10;
        data_in = 8'hAB;
        wr_en = 1;
        #10; // espera uma borda de clock

        // Teste 2: Leitura do address 10
        wr_en = 0;
        #10;

        if (data_out !== 8'hAB)
            $display("Erro: Esperado AB em address 10, encontrado %h", data_out);
        else
            $display("Leitura OK em address 10: %h", data_out);

        // Teste 3: Escrita em múltiplos addresss
        repeat (5) begin
            address = $urandom_range(0, 255);
            data_in = $urandom_range(0, 255);
            wr_en = 1;
            #10;
            wr_en = 0;
            #10;

            if (data_out !== data_in)
                $display("Erro: Escrita/Leitura falhou no address %0d. Esperado %h, lido %h", address, data_in, data_out);
            else
                $display("Teste OK no address %0d: %h", address, data_out);
        end

        $display("Teste finalizado.");
        $finish;
    end

endmodule
