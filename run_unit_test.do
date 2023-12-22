vlib work
vmap work

vlog -lint *.sv
vsim -voptargs=+acc work.testbench

# add all of the important signals to our waveform
add wave -hex -label clk /testbench/clk
add wave -position end -hex -label reset /testbench/reset
add wave -position end -hex -label pc /testbench/dut/pc
add wave -position end -hex -label instr_f /testbench/dut/core/instr_f
add wave -position end -hex -label stall_f /testbench/dut/core/dp/stall_f
add wave -position end -hex -label instr_d /testbench/dut/core/instr_d
add wave -position end -hex -label flush_d /testbench/dut/core/dp/flush_d
add wave -position end -hex -label stall_d /testbench/dut/core/dp/stall_d
add wave -position end -hex -label forward_a_x /testbench/dut/core/dp/forward_a_x
add wave -position end -hex -label forward_b_x /testbench/dut/core/dp/forward_b_x
add wave -position end -hex -label flush_x /testbench/dut/core/dp/flush_x
add wave -position end -hex -label alu_result_x /testbench/dut/core/dp/alu_result_x
add wave -position end -hex -label dmem_write_data_m /testbench/dut/core/dmem_write_data
add wave -position end -hex -label dmem_write_m /testbench/dut/core/dmem_write
add wave -position end -hex -label dmem_read_data_m /testbench/dut/core/dmem_read_data

run 100
