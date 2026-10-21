module tb_pin_verification;

    reg clk, rst;
    reg card_inserted;
    reg [3:0] keypad_digit;
    reg digit_valid;
    reg [15:0] stored_pin;
    reg [1:0] tx_sel;
    reg amount_entered;
    reg [7:0] amount_reg;

    wire [7:0] account_balance;
    wire eject_card, blocked, authenticated;
    wire dispense_cash, accept_cash;
    wire [2:0] screen_msg;
    wire tx_success;

    atm_top_2 dut (
        .clk(clk),
        .rst(rst),
        .card_inserted(card_inserted),
        .keypad_digit(keypad_digit),
        .digit_valid(digit_valid),
        .stored_pin(stored_pin),
        .tx_sel(tx_sel),
        .amount_entered(amount_entered),
        .amount_reg(amount_reg),
        .account_balance(account_balance),
        .eject_card(eject_card),
        .blocked(blocked),
        .authenticated(authenticated),
        .dispense_cash(dispense_cash),
        .accept_cash(accept_cash),
        .screen_msg(screen_msg),
        .tx_success(tx_success)
    );

    always #5 clk = ~clk;

    // Reset the complete ATM
    task reset_dut;
    begin
        @(negedge clk);
        rst = 1;
        card_inserted = 0;
        digit_valid = 0;
        keypad_digit = 0;
        stored_pin = 16'h1234;
        tx_sel = 2'b00;
        amount_entered = 0;
        amount_reg = 0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 0;
        repeat (2) @(posedge clk);
    end
    endtask

    // Insert card and enter a four-digit PIN
    task enter_pin;
        input [15:0] pin_value;
    begin
        @(negedge clk);
        card_inserted = 1;

        @(negedge clk);
        card_inserted = 0;

        // Allow FSM to enter WAIT_PIN
        repeat (2) @(posedge clk);

        @(negedge clk);
        keypad_digit = pin_value[15:12];
        digit_valid = 1;
        @(negedge clk);
        keypad_digit = pin_value[11:8];
        @(negedge clk);
        keypad_digit = pin_value[7:4];
        @(negedge clk);
        keypad_digit = pin_value[3:0];
        @(negedge clk);
        digit_valid = 0;

        // Allow PIN verification to complete
        repeat (4) @(posedge clk);
        #1;
    end
    endtask

    initial begin
        clk = 0;
        rst = 0;
        card_inserted = 0;
        keypad_digit = 0;
        digit_valid = 0;
        stored_pin = 16'h1234;
        tx_sel = 2'b00;
        amount_entered = 0;
        amount_reg = 0;

        $display("\n--- PIN VERIFICATION TEST ---");

        // TEST 1: Correct PIN
        reset_dut();
        enter_pin(16'h1234);

        if (authenticated)
            $display("PASS: Correct PIN authenticated");
        else
            $display("FAIL: Correct PIN was rejected");

        // Reset before testing incorrect PINs
        reset_dut();

        // TEST 2: One incorrect PIN
        enter_pin(16'h1235);

        if (!authenticated && !blocked)
            $display("PASS: Wrong PIN rejected; card not yet blocked");
        else
            $display("FAIL: Unexpected result for first wrong PIN");

        // TEST 3: Further incorrect attempts
        enter_pin(16'h1235);
        enter_pin(16'h1235);

        if (blocked)
            $display("PASS: Card blocked after repeated wrong PINs");
        else
            $display("FAIL: Card was not blocked as expected");

        $display("--- PIN TEST FINISHED ---\n");
        $finish;
    end

endmodule