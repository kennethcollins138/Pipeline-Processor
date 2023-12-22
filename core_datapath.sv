/*
 * core_datapath.sv
 *
 * Authors: David and Sarah Harris
 * Updated By: Kenny Collins
 *
 * Module that implements datapath component of MIPS core.
 */

module core_datapath(input  logic   clk, reset,
                input  logic        pc_src_x,
                input  logic [1:0]  result_src_w, imm_src_d,
                input  logic        alu_src_x,
                input  logic        reg_write_w,
                input  logic [2:0]  alu_ctrl_x,
                output logic        zero_x,
                output logic [31:0] pc,
                input  logic [31:0] instr_f,
                output logic [31:0] instr_d,
                output logic [31:0] alu_result_m, dmem_write_data_m,
                input  logic [31:0] dmem_read_data_m,
				input logic         stall_f, stall_d, flush_d, flush_x, 
				input logic [1:0]  forward_a_x, forward_b_x,
				output logic [4:0] rs1_d, rs2_d, rs1_x, rs2_x,
				output logic [4:0] rd_x, rd_m, rd_w,
				input logic forward_p2_ho,
				output logic [4:0] p2_rs2);

	// Fetch (F) stage signals
	logic [31:0] pc_plus_4_f, pc_next_br_f, pc_next_f;

	// Decode (D) stage signals
	logic [31:0] imm_ext_d, pc_plus_4_d, pc_d, rd1_d, rd2_d;

	// Execute (X) stage signals
	logic [31:0] imm_ext_x, pc_plus_4_x, pc_x, pc_target_x, srca_x, srcb_x;
	logic [31:0] rd1_x, rd2_x, dmem_write_data_x, alu_result_x;
	logic carry_x, overflow_x;

	// Memory (M) stage signals
	logic [31:0] pc_plus_4_m;
	
	// Writeback (W) stage signals
	logic [31:0] alu_result_w, dmem_read_data_w, result_w, pc_plus_4_w;

	// Fetch (F) stage datapath components
	
	// TODO: switch pcreg to flopenr (see flip-flops.sv)
	flopenr #(32) pcreg(.clk, .reset, .en(~stall_f), .d(pc_next_f), .q(pc));

	adder #(32) pcadd4(.a(pc), .b(32'd4), .y(pc_plus_4_f));

	mux2 #(32) pcmux(.d0(pc_plus_4_f), .d1(pc_target_x), .sel(pc_src_x), .y(pc_next_f));


	// Fetch-to-Decode Inter-stage Registers
	// TODO: update F-D registers to use flopenr and utilize stall_d and flush_d
	flopenr #(32) pc_reg_f_d(.clk, .reset(reset | flush_d),.en(~stall_d), .d(pc), .q(pc_d));
	flopenr #(32) pc_plus_4_reg_f_d(.clk, .reset(reset | flush_d), .en(~stall_d), .d(pc_plus_4_f), .q(pc_plus_4_d));
	flopenr #(32) instr_reg_f_d(.clk, .reset(reset | flush_d), .en(~stall_d), .d(instr_f), .q(instr_d));



	// Decode (D) stage datapath components 
	
	// Note: reg file also used WB
	regfile #(32,32) rf(.clk(~clk), .we3(reg_write_w & ~reset), 
						.ra1(instr_d[19:15]), .ra2(instr_d[24:20]),
						.rd1(rd1_d), .rd2(rd2_d),
						.wa3(rd_w), .wd3(result_w)
					);

	extend ext(.instr(instr_d[31:7]), .imm_src(imm_src_d), .imm_ext(imm_ext_d));
	// assign rs1 and rs2
	assign rs1_d = instr_d[19:15];
	assign rs2_d = instr_d[24:20];

	// Decode-to-Execute Inter-stage Registers
	// TODO: update D-X registers to utilize flush_x
	flopr #(32) rd1_reg_d_x(.clk, .reset(reset | flush_x), .d(rd1_d), .q(rd1_x));
	flopr #(32) rd2_reg_d_x(.clk, .reset(reset | flush_x), .d(rd2_d), .q(rd2_x));
	flopr #(32) pc_reg_d_x(.clk, .reset(reset | flush_x), .d(pc_d), .q(pc_x));
	flopr #(5) rd_reg_d_x(.clk, .reset(reset | flush_x), .d(instr_d[11:7]), .q(rd_x));
	flopr #(32) imm_ext_reg_d_x(.clk, .reset(reset | flush_x), .d(imm_ext_d), .q(imm_ext_x));
	flopr #(32) pc_plus_4_reg_d_x(.clk, .reset(reset | flush_x), .d(pc_plus_4_d), .q(pc_plus_4_x));
	flopr #(5) rs1_reg_d_x(.clk, .reset(reset | flush_x), .d(rs1_d), .q(rs1_x));
	flopr #(5) rs2_reg_d_x(.clk, .reset(reset | flush_x), .d(rs2_d), .q(rs2_x));
	

	// Execute (X) stage datapath components
	adder #(32) pcaddbranch(.a(pc_x), .b(imm_ext_x), .y(pc_target_x));

	// TODO: add MUXes for forwarding paths
	logic [31:0] forward_b_o; //undefined wire
	mux3 #(32) forward_a_mux(.d0(rd1_x), .d1(result_w), .d2(alu_result_m), .sel(forward_a_x), .y(srca_x));
	mux3 #(32) forward_b_mux(.d0(rd2_x), .d1(result_w), .d2(alu_result_m), .sel(forward_b_x), .y(forward_b_o));
	
	// selects if alu's 2nd input is immediate or register
	mux2 #(32) srcbmux(.d0(forward_b_o), .d1(imm_ext_x),
						.sel(alu_src_x), .y(srcb_x));

	alu #(32) alu(.a(srca_x), .b(srcb_x), .f(alu_ctrl_x), .y(alu_result_x),
					.zero(zero_x), .carry(carry_x), .overflow(overflow_x));

	// Execute-to-Memory Inter-stage Registers
	logic [31:0] p2_wire;
	flopr #(32) alu_result_reg_x_m(.clk, .reset, .d(alu_result_x), .q(alu_result_m));
	flopr #(32) dmem_write_data_reg_x_m(.clk, .reset, .d(forward_b_o), .q(p2_wire));
	flopr #(5) rd_reg_x_m(.clk, .reset, .d(rd_x), .q(rd_m));
	flopr #(32) pc_plus_4_reg_x_m(.clk, .reset, .d(pc_plus_4_x), .q(pc_plus_4_m));
	flopr #(5)  p2_rs2_fwd_x_m(.clk,.reset, .d(rs2_x), .q(p2_rs2));
	


	// Memory (M) stage datapath components
	
	// Wait, where are they?!?! 
	// Oh, that's right. Data memory is its own module that we hook up to via
	// inputs and outputs of this module.

	// TODO: Add a MUX to allow the new LW-to-SW forwarding path (part 2 of
	// the project)
	mux2 #(32) p2_mux(.d0(p2_wire), .d1(result_w), .sel(forward_p2_ho), .y(dmem_write_data_m));

	// Memory-to-Writeback Inter-stage Registers
	flopr #(32) alu_result_reg_m_w(.clk, .reset, .d(alu_result_m), .q(alu_result_w));
	flopr #(32) dmem_read_data_reg_m_w(.clk, .reset, 
										.d(dmem_read_data_m), .q(dmem_read_data_w));
	flopr #(5) rd_reg_m_w(.clk, .reset, .d(rd_m), .q(rd_w));
	flopr #(32) pc_plus_4_reg_m_w(.clk, .reset, .d(pc_plus_4_m), .q(pc_plus_4_w));



	// Writeback (W) stage datapath components
	
	mux3 #(32) resmux(.d0(alu_result_w), .d1(dmem_read_data_w), .d2(pc_plus_4_w),
						 .sel(result_src_w), .y(result_w));

endmodule
