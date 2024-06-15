module rcu
(
    input logic d_edge,
    input logic eop,
    input logic bit8, 
    input logic bit7, 
    input logic bit5, 
    input logic bit4,
    input logic clk,
    input logic n_rst,
    input logic [7:0] byte_data,
    input logic [7:0] fifo_data,
    output logic w_en,
    output logic r_en,
    output logic shift_en,
    output logic en8,
    output logic en7,
    output logic en5,
    output logic en4,
    output logic clear,
    output logic RX_Data_Ready,
    output logic RX_Transfer_Active,
    output logic RX_Error,
    output logic flush,
    output logic Store_RX_Packet_Data,
    output logic [3:0] RX_Packet,
    output logic [7:0] RX_Packet_Data
);
    typedef enum logic [5:0] {
        IDLE,
        START,
        SYNCWAIT,
        SYNC,
        PIDWAIT,
        PID,
        ACK,
        NAK,
        OUT,
        IN,
        TKNADDR,
        TKNENDWAIT,
        TKNEND,
        TKNCRCWAIT,
        TKNCRC,
        DWAIT1,
        DSTORE1,
        DWAIT2,
        DSTORE2,
        DATAWAIT,
        DATASTORE,
        DATASTORE2,
        CRCWAIT,
        CRC1,
        CRC2,
        EOP,
        FLUSH,
        ERR
    } state_t;
    state_t state, nxt_state;

    always_ff @(posedge clk, negedge n_rst) begin : STATE_LOGIC
        if(n_rst == 1'b0) begin
            state <= IDLE;
        end else begin
            state <= nxt_state;
        end
    end

    always_comb begin : NEXT_STATE_LOGIC
        case(state)
        IDLE: nxt_state = eop ? ERR : d_edge ? START : IDLE;
        START: nxt_state = eop ? ERR : SYNCWAIT;
        SYNCWAIT: nxt_state = eop ? ERR : bit8 ? SYNC : SYNCWAIT;
        SYNC: nxt_state = eop ? ERR : byte_data == 8'b00000001 ? PIDWAIT : ERR;
        PIDWAIT: nxt_state = eop ? ERR : bit8 ?  PID : PIDWAIT;
        PID: nxt_state = eop ? ERR :
             byte_data == 8'b00011110 ? EOP : 
             byte_data == 8'b11010010 ? ACK :
             byte_data == 8'b01011010 ? NAK :
             byte_data == 8'b11100001 ? OUT :
             byte_data == 8'b01101001 ? IN :
             byte_data == 8'b11000011 ? DWAIT1 :
             byte_data == 8'b01001011 ? DWAIT1 : ERR;
        ACK: nxt_state = eop ? ERR : EOP;
        NAK: nxt_state = eop  ? ERR : EOP;
        OUT: nxt_state = eop ? ERR : bit7 ? TKNADDR : OUT;
        IN: nxt_state = eop ? ERR : bit7 ?  TKNADDR : IN;
        TKNADDR: nxt_state = (eop | (byte_data[7:1] != 7'b1000001)) ? ERR : TKNENDWAIT;
        TKNENDWAIT: nxt_state = eop ? ERR : bit4 ? TKNEND : TKNENDWAIT;
        TKNEND: nxt_state = (eop | (byte_data[7:4] != 4'b1001)) ? ERR : TKNCRCWAIT;
        TKNCRCWAIT: nxt_state = eop ? ERR : bit5 ? TKNCRC : TKNCRCWAIT;
        TKNCRC: nxt_state = (eop | byte_data[7:3] != 5'b10101) ? ERR : EOP;
        DWAIT1: nxt_state = eop ? CRCWAIT : bit8 ? DSTORE1: DWAIT1;
        DSTORE1: nxt_state = eop ? CRCWAIT : DWAIT2;
        DWAIT2: nxt_state = eop ? CRCWAIT : bit8 ? DSTORE2 : DWAIT2;
        DSTORE2: nxt_state = eop ? CRCWAIT : DATAWAIT;
        DATAWAIT: nxt_state = eop ? CRCWAIT : bit8 ? DATASTORE : DATAWAIT;
        DATASTORE: nxt_state = eop ? CRCWAIT : DATASTORE2;
        DATASTORE2: nxt_state = eop ? CRCWAIT : DATAWAIT;
        CRCWAIT: nxt_state = CRC1;
        CRC1: nxt_state = fifo_data == 8'b10101010 ? CRC2 : FLUSH;
        CRC2: nxt_state = fifo_data == 8'b01010101 ? IDLE : FLUSH;
        EOP: nxt_state = eop ? IDLE : EOP;
        FLUSH: nxt_state = IDLE;
        ERR: nxt_state = IDLE;
        default: nxt_state = IDLE;
        endcase
    end

    always_comb begin : OUTPUT_LOGIC
        w_en = 1'b0;
        r_en = 1'b0;
        shift_en = 1'b0;
        en8 = 1'b0;
        en7 = 1'b0;
        en5 = 1'b0;
        en4 = 1'b0;
        clear = 1'b0;
        RX_Data_Ready = 1'b0;
        RX_Transfer_Active = 1'b1; // only off during IDLE
        RX_Error = 1'b0;
        flush = 1'b0;
        Store_RX_Packet_Data = 1'b0;
        RX_Packet = 4'b0;
        RX_Packet_Data = 8'b0;
        case(state)
        IDLE: begin 
            RX_Transfer_Active = 1'b0;
            clear = 1'b1;
        end
        START: begin
            en8 = 1'b1;
            shift_en = 1'b1;
            flush = 1'b1;
        end
        SYNCWAIT: begin
            en8 = 1'b1;
            shift_en = 1'b1;
        end
        SYNC: begin
            en8 = 1'b1;
            shift_en = 1'b1;
        end
        PIDWAIT: begin
            en8 = 1'b1;
            shift_en = 1'b1;
        end
        PID: begin
            en8 = 1'b1;
            shift_en = 1'b1;
        end
        ACK: RX_Packet = 4'b0100;
        NAK: RX_Packet = 4'b1000;
        OUT: begin
            RX_Packet = 4'b0010;
            en7 = 1'b1;
            shift_en = 1'b1;
        end
        IN: begin
            RX_Packet = 4'b0001;
            en7 = 1'b1;
            shift_en = 1'b1;
        end
        TKNADDR: begin
            en4 = 1'b1;
            shift_en = 1'b1;
        end
        TKNENDWAIT: begin
            en4 = 1'b1;
            shift_en = 1'b1;
        end
        TKNEND: begin
            en5 = 1'b1;
            shift_en = 1'b1;
        end
        TKNCRCWAIT: begin
            en5 = 1'b1;
            shift_en = 1'b1;
        end
        TKNCRC: begin
        end
        DWAIT1: begin
            en8 = 1'b1;
            shift_en = 1'b1;
        end
        DSTORE1: begin
            en8 = 1'b1;
            shift_en = 1'b1;
            w_en = 1'b1;
        end
        DWAIT2: begin
            en8 = 1'b1;
            shift_en = 1'b1;
        end
        DSTORE2: begin
            en8 = 1'b1;
            shift_en = 1'b1;
            w_en = 1'b1;
        end
        DATAWAIT: begin
            en8 = 1'b1;
            shift_en = 1'b1;
        end
        DATASTORE: begin
            en8 = 1'b1;
            shift_en = 1'b1;
            w_en = 1'b1;
            r_en = 1'b1;
            // Store_RX_Packet_Data = 1'b1;
            // RX_Packet_Data = fifo_data;
        end
        DATASTORE2: begin
            en8 = 1'b1;
            shift_en = 1'b1;
            Store_RX_Packet_Data = 1'b1;
            RX_Packet_Data = fifo_data;
        end
        CRCWAIT : r_en = 1'b1;
        CRC1: r_en = 1'b1;
        CRC2: begin
            RX_Data_Ready = 1'b1;
        end
        EOP: begin
        end
        FLUSH: begin
            clear = 1'b1;
            RX_Error = 1'b1;
            flush = 1'b1;
        end
        ERR: RX_Error = 1'b1;
        endcase
    end
endmodule