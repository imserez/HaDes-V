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

    logic [1:0] saved = 0;
    logic [1:0] finished_reset = 0;


    typedef enum logic [1:0] {
        STAGE_RST,
        STAGE_FETCH,
        STAGE_HOLD
    } fetch_state_t;

    typedef enum logic [1:0] {
        WB_SENT,
        WB_WORKING,
        WB_READY
    } wb_state_t;


    logic [2:0] curr_fetch_status = fetch_state_t::STAGE_INIT;
    logic [2:0] curr_wb_status;


    // combinational logic for backwarding status
    always_comb begin

    end

    // TODO: change enum to typedef
    // check if finished_reset makes sense



    // Notes for myself:

    // byte-addressing to word-addressing
    // i.e; byte 4, word 1. Memory returns 32-bits starting from address wb.adr
    // because a word is 32-bits. 4 bytes.
    // So if we want 0x0000, then wb.addr gets 0. 0x0004 => wb.addr = 1
    // it's like ram[0], ram[1] in a ram = [x][32] bit-size!


    // ok to be set here, outside?
    assign  wb.we = 0;
    assign  wb.sel = 4'b1111;

    always_ff @(posedge clk) begin

        if (rst) begin
            curr_fetch_status <= fetch_state_t::STAGE_RST;
            wb.cyc <= 0;
            wb.stb <= 0;
            finished_reset <= 0;
            //TODO: maybe add here forwarding state? Bubble?
        end
        else begin

            if (status_backwards_in == pipeline_status::JUMP && finished_reset) begin
                wb.adr <= jump_address_backwards_in >> 2;
                pc <= jump_address_backwards_in;
            end
            else if (finished_reset) begin
                wb.adr <= pc >> 2;
            end

            case (curr_fetch_status)
                STAGE_RST: begin
                    curr_fetch_status <= STAGE_FETCH;
                    wb.adr  <= constants::RESET_ADDRESS >> 2;
                    pc <= constants::RESET_ADDRESS;
                end
                STAGE_FETCH: begin
                    if (wb.err == 1) begin
                        status_forwards_out <= pipeline_status::FETCH_FAULT;
                        // what with finished_rst here?

                        // at this sage, retry read? pc to next instruction?
                    end
                    else if (wb.ack == 1) begin
                        finished_reset <= 1;

                        // imagine, if we're ready, go fetch the next instruction and store the current. In case a JUMP is issued, clean our registers and read again. This time, fetch would be faster?
                        instruction_reg_out <= wb.dat_miso; // miso = read!

                        if (status_backwards_in == pipeline_status::READY) begin
                            curr_fetch_status <= fetch_state_t::STAGE_FETCH;
                            status_forwards_out <= pipeline_status::BUBBLE;
                            pc <= pc + 4;
                        end
                        else begin
                            curr_fetch_status <= fetch_state_t::STAGE_HOLD;
                            status_forwards_out <= pipeline_status::VALID;
                            wb.cyc <= 0;
                            wb.stb <= 0;
                        end
                    end
                end
                STAGE_HOLD: begin
                    if (status_backwards_in == pipeline_status::READY) begin
                        pc <= pc + 4;
                        curr_fetch_status <= fetch_state_t::STAGE_FETCH;
                        status_forwards_out <= pipeline_status::BUBBLE;
                        // good idea to load everything here to save 1 clk cycle?
                        // or do it in next FSM check?
                        wb.cyc <= 1;
                        wb.stb <= 1;
                    end
                end
            endcase

            // this FSM implementation could be more clear if every state implements at it's own time its properties, but this would cost 1 more clk cycle.
            // current: clk[0] => change+set clk[1] = ready
            // clearer: clk[0] => change => clk[1] => set., clk[2] ready

            program_counter_reg_out <= pc;
        end
    end


    // // TODO: Delete the following line and implement this module.
    // ref_fetch_stage golden(.*);

endmodule
