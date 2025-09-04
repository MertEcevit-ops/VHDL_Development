onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /uart_tb/clk
add wave -noupdate /uart_tb/rst
add wave -noupdate -divider {UART I/O}
add wave -noupdate -divider {Recv byte}
add wave -noupdate /uart_tb/recv_tdata
add wave -noupdate /uart_tb/recv_tvalid
add wave -noupdate /uart_tb/recv_tready
add wave -noupdate -divider {Send byte}
add wave -noupdate /uart_tb/send_tdata
add wave -noupdate /uart_tb/send_tvalid
add wave -noupdate /uart_tb/send_tready
add wave -noupdate -divider {DUT Error indicators}
add wave -noupdate /uart_tb/rx_stop_bit_error
add wave -noupdate /uart_tb/rx_fifo_full
add wave -noupdate -divider DUT
add wave -noupdate /uart_tb/DUT/tx_tvalid
add wave -noupdate /uart_tb/DUT/tx_tready
add wave -noupdate /uart_tb/DUT/tx_tdata
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {22 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 258
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
configure wave -timeline 1
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {23330192 ns}
