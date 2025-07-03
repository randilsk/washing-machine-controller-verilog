`timescale 1ns/1ps
`include "washing_machine_top.v"

module washing_machine_tb;

    // Inputs
    reg clk;
    reg reset;
    reg start_pause;
    reg [1:0] mode_select;
    reg door_sensor;
    
    // Outputs
    wire water_valve;
    wire drain_valve;
    wire motor;
    wire [1:0] motor_dir;
    wire [3:0] leds;
    
    // Instantiate the Unit Under Test (UUT)
    washing_machine_top uut (
        .clk(clk),
        .reset(reset),
        .start_pause(start_pause),
        .mode_select(mode_select),
        .door_sensor(door_sensor),
        .water_valve(water_valve),
        .drain_valve(drain_valve),
        .motor(motor),
        .motor_dir(motor_dir),
        .leds(leds)
    );
    
    // Clock generation (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Create waveform dump
    initial begin
        $dumpfile("washing_machine.vcd");
        $dumpvars(0, washing_machine_tb);
    end
    
    // State names for display
    reg [8*20:1] state_name; // 20-character string
    always @(uut.fsm_inst.current_state) begin
        case(uut.fsm_inst.current_state)
            4'd0: state_name = "IDLE";
            4'd1: state_name = "FILL_WATER";
            4'd2: state_name = "WASH";
            4'd3: state_name = "RINSE";
            4'd4: state_name = "SPIN";
            4'd5: state_name = "PAUSE";
            4'd6: state_name = "COMPLETE";
            4'd7: state_name = "ERROR";
            default: state_name = "UNKNOWN";
        endcase
        $display("[%0t] State: %s", $time, state_name);
    end
    
    // Main test sequence
    initial begin
        // Initialize inputs
        reset = 1;
        start_pause = 0;
        mode_select = 0;
        door_sensor = 1;
        
        // Reset the system
        #100;
        reset = 0;
        $display("=== System reset complete ===");
        
        // Test Case 1: Normal wash cycle
        $display("\n=== TEST 1: Normal Wash Cycle ===");
        mode_select = 2'b00; // Normal mode
        start_pause = 1;
        #10;
        start_pause = 0;
        
        // Wait for completion (reduced times for simulation)
        #200000; // Reduced from actual timing for simulation
        
        // Test Case 2: Pause/Resume
        $display("\n=== TEST 2: Pause/Resume ===");
        reset = 1;
        #10;
        reset = 0;
        mode_select = 2'b00;
        start_pause = 1;
        #10;
        start_pause = 0;
        
        // Pause after some time
        #50000;
        start_pause = 1;
        #10;
        start_pause = 0;
        $display("System paused");
        
        // Resume after some time
        #100000;
        start_pause = 1;
        #10;
        start_pause = 0;
        $display("System resumed");
        
        // Test Case 3: Door safety
        $display("\n=== TEST 3: Door Safety ===");
        reset = 1;
        #10;
        reset = 0;
        mode_select = 2'b01; // Delicate mode
        start_pause = 1;
        #10;
        start_pause = 0;
        
        // Open door during operation
        #50000;
        door_sensor = 0;
        #10;
        $display("Door opened");
        
        // Verify error state
        #100000;
        door_sensor = 1;
        start_pause = 1;
        #10;
        start_pause = 0;
        
        // Test Case 4: Mode testing
        $display("\n=== TEST 4: Mode Testing ===");
        test_mode(2'b01, "Delicate");
        test_mode(2'b10, "Heavy");
        test_mode(2'b11, "Rinse-only");
        
        // Finish simulation
        #100000;
        $display("\n=== Simulation Complete ===");
        $finish;
    end
    
    // Task to test different modes
    task test_mode;
        input [1:0] mode;
        input [8*20:1] mode_str;
        begin
            $display("\nTesting %0s mode", mode_str);
            reset = 1;
            #10;
            reset = 0;
            mode_select = mode;
            start_pause = 1;
            #10;
            start_pause = 0;
            
            // Wait for completion (reduced time)
            #200000;
        end
    endtask
    
endmodule