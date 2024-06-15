module fifo_rx
(
    input logic [7:0] byte_data,
    input logic w_en,
    input logic r_en,
    input logic clk,
    input logic n_rst,
    output logic [7:0] fifo_data
);
    // FIFO with 2 bytes depth
    logic [7:0] fifo[1:0];
    logic [1:0] w_ptr;
    logic [1:0] r_ptr;
    logic [1:0] nxt_w_ptr;
    logic [1:0] nxt_r_ptr;

    always_comb begin
        if(w_en == 1'b0) begin
            nxt_w_ptr = w_ptr;
        end else begin
            nxt_w_ptr = w_ptr == 2'b01 ? 2'b0 : w_ptr + 1;
        end
    end

    always_comb begin
        if(r_en == 1'b0) begin
            nxt_r_ptr = r_ptr;
        end else begin
            nxt_r_ptr = r_ptr == 2'b01 ? 2'b0 : r_ptr + 1;
        end
    end

    always_ff @(posedge clk, negedge n_rst) begin
        if(n_rst == 1'b0) begin
            w_ptr <= 2'b0;
            r_ptr <= 2'b0;
            fifo[0] <= 8'b0;
            fifo[1] <= 8'b0;
            fifo_data <= 8'b0;
        end else begin
            w_ptr <= nxt_w_ptr;
            r_ptr <= nxt_r_ptr;
            if(w_en == 1'b1) begin
                fifo[w_ptr] <= byte_data;
            end
            if(r_en == 1'b1) begin
                fifo_data <= fifo[r_ptr];
            end
        end
    end

endmodule