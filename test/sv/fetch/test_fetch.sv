module test_fetch;

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


    // --------------------------------------------------------------------------------------------
    // test bench variables
    int error_count = 0;
    int test_id     = 0;
    // --------------------------------------------------------------------------------------------

    initial begin
        $dumpfile("test_fetch.fst");
        $dumpvars(0, test_fetch);

        tb_status_backwards_in = pipeline_status::STALL;

        perform_reset();
        check_fetch(constants::RESET_ADDRESS, 0, fetch_status::STAGE_START);
        @(posedge clk); #1;
        check_fetch(constants::RESET_ADDRESS, 0, fetch_status::STAGE_FETCH);
        @(posedge clk); #1;

        wait(dut_memory_fetch_port.ack == 1);
        check_fetch(constants::RESET_ADDRESS, constants::RESET_ADDRESS, fetch_status::STAGE_HOLD);

        @(posedge clk); #1;
        tb_status_backwards_in = pipeline_status::READY;

        repeat(2) @(posedge clk);
        check_fetch(constants::RESET_ADDRESS+4, constants::RESET_ADDRESS, fetch_status::STAGE_FETCH);


        repeat(10) @(posedge clk);

        // Signal test passed ---------------------------------------------------------------------
        print_test_done();

        // Stop simulation ------------------------------------------------------------------------
        $finish();


    end;

    // ------------- State-modify Tasks
    task perform_reset();
        @(negedge clk); #1;
        rst = 1;
        repeat(2) @(posedge clk);
        rst = 0;
    endtask

    // ------------- Tesing tasks

    task automatic check_fetch(logic [31:0] exp_pc, logic [31:0] exp_pc_reg_out, fetch_state_t exp_state);
        assert(dut.pc == exp_pc)
            else begin
                $error("PC error in <%0t.> Expected: [%h], Obtained: [%h]", $time, exp_pc, dut.pc);
                error_count++;
            end

        assert(dut.program_counter_reg_out == exp_pc_reg_out)
            else begin
                $error("PC error in <%0t.> Expected: [%h], Obtained: [%h]", $time, exp_pc_reg_out, dut.program_counter_reg_out);
                error_count++;
            end

        assert(dut.curr_fetch_status == exp_state)
            else begin
                $error("Curr. Fetch Status Error in <%0t.> Expected: [%h], Obtained: [%s]", $time, exp_state.name(), dut.curr_fetch_status.name());
                error_count++;
            end
    endtask

    task automatic check_forwards_out(pipeline_status::forwards_t exp_status_fowards_out);
        assert (dut.status_forwards_out == exp_status_fowards_out)
            else begin
                 $error("Status forwards out error. <%0t.> Expected: [%s], Obtained: [%s]", $time, exp_status_fowards_out.name(), dut.status_forwards_out.name());
                    error_count++;
            end

    endtask

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


endmodule;
