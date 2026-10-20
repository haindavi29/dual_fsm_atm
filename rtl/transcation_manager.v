module transaction_manager (
    input clk,
    input rst,
    input tx_start,
    input [1:0] tx_sel,
    input amount_entered,
    input [7:0] amount_reg,
    output reg [7:0] account_balance,
    output reg tx_done,
    output reg tx_success,
    output reg dispense_cash,
    output reg accept_cash,
    output reg [2:0] screen_msg
);

parameter TX_IDLE            = 4'd0;
parameter SELECT_TX          = 4'd1;
parameter ENTER_AMOUNT       = 4'd2;
parameter CHECK_BALANCE      = 4'd3;
parameter DISPENSE           = 4'd4;
parameter DEPOSIT            = 4'd5;
parameter SHOW_BAL           = 4'd6;
parameter INSUFFICIENT_FUNDS = 4'd7;
parameter TX_COMPLETE        = 4'd8;

parameter MSG_NONE       = 3'd0;
parameter MSG_SELECT     = 3'd1;
parameter MSG_ENTER_AMT  = 3'd2;
parameter MSG_DISPENSING = 3'd3;
parameter MSG_DEPOSITING = 3'd4;
parameter MSG_BALANCE    = 3'd5;
parameter MSG_INSUF      = 3'd6;

reg [3:0] state;
reg [3:0] next_state;
reg tx_failed;

always @(posedge clk or posedge rst) begin
    if (rst)
        state <= TX_IDLE;
    else
        state <= next_state;
end

always @(*) begin
    case(state)

        TX_IDLE:
            next_state = tx_start ? SELECT_TX : TX_IDLE;

        SELECT_TX:
            if(tx_sel==2'b00)
                next_state=CHECK_BALANCE;
            else if(tx_sel==2'b01 || tx_sel==2'b10)
                next_state=ENTER_AMOUNT;
            else
                next_state=SELECT_TX;

        ENTER_AMOUNT:
            next_state = amount_entered ? CHECK_BALANCE : ENTER_AMOUNT;

        CHECK_BALANCE:
            if(tx_sel==2'b00)
                next_state=SHOW_BAL;
            else if(tx_sel==2'b01) begin
                if(account_balance>=amount_reg)
                    next_state=DISPENSE;
                else
                    next_state=INSUFFICIENT_FUNDS;
            end
            else
                next_state=DEPOSIT;

        DISPENSE:
            next_state=TX_COMPLETE;

        DEPOSIT:
            next_state=TX_COMPLETE;

        SHOW_BAL:
            next_state=TX_COMPLETE;

        INSUFFICIENT_FUNDS:
            next_state=TX_COMPLETE;

        TX_COMPLETE:
            next_state=TX_IDLE;

        default:
            next_state=TX_IDLE;

    endcase
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        account_balance <= 8'd100;
        tx_failed <= 0;
    end
    else begin

        if(state==TX_IDLE)
            tx_failed <= 0;

        if(state==INSUFFICIENT_FUNDS)
            tx_failed <= 1;

        if(state==DISPENSE && account_balance>=amount_reg)
            account_balance <= account_balance - amount_reg;

        if(state==DEPOSIT)
            account_balance <= account_balance + amount_reg;

    end
end

always @(*) begin

    tx_done=0;
    tx_success=0;
    dispense_cash=0;
    accept_cash=0;
    screen_msg=MSG_NONE;

    case(state)

        SELECT_TX:
            screen_msg=MSG_SELECT;

        ENTER_AMOUNT:
            screen_msg=MSG_ENTER_AMT;

        DISPENSE: begin
            dispense_cash=1;
            screen_msg=MSG_DISPENSING;
        end

        DEPOSIT: begin
            accept_cash=1;
            screen_msg=MSG_DEPOSITING;
        end

        SHOW_BAL:
            screen_msg=MSG_BALANCE;

        INSUFFICIENT_FUNDS:
            screen_msg=MSG_INSUF;

        TX_COMPLETE: begin
            tx_done=1;
            tx_success=!tx_failed;
        end

    endcase

end
endmodule