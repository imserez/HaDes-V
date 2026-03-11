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

    import decode_status::*;

    instruction::t  decoded_instruction;

    instruction_decoder decoder (
        .instruction_in(instruction_in),
        .instruction_out(decoded_instruction)
    );

    register_file   reg_file (
        .clk(clk),
        .rst(rst),
        .read_address1(decoded_instruction.rs1_address),
        .read_data1(rs1_data_reg_out),
        .read_address2(decoded_instruction.rs2_address),
        .read_data2(rs2_data_reg_out),
        .write_address(decoded_instruction.rd_address),
        .write_data(0),
        .write_enable(0)
    );

    // Forwards
    // assign jump_address_backwards_out   = jump_address_backwards_in;

    // Backwards
    assign jump_address_backwards_out = jump_address_backwards_in



    always_ff @(posedge clk) begin

        if (rst) begin
            // Output Registers
            rs1_data_reg_out <= 0;
            rs2_data_reg_out <= 0;
            instruction_reg_out <= 0;
            program_counter_reg_out <= 0;
            // Pipeline Control
            status_backwards_out <= pipeline_status::READY;
            status_forwards_out <= pipeline_status::BUBBLE;
            // ----------
            curr_dec_status <= STAGE_WAIT;
        end
        else begin
            case (curr_dec_status)

                STAGE_WAIT: begin
                    status_backwards_out <= pipeline_status::READY;
                    if (status_forwards_in == pipeline_status::VALID) begin
                        program_counter_reg_out <= program_counter_in;
                        instruction_reg_out <= decoded_instruction;
                    end
                end
            endcase

        end


    end


    // // TODO: Delete the following line and implement this module.
    // ref_decode_stage golden(.*);

endmodule
