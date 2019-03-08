module parallel_bitcoin_hash_top_level(
					   input logic clk, reset_n, start,
					   input logic [15:0] message_addr, output_addr,
					  output logic done, mem_clk, mem_we,
					  output logic [15:0] mem_addr,
					  output logic [31:0] mem_write_data,
					   input logic [31:0] mem_read_data);
	
	parameter NUM_NONCES = 16;
	logic done_sigs[15:0];
	assign mem_clk = clk;
	// INSTANTIATE SHA256 MODULES
	genvar q;
	generate
 		for (q = 0; q < NUM_NONCES; q++) begin : generate_sha256_blocks
 			parallel_sha256 block (
 						.clk(mem_clk),
 						.reset_n(reset_n),
 						.start(start),
 						.message_addr,
 						.output_addr,
 						.done(done_sigs[q]),
 						.mem_we,
 						.mem_addr,
 						.mem_write_data,
 						.mem_read_data(mem_read_data),
 						.nonce(q));
 		end
	endgenerate
	assign done = done_sigs[15]; 
endmodule