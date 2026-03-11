/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: fetch_stage.sv
 */



module fetch_stage (
    input logic clk,
    input logic rst,

    // Memory interface
    wishbone_interface.master wb,

    //  Output data
    output logic [31:0] instruction_reg_out,
    output logic [31:0] program_counter_reg_out,

    // Pipeline control
    output pipeline_status::forwards_t  status_forwards_out,
    input  pipeline_status::backwards_t status_backwards_in,
    input  logic [31:0] jump_address_backwards_in
);


    logic [31:0] pc = 0;



    import fetch_status::*;
    fetch_state_t curr_fetch_status = STAGE_START;

    always_comb begin
        wb.adr = pc >> 2;
    end

    assign  wb.we = 0;
    assign  wb.sel = 4'b1111;

    assign wb.cyc = (curr_fetch_status != STAGE_ERR);
    assign wb.stb = (curr_fetch_status != STAGE_ERR);

    always_ff @(posedge clk) begin

        if (rst) begin
            curr_fetch_status <= STAGE_FETCH;

            pc <= constants::RESET_ADDRESS;
            program_counter_reg_out <= 0;
            status_forwards_out <= pipeline_status::BUBBLE;

            instruction_reg_out <= 32'b0;

        end
        else begin

            if (wb.ack == 1) begin
                instruction_reg_out <= wb.dat_miso;
            end

            if (status_backwards_in == pipeline_status::JUMP) begin
                program_counter_reg_out <= jump_address_backwards_in;
            end
            else if (wb.ack == 1) begin
                program_counter_reg_out <= pc;
            end

            if (status_backwards_in == pipeline_status::JUMP) begin

                pc <= jump_address_backwards_in;

                if (jump_address_backwards_in[1:0] & 2'b11) begin // MISALIGNED!! is 0 = false, that's why.
                    status_forwards_out <= pipeline_status::FETCH_MISALIGNED;
                    curr_fetch_status <= STAGE_ERR;
                end
                else begin
                    status_forwards_out <= pipeline_status::BUBBLE;
                    curr_fetch_status <= STAGE_FETCH;
                end
            end
            else begin
                case (curr_fetch_status)
                    STAGE_ERR: begin
                        status_forwards_out <= pipeline_status::BUBBLE;
                    end
                    STAGE_START: begin
                        curr_fetch_status <= STAGE_FETCH;
                        status_forwards_out <= pipeline_status::BUBBLE;
                    end
                    STAGE_FETCH: begin
                        if (wb.err == 1) begin
                            status_forwards_out <= pipeline_status::FETCH_FAULT;
                            curr_fetch_status <= STAGE_ERR;
                        end
                        else if (wb.ack == 1) begin

                            if (status_backwards_in == pipeline_status::READY) begin

                                curr_fetch_status <= STAGE_FETCH;
                                status_forwards_out <= pipeline_status::VALID;
                                pc <= pc + 4;
                            end
                            else begin
                                status_forwards_out <= pipeline_status::VALID;
                            end
                        end
                        else if (status_backwards_in == pipeline_status::READY) begin // -
                            status_forwards_out <= pipeline_status::BUBBLE;
                        end
                    end
                endcase
            end
        end
    end


    // // TODO: Delete the following line and implement this module.
    // ref_fetch_stage golden(.*);

endmodule
