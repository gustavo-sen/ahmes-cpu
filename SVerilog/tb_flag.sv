`timescale 1ns / 1ps

module status_register_tb;

    // --- Sinais para o DUT (Device Under Test) ---
    logic clk;
    logic reset;
    logic load_flags_en;

    logic n_in;
    logic z_in;
    logic c_in;
    logic b_in;
    logic v_in;

    logic n_out;
    logic z_out;
    logic c_out;
    logic b_out;
    logic v_out;

    // --- Parâmetros de simulação ---
    parameter CLK_PERIOD = 10; // 10 ns para um clk de 100 MHz
    integer fail_count = 0;

    // --- Instanciação do DUT ---
    status_register dut (
        .clk(clk),
        .reset(reset),
        .load_flags_en(load_flags_en),
        .n_in(n_in),
        .z_in(z_in),
        .c_in(c_in),
        .b_in(b_in),
        .v_in(v_in),
        .n_out(n_out),
        .z_out(z_out),
        .c_out(c_out),
        .b_out(b_out),
        .v_out(v_out)
    );

    // --- Geração do Clock ---
    always begin
        # (CLK_PERIOD / 2) clk = ~clk;
    end

    // --- Função de Impressão de Resultado ---
    task print_output;
        input [7:0] esperado_result;
        input exp_N, exp_Z, exp_C, exp_B, exp_V;
        reg passed;
        reg [4:0] exp_flags;
        reg [4:0] act_flags;
        begin
            exp_flags = {exp_N, exp_Z, exp_C, exp_V, exp_B};
            act_flags = {n_out, z_out, c_out, v_out, b_out};

            passed = (esperado_result === {n_out, z_out, c_out, b_out, v_out}) &&
                     (n_out === exp_N) && (z_out === exp_Z) && (c_out === exp_C) && (b_out === exp_B) && (v_out === exp_V);

            if (!passed)
                fail_count = fail_count + 1;

            $display("TEST %s | exp flags=NZCVB=%b | act flags=NZCVB=%b",
                (passed ? "PASS" : "FAIL"),
                exp_flags, act_flags
            );
        end
    endtask

    // --- Tarefa de Teste ---
    task test;
        input rst;
        input load_f;
        input n_in;
        input z_in;
        input c_in;
        input b_in;
        input v_in;
        begin   
            reset = rst;
            load_flags_en = load_f;
            n_in = n_in;
            z_in = z_in;
            c_in = c_in;
            b_in = b_in;
            v_in = v_in;
            
            #10;  // Atraso para simular o clock
            
            // Verifica os resultados esperados
            print_output({n_out, z_out, c_out, b_out, v_out}, n_in, z_in, c_in, b_in, v_in);
        end
    endtask

    // --- Sequência de Teste ---
    initial begin
        $display("----------------------------------------");
        $display("Testbench FLAG");
        $display("----------------------------------------");

        // Inicialização dos sinais
        clk = 1'b0;
        reset = 1'b1;
        load_flags_en = 1'b0;
        n_in = 1'b0;
        z_in = 1'b0;
        c_in = 1'b0;
        b_in = 1'b0;
        v_in = 1'b0;

        // Teste de Reset
        #20;  // Atraso para simular o reset
        reset = 1'b0;
        
        // Teste 1: Carregar Flags
        load_flags_en = 1'b1;
        n_in = 1'b1;
        z_in = 1'b0;
        c_in = 1'b1;
        b_in = 1'b0;
        v_in = 1'b1;
        
        test(1'b0, 1'b1, n_in, z_in, c_in, b_in, v_in);  // Teste com load_flags_en = 1

        // Teste 2: Não carregar as Flags
        load_flags_en = 1'b0;
        n_in = 1'b0;
        z_in = 1'b1;
        c_in = 1'b0;
        v_in = 1'b0;
        b_in = 1'b1;
        
        test(1'b0, 1'b0, n_in, z_in, c_in, b_in, v_in);  // Teste com load_flags_en = 0

        // Teste 3: Reset ativo
        reset = 1'b1;
        #10;
        test(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);  // Teste após reset

        // Finalização da simulação
        $display("----------------------------------------");
        if (fail_count == 0)
            $display(">>> End Simulation (PASS) <<<");
        else
            $display(">>> End Simulation (FAIL): %0d <<<", fail_count);
        $display("----------------------------------------");
        
        $finish;
    end
    
endmodule
