module USB_RX
(
    input logic dp,
    input logic dm,
    input logic clk,
    input logic n_rst,
    output logic RX_Data_Ready,
    output logic RX_Transfer_Active,
    output logic RX_Error,
    output logic flush,
    output logic Store_RX_Packet_Data,
    output logic [3:0] RX_Packet,
    output logic [7:0] RX_Packet_Data
);
    logic dp_sync, dm_sync;
    logic eop;
    logic d_orig, d_edge;
    logic w_en, r_en, shift_en, en8, en7, en5, en4, clear;
    logic bit8, bit7, bit5, bit4;
    logic store, clear_b;
    logic [7:0] byte_data, fifo_data, data;

    synchronizer DPLUS(.x(dp), .clk(clk), .n_rst(n_rst), .x_sync(dp_sync));
    synchronizer DMINUS(.x(dm), .clk(clk), .n_rst(n_rst), .x_sync(dm_sync));
    eop_det EOP(.dp(dp_sync), .dm(dm_sync), .clk(clk), .n_rst(n_rst), .eop(eop));
    nrzi_decoder NRZI(.d(dp_sync), .clk(clk), .n_rst(n_rst), .d_orig(d_orig), .d_edge(d_edge));
    stp_sr_8b_lsb SR8(.d(d_orig), .shift_en(shift_en), .clk(clk), .n_rst(n_rst), .byte_data(byte_data));
    rcu RCU(
        .d_edge(d_edge),
        .eop(eop),
        .bit8(bit8), .bit7(bit7), .bit5(bit5), .bit4(bit4),
        .clk(clk),
        .n_rst(n_rst),
        .byte_data(byte_data),
        .fifo_data(fifo_data),
        .w_en(w_en),
        .r_en(r_en),
        .shift_en(shift_en),
        .en8(en8), .en7(en7), .en5(en5), .en4(en4),
        .clear(clear),
        //.clear_b(clear_b),
        .RX_Data_Ready(RX_Data_Ready),
        .RX_Transfer_Active(RX_Transfer_Active),
        .RX_Error(RX_Error),
        .flush(flush),
        .Store_RX_Packet_Data(Store_RX_Packet_Data),
        .RX_Packet(RX_Packet),
        .RX_Packet_Data(RX_Packet_Data)
    );
    fifo_rx FIFO(
        .byte_data(byte_data),
        .w_en(w_en),
        .r_en(r_en),
        .clk(clk),
        .n_rst(n_rst),
        .fifo_data(fifo_data)
    );

    flex_counter #(4) B8(
        .clk(clk), .n_rst(n_rst), .clear(clear), .count_enable(en8), 
        .rollover_val(4'd8), .count_out(), .rollover_flag(bit8)
    );
    
    // token counters
    flex_counter #(3) B7(
        .clk(clk), .n_rst(n_rst), .clear(clear), .count_enable(en7), 
        .rollover_val(3'd5), .count_out(), .rollover_flag(bit7)
    );
    flex_counter #(3) B5(
        .clk(clk), .n_rst(n_rst), .clear(clear), .count_enable(en5), 
        .rollover_val(3'd4), .count_out(), .rollover_flag(bit5)
    );
    flex_counter #(3) B4(
        .clk(clk), .n_rst(n_rst), .clear(clear), .count_enable(en4), 
        .rollover_val(3'd3), .count_out(), .rollover_flag(bit4)
    );

endmodule