module instruction_memory (
    input [31:0] read_address, // 32 bit memory address
    output reg [31:0] instruction // 32 bit instruction register
    );
    
    reg [31:0] instr_memory [0:255];    // since memory is byte addressable, 2^30 words could be supported, but 256 words for now

    initial begin 
		$readmemb("instruction.mem", instr_memory); // read from a file called instruction.mem at first
	end

    always @(read_address) begin
        instruction = instr_memory[read_address];
    end
endmodule

module data_memory (
    input [31:0] read_address, write_address, write_data, // 32 bit address and data
    input sig_mem_read, sig_mem_write, // set to 1 is data_memory is to be read from / written to respectively, 0 otherwise
    output reg [31:0] read_data // 32 bit read data
    );

    reg [31:0] data_memory [0:255]; // 256 words of data memory

    initial begin 
		$readmemb("data.mem", data_memory); // read from a file called data.mem at first
	end

    always @(read_address) begin
        if (sig_mem_read) begin
            read_data = data_memory[read_address]; // read if sig_mem_read is high
        end
    end

    always @(write_address) begin
        if (sig_mem_write) begin
            data_memory[write_address] = write_data; // write if sig_mem_write is high
            $writememb("data.mem", data_memory); // save the modified memory to file
        end
    end
endmodule

module registers (
    input [4:0] read_register_1, read_register_2, write_register, // 5-bit address for 32 registers
    input [31:0] write_data, // 32 bit data to be written to the register
    input sig_reg_write, // set to 1 if register is to be written, 0 otherwise
    output reg [31:0] read_data_1, read_data_2 // data read from register
    );

    reg [31:0] registers [0:31]; // 32 registers
    
    initial begin
        $readmemb("registers.mem", registers); // read from file
    end

    always @(write_register, write_data) begin
        if (sig_reg_write) begin
            registers[write_register] = write_data;
        end
        $writememb("registers.mem", registers); // write to file
    end

    always @(read_register_1, read_register_2) begin
        if (!sig_reg_write) begin
            read_data_1 = registers[read_register_1];
            read_data_2 = registers[read_register_2];
        end
    end
endmodule

module ALU (
    input [31:0] rs_data, rt_data, // input data
    input [2:0] alu_op, // alu control
    output reg [31:0] result, // output result
    output reg zero // flag bit for zero result
    );

    reg signed [31:0] signed_rs, signed_rt; // to store signed versions of rs and rt

    always @(rs_data, rt_data, alu_op) begin
        signed_rs = rs_data; // signed version of rs_data
        signed_rt = rt_data; // signed version of rt_data

        // calculate result based on alu_op
        case (alu_op)
            3'b000: result = rs_data & rt_data; // AND
            3'b001: result = rs_data | rt_data; // OR
            3'b010: result = signed_rs + signed_rt; // ADD
            3'b110: result = signed_rs - signed_rt; // SUB
            3'b111: begin // SLT
                        if (signed_rs < signed_rt) begin
                            result = 1;
                        end else begin
                            result = 0;
                        end
                    end
            default: $display("incorrect alu_op");
        endcase

        // calculate flag zero based on result
        if (result == 0) begin
            zero = 1'b1;
        end else begin
            zero = 1'b0;
        end
    end
endmodule

module control_unit (
    input [5:0] opcode, funct, // 6 bit opcode and 6 bit funct
    input zero, // zero from ALU
    output reg sig_reg_dst, sig_reg_write, sig_alu_src, sig_mem_read, sig_mem_write, sig_mem_to_reg, sig_pc_src,
    output reg [2:0] alu_op
    );

    always @(opcode, funct, zero) begin
        // first set all signals to 0
        sig_reg_dst     = 1'b0;
        sig_reg_write   = 1'b0;
        sig_alu_src     = 1'b0;
        sig_mem_read    = 1'b0;
        sig_mem_write   = 1'b0;
        sig_mem_to_reg  = 1'b0;
        sig_pc_src      = 1'b0;

        case (opcode)
            6'b000000:  begin // R type instructions
                            sig_reg_dst     = 1'b1;
                            sig_reg_write   = 1'b1;
                            
                            case (funct)
                                6'b100000: alu_op = 3'b010; // ADD
                                6'b100010: alu_op = 3'b110; // SUB
                                6'b100100: alu_op = 3'b000; // AND
                                6'b100101: alu_op = 3'b001; // OR
                                6'b101010: alu_op = 3'b111; // SLT
                                default: $display("incorrect funct");
                            endcase
                        end
            6'b100011:  begin // LW
                            sig_reg_write   = 1'b1;
                            sig_alu_src     = 1'b1;
                            sig_mem_read    = 1'b1;
                            sig_mem_to_reg  = 1'b1;
                            alu_op = 3'b010; // ADD
                        end
            6'b101011:  begin // SW
                            sig_alu_src     = 1'b1;
                            sig_mem_write   = 1'b1;
                            alu_op = 3'b010; // ADD
                        end
            6'b000100:  begin // BEQ
                            if (zero) begin
                                sig_pc_src = 1'b1;
                            end
                            alu_op = 3'b110; // SUB
                        end
            default: $display("incorrect opcode");
        endcase
    end
endmodule

// helper modules
module mux5_2x1 (
    input [4:0] in_0, in_1, 
    input control,
    output reg [4:0] out
    );

    always @(in_0, in_1, control) begin
        if (control) begin
            out = in_1;
        end else begin
            out = in_0;
        end
    end
endmodule

// helper modules
module mux32_2x1 (
    input [31:0] in_0, in_1, 
    input control,
    output reg [31:0] out
    );

    always @(in_0, in_1, control) begin
        if (control) begin
            out = in_1;
        end else begin
            out = in_0;
        end
    end
endmodule

module sign_extend (
    input [15:0] immediate,
    output reg [31:0] sext_immediate
    );

    always @(immediate) begin
        sext_immediate = {{16{immediate[15]}}, immediate};
    end
endmodule

module add_4 (
    input [31:0] pc,
    output reg [31:0] next_pc
    );

    always @(pc) begin
        next_pc = pc + 4;
    end
endmodule

module add_shifter (
    input [31:0] next_pc, sext_immediate,
    output reg [31:0] branch_next_pc
    );

    always @(next_pc, sext_immediate) begin
        branch_next_pc = next_pc + (sext_immediate << 2);
    end
endmodule

module mips (
    input clock);

    reg [31:0] pc = 32'b0; // program counter
    reg [31:0] pc_next; // holds the actual next program counter until next clock cycle
    
    wire [31:0] instruction; // instruction register
    
    wire [31:0] read_data; // output data from data memory
    wire [31:0] read_reg_1, read_reg_2; // output data from registers
    wire [31:0] alu_result; // output from ALU
    wire zero; // output from ALU
    // output from 4 mux's
    wire [4:0] write_register;
    wire [31:0] alu_rt;
    wire [31:0] write_data_reg;
    wire [31:0] instr_address; 
    wire [31:0] sext_immediate; // output from sign extend
    wire [31:0] next_pc, branch_next_pc; // output from pc adders

    // signals
    wire sig_reg_dst, sig_reg_write, sig_alu_src, sig_mem_read, sig_mem_write, sig_mem_to_reg, sig_pc_src;
    wire [2:0] alu_op;

    // combine all the modules to form the datapath
    instruction_memory instruction_mem (pc, instruction);
    data_memory data_mem (alu_result, alu_result, read_reg_2, sig_mem_read, sig_mem_write, read_data);
    registers regs (instruction[25:21], instruction[20:16], write_register, write_data_reg, sig_reg_write, read_reg_1, read_reg_2);
    ALU alu (read_reg_1, alu_rt, alu_op, alu_result, zero);
    mux5_2x1 mux_1 (instruction[20:16], instruction[15:11], sig_reg_dst, write_register);
    mux32_2x1 mux_2 (read_reg_2, sext_immediate, sig_alu_src, alu_rt);
    mux32_2x1 mux_3 (alu_result, read_data, sig_mem_to_reg, write_data_reg);
    mux32_2x1 mux_4 (next_pc, branch_next_pc, sig_pc_src, pc_next);
    sign_extend sext (instruction[15:0], sext_immediate);
    add_4 pc_adder (pc, next_pc);
    add_shifter branch_pc_adder (next_pc, sext_immediate, branch_next_pc);
    control_unit ctrl (instruction[31:26], instruction[5:0], zero,
                        sig_reg_dst, sig_reg_write, sig_alu_src, sig_mem_read, sig_mem_write, sig_mem_to_reg, sig_pc_src, alu_op);

    always @(posedge clock) begin
        pc = pc_next;
    end

endmodule

module t_mips;
    reg clock;

    mips test(clock);

    initial begin
        clock = 1'b0;
        forever begin
            #10 clock = ~clock;
        end
    end

    initial #5121 $finish;
endmodule
