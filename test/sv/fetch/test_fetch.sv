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

    //TODO: what if I send here the whole .master? instead of individuals.
    dummy_memory dut_mem(.clk(clk),
        .wb(dut_memory_fetch_port.slave)
    );

    dummy_memory ref_mem(.clk(clk),
        .wb(ref_memory_fetch_port.slave)
    );


    initial begin
        $dumpfile("test_fetch.fst");
        $dumpvars(0, test_fetch);

        rst = 1;
        // tb_jump_address_backwards_in = 32'h0;

        tb_status_backwards_in = pipeline_status::STALL;

        repeat(5) @(posedge clk);

        rst = 0;
        $display("Finish Reset");

        @(posedge clk);
        tb_status_backwards_in = pipeline_status::READY;

        repeat(20) @(posedge clk);

        $finish();
    end



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
