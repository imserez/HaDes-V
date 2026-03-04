/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: cpu.sv
 */



module cpu (
    input logic clk,
    input logic rst,

    wishbone_interface.master memory_fetch_port,
    wishbone_interface.master memory_mem_port,

    input logic external_interrupt_in,
    input logic timer_interrupt_in
);


    //  ************************************************
    //  *** Connections born in FETCH stage
    //  ************************************************

    logic [31:0] fetch_to_decode_instruction_out;
    logic [31:0] fetch_to_decode_program_counter_out;

    pipeline_status::forwards_t fetch_to_decode_status_forwards_out;
    //  ************************************************
    //  *** Connections born in DECODE stage
    //  ************************************************

    logic [31:0] decode_to_exe_rs1_data_out;
    logic [31:0] decode_to_exe_rs2_data_out;
    logic [31:0] decode_to_exe_program_counter_out;
    logic [31:0] decode_to_fetch_jump_address_out;

    instruction::t  decode_to_exe_instruction_out;

    pipeline_status::forwards_t decode_to_exe_status_forwards_out;
    pipeline_status::backwards_t decode_to_fetch_status_backwards_out;

    //  ************************************************
    //  *** Connections born in EXE stage
    //  ************************************************


    logic [31:0] exe_to_mem_source_data_out;
    logic [31:0] exe_to_mem_rd_data_out;
    logic [31:0] exe_to_mem_program_counter_out;
    logic [31:0] exe_to_mem_next_pc_out;
    logic [31:0] exe_to_decode_jump_address_backwards_out;

    instruction::t  exe_to_mem_instruction_out;
    forwarding::t   exe_to_decode_forwarding_out;

    pipeline_status::forwards_t exe_to_mem_status_forward_out;
    pipeline_status::backwards_t exe_to_decode_status_backwards_out;


    //  ************************************************
    //  *** Connections born in MEM stage
    //  ************************************************

    logic [31:0]    mem_to_wb_source_data_out;
    logic [31:0]    mem_to_wb_rd_data_out;
    logic [31:0]    mem_to_wb_program_counter_out;
    logic [31:0]    mem_to_wb_next_pc_out;
    logic [31:0]    mem_to_exe_jump_address_backwards_out;


    instruction::t  mem_to_wb_instruction_out;
    forwarding::t   mem_to_decode_forwarding_out;

    pipeline_status::forwards_t mem_to_wb_status_forwards_out;
    pipeline_status::backwards_t mem_to_exe_status_backwards_out;

    //  ************************************************

    //  ************************************************
    //  *** Connections born in WB stage
    //  ************************************************


    logic [31:0] wb_to_mem_jump_address_backwards_out;

    forwarding::t wb_to_decode_forwarding_out;
    pipeline_status::backwards_t wb_to_mem_status_backwards_out;


    //  ************************************************


    fetch_stage fetch_stage( .clk(clk), .rst(rst), .wb(memory_fetch_port),
        .instruction_reg_out(fetch_to_decode_instruction_out),
        .program_counter_reg_out(fetch_to_decode_program_counter_out),
        .status_forwards_out(fetch_to_decode_status_forwards_out),
        .status_backwards_in(decode_to_fetch_status_backwards_out),
        .jump_address_backwards_in(decode_to_fetch_jump_address_out)
    );


    decode_stage decode_stage(.clk(clk), .rst(rst),
        .instruction_in(fetch_to_decode_instruction_out),
        .program_counter_in(fetch_to_decode_program_counter_out),
        .exe_forwarding_in(exe_to_decode_forwarding_out),
        .mem_forwarding_in(mem_to_decode_forwarding_out),
        .wb_forwarding_in(wb_to_decode_forwarding_out),
        .rs1_data_reg_out(decode_to_exe_rs1_data_out),
        .rs2_data_reg_out(decode_to_exe_rs2_data_out),
        .program_counter_reg_out(decode_to_exe_program_counter_out),
        .instruction_reg_out(decode_to_exe_instruction_out),
        .status_forwards_in(fetch_to_decode_status_forwards_out),
        .status_forwards_out(decode_to_exe_status_forwards_out),
        .status_backwards_in(exe_to_decode_status_backwards_out),
        .status_backwards_out(decode_to_fetch_status_backwards_out),
        .jump_address_backwards_in(exe_to_decode_jump_address_backwards_out),
        .jump_address_backwards_out(decode_to_fetch_jump_address_out)
    );


    execute_stage execute_stage(.clk(clk), .rst(rst),
        .rs1_data_in(decode_to_exe_rs1_data_out),
        .rs2_data_in(decode_to_exe_rs2_data_out),
        .instruction_in(decode_to_exe_instruction_out),
        .program_counter_in(decode_to_exe_program_counter_out),
        .source_data_reg_out(exe_to_mem_source_data_out),
        .rd_data_reg_out(exe_to_mem_rd_data_out),
        .instruction_reg_out(exe_to_mem_instruction_out),
        .program_counter_reg_out(exe_to_mem_program_counter_out),
        .next_program_counter_reg_out(exe_to_mem_next_pc_out),
        .forwarding_out(exe_to_decode_forwarding_out),
        .status_forwards_in(decode_to_exe_status_forwards_out),
        .status_forwards_out(exe_to_mem_status_forward_out),
        .status_backwards_in(mem_to_exe_status_backwards_out),
        .status_backwards_out(exe_to_decode_status_backwards_out),
        .jump_address_backwards_in(mem_to_exe_jump_address_backwards_out),
        .jump_address_backwards_out(exe_to_decode_jump_address_backwards_out)
    );


    memory_stage memory_stage(.clk(clk), .rst(rst), .wb(memory_mem_port),
        .source_data_in(exe_to_mem_source_data_out),
        .rd_data_in(exe_to_mem_rd_data_out),
        .instruction_in(exe_to_mem_instruction_out),
        .program_counter_in(exe_to_mem_program_counter_out),
        .next_program_counter_in(exe_to_mem_next_pc_out),
        .source_data_reg_out(mem_to_wb_source_data_out),
        .rd_data_reg_out(mem_to_wb_rd_data_out),
        .instruction_reg_out(mem_to_wb_instruction_out),
        .program_counter_reg_out(mem_to_wb_program_counter_out),
        .next_program_counter_reg_out(mem_to_wb_next_pc_out),
        .forwarding_out(mem_to_decode_forwarding_out),
        .status_forwards_in(exe_to_mem_status_forward_out),
        .status_forwards_out(mem_to_wb_status_forwards_out),
        .status_backwards_in(wb_to_mem_status_backwards_out),
        .status_backwards_out(mem_to_exe_status_backwards_out),
        .jump_address_backwards_in(wb_to_mem_jump_address_backwards_out),
        .jump_address_backwards_out(mem_to_exe_jump_address_backwards_out)
    );


    writeback_stage writeback_stage(.clk(clk), .rst(rst),
        .source_data_in(mem_to_wb_source_data_out),
        .rd_data_in(mem_to_wb_rd_data_out),
        .instruction_in(mem_to_wb_instruction_out),
        .program_counter_in(mem_to_wb_program_counter_out),
        .next_program_counter_in(mem_to_wb_next_pc_out),
        .external_interrupt_in(external_interrupt_in),
        .timer_interrupt_in(timer_interrupt_in),
        .forwarding_out(wb_to_decode_forwarding_out),
        .status_forwards_in(mem_to_wb_status_forwards_out),
        .status_backwards_out(wb_to_mem_status_backwards_out),
        .jump_address_backwards_out(wb_to_mem_jump_address_backwards_out)
    );


    // // TODO: Delete the following line and implement this module.
    // ref_cpu golden(.*);

endmodule
