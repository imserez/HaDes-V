module dummy_memory (
        input logic clk,
        wishbone_interface.slave wb,
        input logic err
    );

        logic [7:0] delays   = 1;
        logic [7:0] count    = 0;

        logic [31:0] memory_array [0:3];
        logic [1:0]  inst_ptr = 0;

        initial begin
            memory_array[0] = 32'h00000013; // 1. NOP ADDI x0, x0, 0
            memory_array[1] = 32'h007302B3; // 2. ADD x5, x6, x7
            memory_array[2] = 32'hFFF58513; // 3. ADDI x10, x11, -1
            memory_array[3] = 32'h00000013; // 4. NOP ADDI x0, x0, 0
        end

        assign wb.err   = err;

        always_ff @(posedge clk) begin

            if (wb.cyc && wb.stb) begin
                count <= count + 1;
                if (count == delays) begin
                    wb.dat_miso <= memory_array[inst_ptr];
                    wb.ack <= 1;
                    count <= 0;

                    inst_ptr <= inst_ptr + 1;
                end
                else begin
                    wb.ack <= 0;
                end
            end
            else begin
                wb.ack <= 0;
                count <= 0;
            end
        end
endmodule
