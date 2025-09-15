module tb_accumulator;

    // --- Sinais para conectar ao DUT ---
    logic         clk;
    logic         reset;
    logic         load_ac;
    logic [7:0]   data_in;
    logic [7:0]   ac_out;

    // --- Lógica do Testbench ---
    integer fail_count = 0;

    // Instância do Módulo Acumulador (UUT)
    accumulator uut (
        .clk(clk),
        .reset(reset),
        .load_ac(load_ac),
        .data_in(data_in),
        .ac_out(ac_out)
    );

    // Geração do Sinal de Clock (período de 10ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Tarefa para verificar e imprimir o resultado de um teste
    task print_output;
        input [7:0] esperado_result;
        input string test_name;
        reg passed;
        begin
            #1; // Atraso para garantir que a forma de onda no simulador fique clara
            
            passed = (ac_out === esperado_result);

            if (!passed)
                fail_count = fail_count + 1;

            // MENSAGEM FORMATADA PARA SEGUIR O PADRÃO DO tb_alu
            $display("TEST %s | Action: %-30s | Rst=%b Load=%b Din=%3d | exp ac=%3d act ac=%3d",
                (passed ? "PASS" : "FAIL"),
                test_name,
                reset, load_ac, data_in,
                esperado_result, ac_out
            );
        end
    endtask

    // Tarefa genérica para executar um único ciclo de teste
    task test;
        input rst_val, load_val;
        input [7:0] din_val;
        input [7:0] esperado_res;
        input string  test_name;
        begin
            // Aplica os estímulos ANTES da borda do clock
            reset   = rst_val;
            load_ac = load_val;
            data_in = din_val;
            
            // Espera a borda do clock para a ação acontecer
            @(posedge clk);
            
            // Verifica o resultado APÓS a borda do clock
            print_output(esperado_res, test_name);
        end
    endtask

    // Bloco principal que executa a sequência de testes
    initial begin
        $display("------------------------------------------------------------------------------------");
        $display("Testbench Acumulador");
        $display("------------------------------------------------------------------------------------");

        //              RST,LOAD,DATA_IN, RESULTADO_ESPERADO, NOME_DO_TESTE
        test(           1,  0,   8'd255,  8'd0,               "Reset");
        test(           0,  1,   8'd170,  8'd170,             "load 170 (0xAA)");
        test(           0,  0,   8'd240,  8'd170,             "(Hold)");
        test(           0,  0,   8'd18,   8'd170,             "(Hold)");
        test(           0,  1,   8'd31,   8'd31,              "load 31 (0x1F)");
        test(           1,  1,   8'd85,   8'd0,               "Reset sobre Load");

        $display("------------------------------------------------------------------------------------");
        if (fail_count == 0)
            $display(">>> End Simulation (PASS) <<<");
        else
            $display(">>> End Simulaton (Fail): %0d <<<", fail_count);
        $display("------------------------------------------------------------------------------------");
        
        $finish; 
    end

endmodule