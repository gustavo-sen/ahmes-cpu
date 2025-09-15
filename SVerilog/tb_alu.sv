module tb_alu;

    reg [3:0] operacao;
    reg [7:0] operA;
    reg [7:0] operB;
    reg       Cin;

    wire [7:0] result;
    wire N, Z, C, B, V;

    integer fail_count = 0;  // contador de falhas

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

    task print_output;
        input [7:0] esperado_result;
        input exp_N, exp_Z, exp_C, exp_B, exp_V;
        reg passed;
        reg [15*8:1] op_name;
        reg [4:0] exp_flags;
        reg [4:0] act_flags;
        begin
            case (operacao)
                4'b0001: op_name = "ADIC(0001)";
                4'b0010: op_name = "SUB (0010)";
                4'b0011: op_name = "OU  (0011)";
                4'b0100: op_name = "E   (0100)";
                4'b0101: op_name = "NAO (0101)";
                4'b0110: op_name = "DLE (0110)";
                4'b0111: op_name = "DLD (0111)";
                4'b1000: op_name = "DAE (1000)";
                4'b1001: op_name = "DAD (1001)";
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

    initial begin
        $display("Starting ALU testbench");

        // addition 
        // 10 + 20 = 30
        test(
            10,             // operA 
            20,             // operB 
            4'b0001,        // operacao (ADIC)
            0,              // Cin
            30,             // expected result 
            0,              // expected N
            0,              // expected Z
            0,              // expected C
            0,              // expected B
            0               // expected V
        );

        test(
            255,            // operA 
            1,              // operB 
            4'b0001,        // operacao (ADIC - carry)
            0,              // Cin
            0,              // expected result 
            0,              // expected N
            1,              // expected Z
            1,              // expected C
            0,              // expected B
            0               // expected V
        );

        test(
            50,             // operA 
            20,             // operB 
            4'b0010,        // operacao (SUB)
            0,              // Cin
            30,             // expected result 
            0,              // expected N
            0,              // expected Z
            0,              // expected C
            0,              // expected B
            0               // expected V
        );

        test(
            0,              // operA 
            1,              // operB 
            4'b0010,        // operacao (SUB - borrow)
            0,              // Cin
            255,            // expected result 
            1,              // expected N
            0,              // expected Z
            0,              // expected C
            1,              // expected B
            0               // expected V
        );

        test(
            170,            // operA 
            85,             // operB 
            4'b0011,        // operacao (OU)
            0,              // Cin
            255,            // expected
            1,              // expected N
            0,              // expected Z
            0,              // expected C
            0,              // expected B
            0               // expected V
        );

        test(
            240,            // operA 
            0,              // operB 
            4'b0101,        // operacao (NAO)
            0,              // Cin
            15,             // expected 
            0,              // expected N
            0,              // expected Z
            0,              // expected C
            0,              // expected B
            0               // expected V
        );

        test(
            129,            // operA 
            0,              // operB 
            4'b0110,        // operacao (DLE)
            1,              // Cin
            3,              // expected result 
            0,              // expected N
            0,              // expected Z
            1,              // expected C
            0,              // expected B
            0               // expected V
        );

        $display("Testbench finished. Total failed tests: %0d", fail_count);
        $finish;
    end

    task test;
        input [7:0] a, b;
        input [3:0] op;
        input c_in;
        input [7:0] esperado_res;
        input exp_N, exp_Z, exp_C, exp_B, exp_V;
        begin
            operA = a; operB = b; operacao = op; Cin = c_in;
            #10;
            print_output(esperado_res, exp_N, exp_Z, exp_C, exp_B, exp_V);
        end
    endtask

endmodule
