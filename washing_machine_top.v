`timescale 1ns/1ps
`include "Washing_Machine_FSM/washing_machine_fsm.v"
`include "Timer/timer.v"

module washing_machine_top(
    input clk,
    input reset,
    input start_pause,
    input [1:0] mode_select,
    input door_sensor,
    output water_valve,
    output drain_valve,
    output motor,
    output [1:0] motor_dir,
    output [3:0] leds
);

    // Wire declarations
    wire timer_done;
    wire [31:0] timer_value;
    wire timer_start;
    
    // Instantiate FSM
    washing_machine_fsm fsm_inst (
        .clk(clk),
        .reset(reset),
        .start_pause(start_pause),
        .mode_select(mode_select),
        .door_sensor(door_sensor),
        .timer_done(timer_done),
        .water_valve(water_valve),
        .drain_valve(drain_valve),
        .motor(motor),
        .motor_dir(motor_dir),
        .leds(leds),
        .timer_value(timer_value),
        .timer_start(timer_start)
    );
    
    // Instantiate Timer
    timer timer_inst (
        .clk(clk),
        .reset(reset),
        .start(timer_start),
        .duration(timer_value),
        .done(timer_done)
    );

endmodule