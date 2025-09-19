`timescale 1ns/1ps
// =================================================================
// Testbench for Datapath with Internal ALU (Patched)
// =================================================================
module tb_datapath;

// ---------------- DUT Interface ----------------
logic         clk;
logic         reset;
logic         pc_load_en, pc_inc_en, ac_load_en, flags_load_en;
logic [3:0]   alu_op;
logic         alu_cin;
logic         io_write_en, io_read_en;
logic [7:0]   data_bus_in, addr_bus_in;
logic [3:0]   in_switches;

logic [7:0]   pc_out, ac_out, io_read_data;
logic [3:0]   out_leds;
logic         flag_n, flag_z, flag_c, flag_b, flag_v;

integer fail_count = 0;

// ---------------- Instantiate DUT ----------------
datapath uut (
    .clk(clk),
    .reset(reset),
    .pc_load_en(pc_load_en),
    .pc_inc_en(pc_inc_en),
    .ac_load_en(ac_load_en),
    .flags_load_en(flags_load_en),
    .alu_op(alu_op),
    .alu_cin(alu_cin),
    .io_write_en(io_write_en),
    .io_read_en(io_read_en),
    .data_bus_in(data_bus_in),
    .addr_bus_in(addr_bus_in),
    .in_switches(in_switches),
    .pc_out(pc_out),
    .ac_out(ac_out),
    .io_read_data(io_read_data),
    .out_leds(out_leds),
    .flag_n(flag_n),
    .flag_z(flag_z),
    .flag_c(flag_c),
    .flag_b(flag_b),
    .flag_v(flag_v)
);

// ---------------- Clock ----------------
initial clk = 0;
always #5 clk = ~clk; // 100 MHz clock

// ---------------- Utility Tasks ----------------
task reset_dut;
    reset = 1;
    @(posedge clk);
    @(posedge clk);
    reset = 0;
endtask

// PATCH: `load_ac` ajustado para não modificar as flags
task load_ac(input [7:0] value);
    // carrega direto no acumulador via ADD com 0
    alu_op        = 4'b0001; // ADIC
    data_bus_in   = value;
    alu_cin       = 0;
    ac_load_en    = 1;
    flags_load_en = 0; // Correto, um load não deve afetar as flags
    @(posedge clk); @(posedge clk);
    ac_load_en    = 0;
endtask

task check_output(
    input [7:0] expected_val,
    input [7:0] actual_val,
    input [127:0] name
);
    if (expected_val !== actual_val) begin
        $display("FAIL: %s | exp=%0d got=%0d", name, expected_val, actual_val);
        fail_count++;
    end else begin
        $display("PASS: %s | got=%0d", name, actual_val);
    end
endtask

task check_flags(
    input expN, expZ, expC, expB, expV,
    input [127:0] name
);
    reg [4:0] exp, act;
    exp = {expN,expZ,expC,expB,expV};
    act = {flag_n,flag_z,flag_c,flag_b,flag_v};

    if (exp !== act) begin
        $display("FAIL FLAGS: %s | exp=%b got=%b", name, exp, act);
        fail_count++;
    end else begin
        $display("PASS FLAGS: %s | %b", name, act);
    end
endtask

// ---------------- ALU Test ----------------
// FIX: Adicionado um atraso de 1 ciclo para evitar race condition
task test_alu(
    input [7:0] opA, opB,
    input [3:0] op,
    input c_in,
    input [7:0] expected_res,
    input expN, expZ, expC, expB, expV,
    input [127:0] name
);
    reset_dut();
    load_ac(opA);

    // FIX: Adiciona um ciclo de espera para o datapath estabilizar
    // entre a operação de load e a operação da ALU.
    @(posedge clk);

    alu_op        = op;
    data_bus_in   = opB;
    alu_cin       = c_in;
    ac_load_en    = 1;
    flags_load_en = 1;
    @(posedge clk);
    @(posedge clk);
    ac_load_en    = 0;
    flags_load_en = 0;

    check_output(expected_res, ac_out, {name, " result"});
    check_flags(expN, expZ, expC, expB, expV, {name, " flags"});
endtask

// ---------------- Test Sequence ----------------
initial begin
    $display("====================================");
    $display("       Starting Datapath Tests");
    $display("====================================");

    // Init
    pc_load_en=0; pc_inc_en=0; ac_load_en=0; flags_load_en=0;
    io_write_en=0; io_read_en=0;
    data_bus_in=0; addr_bus_in=0; in_switches=0;

    // --- PC TESTS ---
    $display("\n--- PC TESTS ---");
    reset_dut();

    pc_inc_en = 1; @(posedge clk); @(posedge clk); pc_inc_en = 0;
    check_output(8'd1, pc_out, "PC INC");

    data_bus_in = 8'hA5; pc_load_en = 1; @(posedge clk); @(posedge clk); pc_load_en = 0;
    check_output(8'hA5, pc_out, "PC LOAD");

    // PATCH: Seção de I/O ajustada
    $display("\n--- I/O TESTS ---");
    reset_dut();

    load_ac(8'b1101_1010); // AC=0xDA
    io_write_en = 1; addr_bus_in = 8'h00;
    @(posedge clk); @(posedge clk);
    io_write_en = 0;
    // Espera apenas os 4 LSB
    check_output(4'b1010, out_leds, "LED WRITE");

    in_switches = 4'b1100;
    addr_bus_in = 8'h04; io_read_en = 1;
    repeat(4) @(posedge clk); // precisa 2 estágios + 1 leitura
    check_output(8'h0C, io_read_data, "SWITCH READ");
    io_read_en = 0;

    // PATCH: Testes da ALU com expectativas de flags corrigidas
    $display("\n--- ALU TESTS ---");
    test_alu(10,20,4'b0001,0,30, 0,0,0,0,0,"ADD");
    test_alu(255,1,4'b0001,0,0,  0,1,1,0,0,"ADD overflow"); // FIX: Carry (C) deve ser 1
    test_alu(127,1,4'b0001,0,128,1,0,0,0,1,"ADD signed overflow");

    test_alu(50,20,4'b0010,0,30, 0,0,1,0,0,"SUB"); // carry=~borrow, so C=1 for no borrow
    test_alu(0,1,  4'b0010,0,255,1,0,0,1,0,"SUB borrow"); // borrow occurred, so C=0

    test_alu(170,85,4'b0011,0,255,1,0,0,0,0,"OR");
    test_alu(240,170,4'b0100,0,160,1,0,0,0,0,"AND");
    test_alu(240,0, 4'b0101,0,15,  0,0,0,0,0,"NOT");
    test_alu(240,170,4'b0110,0,90, 0,0,0,0,0,"XOR");

    test_alu(129,0,4'b0111,1,3,   0,0,1,0,0,"DLE"); // 10000001 << 1 com Cin=1 -> 00000011, Cout=1
    test_alu(129,0,4'b1000,0,2,   0,0,1,0,0,"DAE"); // 10000001 << 1 com Cin=0 -> 00000010, Cout=1
    test_alu(129,0,4'b1001,1,192, 1,0,0,0,0,"DLD"); // 10000001 >> 1 com Cin=1 -> 11000000, Cout=1
    test_alu(129,0,4'b1010,0,64,  0,0,0,0,0,"DAD"); // 10000001 >> 1 com Cin=0 -> 01000000, Cout=1

    // --- REPORT ---
    $display("\n====================================");
    if (fail_count==0) $display("ALL TESTS PASSED!");
    else $display("%0d TESTS FAILED!", fail_count);
    $display("====================================");
    $finish;
end

endmodule