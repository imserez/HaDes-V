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
        instruction_out.op          = op::ILLEGAL;
        instruction_out.rd_address  = 5'b0;
        instruction_out.rs1_address = 5'b0;
        instruction_out.rs2_address = 5'b0;
        instruction_out.immediate   = 32'b0;
        // instruction_out.csr         = csr::     ;

        case (instruction_in[6:0])

            7'b0110011: begin // R-TYPE
                instruction_out.rd_address  = instruction_in[11:7];
                instruction_out.rs1_address = instruction_in[19:15];
                instruction_out.rs2_address = instruction_in[24:20];
                instruction_out.immediate   = 32'b0;
                // instruction_out.csr         = csr::     ;

                case ({instruction_in[31:25], instruction_in[14:12]})
                    {7'b0000000, 3'b000}: instruction_out.op = op::ADD;
                    {7'b0100000, 3'b000}: instruction_out.op = op::SUB;
                    {7'b0000000, 3'b001}: instruction_out.op = op::SLL;
                    {7'b0000000, 3'b010}: instruction_out.op = op::SLT;
                    {7'b0000000, 3'b011}: instruction_out.op = op::SLTU;
                    {7'b0000000, 3'b100}: instruction_out.op = op::XOR;
                    {7'b0000000, 3'b101}: instruction_out.op = op::SRL;
                    {7'b0100000, 3'b101}: instruction_out.op = op::SRA;
                    {7'b0000000, 3'b110}: instruction_out.op = op::OR;
                    {7'b0000000, 3'b111}: instruction_out.op = op::AND;
                    default: instruction_out.op = op::ILLEGAL;
                endcase
            end

            7'b0010011: begin // I-TYPE
                instruction_out.rd_address  = instruction_in[11:7];
                instruction_out.rs1_address = instruction_in[19:15];
                instruction_out.rs2_address = 0;
                instruction_out.immediate   = { {20{instruction_in[31]}}, instruction_in[31:20] }; // Sign-extending!!
                // instruction_out.csr         = csr::     ;

                casez ({instruction_in[31:20], instruction_in[14:12]})
                    {12'b????????????, 3'b000}: instruction_out.op = op::ADDI;
                    {12'b????????????, 3'b010}: instruction_out.op = op::SLTI;
                    {12'b????????????, 3'b011}: instruction_out.op = op::SLTIU;
                    {12'b????????????, 3'b100}: instruction_out.op = op::XORI;
                    {12'b????????????, 3'b110}: instruction_out.op = op::ORI;
                    {12'b????????????, 3'b111}: instruction_out.op = op::ANDI;
                    {12'b0000000?????, 3'b001}: instruction_out.op = op::SLLI;
                    {12'b0000000?????, 3'b101}: instruction_out.op = op::SRLI;
                    {12'b0100000?????, 3'b101}: instruction_out.op = op::SRAI;
                    default: instruction_out.op = op::ILLEGAL;
                endcase
            end

            7'b0100011: begin // S-TYPE
                instruction_out.rd_address  = 5'b0;
                instruction_out.rs1_address = instruction_in[19:15];
                instruction_out.rs2_address = instruction_in[24:20];
                instruction_out.immediate   = { {20{instruction_in[31]}}, instruction_in[31:25], instruction_in[11:7] };
                // instruction_out.csr         = csr::     ;

                case (instruction_in[14:12])
                    3'b000: instruction_out.op  = op::SB;
                    3'b001: instruction_out.op  = op::SH;
                    3'b010: instruction_out.op  = op::SW;
                    default: instruction_out.op = op::ILLEGAL;
                endcase
            end

            7'b0000011: begin // L-TYPE

                instruction_out.rd_address  = instruction_in[11:7];
                instruction_out.rs1_address = instruction_in[19:15];
                instruction_out.rs2_address = 5'b0;
                instruction_out.immediate   = { {20{instruction_in[31]}}, instruction_in[31:20] };
                // instruction_out.csr         = csr::     ;

                case (instruction_in[14:12])
                    3'b000: instruction_out.op = op::LB;
                    3'b001: instruction_out.op = op::LH;
                    3'b010: instruction_out.op = op::LW;
                    3'b100: instruction_out.op = op::LBU;
                    3'b101: instruction_out.op = op::LHU;
                    default: instruction_out.op = op::ILLEGAL;
                endcase
            end



            7'b0110111, 7'b0010111: begin // U-TYPE
                instruction_out.rd_address  = 5'b0;
                instruction_out.rs1_address = instruction_in[19:15];
                instruction_out.rs2_address = instruction_in[24:20];
                instruction_out.immediate   = { {20{instruction_in[31]}}, instruction_in[31:25], instruction_in[11:7] };
                // instruction_out.csr         = csr::     ;
            end

            7'b1101111: begin // J-TYPE
            end

            7'b1100011: begin // B-TYPE
                instruction_out.rd_address  = 5'b0;
                instruction_out.rs1_address = instruction_in[19:15];
                instruction_out.rs2_address = instruction_in[24:20];
                instruction_out.immediate = {
                    {20{instruction_in[31]}},
                    instruction_in[7],
                    instruction_in[30:25],
                    instruction_in[11:8],
                    1'b0
                };
                // instruction_out.csr         = csr::     ;

                case (instruction_in[14:12])
                    3'b000: instruction_out.op = op::BEQ;
                    3'b001: instruction_out.op = op::BNE;
                    3'b100: instruction_out.op = op::BLT;
                    3'b101: instruction_out.op = op::BGE;
                    3'b110: instruction_out.op = op::BLTU;
                    3'b111: instruction_out.op = op::BGEU;
                    default: instruction_out.op = op::ILLEGAL;
                endcase
            end

        endcase

    end

    // // TODO: Delete the following line and implement this module.
    // ref_instruction_decoder golden(.*);

endmodule
