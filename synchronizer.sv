module synchronizer
(
    input logic x,
    input logic clk,
    input logic n_rst,
    output logic x_sync
);
    logic q;
    always_ff @(posedge clk, negedge n_rst) begin
        if(n_rst == 1'b0) begin
            q <= 1'b0;
            x_sync <= 1'b0;
        end else begin
            q <= x;
            x_sync <= q;
        end
    end
endmodule