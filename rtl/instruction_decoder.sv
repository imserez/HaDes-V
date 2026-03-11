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

    // always_comb begin
    //     instruction_out.op          = op::ILLEGAL;
    //     instruction_out.rd_address  = 5'b0;
    //     instruction_out.rs1_address = 5'b0;
    //     instruction_out.rs2_address = 5'b0;
    //     instruction_out.immediate   = 32'b0;
    //     instruction_out.csr         = csr::MSCRATCH;

    //     case (instruction_in[6:0])

    //         7'b0110011: begin // R-TYPE
    //             instruction_out.rd_address  = instruction_in[11:7];
    //             instruction_out.rs1_address = instruction_in[19:15];
    //             instruction_out.rs2_address = instruction_in[24:20];
    //             instruction_out.immediate   = 32'b0;


    //             case ({instruction_in[31:25], instruction_in[14:12]})
    //                 {7'b0000000, 3'b000}: instruction_out.op = op::ADD;
    //                 {7'b0100000, 3'b000}: instruction_out.op = op::SUB;
    //                 {7'b0000000, 3'b001}: instruction_out.op = op::SLL;
    //                 {7'b0000000, 3'b010}: instruction_out.op = op::SLT;
    //                 {7'b0000000, 3'b011}: instruction_out.op = op::SLTU;
    //                 {7'b0000000, 3'b100}: instruction_out.op = op::XOR;
    //                 {7'b0000000, 3'b101}: instruction_out.op = op::SRL;
    //                 {7'b0100000, 3'b101}: instruction_out.op = op::SRA;
    //                 {7'b0000000, 3'b110}: instruction_out.op = op::OR;
    //                 {7'b0000000, 3'b111}: instruction_out.op = op::AND;
    //             endcase
    //         end

    //         7'b0010011: begin // I-TYPE
    //             instruction_out.rd_address  = instruction_in[11:7];
    //             instruction_out.rs1_address = instruction_in[19:15];
    //             instruction_out.rs2_address = 0;
    //             instruction_out.immediate   = { {20{instruction_in[31]}}, instruction_in[31:20] }; // Sign-extending!!


    //             casez ({instruction_in[31:20], instruction_in[14:12]})
    //                 {12'b????????????, 3'b000}: instruction_out.op = op::ADDI;
    //                 {12'b????????????, 3'b010}: instruction_out.op = op::SLTI;
    //                 {12'b????????????, 3'b011}: instruction_out.op = op::SLTIU;
    //                 {12'b????????????, 3'b100}: instruction_out.op = op::XORI;
    //                 {12'b????????????, 3'b110}: instruction_out.op = op::ORI;
    //                 {12'b????????????, 3'b111}: instruction_out.op = op::ANDI;
    //                 {12'b0000000?????, 3'b001}: instruction_out.op = op::SLLI;
    //                 {12'b0000000?????, 3'b101}: instruction_out.op = op::SRLI;
    //                 {12'b0100000?????, 3'b101}: instruction_out.op = op::SRAI;
    //             endcase
    //         end

    //         7'b0000011: begin // L-TYPE

    //             instruction_out.rd_address  = instruction_in[11:7];
    //             instruction_out.rs1_address = instruction_in[19:15];
    //             instruction_out.rs2_address = 5'b0;
    //             instruction_out.immediate   = { {20{instruction_in[31]}}, instruction_in[31:20] };


    //             case (instruction_in[14:12])
    //                 3'b000: instruction_out.op = op::LB;
    //                 3'b001: instruction_out.op = op::LH;
    //                 3'b010: instruction_out.op = op::LW;
    //                 3'b100: instruction_out.op = op::LBU;
    //                 3'b101: instruction_out.op = op::LHU;
    //             endcase
    //         end

    //         7'b0100011: begin // S-TYPE
    //             instruction_out.rd_address  = 5'b0;
    //             instruction_out.rs1_address = instruction_in[19:15];
    //             instruction_out.rs2_address = instruction_in[24:20];
    //             instruction_out.immediate   = { {20{instruction_in[31]}}, instruction_in[31:25], instruction_in[11:7] };


    //             case (instruction_in[14:12])
    //                 3'b000: instruction_out.op  = op::SB;
    //                 3'b001: instruction_out.op  = op::SH;
    //                 3'b010: instruction_out.op  = op::SW;

    //             endcase
    //         end

    //         7'b1100011: begin // B-TYPE
    //             instruction_out.rd_address  = 5'b0;
    //             instruction_out.rs1_address = instruction_in[19:15];
    //             instruction_out.rs2_address = instruction_in[24:20];
    //             instruction_out.immediate = {
    //                 {20{instruction_in[31]}},
    //                 instruction_in[7],
    //                 instruction_in[30:25],
    //                 instruction_in[11:8],
    //                 1'b0
    //             };


    //             case (instruction_in[14:12])
    //                 3'b000: instruction_out.op = op::BEQ;
    //                 3'b001: instruction_out.op = op::BNE;
    //                 3'b100: instruction_out.op = op::BLT;
    //                 3'b101: instruction_out.op = op::BGE;
    //                 3'b110: instruction_out.op = op::BLTU;
    //                 3'b111: instruction_out.op = op::BGEU;

    //             endcase
    //         end

    //         7'b0110111, 7'b0010111: begin // U-TYPE
    //             instruction_out.rd_address  = instruction_in[11:7];
    //             instruction_out.rs1_address = 5'b0;
    //             instruction_out.rs2_address = 5'b0;
    //             instruction_out.immediate   = {instruction_in[31:12], 12'b0};


    //             if (instruction_in[6:0] == 7'b0110111)
    //                 instruction_out.op = op::LUI;
    //             else
    //                 instruction_out.op = op::AUIPC;
    //         end

    //         7'b1101111: begin // J-TYPE
    //             instruction_out.rd_address  = instruction_in[11:7];
    //             instruction_out.rs1_address = 5'b0;
    //             instruction_out.rs2_address = 5'b0;
    //             instruction_out.immediate = {
    //                 {12{instruction_in[31]}},
    //                 instruction_in[19:12],
    //                 instruction_in[20],
    //                 instruction_in[30:21],
    //                 1'b0
    //             };


    //             instruction_out.op = op::JAL;
    //         end

    //         7'b1100111: begin // JALR
    //             instruction_out.rd_address  = instruction_in[11:7];
    //             instruction_out.rs1_address = instruction_in[19:15];
    //             instruction_out.rs2_address = 5'b0;

    //             instruction_out.immediate   = { {20{instruction_in[31]}}, instruction_in[31:20] };

    //             if (instruction_in[14:12] == 3'b000) begin
    //                 instruction_out.op = op::JALR;
    //             end
    //         end

    //         7'b0001111: begin // MISC-MEM FENCE, FENCE.I
    //             instruction_out.rd_address  = instruction_in[11:7];
    //             instruction_out.rs1_address = instruction_in[19:15];
    //             instruction_out.rs2_address = 5'b0;
    //             instruction_out.immediate   = { {20{instruction_in[31]}}, instruction_in[31:20] };

    //             case (instruction_in[14:12])
    //                 3'b000: instruction_out.op = op::FENCE;
    //                 3'b001: instruction_out.op = op::FENCE_I;

    //             endcase
    //         end

    //         7'b1110011: begin // SYS-TYPE
    //             instruction_out.rd_address  = instruction_in[11:7];
    //             instruction_out.rs1_address = instruction_in[19:15];
    //             instruction_out.rs2_address = 5'b0;
    //             instruction_out.immediate   = { 27'b0, instruction_in[19:15] };

    //             // if (instruction_in[19:7] == 13'b0) begin // this already includes func3 3'b000 !!

    //             if (instruction_in[14:12] == 13'b0) begin // less restrictive, just func3
    //                 case (instruction_in[31:20])
    //                     12'b000000000000: instruction_out.op = op::ECALL;
    //                     12'b000000000001: instruction_out.op = op::EBREAK;
    //                     12'b001100000010: instruction_out.op = op::MRET;
    //                     12'b000100000101: instruction_out.op = op::WFI;
    //                 endcase
    //             end
    //             else begin
    //                 instruction_out.csr = csr::t'(instruction_in[31:20]);
    //                 case (instruction_in[14:12])
    //                     3'b001: begin
    //                         instruction_out.op = op::CSRRW;
    //                     end
    //                     3'b010: begin
    //                         instruction_out.op = op::CSRRS;
    //                     end
    //                     3'b011: begin
    //                         instruction_out.op = op::CSRRC;
    //                     end
    //                     3'b101: begin
    //                         instruction_out.op = op::CSRRWI;
    //                     end
    //                     3'b110: begin
    //                         instruction_out.op = op::CSRRSI;
    //                     end
    //                     3'b111: begin
    //                         instruction_out.op = op::CSRRCI;
    //                     end
    //                 endcase
    //             end
    //         end
    //     endcase

    // end

    // TODO: Delete the following line and implement this module.
    ref_instruction_decoder golden(.*);

endmodule
