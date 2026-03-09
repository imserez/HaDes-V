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
        casez(instruction_in)

            {22'b?, 5'b00000, 7'b0110011}: begin

            end

        endcase

    end



    // TODO: Delete the following line and implement this module.
    ref_instruction_decoder golden(.*);

endmodule
