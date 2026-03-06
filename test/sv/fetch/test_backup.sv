/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: test_fetch.sv
 */



module test_fetch;
    // --------------------------------------------------------------------------------------------
    // This module serves as an example/starting point for implementing a testbench in
    // SystemVerilog to test your modules.
    // This illustrative testbench accesses the register file, writes values to registers,
    // and reads them out.
    // --------------------------------------------------------------------------------------------
    import clk_params::*;
    import fetch_status::*;

    /*verilator lint_off UNUSED*/
    logic clk, clk_vga;
    logic rst;
    /*verilator lint_on UNUSED*/

    // System clock
    initial begin
        clk = 1;
        forever begin
            #(int'(SIM_CYCLES_PER_SYS_CLK / 2));
            clk = ~clk;
        end
    end

    // VGA pixel clock
    initial begin
        clk_vga = 1;
        forever begin
            #(int'(SIM_CYCLES_PER_VGA_CLK / 2));
            clk_vga = ~clk_vga;
        end
    end

    // --------------------------------------------------------------------------------------------
    // test bench variables
    int error_count = 0;

    // --------------------------------------------------------------------------------------------
    // device under test
    logic [4:0]  dut_read_address1;
    logic [31:0] dut_read_data1;
    logic [4:0]  dut_read_address2;
    logic [31:0] dut_read_data2;
    logic [4:0]  dut_write_address;
    logic [31:0] dut_write_data;
    logic        dut_write_enable;

    wishbone_interface              dut_memory_fetch_port();
    logic [31:0]                    dut_instruction_reg_out;
    logic [31:0]                    dut_program_counter_reg_out;
    pipeline_status::forwards_t     dut_status_forwards_out;

    logic [31:0]                    tb_jump_address_backwards_in;
    pipeline_status::backwards_t    tb_status_backwards_in;

    wishbone_interface              ref_memory_fetch_port();
    logic [31:0]                    ref_instruction_reg_out;
    logic [31:0]                    ref_program_counter_reg_out;
    pipeline_status::forwards_t     ref_status_forwards_out;


    fetch_stage dut (
        .clk(clk),
        .rst(rst),
        .wb(dut_memory_fetch_port.master),
        .instruction_reg_out(dut_instruction_reg_out),
        .program_counter_reg_out(dut_program_counter_reg_out),
        .status_forwards_out(dut_status_forwards_out),
        .status_backwards_in(tb_status_backwards_in),
        .jump_address_backwards_in(tb_jump_address_backwards_in)
    );

    ref_fetch_stage ref_fetch (
        .clk(clk),
        .rst(rst),
        .wb(ref_memory_fetch_port.master),
        .instruction_reg_out(ref_instruction_reg_out),
        .program_counter_reg_out(ref_program_counter_reg_out),
        .status_forwards_out(ref_status_forwards_out),
        .status_backwards_in(tb_status_backwards_in),
        .jump_address_backwards_in(tb_jump_address_backwards_in)
    );

    dummy_memory dut_mem(.clk(clk),
        .wb(dut_memory_fetch_port.slave)
    );

    dummy_memory ref_mem(.clk(clk),
        .wb(ref_memory_fetch_port.slave)
    );


    int test_id = 0;

    initial begin

        $dumpfile("test_fetch.fst");
        $dumpvars(0, test_fetch);

        perform_reset();
        tb_status_backwards_in = pipeline_status::STALL;

        #1;
        $display("Checking values after RESET");
        check_fetch(constants::RESET_ADDRESS, fetch_status::STAGE_FETCH);

        $display("--- Testing if keeps the value when backwards is STALL ---");
        @(posedge clk);

        wait(dut_memory_fetch_port.ack == 1);

        @(posedge clk); #1;
        $display("Checking HOLD after 1 cycle");
        check_fetch(constants::RESET_ADDRESS, fetch_status::STAGE_HOLD);
        $display("Checking HOLD after 14 cycles");
        repeat(14) @(posedge clk); #1;
        check_fetch(constants::RESET_ADDRESS, fetch_status::STAGE_HOLD);
        $display("Checking the value readed");
        check_instruction_reg_out(constants::RESET_ADDRESS, dut.pc >> 2);


        $display("--- Test: Resume after HOLD ---");
        tb_status_backwards_in = pipeline_status::READY;
        @(posedge clk);

        wait(dut_memory_fetch_port.ack == 1);
        @(posedge clk); #1;
        check_fetch(32'h4, fetch_status::STAGE_FETCH);


        $display("--- Test: Immediate Jump ---");
        tb_jump_address_backwards_in = 32'h20;
        tb_status_backwards_in = pipeline_status::JUMP;

        @(posedge clk); #1;
        check_fetch(32'h20, fetch_status::STAGE_FETCH);

        // Volvemos a READY para que termine de pedir la instrucción en 0x20
        tb_status_backwards_in = pipeline_status::READY;
        wait(dut_memory_fetch_port.ack == 1);
        @(posedge clk); #1;
        check_fetch(32'h20, fetch_status::STAGE_FETCH);


        $display("--- Test: Misaligned Jump (Error case) ---");
        tb_jump_address_backwards_in = 32'h23;
        tb_status_backwards_in = pipeline_status::JUMP;

        @(posedge clk); #1;
        check_fetch(32'h23, fetch_status::STAGE_ERR);

        if (dut_status_forwards_out !== pipeline_status::FETCH_MISALIGNED) begin
            $display("ERROR: No se detecto FETCH_MISALIGNED en la salida");
            error_count++;
        end

        $display("--- Finished tests ---");
        print_test_done();
        $finish();

    end

    task automatic perform_reset();
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
        @(posedge clk);
    endtask

    task automatic check_instruction_reg_out(logic [31:0] exp_pc_reg_out, logic [31:0] exp_reg_out);
        if (dut_program_counter_reg_out !== exp_pc_reg_out || dut.instruction_reg_out >> 2 !== exp_reg_out) begin
            $display("ERROR in time: %t", $time);
            $display("Expected: PC-OUT=%h, Instruction=%h", exp_pc_reg_out, exp_reg_out);
            $display("Obtained: PC-OUT=%h, Instruction=%h", dut.program_counter_reg_out, dut.instruction_reg_out);
            error_count++;
        end else begin
            $display("CHECK OK in time %t", $time);
            $display("Obtained: PC-OUT=%h, Instruction=%h", dut.program_counter_reg_out, dut.instruction_reg_out);

        end
    endtask


    task automatic check_fetch(logic [31:0] exp_pc, logic [1:0] exp_state);

        if (dut_program_counter_reg_out !== exp_pc || dut.curr_fetch_status !== exp_state) begin
            $display("ERROR in time: %t", $time);
            $display("Expected: PC=%h, Fetch_Status=%b", exp_pc, exp_state);
            $display("Obtained: PC=%h, Fetch_Status=%s", dut.program_counter_reg_out, dut.curr_fetch_status.name());
            error_count++;
        end else begin
            $display("CHECK OK in time %t", $time);
            $display("Obtained: PC=%h, Fetch_Status=%s", dut.program_counter_reg_out, dut.curr_fetch_status.name());
        end
    endtask


    // --------------------------------------------------------------------------------------------
    // |                                    Main Test Function                                    |
    // --------------------------------------------------------------------------------------------
    // initial begin
    //     $dumpfile("test_example.fst");
    //     $dumpvars;

    //     reset_module_inputs();

    //     // Write value to register ----------------------------------------------------------------
    //     $display("------------------------------ (%6d ns) Write value to register", $time());
    //     perform_rst();

    //     @(posedge clk); #1;
    //     set_write_port(.write_enable(1), .write_addr(1), .write_data(32'hcafebabe));
    //     set_read_ports(.addr1(1), .addr2(0));
    //     // check if data is correct
    //     @(posedge clk);
    //     prove(.exp_read_data1(0), .exp_read_data2(0)); // read old value
    //     #1; // wait one simulation cycle
    //     prove(.exp_read_data1(32'hcafebabe), .exp_read_data2(0)); // read new value

    //     // set new inputs
    //     set_write_port(.write_enable(1), .write_addr(31), .write_data(32'hdeadbeef));
    //     set_read_ports(.addr1(1), .addr2(31));
    //     // check if data is correct
    //     @(posedge clk);
    //     prove(.exp_read_data1(32'hcafebabe), .exp_read_data2(0)); // read old value
    //     #1; // wait one simulation cycle
    //     prove(.exp_read_data1(32'hcafebabe), .exp_read_data2(32'hdeadbeef)); // read new value

    //     // Check asynchron read -------------------------------------------------------------------
    //     @(posedge clk);
    //     $display("------------------------------ (%6d ns) Check asynchron read", $time());

    //     set_read_ports(.addr1(31), .addr2(2));
    //     #1; // wait one simulation cycle
    //     prove(.exp_read_data1(32'hdeadbeef), .exp_read_data2(0));

    //     set_read_ports(.addr1(30), .addr2(1));
    //     #1; // wait one simulation cycle
    //     prove(.exp_read_data1(0), .exp_read_data2(32'hcafebabe));

    //     set_read_ports(.addr1(1), .addr2(0));
    //     #1; // wait one simulation cycle
    //     prove(.exp_read_data1(32'hcafebabe), .exp_read_data2(0));

    //     @(posedge clk);
    //     @(posedge clk);

    //     // Signal test passed ---------------------------------------------------------------------
    //     print_test_done();

    //     // Stop simulation ------------------------------------------------------------------------
    //     $finish();
    // end

    // --------------------------------------------------------------------------------------------
    function void reset_module_inputs();
        dut_read_address1 = 5'(0);
        dut_read_address2 = 5'(0);
        dut_write_address = 5'(0);
        dut_write_data    = 0;
        dut_write_enable  = 0;
    endfunction

    function void perform_rst();
        @(negedge clk); #1;
        rst = 1;
        // reset module inputs
        reset_module_inputs();
        // clear reset
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;
    endfunction

    // --------------------------------------------------------------------------------------------
    /*verilator lint_off UNUSED*/
    function void set_write_port(logic write_enable, int write_addr, logic [31:0] write_data);
        dut_write_address = 5'(write_addr);
        dut_write_data    = write_data;
        dut_write_enable  = write_enable;
    endfunction

    function void set_read_ports(int addr1, int addr2);
        dut_read_address1 = 5'(addr1);
        dut_read_address2 = 5'(addr2);
    endfunction
    /*verilator lint_on UNUSED*/

    // --------------------------------------------------------------------------------------------
    function void prove(logic [31:0] exp_read_data1, logic [31:0] exp_read_data2);
        assert(dut_read_data1 == exp_read_data1) else begin $display("(%6d ns) read_data1 = 0x%x (0x%x)", $time(), dut_read_data1, exp_read_data1); error_count++; end;
        assert(dut_read_data2 == exp_read_data2) else begin $display("(%6d ns) read_data2 = 0x%x (0x%x)", $time(), dut_read_data2, exp_read_data2); error_count++; end;
    endfunction

    // --------------------------------------------------------------------------------------------
    // print helper functions
    function void print_test_done();
        if (error_count != 0) begin
            $display("\033[0;31m"); // color_red
            $display("Some test(s) failed! (# Errors: %4d)", error_count);
        end
        else begin
            $display("\033[0;32m"); // color green
            $display("All tests passed! (# Errors: %4d)", error_count);
        end
        $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        $display("!!!!!!!!!!!!!!!!!!!! TEST DONE !!!!!!!!!!!!!!!!!!!!");
        $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        $display("\033[0m"); // color off
    endfunction

endmodule
