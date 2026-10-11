module automated_railway_crossing #(
    parameter CLK_FREQ_HZ = 10,
    parameter WARNING_SEC = 2,
    parameter CLOSING_SEC = 2,
    parameter OPENING_SEC = 2
)(
    input  wire clk,
    input  wire rst_n,

    input  wire train_arrival,
    input  wire train_departure,

    output reg train_detected,
    output reg warning,
    output reg gate_closing,
    output reg gate_closed,
    output reg gate_opening
);

    // FSM states
    localparam S_SAFE         = 3'd0;
    localparam S_WARNING      = 3'd1;
    localparam S_GATE_CLOSING = 3'd2;
    localparam S_GATE_CLOSED  = 3'd3;
    localparam S_GATE_OPENING = 3'd4;

    reg [2:0] state;
    reg [2:0] next_state;

    reg [31:0] timer;

    // Timer counts for each phase
    localparam WARNING_COUNT = CLK_FREQ_HZ * WARNING_SEC;
    localparam CLOSING_COUNT = CLK_FREQ_HZ * CLOSING_SEC;
    localparam OPENING_COUNT = CLK_FREQ_HZ * OPENING_SEC;


    // --------------------------------
    // 1. State Register and Timer
    // --------------------------------

    always @(posedge clk) begin

        if (!rst_n) begin
            state <= S_SAFE;
            timer <= 0;
        end

        else begin
            state <= next_state;

            if (state != next_state)
                timer <= 0;

            else if ((state == S_WARNING) ||
                     (state == S_GATE_CLOSING) ||
                     (state == S_GATE_OPENING))
                timer <= timer + 1'b1;

            else
                timer <= 0;
        end
    end


    // --------------------------------
    // 2. Next State Logic
    // --------------------------------

    always @(*) begin

        next_state = state;

        case (state)

            // Gate open; waiting for train
            S_SAFE: begin
                if (train_arrival)
                    next_state = S_WARNING;
            end

            // Warning for 2 seconds
            S_WARNING: begin
                if (timer >= WARNING_COUNT - 1)
                    next_state = S_GATE_CLOSING;
            end

            // Gate closing for 2 seconds
            S_GATE_CLOSING: begin
                if (timer >= CLOSING_COUNT - 1)
                    next_state = S_GATE_CLOSED;
            end

            // Gate remains closed until train departs
            S_GATE_CLOSED: begin
                if (train_departure)
                    next_state = S_GATE_OPENING;
            end

            // Gate opening for 2 seconds
            S_GATE_OPENING: begin
                if (timer >= OPENING_COUNT - 1)
                    next_state = S_SAFE;
            end

            default: begin
                next_state = S_SAFE;
            end

        endcase
    end


    // --------------------------------
    // 3. Output Logic
    // --------------------------------

    always @(*) begin

        // Default: all outputs OFF
        train_detected = 1'b0;
        warning        = 1'b0;
        gate_closing   = 1'b0;
        gate_closed    = 1'b0;
        gate_opening   = 1'b0;

        case (state)

            // Safe state
            S_SAFE: begin
                // All outputs OFF
            end

            // Train detected and warning ON
            S_WARNING: begin
                train_detected = 1'b1;
                warning        = 1'b1;
            end

            // Gate is closing
            S_GATE_CLOSING: begin
                train_detected = 1'b1;
                warning        = 1'b1;
                gate_closing   = 1'b1;
            end

            // Gate fully closed
            S_GATE_CLOSED: begin
                train_detected = 1'b1;
                warning        = 1'b1;
                gate_closed    = 1'b1;
            end

            // Gate is opening after train departure
            S_GATE_OPENING: begin
                gate_opening = 1'b1;
            end

            default: begin
                train_detected = 1'b0;
                warning        = 1'b0;
                gate_closing   = 1'b0;
                gate_closed    = 1'b0;
                gate_opening   = 1'b0;
            end

        endcase
    end

endmodule