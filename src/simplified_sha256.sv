module simplified_sha256(input logic clk, reset_n, start,
						 input logic [15:0] message_addr, output_addr,
						output logic done, mem_clk, mem_we,
						output logic [15:0] mem_addr,
						output logic [31:0] mem_write_data,
						 input logic [31:0] mem_read_data);
	
	
	parameter PROCESSING_ROUNDS = 8'd64;  // 64 processing rounds
	parameter BLOCKS = 2'd2;
	
	assign mem_clk = clk;

  	// State set up and other variables
  	enum logic [3:0] {IDLE, INIT, WAIT, COMPUTE, READ, WRITE, DONE, POST} state;
  	logic [31:0] block_counter;
	logic [15:0] in_addr, out_addr, t_counter;
	logic [31:0] H[0:7];
	logic [31:0] a, b, c, d, e, f, g, h;
	
	// w
	logic [31:0] w[0:15] = '{
	 32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5, 32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
	 32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3, 32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174
	};
	
	//The function that gives new w[15]
	function logic [31:0] wtnew; // function with no inputs     
		logic [31:0] s0, s1;
		begin
	     	s0 = rightrotate(w[1],7)^rightrotate(w[1],18)^(w[1]>>3);     
			s1 = rightrotate(w[14],17)^rightrotate(w[14],19)^(w[14]>>10);     
			wtnew = w[0] + s0 + w[9] + s1;
		end
	endfunction

	always_ff @(posedge clk, negedge reset_n) begin
 		if (!reset_n) begin
 			state <= IDLE;
 		end 
		else 
			case(state)
 			IDLE: begin
				//Reset state and all output
				done <= 0;
				mem_we <= 0;
				mem_addr <= 0;
				mem_write_data <= 0;
	 			block_counter <= 0;

				//Wait for start signal
				if (start) begin
					state <= INIT;
					//Save the info
//					in_addr <= message_addr;
//					out_addr <= output_addr;
					t_counter <= 0;
					
					//Init the 8 regs
					H[0] <= 32'h6a09e667;
					H[1] <= 32'hbb67ae85;
					H[2] <= 32'h3c6ef372;
					H[3] <= 32'ha54ff53a;
					H[4] <= 32'h510e527f;
					H[5] <= 32'h9b05688c;
					H[6] <= 32'h1f83d9ab;
					H[7] <= 32'h5be0cd19;
					
					state <= INIT;
				end
 			end
			INIT: begin
				{a, b, c, d, e, f, g, h} <= {H[0], H[1], H[2], H[3], H[4], H[5], H[6], H[7]};
				state <= WAIT;
				t_counter <= 0;
				//Request first word
				mem_we <= 0;
				mem_addr <= message_addr + (block_counter*32'd16);
			end
			WAIT: begin
				state <= READ;
				mem_addr <= message_addr + (block_counter*32'd16) + 1;
			end
			READ: begin
				w[15] <= mem_read_data;
				state <= COMPUTE;
				mem_addr <= message_addr + (block_counter*32'd16) + 2;
			end
 			COMPUTE: begin
	 			if (t_counter < 8'd15) begin
		 			if (block_counter > 0) begin
			 			if (t_counter < 2) begin
				 			mem_addr <= message_addr + (block_counter*32'd16) + 3 + t_counter;
			 				w[15] <= mem_read_data;
			 			end else if (t_counter < 3)
			 				w[15] <= mem_read_data;
			 			else if (t_counter == 3)
				 			w[15] <= 32'h8000_0000;
			 			else if (t_counter <  14)
				 			w[15] <= 32'h0;
			 			else
				 			w[15] <= 32'd640;
		 			end else begin
			 			mem_addr <= message_addr + (block_counter*32'd16) + 3 + t_counter;
			 			w[15] <= mem_read_data;
			 		end
		 			{a, b, c, d, e, f, g, h} <= sha256_op(a, b, c, d, e, f, g, h, w[15], t_counter);
		 			state <= COMPUTE;
		 			for (int n = 0; n < 15; n++) w[n] <= w[n+1]; // just wires for sliding window
	 			end else if (t_counter < PROCESSING_ROUNDS) begin
		 			for (int n = 0; n < 15; n++) w[n] <= w[n+1]; // just wires for sliding window
		 			w[15] <= wtnew();
 					{a, b, c, d, e, f, g, h} <= sha256_op(a, b, c, d, e, f, g, h, w[15], t_counter);
		 			state <= COMPUTE;
	 			end else begin
		 			state <= POST;
		 		end
	 			t_counter++;
 			end
 			POST: begin
	 			H[0] <= H[0] + a;
				H[1] <= H[1] + b;
				H[2] <= H[2] + c;
				H[3] <= H[3] + d;
				H[4] <= H[4] + e;
				H[5] <= H[5] + f;
				H[6] <= H[6] + g;
				H[7] <= H[7] + h;
				block_counter <= block_counter + 1;
				if (block_counter < (BLOCKS - 1))
					state <= INIT;
				else begin
					state <= WRITE;
					t_counter <= 0;
				end
 			end
 			WRITE: begin
	 			if (t_counter < 8) begin
		 			for (int n = 0; n < 7; n++) H[n] <= H[n+1]; // just wires for sliding window
		 			mem_write_data <= H[0];
		 			mem_we <= 1;
		 			mem_addr <= output_addr + t_counter;
		 			t_counter <= t_counter + 1;
		 			state = WRITE;
	 			end else begin
		 			state <= DONE;
 				end
	 		end
 			DONE: begin
	 			done <= 1;
	 		end
 		
 			endcase
	end
endmodule
