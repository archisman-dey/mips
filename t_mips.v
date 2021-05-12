module t_mips;
    reg clock;

    mips test(clock);

    initial begin
        clock = 1'b0;
        forever begin
            #10 clock = ~clock;
        end
    end
endmodule
