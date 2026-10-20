module session_manager (
   input clk,
    input rst,
    input card_inserted,
    input [3:0] keypad_digit,
    input digit_valid,
    input [15:0] stored_pin,
    input tx_done,
    output reg eject_card,
    output reg blocked,
    output reg tx_start,
    output reg authenticated
);

parameter IDLE          = 4'd0;
parameter CARD_INSERTED = 4'd1;
parameter WAIT_PIN      = 4'd2;
parameter VERIFY_PIN    = 4'd3;
parameter PIN_ERROR     = 4'd4;
parameter CARD_BLOCKED  = 4'd5;
parameter AUTHENTICATED = 4'd6;
parameter PROCESSING    = 4'd7;
parameter DONE          = 4'd8;

reg [3:0] state, next_state;
reg [1:0] try_count;
reg [15:0] entered_pin;
reg [1:0] digit_count;
reg pin_entered;

always @(posedge clk or posedge rst) begin
    if (rst)
        state <= IDLE;
    else
        state <= next_state;
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        entered_pin <= 16'd0;
        digit_count <= 2'd0;
        pin_entered <= 1'b0;
    end
    else if (state == IDLE || state == CARD_INSERTED) begin
        entered_pin <= 16'd0;
        digit_count <= 2'd0;
        pin_entered <= 1'b0;
    end
    else if (state == WAIT_PIN && digit_valid) begin
        entered_pin <= {entered_pin[11:0], keypad_digit};
        digit_count <= digit_count + 1'b1;

        if (digit_count == 2'd3)
            pin_entered <= 1'b1;
        else
            pin_entered <= 1'b0;
    end
    else begin
        pin_entered <= 1'b0;
    end
end

always @(*) begin
    case(state)

        IDLE:
            if(card_inserted)
                next_state = CARD_INSERTED;
            else
                next_state = IDLE;

        CARD_INSERTED:
            next_state = WAIT_PIN;

        WAIT_PIN:
            if(pin_entered)
                next_state = VERIFY_PIN;
            else
                next_state = WAIT_PIN;

        VERIFY_PIN:
            if(entered_pin == stored_pin)
                next_state = AUTHENTICATED;
            else
                next_state = PIN_ERROR;

        PIN_ERROR:
            if(try_count >= 2)
                next_state = CARD_BLOCKED;
            else
                next_state = WAIT_PIN;

        CARD_BLOCKED:
            next_state = CARD_BLOCKED;

        AUTHENTICATED:
            next_state = PROCESSING;

        PROCESSING:
            if(tx_done)
                next_state = DONE;
            else
                next_state = PROCESSING;

        DONE:
            next_state = IDLE;

        default:
            next_state = IDLE;

    endcase
end

always @(posedge clk or posedge rst) begin
    if(rst)
        try_count <= 2'd0;
    else if(state == IDLE)
        try_count <= 2'd0;
    else if(state == PIN_ERROR)
        try_count <= try_count + 1'b1;
end

always @(*) begin

    eject_card    = 1'b0;
    blocked       = 1'b0;
    tx_start      = 1'b0;
    authenticated = 1'b0;

    case(state)

        IDLE: begin
            eject_card = 1'b0;
        end

        CARD_INSERTED: begin
        end

        WAIT_PIN: begin
        end

        VERIFY_PIN: begin
        end

        PIN_ERROR: begin
        end

        CARD_BLOCKED: begin
            blocked = 1'b1;
        end

        AUTHENTICATED: begin
            authenticated = 1'b1;
            tx_start = 1'b1;
        end

        PROCESSING: begin
        end

        DONE: begin
            eject_card = 1'b1;
        end

    endcase

end

endmodule