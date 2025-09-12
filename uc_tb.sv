`timescale 1ns/1ps

module uc_tb;

    // --- sinais da UC ---
    logic clk;
    logic reset;
    logic [7:0] data_in;
    logic [7:0] data_out;
    logic mem_write;
    logic [7:0] address_bus;
    logic [3:0] OPERACAO;
    logic [7:0] OPER_A, OPER_B;
    logic [7:0] RESULT;
    logic Cout;
    logic N,Z,C,B,V;
    logic ERROR;

    // --- Instancia a ALU ---
    alu my_alu (
        .A(OPER_A),
        .B(OPER_B),
        .op(OPERACAO),
        .Y(RESULT),
        .N(N),
        .Z(Z),
        .C(C),
        .B(B),
        .V(V)
    );

    // --- Instancia a UC ---
    uc my_uc (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_out(data_out),
        .mem_write(mem_write),
        .address_bus(address_bus),
        .OPERACAO(OPERACAO),
        .OPER_A(OPER_A),
        .OPER_B(OPER_B),
        .RESULT(RESULT),
        .Cout(Cout),
        .N(N),
        .Z(Z),
        .C(C),
        .B(B),
        .V(V),
        .ERROR(ERROR)
    );

    // --- Clock ---
    initial clk = 0;
    always #5 clk = ~clk; // clock 10ns período

    // --- Testes ---
    initial begin
        // Inicialização
        reset = 1;
        data_in = 8'b0;
        #20;
        reset = 0;

        // Teste 1: LDA
        data_in = 8'hAA; // dado da memória
        #10;
        if (RESULT == 8'hAA)
            $display("Teste LDA: PASS");
        else
            $display("Teste LDA: FAIL - Resultado: %h", RESULT);

        // Teste 2: ADD
        OPER_A = 8'h10;
        OPER_B = 8'h20;
        OPERACAO = 4'b0001; // operação ADD
        #10;
        if (RESULT == 8'h30)
            $display("Teste ADD: PASS");
        else
            $display("Teste ADD: FAIL - Resultado: %h", RESULT);

        // Teste 3: NOT
        OPER_A = 8'h0F;
        OPERACAO = 4'b0101; // operação NOT
        #10;
        if (RESULT == 8'hF0)
            $display("Teste NOT: PASS");
        else
            $display("Teste NOT: FAIL - Resultado: %h", RESULT);

        // Finaliza simulação
        $display("Testbench finalizado!");
        $finish;
    end

endmodule

