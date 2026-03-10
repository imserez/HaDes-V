/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: decode_stage.sv
 */



module decode_stage (
    input logic clk,
    input logic rst,

    // Inputs
    input logic [31:0]  instruction_in,
    input logic [31:0]  program_counter_in,
    input forwarding::t exe_forwarding_in,
    input forwarding::t mem_forwarding_in,
    input forwarding::t wb_forwarding_in,

    // Output Registers
    output logic [31:0]   rs1_data_reg_out,
    output logic [31:0]   rs2_data_reg_out,
    output logic [31:0]   program_counter_reg_out,
    output instruction::t instruction_reg_out,

    // Pipeline control
    input  pipeline_status::forwards_t  status_forwards_in,
    output pipeline_status::forwards_t  status_forwards_out,
    input  pipeline_status::backwards_t status_backwards_in,
    output pipeline_status::backwards_t status_backwards_out,
    input  logic [31:0] jump_address_backwards_in,
    output logic [31:0] jump_address_backwards_out
);

//     import decode_status::*;

//     decode_state_t curr_dec_status = STAGE_DECODE;



//     logic [31:0]  reg_instruction_in;
//     logic [31:0]  reg_pc_in,


//     always_ff @(posedge clk) begin

//         if (rst) begin
//             status_backwards_out <= pipeline_status::BUBBLE;
//             jump_address_backwards_out <= 0;
//             instruction_reg_out <= 0;
//             rs1_data_reg_out <= 0;
//             rs2_data_reg_out <= 0;
//             status_forwards_out <= pipeline_status::BUBBLE;
//             curr_dec_status <= STAGE_START;
//         end
//         else begin
//             case (curr_dec_status)
//                 STAGE_START: begin
//                     curr_dec_status <= STAGE_WAIT;
//                     status_backwards_out <= pipeline_status::READY;
//                     status_forwards_out <= pipeline_status::BUBBLE;
//                 end
//                 STAGE_WAIT: begin
//                     status_forwards_out <= pipeline_status::BUBBLE;

//                     if (status_forwards_in == pipeline_status::VALID) begin
//                         reg_instruction_in <= instruction_in;
//                         reg_pc_in <= program_counter_in;
//                         curr_dec_status <= STAGE_DECODE;
//                         status_backwards_out <= pipeline_status::BUBBLE;
//                     end
//                 end
//                 STAGE_DECODE: begin

//                 end

//             endcase

//         end


//     end



    // TODO: Delete the following line and implement this module.
    ref_decode_stage golden(.*);

endmodule
