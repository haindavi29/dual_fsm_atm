module atm_top_2(
 input clk,
    input rst,
    input card_inserted,
    input [3:0] keypad_digit,
    input digit_valid,
    input [15:0] stored_pin,
    input [1:0] tx_sel,
    input amount_entered,
    input [7:0] amount_reg,
    output [7:0] account_balance,
    output eject_card,
    output blocked,
    output authenticated,
    output dispense_cash,
    output accept_cash,
    output [2:0] screen_msg,
    output tx_success
);

wire tx_start;
wire tx_done;

session_manager fsm1(
    .clk(clk),
    .rst(rst),
    .card_inserted(card_inserted),
    .keypad_digit(keypad_digit),
    .digit_valid(digit_valid),
    .stored_pin(stored_pin),
    .tx_done(tx_done),
    .eject_card(eject_card),
    .blocked(blocked),
    .tx_start(tx_start),
    .authenticated(authenticated)
);

transaction_manager fsm2(
    .clk(clk),
    .rst(rst),
    .tx_start(tx_start),
    .tx_sel(tx_sel),
    .amount_entered(amount_entered),
    .amount_reg(amount_reg),
    .account_balance(account_balance),
    .tx_done(tx_done),
    .tx_success(tx_success),
    .dispense_cash(dispense_cash),
    .accept_cash(accept_cash),
    .screen_msg(screen_msg)

    );
endmodule