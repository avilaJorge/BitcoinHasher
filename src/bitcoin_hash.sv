module bitcoin_hash(input logic clk, reset_n, start,
						 input logic [15:0] message_addr, output_addr,
						output logic done, mem_clk, mem_we,
						output logic [15:0] mem_addr,
						output logic [31:0] mem_write_data,
						 input logic [31:0] mem_read_data);
	
	
	parameter PROCESSING_ROUNDS = 8'd64;  // 64 processing rounds
	parameter BLOCKS = 32'd33;
	
	assign mem_clk = clk;

  	// State set up and other variables
  	enum logic [3:0] {IDLE, INIT, INIT_2, WAIT, COMPUTE, READ, WRITE, DONE, POST} state;
  	logic [31:0] block_counter;
	logic [15:0] t_counter;
	logic [31:0] H[0:7];
	logic [31:0] H_P1[0:7];
	logic [31:0] H_P2[0:7];
	logic [31:0] H0[0:15];
	logic [31:0] a, b, c, d, e, f, g, h, precomp_wp;
	
		// SHA256 K constants
	parameter int k[0:63] = '{
	   32'h428a2f98,32'h71374491,32'hb5c0fbcf,32'he9b5dba5,32'h3956c25b,32'h59f111f1,32'h923f82a4,32'hab1c5ed5,
	   32'hd807aa98,32'h12835b01,32'h243185be,32'h550c7dc3,32'h72be5d74,32'h80deb1fe,32'h9bdc06a7,32'hc19bf174,
	   32'he49b69c1,32'hefbe4786,32'h0fc19dc6,32'h240ca1cc,32'h2de92c6f,32'h4a7484aa,32'h5cb0a9dc,32'h76f988da,
	   32'h983e5152,32'ha831c66d,32'hb00327c8,32'hbf597fc7,32'hc6e00bf3,32'hd5a79147,32'h06ca6351,32'h14292967,
	   32'h27b70a85,32'h2e1b2138,32'h4d2c6dfc,32'h53380d13,32'h650a7354,32'h766a0abb,32'h81c2c92e,32'h92722c85,
	   32'ha2bfe8a1,32'ha81a664b,32'hc24b8b70,32'hc76c51a3,32'hd192e819,32'hd6990624,32'hf40e3585,32'h106aa070,
	   32'h19a4c116,32'h1e376c08,32'h2748774c,32'h34b0bcb5,32'h391c0cb3,32'h4ed8aa4a,32'h5b9cca4f,32'h682e6ff3,
	   32'h748f82ee,32'h78a5636f,32'h84c87814,32'h8cc70208,32'h90befffa,32'ha4506ceb,32'hbef9a3f7,32'hc67178f2
	};	
	
	// SHA256 hash round
	function logic [287:0] sha256_op(input logic [31:0] a, b, c, d, e, f, g, h, w, precomp_wp,
	                                 input logic [7:0] t);
	    logic [31:0] S1, S0, ch, maj, t1, t2;// internal signals
	begin
	    S1 = rightrotate(e, 6) ^ rightrotate(e, 11) ^ rightrotate(e, 25);
	    ch = (e & f) ^ ((~e) & g);
	    t1 = S1 + ch + precomp_wp;
	    S0 = rightrotate(a, 2) ^ rightrotate(a, 13) ^ rightrotate(a, 22);
	    maj = (a & b) ^ (a & c) ^ (b & c);
	    t2 = S0 + maj;
	
	    sha256_op = {t1 + t2, a, b, c, d + t1, e, f, g};
	end
	endfunction
	
	// right rotation
	function logic [31:0] rightrotate(input logic [31:0] x,
	                                  input logic [7:0] r);
	begin
	    rightrotate = (x >> r) | (x << (32-r));
	end
	endfunction

	// w
	logic [31:0] w[0:15] = '{
	 32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5, 32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
	 32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3, 32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174
	};
	
	// Nonces
	logic [31:0] nonce[0:15] = '{
		32'd0, 32'd1, 32'd2, 32'd3, 32'd4, 32'd5, 32'd6, 32'd7, 32'd8, 32'd9, 32'd10, 32'd11, 32'd12, 32'd13, 32'd14, 32'd15
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
					
					mem_addr <= message_addr + (block_counter*32'd16);
					state <= INIT;
				end
 			end
			INIT: begin
				if ((block_counter % 32'd2) == 32'd0) begin
					{a, b, c, d, e, f, g, h} <= {H[0], H[1], H[2], H[3], H[4], H[5], H[6], H[7]};
				end else begin
					{a, b, c, d, e, f, g, h} <= {H_P1[0], H_P1[1], H_P1[2], H_P1[3], H_P1[4], H_P1[5], H_P1[6], H_P1[7]};
				end
				if (block_counter == 0) begin
					state <= WAIT;
					mem_we <= 0;
					mem_addr <= message_addr + ((block_counter % 2) *32'd16) + 1;
				end else if ((block_counter % 2) == 0) begin
					w[15] <= H_P2[0];
		 			for (int n = 0; n < 7; n++) H_P2[n] <= H_P2[n+1]; // just wires for sliding window
		 			state <= READ;
				end else begin
					state <= READ;
					mem_addr <= message_addr + ((block_counter % 2) * 32'd16) + 2;
					w[15] <= mem_read_data;
				end
			end
			WAIT: begin
				state <= READ;
				w[15] <= mem_read_data;
				mem_addr <= message_addr + (block_counter*32'd16) + 2;
			end
			READ: begin
				if (block_counter != 0 && (block_counter % 2) == 0) begin
					w[15] <= H_P2[0];
		 			for (int n = 0; n < 7; n++) H_P2[n] <= H_P2[n+1]; // just wires for sliding window
				end else begin
					w[15] <= mem_read_data;
					mem_addr <= message_addr + ((block_counter % 2) * 32'd16) + 3;
				end
				precomp_wp <= w[15] + h + k[0];
		 		for (int n = 0; n < 15; n++) w[n] <= w[n+1]; // just wires for sliding window
				state <= COMPUTE;
			end
 			COMPUTE: begin
	 			if (t_counter < 8'd14) begin
		 			if (block_counter == 0) begin
			 			mem_addr <= message_addr + 4 + t_counter;
			 			w[15] <= mem_read_data;
		 			end else if ((block_counter % 2) == 0) begin
			 			if (t_counter < 6) begin
							w[15] <= H_P2[0];
						 	for (int n = 0; n < 7; n++) H_P2[n] <= H_P2[n+1]; // just wires for sliding window
			 			end else if (t_counter == 6) begin
				 			w[15] <= 32'h8000_0000;
			 			end else if (t_counter < 13) begin
				 			w[15] <= 32'd0;
			 			end else
				 			w[15] <= 32'd256;
		 			end else begin
			 			if (t_counter < 1) begin
				 			mem_addr <= message_addr + 4;
			 				w[15] <= mem_read_data;
			 			end else if (t_counter == 1) begin
				 			w[15] <= nonce[0];
			 				for (int n = 0; n < 15; n++) nonce[n] <= nonce[n+1]; // just wires for sliding window
			 			end else if (t_counter == 2)
				 			w[15] <= 32'h8000_0000;
			 			else if (t_counter <  13)
				 			w[15] <= 32'h0;
			 			else
				 			w[15] <= 32'd640;
		 			end
		 			precomp_wp <= w[15] + g + k[t_counter+1];
		 			{a, b, c, d, e, f, g, h} <= sha256_op(a, b, c, d, e, f, g, h, w[15], precomp_wp, t_counter);
		 			state <= COMPUTE;
		 			for (int n = 0; n < 15; n++) w[n] <= w[n+1]; // just wires for sliding window
	 			end else if (t_counter < PROCESSING_ROUNDS) begin
		 			for (int n = 0; n < 15; n++) w[n] <= w[n+1]; // just wires for sliding window
		 			w[15] <= wtnew();
		 			precomp_wp <= w[15] + g + k[t_counter+1];
 					{a, b, c, d, e, f, g, h} <= sha256_op(a, b, c, d, e, f, g, h, w[15], precomp_wp, t_counter);
		 			state <= COMPUTE;
	 			end else begin
				 	mem_addr <= message_addr + 32'd16;
		 			state <= POST;
		 		end
	 			t_counter++;
 			end
 			POST: begin
	 			
	 			if (block_counter == 32'd0) begin
					H_P1[0] <= H[0] + a;
					H_P1[1] <= H[1] + b;
					H_P1[2] <= H[2] + c;
					H_P1[3] <= H[3] + d;
					H_P1[4] <= H[4] + e;
					H_P1[5] <= H[5] + f;
					H_P1[6] <= H[6] + g;
					H_P1[7] <= H[7] + h;
		 			
					H_P2[0] <= H[0] + a;
					H_P2[1] <= H[1] + b;
					H_P2[2] <= H[2] + c;
					H_P2[3] <= H[3] + d;
					H_P2[4] <= H[4] + e;
					H_P2[5] <= H[5] + f;
					H_P2[6] <= H[6] + g;
					H_P2[7] <= H[7] + h;
	 			end else if ((block_counter % 2) != 0) begin
					//Init the 8 regs
					H[0] <= 32'h6a09e667;
					H[1] <= 32'hbb67ae85;
					H[2] <= 32'h3c6ef372;
					H[3] <= 32'ha54ff53a;
					H[4] <= 32'h510e527f;
					H[5] <= 32'h9b05688c;
					H[6] <= 32'h1f83d9ab;
					H[7] <= 32'h5be0cd19;
					 // Store H's from phase 2 for calculations in phase 3
					H_P2[0] <= H_P1[0] + a;
					H_P2[1] <= H_P1[1] + b;
					H_P2[2] <= H_P1[2] + c;
					H_P2[3] <= H_P1[3] + d;
					H_P2[4] <= H_P1[4] + e;
					H_P2[5] <= H_P1[5] + f;
					H_P2[6] <= H_P1[6] + g;
					H_P2[7] <= H_P1[7] + h;
		 		end
		 			
				block_counter <= block_counter + 1;
				mem_addr <= message_addr + 32'd17;
	 			if (block_counter == (BLOCKS - 1)) begin
		 			H0[15] <= H[0] + a;
					for (int n = 0; n < 15; n++) H0[n] <= H0[n+1];
		 			state <= WRITE;
				end else if (block_counter != 0 && ((block_counter) % 2) == 0) begin
		 			H0[15] <= H[0] + a;
					for (int n = 0; n < 15; n++) H0[n] <= H0[n+1];
		 			state <= INIT;
				end else begin
					state <= INIT;
				end
				t_counter <= 0;
 			end
 			WRITE: begin
	 			if (t_counter < 16) begin
		 			for (int n = 0; n < 15; n++) H0[n] <= H0[n+1]; // just wires for sliding window
		 			mem_write_data <= H0[0];
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