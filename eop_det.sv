module eop_det
(
    input logic dp,
    input logic dm,
    input logic clk,
    input logic n_rst,
    output logic eop
);
    // EOP goes high after dp and dm are 0 for 2 clock cycles
    logic [1:0] eop_cnt;
    logic [1:0] nxt_eop_cnt;

    always_comb begin
        if(dp == 1'b0 && dm == 1'b0) begin
            nxt_eop_cnt = eop_cnt + 1;
        end else begin
            nxt_eop_cnt = 2'b0;
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if(n_rst == 1'b0) begin
            eop_cnt <= 2'b0;
            eop <= 1'b0;
        end else begin
            eop_cnt <= nxt_eop_cnt;
            if(eop_cnt == 2'b11) begin
                eop <= 1'b1;
            end else begin
                eop <= 1'b0;
            end
        end
    end
endmodule