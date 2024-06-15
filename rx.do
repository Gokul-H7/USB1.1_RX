onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -color Cyan /tb_USB_RX/tb_test_num
add wave -noupdate -color Cyan /tb_USB_RX/tb_test_case
add wave -noupdate -color Cyan /tb_USB_RX/tb_data_check
add wave -noupdate -color Red /tb_USB_RX/DUT/RCU/state
add wave -noupdate -expand -group {Output Signals} -color Magenta /tb_USB_RX/tb_RX_Data_Ready
add wave -noupdate -expand -group {Output Signals} -color Magenta /tb_USB_RX/tb_RX_Transfer_Active
add wave -noupdate -expand -group {Output Signals} -color Magenta /tb_USB_RX/tb_RX_Error
add wave -noupdate -expand -group {Output Signals} -color Magenta /tb_USB_RX/tb_flush
add wave -noupdate -expand -group {Output Signals} -color Magenta /tb_USB_RX/tb_Store_RX_Packet_Data
add wave -noupdate -expand -group {Output Signals} -color Magenta /tb_USB_RX/tb_RX_Packet
add wave -noupdate -expand -group {Output Signals} -color Magenta /tb_USB_RX/tb_RX_Packet_Data
add wave -noupdate -expand -group {RX Fifo} /tb_USB_RX/DUT/FIFO/byte_data
add wave -noupdate -expand -group {RX Fifo} -color Yellow /tb_USB_RX/DUT/FIFO/w_en
add wave -noupdate -expand -group {RX Fifo} -color Yellow /tb_USB_RX/DUT/FIFO/r_en
add wave -noupdate -expand -group {RX Fifo} -color Yellow /tb_USB_RX/DUT/FIFO/fifo_data
add wave -noupdate -expand -group {RX Fifo} -color Yellow /tb_USB_RX/DUT/FIFO/fifo
add wave -noupdate -expand -group {RX Fifo} /tb_USB_RX/DUT/FIFO/w_ptr
add wave -noupdate -expand -group {RX Fifo} /tb_USB_RX/DUT/FIFO/r_ptr
add wave -noupdate /tb_USB_RX/DUT/RCU/nxt_state
add wave -noupdate -color Magenta /tb_USB_RX/DUT/eop
add wave -noupdate /tb_USB_RX/tb_clk
add wave -noupdate /tb_USB_RX/tb_n_rst
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {10650 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 167
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {2725142 ps} {2759204 ps}
