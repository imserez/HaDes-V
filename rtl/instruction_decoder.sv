/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: instruction_decoder.sv
 */



module instruction_decoder (
    input  logic [31:0]   instruction_in,
    output instruction::t instruction_out
);


    // opcodes

    // R = 0110011
    // I = 0010011
    // S = 0000011
    // B = 0100011
    // ....


    always_comb begin


        case (instruction_in[6:0])

            7'b0110011: begin // R-TYPE
                instruction_out.rd_address = instruction_in[11:7];
                instruction_out.rs1_address = instruction_in[19:15];
                instruction_out.rs2_address = instruction_in[24:20];

                case ({instruction_in[31:25], instruction_in[14:12]})
                    {7'b0000000, 3'b000}: instruction_out.op = op::ADD;
                    {7'b0100000, 3'b000}: instruction_out.op = op::SUB;
                    {7'b0000000, 3'b101}: instruction_out.op = op::SRL;
                    {7'b0100000, 3'b101}: instruction_out.op = op::SRA;

                    {7'b0000000, 3'b001}: instruction_out.op = op::SLL;
                    {7'b0000000, 3'b010}: instruction_out.op = op::SLT;
                    {7'b0000000, 3'b011}: instruction_out.op = op::SLTU
                    {7'b0000000, 3'b100}: instruction_out.op = op::XOR;
                    {7'b0000000, 3'b110}: instruction_out.op = op::OR;
                    {7'b0000000, 3'b111}: instruction_out.op = op::AND;
                    default: instruction_out.op = op::ILLEGAL;
                endcase
                case(instruction_in[14:12])

                    3'b001: instruction_out.op = op.SLL;
                    3'b010: instruction_out.op = op.SLT;
                    3'b011: instruction_out.op = op.ADD;
                    3'b100: instruction_out.op = op.SLTU;
                    3'b110: instruction_out.op = op.OR;
                    3'b111: instruction_out.op = op.AND;
                endcase
            end



        endcase


        casez(instruction_in)

            {25'b?, 7'b0110011}: begin

            end

        endcase

    end



    // TODO: Delete the following line and implement this module.
    ref_instruction_decoder golden(.*);

endmodule
