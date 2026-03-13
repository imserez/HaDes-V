module dummy_memory (
        input logic clk,
        wishbone_interface.slave wb,
        input logic err
    );

        logic [7:0] delays   = 1;
        logic [7:0] count    = 0;

        assign wb.err   = err;

        always_ff @(posedge clk) begin

            if (wb.cyc && wb.stb) begin
                count <= count + 1;
                if (count == delays) begin
                    // wb.dat_miso <= wb.adr; // let's return the same address as the ret value!!
                    // ADDI x0, x0, 0
                    wb.dat_miso <= 32'h00000013;
                    wb.ack <= 1;
                    count <= 0;
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
