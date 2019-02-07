module simplified_sha256(input logic clk, reset_n, start,
						 input logic [15:0] message_addr, output_addr,
						output logic done, mem_clk, mem_we,
						output logic [15:0] mem_addr,
						output logic [31:0] mem_write_data,
						 input logic [31:0] mem_read_data);

	assign mem_addr = clk;

  	// State set up and other variables
  	enum logic [2:0] {IDLE, INIT, WAIT, READ, WRITE, DONE} state;
  	logic [31:0] buffer;
	logic [15:0] in_addr,out_addr,counter;
	logic [31:0] H0, H1, H2, H3, H4, H5, H6, H7;
	logic [31:0] a, b, c, d, e, f, g, h;
	logic []

	// SHA256 K constants
	parameter int sha256_k[0:63] = '{
	 32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5, 32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
	 32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3, 32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,
	 32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc, 32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,
	 32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7, 32'hc6e00bf3, 32'hd5a79147, 32'h06ca6351, 32'h14292967,
	 32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13, 32'h650a7354, 32'h766a0abb, 32'h81c2c92e, 32'h92722c85,
	 32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3, 32'hd192e819, 32'hd6990624, 32'hf40e3585, 32'h106aa070,
	 32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5, 32'h391c0cb3, 32'h4ed8aa4a, 32'h5b9cca4f, 32'h682e6ff3,
	 32'h748f82ee, 32'h78a5636f, 32'h84c87814, 32'h8cc70208, 32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2
	};

	// w
	parameter int w[0:15] = '{
	 32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5, 32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
	 32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3, 32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,
	};
	
	// right rotation
	function logic [31:0] rightrotate(input logic [31:0] x,
 		input logic [ 7:0] r);
 		rightrotate = (x >> r) | (x << (32-r));
	endfunction
	
	//sha256 operation
	function logic [255:0] sha256_op(input logic [31:0] a, b, c, d, e, f, g, h, w, k);
 		logic [31:0] S1, S0, ch, maj, t1, t2; // internal signals
	begin
 		S1 = rightrotate(e, 6) ^ rightrotate(e, 11) ^ rightrotate(e, 25);
 		ch = (e & f) ^ ((~e) & g);
 		t1 = ch + S1 + h + k + w;
 		S0 = rightrotate(a, 2) ^ rightrotate(a, 13) ^ rightrotate(a, 22);
 		maj = (a & b) ^ (a & c) ^ (b & c);
 		t2 = maj + S0;
 		sha256_op = {t1 + t2, a, b, c, d + t1, e, f, g};
	end
	endfunction
	
	//The function that gives new w[15]
	function logic [31:0] wtnew; // function with no inputs     
		logic [31:0] s0, s1; 
     		s0 = rrot(w[1],7)^rrot(w[1],18)^(w[1]>>3);     
		s1 = rrot(w[14],17)^rrot(w[14],19)^(w[14]>>10);     
		wtnew = w[0] + s0 + w[9] + s1; 
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

				//Wait for start signal
				if (start) begin
					state <= INIT;
					//Save the info
					in_addr <= message_addr;
					out_addr <= output_addr;
					counter <= size;
				end
			end
			INIT: begin
				//Init the 8 regs
				H0 = 6a09e667;
				H1 = bb67ae85;
				H2 = 3c6ef372;
				H3 = a54ff53a;
				H4 = 510e527f;
				H5 = 9b05688c;
				H6 = 1f83d9ab;
				H7 = 5be0cd19; 


				//Request first word
				mem_we <= 0;
				mem_addr <= in_addr;
				state <= WAIT;
			end
 			COMPUTE: begin
 				for (int n = 0; n < 15; n++) w[n] <= w[n+1]; // just wires 
				w[15] <= wtnew();
 				{a, b, c, d, e, f, g, h} <= sha256_op(a, b, c, d, e, f, g, h, w, k[t]);
 			
 			end
 		
 			endcase
	end
endmodule
