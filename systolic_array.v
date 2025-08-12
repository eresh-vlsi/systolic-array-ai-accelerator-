module systolic_array_3x3 #(
    parameter DATA_WIDTH = 8,
    parameter RESULT_WIDTH = 16
) (
    input wire clk,
    input wire rst,
    input wire start,
    
    // Matrix A inputs
    input wire signed [DATA_WIDTH-1:0] a00_in, a01_in, a02_in,
    input wire signed [DATA_WIDTH-1:0] a10_in, a11_in, a12_in,
    input wire signed [DATA_WIDTH-1:0] a20_in, a21_in, a22_in,
    
    // Matrix B inputs
    input wire signed [DATA_WIDTH-1:0] b00_in, b01_in, b02_in,
    input wire signed [DATA_WIDTH-1:0] b10_in, b11_in, b12_in,
    input wire signed [DATA_WIDTH-1:0] b20_in, b21_in, b22_in,
    
    // Result matrix outputs
    output wire signed [RESULT_WIDTH-1:0] c00_out, c01_out, c02_out,
    output wire signed [RESULT_WIDTH-1:0] c10_out, c11_out, c12_out,
    output wire signed [RESULT_WIDTH-1:0] c20_out, c21_out, c22_out,
    
    output reg valid_out
);

    // Internal wires for connecting PEs
    wire signed [DATA_WIDTH-1:0] a_h[0:2][0:3];
    wire signed [DATA_WIDTH-1:0] b_v[0:3][0:2];
    
    // Control signals
    reg [3:0] cycle_count;
    reg computing;
    reg enable;
    
    // Matrix storage
    reg signed [DATA_WIDTH-1:0] matrix_a[0:2][0:2];
    reg signed [DATA_WIDTH-1:0] matrix_b[0:2][0:2];
    
    // Input feeding registers
    reg signed [DATA_WIDTH-1:0] a_inputs[0:2];
    reg signed [DATA_WIDTH-1:0] b_inputs[0:2];
    
    // Control logic
    always @(posedge clk) begin
        if (rst) begin
            cycle_count <= 0;
            computing <= 0;
            valid_out <= 0;
            enable <= 0;
            
            // Clear input registers
            a_inputs[0] <= 0; a_inputs[1] <= 0; a_inputs[2] <= 0;
            b_inputs[0] <= 0; b_inputs[1] <= 0; b_inputs[2] <= 0;
            
            // Store input matrices
            matrix_a[0][0] <= 0; matrix_a[0][1] <= 0; matrix_a[0][2] <= 0;
            matrix_a[1][0] <= 0; matrix_a[1][1] <= 0; matrix_a[1][2] <= 0;
            matrix_a[2][0] <= 0; matrix_a[2][1] <= 0; matrix_a[2][2] <= 0;
            
            matrix_b[0][0] <= 0; matrix_b[0][1] <= 0; matrix_b[0][2] <= 0;
            matrix_b[1][0] <= 0; matrix_b[1][1] <= 0; matrix_b[1][2] <= 0;
            matrix_b[2][0] <= 0; matrix_b[2][1] <= 0; matrix_b[2][2] <= 0;
            
        end else if (start && !computing) begin
            computing <= 1;
            cycle_count <= 0;
            valid_out <= 0;
            enable <= 0;
            
            // Load matrices
            matrix_a[0][0] <= a00_in; matrix_a[0][1] <= a01_in; matrix_a[0][2] <= a02_in;
            matrix_a[1][0] <= a10_in; matrix_a[1][1] <= a11_in; matrix_a[1][2] <= a12_in;
            matrix_a[2][0] <= a20_in; matrix_a[2][1] <= a21_in; matrix_a[2][2] <= a22_in;
            
            matrix_b[0][0] <= b00_in; matrix_b[0][1] <= b01_in; matrix_b[0][2] <= b02_in;
            matrix_b[1][0] <= b10_in; matrix_b[1][1] <= b11_in; matrix_b[1][2] <= b12_in;
            matrix_b[2][0] <= b20_in; matrix_b[2][1] <= b21_in; matrix_b[2][2] <= b22_in;
            
        end else if (computing) begin
            cycle_count <= cycle_count + 1;
            
            // Enable computation after setup
            if (cycle_count >= 1 && cycle_count <= 9) begin
                enable <= 1;
            end else begin
                enable <= 0;
            end
            
            // Feed data based on cycle
            case (cycle_count)
                1: begin
                    a_inputs[0] <= matrix_a[0][0];
                    b_inputs[0] <= matrix_b[0][0];
                    a_inputs[1] <= 0;
                    b_inputs[1] <= 0;
                    a_inputs[2] <= 0;
                    b_inputs[2] <= 0;
                end
                2: begin
                    a_inputs[0] <= matrix_a[0][1];
                    a_inputs[1] <= matrix_a[1][0];
                    b_inputs[0] <= matrix_b[1][0];
                    b_inputs[1] <= matrix_b[0][1];
                    a_inputs[2] <= 0;
                    b_inputs[2] <= 0;
                end
                3: begin
                    a_inputs[0] <= matrix_a[0][2];
                    a_inputs[1] <= matrix_a[1][1];
                    a_inputs[2] <= matrix_a[2][0];
                    b_inputs[0] <= matrix_b[2][0];
                    b_inputs[1] <= matrix_b[1][1];
                    b_inputs[2] <= matrix_b[0][2];
                end
                4: begin
                    a_inputs[0] <= 0;
                    a_inputs[1] <= matrix_a[1][2];
                    a_inputs[2] <= matrix_a[2][1];
                    b_inputs[0] <= 0;
                    b_inputs[1] <= matrix_b[2][1];
                    b_inputs[2] <= matrix_b[1][2];
                end
                5: begin
                    a_inputs[0] <= 0;
                    a_inputs[1] <= 0;
                    a_inputs[2] <= matrix_a[2][2];
                    b_inputs[0] <= 0;
                    b_inputs[1] <= 0;
                    b_inputs[2] <= matrix_b[2][2];
                end
                default: begin
                    a_inputs[0] <= 0;
                    a_inputs[1] <= 0;
                    a_inputs[2] <= 0;
                    b_inputs[0] <= 0;
                    b_inputs[1] <= 0;
                    b_inputs[2] <= 0;
                end
            endcase
            
            // Signal completion
            if (cycle_count == 10) begin
                valid_out <= 1;
                computing <= 0;
                enable <= 0;
            end
        end
    end
    
    // Wire connections for systolic array
    assign a_h[0][0] = a_inputs[0];
    assign a_h[1][0] = a_inputs[1];
    assign a_h[2][0] = a_inputs[2];
    
    assign b_v[0][0] = b_inputs[0];
    assign b_v[0][1] = b_inputs[1];
    assign b_v[0][2] = b_inputs[2];
    
    // Instantiate 3x3 PE array
    PE #(.DATA_WIDTH(DATA_WIDTH), .RESULT_WIDTH(RESULT_WIDTH)) pe00 (
        .clk(clk), .rst(rst), .enable(enable),
        .a_in(a_h[0][0]), .b_in(b_v[0][0]),
        .a_out(a_h[0][1]), .b_out(b_v[1][0]),
        .c_out(c00_out)
    );
    
    PE #(.DATA_WIDTH(DATA_WIDTH), .RESULT_WIDTH(RESULT_WIDTH)) pe01 (
        .clk(clk), .rst(rst), .enable(enable),
        .a_in(a_h[0][1]), .b_in(b_v[0][1]),
        .a_out(a_h[0][2]), .b_out(b_v[1][1]),
        .c_out(c01_out)
    );
    
    PE #(.DATA_WIDTH(DATA_WIDTH), .RESULT_WIDTH(RESULT_WIDTH)) pe02 (
        .clk(clk), .rst(rst), .enable(enable),
        .a_in(a_h[0][2]), .b_in(b_v[0][2]),
        .a_out(a_h[0][3]), .b_out(b_v[1][2]),
        .c_out(c02_out)
    );
    
    PE #(.DATA_WIDTH(DATA_WIDTH), .RESULT_WIDTH(RESULT_WIDTH)) pe10 (
        .clk(clk), .rst(rst), .enable(enable),
        .a_in(a_h[1][0]), .b_in(b_v[1][0]),
        .a_out(a_h[1][1]), .b_out(b_v[2][0]),
        .c_out(c10_out)
    );
    
    PE #(.DATA_WIDTH(DATA_WIDTH), .RESULT_WIDTH(RESULT_WIDTH)) pe11 (
        .clk(clk), .rst(rst), .enable(enable),
        .a_in(a_h[1][1]), .b_in(b_v[1][1]),
        .a_out(a_h[1][2]), .b_out(b_v[2][1]),
        .c_out(c11_out)
    );
    
    PE #(.DATA_WIDTH(DATA_WIDTH), .RESULT_WIDTH(RESULT_WIDTH)) pe12 (
        .clk(clk), .rst(rst), .enable(enable),
        .a_in(a_h[1][2]), .b_in(b_v[1][2]),
        .a_out(a_h[1][3]), .b_out(b_v[2][2]),
        .c_out(c12_out)
    );
    
    PE #(.DATA_WIDTH(DATA_WIDTH), .RESULT_WIDTH(RESULT_WIDTH)) pe20 (
        .clk(clk), .rst(rst), .enable(enable),
        .a_in(a_h[2][0]), .b_in(b_v[2][0]),
        .a_out(a_h[2][1]), .b_out(b_v[3][0]),
        .c_out(c20_out)
    );
    
    PE #(.DATA_WIDTH(DATA_WIDTH), .RESULT_WIDTH(RESULT_WIDTH)) pe21 (
        .clk(clk), .rst(rst), .enable(enable),
        .a_in(a_h[2][1]), .b_in(b_v[2][1]),
        .a_out(a_h[2][2]), .b_out(b_v[3][1]),
        .c_out(c21_out)
    );
    
    PE #(.DATA_WIDTH(DATA_WIDTH), .RESULT_WIDTH(RESULT_WIDTH)) pe22 (
        .clk(clk), .rst(rst), .enable(enable),
        .a_in(a_h[2][2]), .b_in(b_v[2][2]),
        .a_out(a_h[2][3]), .b_out(b_v[3][2]),
        .c_out(c22_out)
    );

endmodule
