--Initialize
VFF_Smoke = GetSelf()
VFF_Sensor = get_base_data()

update_rate = 0.05
make_default_activity(update_rate)

--Set binding values
local SMOKE_ON = 5000
local SMOKE_OFF = 5001
local SMOKE_TOGGLE = 5002
local SMOKE_ARM = 5003

--Pylon station (Station - 1)
local SmokeStation = 11

--Listen for binding press
VFF_Smoke:listen_command(SMOKE_ON)
VFF_Smoke:listen_command(SMOKE_OFF)
VFF_Smoke:listen_command(SMOKE_TOGGLE)
VFF_Smoke:listen_command(SMOKE_ARM)

--Set inital aircraft state
function post_initialize()
    --Key States
    ARM_KEY = false
    SMOKE_KEY = false

    --Smoke State
    smkState = false
    smkBurnerState = false
    jetPower = false
    aircraftBurnerState = false
    armState = false
end

--Check for updates at update rate
function update()
    UpdateArmState()
    UpdateSmokeState()
end

function SetCommand(Command, Value)
    if Command == SMOKE_TOGGLE then
        SMOKE_KEY = not SMOKE_KEY
    end

    if Command == SMOKE_ON then
        SMOKE_KEY = true
    end
    
    if Command == SMOKE_OFF then
        SMOKE_KEY = false
    end

    if Command == SMOKE_ARM then
        ARM_KEY = not ARM_KEY
    end
end

--Smoke Arm Logic--
function UpdateArmState()
    --Make sure jet has power and set state accordingly
    if get_cockpit_draw_argument_value(95) > 0.33  and jetPower == false then
        jetPower = true
    elseif get_cockpit_draw_argument_value(95) < 0.33 and jetPower == true then
        jetPower = false
    end

    --Arm Smoke if jet has power
    if ARM_KEY == true and jetPower == true and armState == false then
        armState = true
        print_message_to_user("Smoke is armed.")
    elseif ARM_KEY == false and armState == true then
        armState = false
        print_message_to_user("Smoke is unarmed")
    elseif ARM_KEY == true and jetPower == false then
        armState = false
        ARM_KEY = false
        print_message_to_user("No power to jet.")
    end
end

--Smoke Logic--
function UpdateSmokeState()
    --Is aircraft in burner
    if get_cockpit_draw_argument_value(95) > 0.87 and get_cockpit_draw_argument_value(94) > 0.115 then
        aircraftBurnerState = true
    else
        aircraftBurnerState = false
    end

    --Fire smoke
    if SMOKE_KEY == true and armState == true and smkState == false and aircraftBurnerState == false and smkBurnerState == false then -- turn on in normal operation
        smkState = true
        VFF_Smoke:launch_station(SmokeStation)
        print_message_to_user("Smoke on")
    elseif SMOKE_KEY == false and armState == true and smkState == true and aircraftBurnerState == false and smkBurnerState == false then -- turn off in normal operation
        smkState = false
        VFF_Smoke:launch_station(SmokeStation)
        print_message_to_user("Smoke off")
    elseif smkState == true and armState == false and aircraftBurnerState == false and smkBurnerState == false then --smoke unarmed while smoke on
        smkState = false
        SMOKE_KEY = false
        VFF_Smoke:launch_station(SmokeStation)
    elseif smkState == true and aircraftBurnerState == true and smkBurnerState == false then --smoke off with burner
        smkBurnerState = true
        VFF_Smoke:launch_station(SmokeStation)
    elseif smkState == true and aircraftBurnerState == false and smkBurnerState == true then --turn smoke back on after burner
        smkBurnerState = false
        VFF_Smoke:launch_station(SmokeStation)
    elseif smkState == true and aircraftBurnerState == true and smkBurnerState == true and SMOKE_KEY == false then --shut smoke off while burner is on
        smkState = false
        smkBurnerState = false
        print_message_to_user('Smoke off')
    elseif smkState == true and armState == false and aircraftBurnerState == true and smkBurnerState == true then --smoke unarmed while smoke on
        smkState = false
        SMOKE_KEY = false
        smkBurnerState = false
    end
end