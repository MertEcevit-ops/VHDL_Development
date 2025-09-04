onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group TB /top_tb/clk
add wave -noupdate -expand -group TB /top_tb/uart_rx
add wave -noupdate -expand -group TB /top_tb/uart_tx
add wave -noupdate -expand -group TB /top_tb/rx_fifo_full
add wave -noupdate -expand -group TB /top_tb/rx_stop_bit_error
add wave -noupdate -expand -group TB /top_tb/data_in
add wave -noupdate -expand -group TB /top_tb/data_in_ready
add wave -noupdate -expand -group TB /top_tb/data_in_valid
add wave -noupdate -expand -group TB /top_tb/data_out
add wave -noupdate -expand -group TB /top_tb/data_out_valid
add wave -noupdate -expand -group TB /top_tb/bfms_start
add wave -noupdate -expand -group TB /top_tb/tx_proc_done
add wave -noupdate -expand -group TB /top_tb/rx_proc_done
add wave -noupdate -group DUT /top_tb/DUT/clk
add wave -noupdate -group DUT /top_tb/DUT/rst_in
add wave -noupdate -group DUT /top_tb/DUT/uart_rx
add wave -noupdate -group DUT /top_tb/DUT/uart_tx
add wave -noupdate -group DUT /top_tb/DUT/rx_fifo_full
add wave -noupdate -group DUT /top_tb/DUT/rx_stop_bit_error
add wave -noupdate -group DUT /top_tb/DUT/rst
add wave -noupdate -group DUT /top_tb/DUT/data
add wave -noupdate -group DUT /top_tb/DUT/valid
add wave -noupdate -group DUT /top_tb/DUT/ready
add wave -noupdate -group DUT /top_tb/DUT/rst_counter
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {177483433 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 214
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
WaveRestoreZoom {0 ns} {186828884 ns}
