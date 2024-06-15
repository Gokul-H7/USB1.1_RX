// $Id: $
// File name:   flex_counter.sv
// Created:     1/31/2024
// Author:      Gokul Harikrishnan
// Lab Section: 337-018
// Version:     1.0  Initial Design Entry

module flex_counter
#(
    parameter NUM_CNT_BITS = 4
)
(
    input logic clk,
    input logic n_rst,
    input logic clear,
    input logic count_enable,
    input logic [(NUM_CNT_BITS - 1):0] rollover_val,
    output logic [(NUM_CNT_BITS - 1):0] count_out,
    output logic rollover_flag
);
    logic [(NUM_CNT_BITS - 1):0] nxt_cnt;
    logic nxt_flg;

    always_comb begin : NEXT_STATE_LOGIC
        if(clear == 1) begin
            nxt_cnt = 0;
            nxt_flg = 0;
        end else if(count_enable == 0) begin
            nxt_cnt = count_out;
            nxt_flg = rollover_flag;
        end else begin
            if(rollover_val == count_out + 1) begin
                nxt_cnt = count_out + 1;
                nxt_flg = 1;
            end else if(rollover_val == count_out) begin
                nxt_cnt = 1;
                nxt_flg = 0;
            end else begin
                nxt_cnt = count_out + 1;
                nxt_flg = 0;
            end
        end
    end
  
    always_ff @ (posedge clk, negedge n_rst) begin
        if(n_rst == 1'b0) begin
            count_out <= 0;
            rollover_flag <= 0;
        end else begin
            count_out <= nxt_cnt;
            rollover_flag <= nxt_flg;
        end
    end

endmodule