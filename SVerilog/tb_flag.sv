module tb_status_register;
    logic clk;
    logic reset;
    logic load_flags_en;
    logic n_in, z_in, c_in, b_in, v_in;

    logic n_out, z_out, c_out, b_out, v_out;

    integer fail_count = 0;

    status_register uut (
        .clk(clk),
        .reset(reset),
        .load_flags_en(load_flags_en),
        .n_in(n_in), .z_in(z_in), .c_in(c_in), .b_in(b_in), .v_in(v_in),
        .n_out(n_out), .z_out(z_out), .c_out(c_out), .b_out(b_out), .v_out(v_out)
    );

    always #5 clk = ~clk;

    task print_flags;
        input [4:0] exp_flags; // {N,Z,C,B,V}
        reg [4:0] actual_flags;
        reg passed;
        begin
            actual_flags = {n_out, z_out, c_out, b_out, v_out};
            passed = (actual_flags === exp_flags);

            if (!passed)
                fail_count++;

            $display("TEST %s | IN: %b | OUT: %b | EXP: %b",
                     (passed ? "PASS" : "FAIL"),
                     {n_in, z_in, c_in, b_in, v_in},
                     actual_flags,
                     exp_flags
            );
        end
    endtask

    // Tarefa para testar carregamento das flags
    task test;
        input [4:0] flags_in; // {N,Z,C,B,V}
        input [4:0] exp_flags;
        begin
            {n_in, z_in, c_in, b_in, v_in} = flags_in;
            load_flags_en = 1;
            #10;
            load_flags_en = 0;
            #1; // tempo para estabilização
            print_flags(exp_flags);
        end
    endtask

    initial begin
        $display("----------------------------------------");
        $display("Testbench STATUS REGISTER");
        $display("----------------------------------------");

        clk = 0;
        reset = 1;
        load_flags_en = 0;
        n_in = 0; z_in = 0; c_in = 0; b_in = 0; v_in = 0;

        #2 reset = 0;

        // Teste 1: Carrega o padrão 10101 nas flags
        // N = 1 (negativo), Z = 0 (resultado diferente de zero), 
        // C = 1 (houve carry), B = 0 (sem borrow), V = 1 (overflow)
        $display("Teste 1: NZCBV = 10101");
        test(5'b10101, 5'b10101);

        // Teste 2: Carrega o padrão 01010 nas flags
        // N = 0 (não negativo), Z = 1 (resultado igual a zero), 
        // C = 0 (sem carry), B = 1 (houve borrow), V = 0 (sem overflow)
        $display("Teste 2: NZCBV = 01010");
        test(5'b01010, 5'b01010);

        // Teste 3: Carrega todas as flags como 1
        // N = 1, Z = 1, C = 1, B = 1, V = 1 → todas as condições foram ativadas
        $display("Teste 3: NZCBV = 11111");
        test(5'b11111, 5'b11111);

        // Teste 4: Aplica reset ao registrador de status
        // Esperado: todas as flags devem ser zeradas (00000)
        // Isso testa o comportamento do reset do registrador
        $display("Teste 4: RESET");
        reset = 1;
        #10;
        reset = 0;
        #1;
        print_flags(5'b00000);

        $display("----------------------------------------");
        if (fail_count == 0)
            $display(">>> End Simulation (PASS) <<<");
        else
            $display(">>> End Simulation (FAIL): %0d <<<", fail_count);
        $display("----------------------------------------");

        $finish;
    end

endmodule
