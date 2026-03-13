module test_decode;

    import clk_params::*;
    import decode_status::*;
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
    forwarding::t tb_exe_forwarding_in;
    forwarding::t tb_mem_forwarding_in;
    forwarding::t tb_wb_forwarding_in;
    pipeline_status::backwards_t tb_status_backwards_in;
    logic [31:0] tb_jump_address_backwards_in;


    logic [31:0]   dut_rs1_data_reg_out;
    logic [31:0]   dut_rs2_data_reg_out;
    logic [31:0]   dut_program_counter_reg_out;
    instruction::t dut_instruction_reg_out;

    pipeline_status::forwards_t  dut_status_forwards_out;
    pipeline_status::backwards_t dut_status_backwards_out;
    logic [31:0] dut_jump_address_backwards_out;


    // Fetch_stage
    logic [4:0]  fetch_read_address1;
    logic [31:0] fetch_read_data1;
    logic [4:0]  fetch_read_address2;
    logic [31:0] fetch_read_data2;
    logic [4:0]  fetch_write_address;
    logic [31:0] fetch_write_data;
    logic        fetch_write_enable;
    wishbone_interface              fetch_memory_fetch_port();
    logic [31:0]                    fetch_instruction_reg_out;
    logic [31:0]                    fetch_program_counter_reg_out;
    pipeline_status::forwards_t     fetch_status_forwards_out;



    decode_stage dut (
        .clk(clk),
        .rst(rst),
        .instruction_in(fetch_instruction_reg_out),
        .program_counter_in(fetch_program_counter_reg_out),
        .exe_forwarding_in(tb_exe_forwarding_in),
        .mem_forwarding_in(tb_mem_forwarding_in),
        .wb_forwarding_in(tb_wb_forwarding_in),
        .rs1_data_reg_out(dut_rs1_data_reg_out),
        .rs2_data_reg_out(dut_rs2_data_reg_out),
        .program_counter_reg_out(dut_program_counter_reg_out),
        .instruction_reg_out(dut_instruction_reg_out),
        .status_forwards_in(fetch_status_forwards_out),
        .status_forwards_out(dut_status_forwards_out),
        .status_backwards_in(tb_status_backwards_in),
        .status_backwards_out(dut_status_backwards_out),
        .jump_address_backwards_in(tb_jump_address_backwards_in),
        .jump_address_backwards_out(dut_jump_address_backwards_out)
    );

    // using my fetch-stage
    fetch_stage dut (
        .clk(clk),
        .rst(rst),
        .wb(fetch_memory_fetch_port.master),
        .instruction_reg_out(fetch_instruction_reg_out),
        .program_counter_reg_out(fetch_program_counter_reg_out),
        .status_forwards_out(fetch_status_forwards_out),
        .status_backwards_in(dut_status_backwards_out),
        .jump_address_backwards_in(dut_jump_address_backwards_out)
    );

    logic tb_wb_err = 0;

    dummy_memory fetch_mem(.clk(clk),
        .wb(fetch_memory_fetch_port.slave),
        .err(tb_wb_err)
    );

endmodule