module stp_sr_8b_lsb
(
    input logic d,
    input logic shift_en,
    input logic clk,
    input logic n_rst,
    output logic [7:0] byte_data
);
    logic [7:0] nxt_byte;

    always_comb begin
        if(shift_en == 1'b0) begin
            nxt_byte = byte_data;
        end else begin
            nxt_byte = {d, byte_data[7:1]};
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if(n_rst == 1'b0) begin
            byte_data <= 8'b0;
        end else begin
            byte_data <= nxt_byte;
        end
    end
endmodule