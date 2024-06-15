`timescale 1ns / 10ps

module tb_USB_RX();
    // Define parameters
    parameter CLK_PERIOD        = 2.5;
    parameter NORM_DATA_PERIOD  = (10 * CLK_PERIOD);

    // DUT inputs
    logic tb_dp, tb_dm, tb_clk, tb_n_rst;
    
    // DUT outputs
    logic tb_RX_Data_Ready, tb_RX_Transfer_Active, tb_RX_Error, tb_flush, tb_Store_RX_Packet_Data;
    logic [3:0] tb_RX_Packet;
    logic [7:0] tb_RX_Packet_Data;

    // DUT expected outputs
    logic tb_exp_RX_Data_Ready, tb_exp_RX_Transfer_Active, tb_exp_RX_Error, tb_exp_flush, tb_exp_Store_RX_Packet_Data;

    // Debug signals
    integer tb_test_num;
    string tb_test_case;
    logic tb_data_check;
    
    // DUT portmap
    USB_RX DUT(
        .dp(tb_dp),
        .dm(tb_dm),
        .clk(tb_clk),
        .n_rst(tb_n_rst),
        .RX_Data_Ready(tb_RX_Data_Ready),
        .RX_Transfer_Active(tb_RX_Transfer_Active),
        .RX_Error(tb_RX_Error),
        .flush(tb_flush),
        .Store_RX_Packet_Data(tb_Store_RX_Packet_Data),
        .RX_Packet(tb_RX_Packet),
        .RX_Packet_Data(tb_RX_Packet_Data)
    );

    task reset_dut;
    begin
        tb_n_rst = 1'b0;
        @(posedge tb_clk);
        @(posedge tb_clk);
        @(negedge tb_clk);
        tb_n_rst = 1'b1;
        @(posedge tb_clk);
        @(posedge tb_clk);
    end
    endtask

    task send_byte;
        input [7:0] byte_data;
        integer i;
    begin 
        for(i = 0; i < 8; i = i + 1)
        begin
            if (byte_data[i] == 1'b0) begin
                @(negedge tb_clk);
                tb_dp = ~tb_dp;
                tb_dm = ~tb_dp;
            end else begin
                @(negedge tb_clk);
                tb_dp = tb_dp;
                tb_dm = ~tb_dp;
            end
        end
    end
    endtask

    task check_outputs;
    begin
        assert(tb_RX_Data_Ready == tb_exp_RX_Data_Ready) else
            $error("Test %0d: %s: RX_Data_Ready mismatch: Expected %b, Got %b", tb_test_num, tb_test_case, tb_exp_RX_Data_Ready, tb_RX_Data_Ready);
        assert(tb_RX_Transfer_Active == tb_exp_RX_Transfer_Active) else
            $error("Test %0d: %s: RX_Transfer_Active mismatch: Expected %b, Got %b", tb_test_num, tb_test_case, tb_exp_RX_Transfer_Active, tb_RX_Transfer_Active);
        assert(tb_RX_Error == tb_exp_RX_Error) else
            $error("Test %0d: %s: RX_Error mismatch: Expected %b, Got %b", tb_test_num, tb_test_case, tb_exp_RX_Error, tb_RX_Error);
        assert(tb_flush == tb_exp_flush) else
            $error("Test %0d: %s: flush mismatch: Expected %b, Got %b", tb_test_num, tb_test_case, tb_exp_flush, tb_flush);
        assert(tb_Store_RX_Packet_Data == tb_exp_Store_RX_Packet_Data) else
            $error("Test %0d: %s: Store_RX_Packet_Data mismatch: Expected %b, Got %b", tb_test_num, tb_test_case, tb_exp_Store_RX_Packet_Data, tb_Store_RX_Packet_Data);
        tb_data_check = 1'b1;
        @(posedge tb_clk);
        tb_data_check = 1'b0;
    end
    endtask

    task stall;
    begin
        @(negedge tb_clk);
        @(negedge tb_clk);
        @(negedge tb_clk);
        @(negedge tb_clk);
        @(negedge tb_clk);
    end
    endtask

    // Clock gen
    always begin : CLK_GEN
        tb_clk = 1'b0;
        #(CLK_PERIOD / 2);
        tb_clk = 1'b1;
        #(CLK_PERIOD / 2);
    end

    integer i;

    // Testbench
    initial begin : TEST_PROC
        // Initialize signals
        tb_test_num = -1;
        tb_test_case = "TB Init";
        tb_data_check = 1'b0;
        // Initialize inputs to inactive/idle values
        tb_dp = 1'b1;
        tb_dm = ~tb_dp;
        tb_n_rst = 1'b1;
        // Initialize expected outputs
        tb_exp_RX_Data_Ready = 1'b0;
        tb_exp_RX_Transfer_Active = 1'b1;
        tb_exp_RX_Error = 1'b0;
        tb_exp_flush = 1'b0;
        tb_exp_Store_RX_Packet_Data = 1'b0;

        #0.1;

        // Test 0: Basic Power on Reset
        tb_test_num = 0;
        tb_test_case = "Power-on-Reset";
        // Reset DUT
        reset_dut; 
        // Check outputs
        tb_exp_RX_Transfer_Active = 1'b0;
        check_outputs;

        // Test 1: Incorrect Sync
        @(negedge tb_clk);
        tb_test_num = 1;
        tb_test_case = "Incorrect Sync";
        // Reset DUT
        reset_dut;
        // Send incorrect sync
        send_byte(8'b00000000);
        // Check outputs
        stall;
        tb_exp_RX_Error = 1'b1;
        tb_exp_RX_Transfer_Active = 1'b1;
        check_outputs;

        // Test 2: Incorrect PID
        @(negedge tb_clk);
        tb_test_num = 2;
        tb_test_case = "Incorrect PID";
        // Reset DUT
        reset_dut;
        // Send incorrect PID
        send_byte(8'b00000001); // correct sync
        send_byte(8'b00000001); // incorrect PID
        // Check outputs
        stall;
        tb_exp_RX_Error = 1'b1;
        check_outputs;

        // Test 3: Correct PID (STALL)
        @(negedge tb_clk);
        tb_test_num = 3;
        tb_test_case = "STALL Packet";
        // Reset DUT
        reset_dut;
        // Send Stall Packet
        send_byte(8'b00000001); // correct sync
        send_byte(8'b00011110); // correct stall PID
        @(negedge tb_clk)
        tb_dp = 1'b0;
        tb_dm = 1'b0;
        stall;
        tb_exp_RX_Error = 1'b0;
        check_outputs;
        tb_dp = 1'b1;
        tb_dm = ~tb_dp;

        // Test 4: Correct PID (ACK)
        @(negedge tb_clk);
        tb_test_num = 4;
        tb_test_case = "ACK Packet";
        // Reset DUT
        reset_dut;
        // Send ACK Packet
        send_byte(8'b00000001); // correct sync
        send_byte(8'b11010010); // correct ACK PID
        @(negedge tb_clk);
        tb_dp = 1'b0;
        tb_dm = 1'b0;
        @(negedge tb_clk);
        @(negedge tb_clk);
        @(negedge tb_clk);
        @(negedge tb_clk);
        assert(tb_RX_Packet == 4'b0100) else
            $error("ACK PACKET IS WRONG");
        @(negedge tb_clk);
        check_outputs;
        tb_dp = 1'b1;
        tb_dm = ~tb_dp;

        // Test 5: Correct PID (NAK)
        @(negedge tb_clk);
        tb_test_num = 5;
        tb_test_case = "NAK Packet";
        // Reset DUT
        reset_dut;
        // Send ACK Packet
        send_byte(8'b00000001); // correct sync
        send_byte(8'b01011010); // correct ACK PID
        @(negedge tb_clk);
        tb_dp = 1'b0;
        tb_dm = 1'b0;
        @(negedge tb_clk);
        @(negedge tb_clk);
        @(negedge tb_clk);
        @(negedge tb_clk);
        assert(tb_RX_Packet == 4'b1000) else
            $error("NAK PACKET IS WRONG");
        @(negedge tb_clk);
        check_outputs;
        tb_dp = 1'b1;
        tb_dm = ~tb_dp;

        // Test 6: Correct PID (OUT)
        @(negedge tb_clk);
        tb_test_num = 6;
        tb_test_case = "OUT Packet";
        // Reset DUT
        reset_dut;
        // Send OUT Packet
        send_byte(8'b00000001); // correct sync
        send_byte(8'b11100001); // correct OUT PID
        send_byte(8'b11000001); // addr, endpoint
        tb_data_check = 1'b1; // check RX_Packet
        assert(tb_RX_Packet == 4'b0010) else
            $error("OUT PACKET IS WRONG");
        @(posedge tb_clk)
        tb_data_check = 1'b0;
        send_byte(8'b10101100); // endpoint, crc
        @(negedge tb_clk);
        tb_dp = 1'b0;
        tb_dm = 1'b0;
        stall;
        check_outputs;
        tb_dp = 1'b1;
        tb_dm = ~tb_dp;

        // Test 7: Correct PID (IN)
        @(negedge tb_clk);
        tb_test_num = 7;
        tb_test_case = "IN Packet";
        // Reset DUT
        reset_dut;
        // Send IN Packet
        send_byte(8'b00000001); // correct sync
        send_byte(8'b01101001); // correct IN PID
        send_byte(8'b11000001); // addr, endpoint
        tb_data_check = 1'b1; // check RX_Packet
        assert(tb_RX_Packet == 4'b0001) else
            $error("IN PACKET IS WRONG");
        @(posedge tb_clk)
        tb_data_check = 1'b0;
        send_byte(8'b10101100); // endpoint, crc
        @(negedge tb_clk);
        tb_dp = 1'b0;
        tb_dm = 1'b0;
        stall;
        check_outputs;
        tb_dp = 1'b1;
        tb_dm = ~tb_dp;

        // Test 8: Incorrect Token Packet addr
        @(negedge tb_clk);
        tb_test_num = 8;
        tb_test_case = "Incorrect Token Packet addr";
        // Reset DUT
        reset_dut;
        // Send IN Packet
        send_byte(8'b00000001); // correct sync
        send_byte(8'b01101001); // correct IN PID
        send_byte(8'b11001111); // incorrect addr, endpoint
        @(negedge tb_clk);
        @(negedge tb_clk);
        @(negedge tb_clk);
        @(negedge tb_clk);
        tb_exp_RX_Error = 1'b1;
        check_outputs;
        tb_dp = 1'b0;
        tb_dm = 1'b0;
        @(negedge tb_clk);
        @(negedge tb_clk);
        tb_dp = 1'b1;
        tb_dm = ~tb_dp;

        // Test 9: Incorrect Token Packet endpoint
        @(negedge tb_clk);
        tb_test_num = 9;
        tb_test_case = "Incorrect Token Packet endpoint";
        // Reset DUT
        reset_dut;
        // Send IN Packet
        send_byte(8'b00000001); // correct sync
        send_byte(8'b01101001); // correct IN PID
        send_byte(8'b11000001); // addr, incorrect endpoint
        stall;
        @(negedge tb_clk);
        @(negedge tb_clk);
        @(negedge tb_clk);
        tb_exp_RX_Error = 1'b1;
        check_outputs;
        send_byte(8'b10101111); // incorrect endpoint, crc
        @(negedge tb_clk);
        tb_dp = 1'b0;
        tb_dm = 1'b0;
        @(negedge tb_clk);
        @(negedge tb_clk);
        tb_dp = 1'b1;
        tb_dm = ~tb_dp;

        // Test 10: Empty Data Packet
        @(negedge tb_clk);
        tb_test_num = 10;
        tb_test_case = "Empty Data Packet";
        // Reset DUT
        reset_dut;
        // Send Data Packet
        send_byte(8'b00000001); // correct sync
        send_byte(8'b11000011); // Data PID
        send_byte(8'b10101010); // crc1
        send_byte(8'b01010101); // crc2
        @(negedge tb_clk)
        tb_dp = 1'b0;
        tb_dm = 1'b0;
        stall;
        @(negedge tb_clk);
        @(negedge tb_clk);
        @(negedge tb_clk);
        @(negedge tb_clk);
        tb_exp_RX_Data_Ready = 1'b1;
        tb_exp_RX_Error = 1'b0;
        check_outputs;
        tb_dp = 1'b1;
        tb_dm = ~tb_dp;
        
        // Test 11: Arbitrary Data Packet
        @(negedge tb_clk);
        tb_test_num = 11;
        tb_test_case = "Arbitrary Data Packet";
        // Reset DUT
        reset_dut;
        // Send Data Packet
        send_byte(8'b00000001); // correct sync
        send_byte(8'b11000011); // Data PID

        send_byte(8'b11111111); // Data Packets
        send_byte(8'b11111111);
        send_byte(8'b11000011);
        send_byte(8'b00000001);
        send_byte(8'b11100111);
        send_byte(8'b00110101);
        
        send_byte(8'b10101010); // crc1
        send_byte(8'b01010101); // crc2
        @(negedge tb_clk)
        tb_dp = 1'b0;
        tb_dm = 1'b0;
        stall;
        @(negedge tb_clk);
        @(negedge tb_clk);
        @(negedge tb_clk);
        @(negedge tb_clk);
        tb_exp_RX_Data_Ready = 1'b1;
        check_outputs;
        tb_dp = 1'b1;
        tb_dm = ~tb_dp;

        // Test 12: Invalid Data Packet CRC
        @(negedge tb_clk);
        tb_test_num = 12;
        tb_test_case = "Invalid Data Packet CRC";
        // Reset DUT
        reset_dut;
        // Send Data Packet
        send_byte(8'b00000001); // correct sync
        send_byte(8'b11000011); // Data PID

        send_byte(8'b11111111); // Data Packets
        send_byte(8'b11111111);
        send_byte(8'b11000011);
        send_byte(8'b00000001);
        send_byte(8'b11100111);
        send_byte(8'b00110101);

        send_byte(8'b00000000); // crc1
        send_byte(8'b00000000); // crc2
        @(negedge tb_clk)
        tb_dp = 1'b0;
        tb_dm = 1'b0;
        stall;
        @(negedge tb_clk);
        @(negedge tb_clk);
        @(negedge tb_clk);
        @(negedge tb_clk);
        tb_exp_RX_Data_Ready = 1'b0;
        tb_exp_RX_Error = 1'b1;
        tb_exp_flush = 1'b1;
        check_outputs;
        tb_dp = 1'b1;
        tb_dm = ~tb_dp;

        // Test 13: Full Data Packet
        @(negedge tb_clk);
        tb_test_num = 13;
        tb_test_case = "Full Data Packet";
        // Reset DUT
        reset_dut;
        // Send Data Packet
        send_byte(8'b00000001); // correct sync
        send_byte(8'b11000011); // Data PID
        for (i = 0; i < 32; i = i + 1) // 64 data packets
        begin
            send_byte(8'b11111111);
            send_byte(8'b00000000);
        end
        send_byte(8'b10101010); // crc1
        send_byte(8'b01010101); // crc2
        @(negedge tb_clk)
        tb_dp = 1'b0;
        tb_dm = 1'b0;
        stall;
        @(negedge tb_clk);
        @(negedge tb_clk);
        @(negedge tb_clk);
        @(negedge tb_clk);
        tb_exp_RX_Data_Ready = 1'b1;
        tb_exp_flush = 1'b0;
        tb_exp_RX_Error = 1'b0;
        check_outputs;
        tb_dp = 1'b1;
        tb_dm = ~tb_dp;

        // Test 14: Early Eop
        @(negedge tb_clk);
        tb_test_num = 14;
        tb_test_case = "Early EOP";
        // Reset DUT
        reset_dut;
        // end Data Packet
        send_byte(8'b00000001); // correct sync
        @(negedge tb_clk);
        tb_dp = 1'b0;
        tb_dm = 1'b0;
        stall;
        @(negedge tb_clk);
        @(negedge tb_clk);
        tb_exp_RX_Error = 1'b1;
        tb_exp_RX_Data_Ready = 1'b0;
        check_outputs;
        tb_dp = 1'b1;
        tb_dm = ~tb_dp;
        @(negedge tb_clk);
        @(negedge tb_clk);

    $stop();
    end


endmodule