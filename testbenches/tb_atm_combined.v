module tb_atm_combined;
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

    // Insert card and enter the correct PIN
    task authenticate_user;
    begin
        @(negedge clk);
        card_inserted = 1;

        @(negedge clk);
        card_inserted = 0;

        repeat (2) @(posedge clk);

        @(negedge clk);
        keypad_digit = 4'h1;
        digit_valid = 1;
        @(negedge clk);
        keypad_digit = 4'h2;
        @(negedge clk);
        keypad_digit = 4'h3;
        @(negedge clk);
        keypad_digit = 4'h4;
        @(negedge clk);
        digit_valid = 0;

        wait(authenticated == 1);
        #1;

        if (authenticated)
            $display("PASS: PIN authenticated");
        else
            $display("FAIL: Authentication failed");
    end
    endtask

    // Execute a withdrawal or deposit through the top module
    task perform_transaction;
        input [1:0] selection;
        input [7:0] amount;
        input [7:0] expected_balance;
    begin
        tx_sel = selection;
        amount_reg = amount;

        authenticate_user();

        // Wait until transaction FSM requests an amount
        wait(screen_msg == 3'd2);

        @(negedge clk);
        amount_entered = 1;

        @(negedge clk);
        amount_entered = 0;

        if (selection == 2'b01) begin
            wait(dispense_cash == 1);
            $display("PASS: Dispense cash signal asserted");
        end
        else if (selection == 2'b10) begin
            wait(accept_cash == 1);
            $display("PASS: Accept cash signal asserted");
        end

        wait(tx_success == 1);
        #1;

        if (account_balance == expected_balance)
            $display("PASS: Balance=%0d, Expected=%0d",
                     account_balance, expected_balance);
        else
            $display("FAIL: Balance=%0d, Expected=%0d",
                     account_balance, expected_balance);

        // Wait for session FSM to finish and eject card
        wait(eject_card == 1);
        @(negedge clk);
        repeat (2) @(negedge clk);
    end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        card_inserted = 0;
        keypad_digit = 0;
        digit_valid = 0;
        stored_pin = 16'h1234;
        tx_sel = 0;
        amount_entered = 0;
        amount_reg = 0;

        $display("\n--- COMBINED ATM TEST ---");

        repeat (2) @(negedge clk);
        rst = 0;
        repeat (2) @(negedge clk);

        if (account_balance == 100)
            $display("PASS: Initial balance = 100");
        else
            $display("FAIL: Initial balance is incorrect");

        // TEST 1: Withdraw 30 from 100
        $display("\nTEST 1: WITHDRAWAL");
        perform_transaction(2'b01, 8'd30, 8'd70);

        // TEST 2: Deposit 20 into 70
        $display("\nTEST 2: DEPOSIT");
        perform_transaction(2'b10, 8'd20, 8'd90);

        $display("\nFinal account balance = %0d",
                 account_balance);
        $display("--- COMBINED ATM TEST FINISHED ---\n");

        $finish;
    end

    // Prevent a failed wait from hanging simulation forever
    initial begin
        #10000;
        $display("TIMEOUT: Check FSM transitions and testbench inputs");
        $finish;
    end

endmodule