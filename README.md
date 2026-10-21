## SIMULATED ATM USING VERILOG HDL ##
---------------------------------------------------------------------------------------------------
#### PROJECT OVERVIEW ####
 
 
 This project implements a Dual-FSM (Finite State Machine) based ATM Controller in Verilog HDL.
 The design is divided into two independent finite state machines:
 - FSM1 – User Authentication and Session Management
 - FSM2 – Transaction Management
 Both FSMs communicate using a handshake protocol (tx_start and tx_done) to ensure synchronized operation.
 - Project presentation- https://canva.link/zpul7c3nkyewxst
---------------------------------------------------------------------------------------------------
#### Features ####
> FSM1 States
- IDLE
- CARD_INSERTED
- WAIT_PIN
- VERIFY_PIN
- PIN_ERROR
- CARD_BLOCKED
- AUTHENTICATED
- PROCESSING
- DONE

> FSM2 States
- TX_IDLE
- SELECT_TX
- ENTER_AMOUNT
- CHECK_BALANCE
- DISPENSE
- DEPOSIT
- SHOW_BAL
- INSUFFICIENT_FUNDS
- TX_COMPLETE

> Handshake Protocol
- FSM1 ---- tx_start ----> FSM2
- FSM2 ---- tx_done -----> FSM1

---------------------------------------------------------------------------------------------------

#### WAVE FORMS ####

- [DEPOSITION AND WITHDRAWAL](wave_form_1.png)

- [Pin verification](wave_form_2.png)