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
    logic [31:0] read_instruction = 0;

    logic [1:0] saved = 0;
    logic [1:0] after_reset = 0;

    enum logic [1:0] {
        WB_SENT,
        WB_WAIT
    } wb_status;



    // combinational logic for backwarding status
    always_comb begin

    end

    always_ff @(posedge clk) begin

        if(rst) begin
            pc <= 0;
            after_reset <= 1;
            wb.cyc <= 0;
            wb.stb <= 0;
        end
        else begin

            // init ask
            if (wb.ack == 1 && (status_backwards_in != pipeline_status::READY)) begin
                // if we have the response, and the next stage is not ready for it
                // then we hold this value.
                if (!saved) begin

                    read_instruction <= wb.dat_miso;
                    saved <= 1;
                end
                wb.cyc <= 0;
                wb.stb <= 0;
                wb.we  <= 0;
            end
            else begin
                wb.cyc <= 1;
                wb.stb <= 1;
                wb.we  <= 0;
                saved <= 0;
            end

            wb.sel <= 4'b1111; // 4-bytes of the word are accessed

            // set the apropiate address to fetch from
            if (after_reset == 1) begin
                wb.adr <= constants::RESET_ADDRESS >> 2;
                pc <= constants::RESET_ADDRESS;
            end
            else if (status_backwards_in == pipeline_status::JUMP) begin
                wb.adr <= jump_address_backwards_in >> 2;
                pc <= jump_address_backwards_in;
            end
            else begin
                wb.adr <= pc >> 2; // byte-addressing to word-addressing
                program_counter_reg_out <= pc;
            end

            program_counter_reg_out <= pc;


            // wait for response
            if (wb.ack == 1) begin
                after_reset <= 0;

                read_instruction <= wb.dat_miso;

                instruction_reg_out <= read_instruction; // read => out (mIsO)
                status_forwards_out <= pipeline_status::VALID;

                if (status_backwards_in == pipeline_status::READY) begin
                    pc <= pc + 4;
                end

            end
            else begin
                if (wb.err == 1) begin
                    status_forwards_out <= pipeline_status::FETCH_FAULT;
                end
                else begin
                    status_forwards_out <= pipeline_status::BUBBLE;
                end
            end



        end
    end




    // // TODO: Delete the following line and implement this module.
    // ref_fetch_stage golden(.*);

endmodule
