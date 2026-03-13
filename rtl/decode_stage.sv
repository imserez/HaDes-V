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
    // import pipeline_status::*;

    instruction::t  decoded_instruction;

    instruction_decoder decoder (
        .instruction_in(instruction_in),        // directly from fetch
        .instruction_out(decoded_instruction)
    );

    logic [31:0] rf_read_data1;
    logic [31:0] rf_read_data2;

    register_file   reg_file (
        .clk(clk),
        .rst(rst),
        .read_address1(decoded_instruction.rs1_address), // directly from fetch
        .read_data1(rf_read_data1),
        .read_address2(decoded_instruction.rs2_address),
        .read_data2(rf_read_data2),
        .write_address(wb_forwarding_in.address), // usage of WB forwarding
        .write_data(wb_forwarding_in.data),
        .write_enable(wb_forwarding_in.data_valid)
    );


    decode_state_t curr_dec_status;


    // Forwards
    // assign jump_address_backwards_out   = jump_address_backwards_in;

    // Backwards
    assign jump_address_backwards_out = jump_address_backwards_in;

    logic [31:0] selected_rs1_data;
    logic [31:0] selected_rs2_data;

    // assign selected_rs1_data = (decoded_instruction.rs1_address == wb_forwarding_in.address) ? wb_forwarding_in.data : rf_read_data1;

    // assign selected_rs2_data = (decoded_instruction.rs2_address == wb_forwarding_in.address) ? wb_forwarding_in.data : rf_read_data2;


    logic stall;

    always_comb begin
        // EXE -> MEM -> WB !!!
        // inverted order, so the last one wins.
        selected_rs1_data = rf_read_data1;
        selected_rs2_data = rf_read_data2;
        stall = 1'b0;

        if (wb_forwarding_in.data_valid) begin
            if (decoded_instruction.rs1_address == wb_forwarding_in.address) begin
                selected_rs1_data = wb_forwarding_in.data;
            end

            if (decoded_instruction.rs2_address == wb_forwarding_in.address) begin
                selected_rs2_data = wb_forwarding_in.data;
            end
        end

        if (mem_forwarding_in.data_valid) begin
            if (decoded_instruction.rs1_address == mem_forwarding_in.address) begin
                selected_rs1_data = mem_forwarding_in.data;
            end

            if (decoded_instruction.rs2_address == mem_forwarding_in.address) begin
                selected_rs2_data = mem_forwarding_in.data;
            end
        end

        if (exe_forwarding_in.data_valid) begin
            if (decoded_instruction.rs1_address == exe_forwarding_in.address) begin
                selected_rs1_data = exe_forwarding_in.data;
            end

            if (decoded_instruction.rs2_address == exe_forwarding_in.address) begin
                selected_rs2_data = exe_forwarding_in.data;
            end
        end

        if (decoded_instruction.rs1_address == 5'b0) begin
            selected_rs1_data = 32'b0;
        end
        if (decoded_instruction.rs2_address == 5'b0) begin
            selected_rs2_data = 32'b0;
        end

        // HAZARD DETECTION

        if (exe_forwarding_in.address == decoded_instruction.rs1_address
            && exe_forwarding_in.address != 5'd0
            && exe_forwarding_in.data_valid == 1'b0)
        begin
            stall = 1'b1;
        end

        if (exe_forwarding_in.address == decoded_instruction.rs2_address
            && exe_forwarding_in.address != 5'd0
            && exe_forwarding_in.data_valid == 1'b0)
        begin
            stall = 1'b1;
        end

        // ADDING BACKWARDS IN comb
        if (status_backwards_in == pipeline_status::JUMP) begin
            status_backwards_out = pipeline_status::JUMP;
        end
        else if (stall) begin
            status_backwards_out = pipeline_status::STALL;
        end else begin
            status_backwards_out = pipeline_status::READY;
        end

    end




    always_ff @(posedge clk) begin

        if (rst) begin
            // Output Registers
            rs1_data_reg_out <= 0;
            rs2_data_reg_out <= 0;
            instruction_reg_out <= 0;
            program_counter_reg_out <= 0;
            // Pipeline Control
            status_forwards_out <= pipeline_status::BUBBLE;
            // ----------
            curr_dec_status <= STAGE_WAIT;
        end
        if (status_backwards_in == pipeline_status::JUMP) begin
            status_forwards_out <= pipeline_status::BUBBLE;
        end
        else if (status_backwards_in == pipeline_status::STALL) begin

        end
        else begin
            case (curr_dec_status)
                STAGE_WAIT: begin

                    if (stall) begin
                        status_forwards_out <= pipeline_status::BUBBLE;
                    end
                    else begin
                        if (decoded_instruction.op == op::ILLEGAL) begin
                            status_forwards_out <= pipeline_status::ILLEGAL_INSTRUCTION;
                        end
                        else if (decoded_instruction.op == op::ECALL) begin
                            status_forwards_out <= pipeline_status::ECALL;
                        end
                        else if (decoded_instruction.op == op::EBREAK) begin
                            status_forwards_out <= pipeline_status::EBREAK;
                        end
                        else if (status_forwards_in == pipeline_status::BUBBLE)begin
                            status_forwards_out <= pipeline_status::BUBBLE;
                        end
                        else begin
                            status_forwards_out <= pipeline_status::VALID;
                        end

                        if (status_forwards_in == pipeline_status::VALID) begin
                            program_counter_reg_out <= program_counter_in;
                            instruction_reg_out <= decoded_instruction;
                            rs1_data_reg_out <= selected_rs1_data;
                            rs2_data_reg_out <= selected_rs2_data;
                        end
                    end
                end
            endcase

        end
    end


    // // TODO: Delete the following line and implement this module.
    // ref_decode_stage golden(.*);

endmodule
