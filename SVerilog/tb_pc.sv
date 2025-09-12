module tb_pc;

    logic clk, reset, load, inc;
    logic [7:0] pc_in;
    logic [7:0] pc_out;

    // Instância do DUT
    PC uut (
        .clk(clk),
        .reset(reset),
        .load(load),
        .inc(inc),
        .pc_in(pc_in),
        .pc_out(pc_out)
    );

    // Geração de clock: alterna a cada 5 ns
    initial clk = 0;
    always #5 clk = ~clk;

    // Procedimento de teste
    initial begin
        // Inicialização
        reset = 1; load = 0; inc = 0; pc_in = 8'd0;
        #10;

        reset = 0;
        inc = 1;
        #10
        
        @(posedge clk);
        test(8'd1);

        @(posedge clk);
        test(8'd2);

        @(posedge clk);
        test(8'd3);

        inc = 0;

        // === Salto para 0x10 ===
        pc_in = 8'h10;
        load = 1;
        @(posedge clk);
        load = 0;
        test(8'h10);

        // === Incrementa mais 2 vezes ===
        inc = 1;

        @(posedge clk);
        test(8'h11);

        @(posedge clk);
        test(8'h12);

        inc = 0;

        $display("== End Simulation ==.");
        $finish;
    end

    // Tarefa para verificar o valor do PC
    task test(input logic [7:0] expected);
        if (pc_out === expected)
            $display("TEST PASS | Time=%0t | PC=%h | Esperado=%h", $time, pc_out, expected);
        else
            $display("TEST FAIL | Time=%0t | PC=%h | Esperado=%h", $time, pc_out, expected);
    endtask

endmodule
