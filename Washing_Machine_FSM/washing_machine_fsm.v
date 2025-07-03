module washing_machine_fsm (
    input clk,
    input reset,
    input start_pause,
    input [1:0] mode_select,
    input door_sensor,
    input timer_done,
    output reg water_valve,
    output reg drain_valve,
    output reg motor,
    output reg [1:0] motor_dir,
    output reg [3:0] leds,
    output reg [31:0] timer_value,
    output reg timer_start
);

//state definitions
parameter IDLE       = 3'b000;
parameter FILL_WATER = 3'b001;
parameter WASH       = 3'b010;
parameter RINSE      = 3'b011;
parameter SPIN       = 3'b100;
parameter PAUSE      = 3'b101;
parameter COMPLETE   = 3'b110;
parameter ERROR      = 3'b111;

reg [3:0] current_state, next_state;

//mode definitions
parameter NORMAL     = 2'b00;
parameter DELICATE   = 2'b01;
parameter HEAVY      = 2'b10;
parameter RINSE_ONLY = 2'b11;

//timing parameters
parameter FILL_TIME  = 5000000;    // ~5 seconds for simulation
parameter WASH_TIME  = 15000000;   // ~15 seconds
parameter RINSE_TIME = 10000000;   // ~10 seconds
parameter SPIN_TIME  = 8000000;    // ~8 seconds

reg [1:0] current_mode;
reg is_running;
reg is_paused;
reg door_closed;

//state transition logic
always @(posedge clk or posedge reset) begin
    if(reset) begin
    current_state <=IDLE;
    is_running <=0;
    is_paused <=0;
    timer_start <= 0;
    end 
    else begin
       door_closed<= door_sensor;
       current_state <= next_state;

       if(timer_start) begin
        timer_start <= 0; // Reset timer start after each cycle
       end
    end 
end

//next state logics
always @(*) begin
    next_state = current_state;
    timer_start = 0;
    timer_value = 0;

    case(current_state)
        IDLE: begin
            if (start_pause && door_closed && !is_running) begin
                next_state = FILL_WATER;
                is_running = 1;
                current_mode = mode_select;
                timer_value = FILL_TIME;
                timer_start = 1;   
            end
        end

        FILL_WATER: begin
            if(!door_closed) begin
                next_state = ERROR;
            end
            else if(timer_done) begin
                if(current_mode == RINSE_ONLY) begin
                    next_state = RINSE;
                    timer_value = RINSE_TIME;
                end
                else begin
                    next_state = WASH;
                    timer_value = (current_mode == DELICATE) ? WASH_TIME / 2 : (current_mode == HEAVY) ? WASH_TIME * 2 : WASH_TIME;
                end
                timer_start = 1;    
            end
        end

        WASH: begin
            if(!door_closed) begin
                next_state = ERROR;
            end
            else if(timer_done) begin
                next_state = RINSE;
                timer_value = RINSE_TIME;
                timer_start = 1;
            end
        end

        RINSE: begin
            if(!door_closed) begin
            next_state = ERROR;
            end
            else if(timer_done) begin
                next_state = SPIN;
                timer_value = SPIN_TIME;
                timer_start = 1;
            end
        end

        SPIN: begin
            if (!door_closed) begin
               next_state = ERROR;
            end
            else if (timer_done) begin
               next_state = COMPLETE;
               timer_value = 0; // optional, can be set again in COMPLETE if needed
               timer_start = 0;
            end
        end


        PAUSE: begin
            if(start_pause && door_closed) begin
                next_state = current_state;
                is_paused = 0;
                timer_start = 0; 
            end  
        end

        COMPLETE: begin
            if(start_pause) begin
                next_state = IDLE;
                is_running = 0;
            end
        end

        ERROR: begin
            if(door_closed && start_pause) begin
                next_state = IDLE;
                is_running = 0;
            end
        end

        default: next_state = IDLE; // Default case to handle unexpected states
    endcase

    //handle pause button
    if(start_pause && is_running && door_closed && current_state != PAUSE) begin
        next_state = PAUSE;
        is_paused = 1;
    end
end


//output logic
always @(posedge clk) begin
    water_valve <=0;
    drain_valve <=0;
    motor <=0;
    motor_dir <= 2'b00;
    leds <= 4'b0000;

    case (current_state)
        IDLE: begin
                leds <= 4'b0001;
            end
            
            FILL_WATER: begin
                water_valve <= 1;
                leds <= 4'b0010;
            end
            
            WASH: begin
                motor <= 1;
                // Alternate motor direction
                motor_dir <= (timer_value[20]) ? 2'b01 : 2'b10;
                leds <= 4'b0100;
            end
            
            RINSE: begin
                water_valve <= 1;
                motor <= 1;
                motor_dir <= (timer_value[20]) ? 2'b01 : 2'b10;
                leds <= 4'b1000;
            end
            
            SPIN: begin
                drain_valve <= 1;
                motor <= 1;
                motor_dir <= 2'b01; // Only clockwise for spin
                leds <= 4'b0011;
            end
            
            PAUSE: begin
                leds <= 4'b1010;
            end
            
            COMPLETE: begin
                leds <= 4'b1111;
            end
            
            ERROR: begin
                leds <= 4'b1001;

            end
    endcase
end

endmodule