module tb_alu;

    // --- Entradas para a ULA ---
    reg [3:0] operacao;
    reg [7:0] operA;
    reg [7:0] operB;
    reg       Cin;

    // --- Saídas da ULA ---
    wire [7:0] result;
    wire N, Z, C, B, V;

    // --- Lógica do Testbench ---
    integer fail_count = 0;  // contador de falhas

    // Instância da Unidade sob Teste (Unit Under Test - UUT)
    ALU uut (
        .operacao(operacao),
        .operA(operA),
        .operB(operB),
        .Cin(Cin),
        .result(result),
        .N(N),
        .Z(Z),
        .C(C),
        .B(B),
        .V(V)
    );

    // Tarefa para verificar e imprimir o resultado de um teste
    task print_output;
        input [7:0] esperado_result;
        input exp_N, exp_Z, exp_C, exp_B, exp_V;
        reg passed;
        reg [15*8:1] op_name;
        reg [4:0] exp_flags;
        reg [4:0] act_flags;
        begin
            // Tabela de opcodes CORRIGIDA para corresponder à ULA
            case (operacao)
                4'b0001: op_name = "ADIC(0001)";
                4'b0010: op_name = "SUB (0010)";
                4'b0011: op_name = "OU  (0011)";
                4'b0100: op_name = "E   (0100)";
                4'b0101: op_name = "NAO (0101)";
                4'b0110: op_name = "XOU (0110)";
                4'b0111: op_name = "DLE (0111)"; // Corrigido
                4'b1000: op_name = "DLD (1000)"; // Corrigido
                4'b1001: op_name = "DAE (1001)"; // Corrigido
                4'b1010: op_name = "DAD (1010)"; // Corrigido
                default: op_name = "UNKNOWN";
            endcase

            exp_flags = {exp_N, exp_Z, exp_C, exp_V, exp_B};
            act_flags = {N, Z, C, V, B};

            passed = (result === esperado_result) &&
                     (N === exp_N) && (Z === exp_Z) && (C === exp_C) && (B === exp_B) && (V === exp_V);

            if (!passed)
                fail_count = fail_count + 1;

            $display("TEST %s | Op: %s | A=%0d B=%0d Cin=%b | exp res=%0d act res=%0d | Flags exp=NZCVB=%b act=%b",
                (passed ? "PASS" : "FAIL"),
                op_name,
                operA, operB, Cin,
                esperado_result, result,
                exp_flags, act_flags
            );
        end
    endtask

    // Tarefa genérica para executar um único teste
    task test;
        input [7:0] a, b;
        input [3:0] op;
        input c_in;
        input [7:0] esperado_res;
        input exp_N, exp_Z, exp_C, exp_B, exp_V;
        begin
            operA = a; operB = b; operacao = op; Cin = c_in;
            #10; // Espera 10 unidades de tempo para a lógica combinacional propagar
            print_output(esperado_res, exp_N, exp_Z, exp_C, exp_B, exp_V);
        end
    endtask

    // Bloco principal que executa a sequência de testes
    initial begin
        $display("----------------------------------------");
        $display("Testbench ULA");
        $display("----------------------------------------");

        // --- Testes de Adição ---
        // opA,opB,opcode,cin,expt,res,N,Z,C,B,V
        test(10, 20, 4'b0001, 0, 30, 0,0,0,0,0);  // 10 + 20 = 30
        test(255, 1, 4'b0001, 0, 0, 0,1,1,0,0);   // 255 + 1 = 0 (com Carry)
        test(127, 1, 4'b0001, 0, 128, 1,0,0,0,1); // 127 + 1 = 128 (com Overflow)

        // --- Testes de Subtração ---
        // opA,opB,opcode,cin,expt,res,N,Z,C,B,V
        test(50, 20, 4'b0010, 0, 30, 0,0,0,0,0);  // 50 - 20 = 30
        test(0, 1, 4'b0010, 0, 255, 1,0,0,1,0);   // 0 - 1 = 255 (com Borrow)
        
        // --- Testes Lógicos ---
        // opA,opB,opcode,cin,expt,res,N,Z,C,B,V
        test(170, 85, 4'b0011, 0, 255, 1,0,0,0,0);   // OU: 10101010 | 01010101 = 11111111
        test(240, 0, 4'b0101, 0, 15, 0,0,0,0,0);     // NAO: ~11110000 = 00001111

        // --- Novos testes adicionados para cobertura ---
        // opA,opB,opcode,cin,expt,res,N,Z,C,B,V
        test(240, 170, 4'b0100, 0, 160, 1,0,0,0,0);  // E: 11110000 & 10101010 = 10100000
        test(240, 170, 4'b0110, 0, 90, 0,0,0,0,0);   // XOU: 11110000 ^ 10101010 = 01011010

        // --- Testes de Rotação e Deslocamento ---
        // opA,opB,opcode,cin,expt,res,N,Z,C,B,V
        // DLE: Rotação para a esquerda
        test(129, 0, 4'b0111, 1, 3, 0,0,1,0,0);
        
        // DLD: Rotação para a direita
        test(129, 0, 4'b1000, 1, 192, 1,0,1,0,0);
        
        // DAE: Deslocamento aritmético para a esquerda
        test(129, 0, 4'b1001, 0, 2, 0,0,1,0,0);
        
        // DAD: Deslocamento lógico para a direita
        test(129, 0, 4'b1010, 0, 64, 0,0,1,0,0);

        $display("----------------------------------------");
        if (fail_count == 0)
            $display(">>> End Simulation (PASS) <<<");
        else
            $display(">>> End Simulaton (Fail): %0d <<<", fail_count);
        $display("----------------------------------------");
        
        $finish;
    end
endmodule