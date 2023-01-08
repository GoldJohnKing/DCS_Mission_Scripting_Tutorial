-- Enums

local SIDE = {
    BLUE = coalition.side.BLUE,
    RED = coalition.side.RED,
    NEUTRAL = coalition.side.NEUTRAL,
}

local SIDE_ENEMY = {
    [SIDE.BLUE] = SIDE.RED,
    [SIDE.RED] = SIDE.BLUE,
}

local COUNTRY = {
    [SIDE.BLUE] = country.id.CJTF_BLUE,
    [SIDE.RED] = country.id.CJTF_RED,
}

local ZONE_COLOR = {
    [SIDE.BLUE] = { 0, 0, 0.8 },
    [SIDE.RED] = { 0.8, 0, 0 },
    [SIDE.NEUTRAL] = { 0.8, 0.8, 0.8 },
}

local NAME_PREFIX = {
    [SIDE.BLUE] = "B",
    [SIDE.RED] = "R",
}

-- Public Functions

local function get_random(tb)
    local keys = {}

    for key, vaule in pairs(tb) do
        table.insert(keys, key)
    end

    return tb[keys[math.random(#keys)]]
end

local function message_to_all(_text, _lasts_time)
    if _lasts_time == nil then
        _lasts_time = 90
    end

    MESSAGE:New(_text, _lasts_time):ToAll()
end

message_to_all("Mission.lua Loading", 3) -- Debug

-- Zones

local zones = {
    ["BlueZone-1"] = SIDE.BLUE,
    ["BlueZone-2"] = SIDE.BLUE,
    ["RedZone-1"] = SIDE.RED,
    ["RedZone-2"] = SIDE.RED,
}

local set_zones = {
    [SIDE.BLUE] = SET_ZONE:New(),
    [SIDE.RED] = SET_ZONE:New(),
    [SIDE.NEUTRAL] = SET_ZONE:New(),
}

for key, value in pairs(zones) do
    set_zones[value]:AddZonesByName(key)
end

-- Draw zones and names
for key, value in pairs(set_zones) do
    value:DrawZone(-1, { 1, 1, 1 }, 1, ZONE_COLOR[key], 0.25, 1, false)
end

-- local function draw_zones(_zones)
--     for key, value in pairs(_zones) do
--         ZONE:FindByName(key):DrawZone(-1, { 1, 1, 1 }, 1, ZONE_COLOR[value], 0.25, 1, false)
--     end
-- end

-- draw_zones(zones)

local function draw_zone_names(_zones)
    for key, value in pairs(_zones) do
        local _zone = ZONE:FindByName(key)
        _zone:GetCoordinate():TextToAll(_zone:GetName(), -1, { 0, 0, 0 }, 0.75, nil, 0, 18, true)
    end
end

draw_zone_names(zones)

-- Groups

local group_template = {
    "AH64D",
    "Ka50_3",
    "J11A",
    "F16C",
    "Mi24P",
}

local group_spawn_index = 0

local on_group_spawn = nil

-- Spawn random group
local function group_spawn_random(_side, _spawn_zone, _target_zone)
    if _spawn_zone == nil then
        _spawn_zone = set_zones[_side]:GetRandomZone()
    end

    local _spawn_airbase = _spawn_zone:GetCoordinate():GetClosestAirbase()

    if _target_zone == nil then
        _target_zone = set_zones[SIDE_ENEMY[_side]]:GetRandomZone()
    end

    local _spawn_template = get_random(group_template)

    local _group_name = NAME_PREFIX[_side] .. "-" .. _spawn_template .. "-" ..
        _spawn_zone:GetName() .. "-" .. _target_zone:GetName() .. "-" .. group_spawn_index

    SPAWN:NewWithAlias(_spawn_template, _group_name)
        :InitCoalition(_side)
        :InitCountry(COUNTRY[_side])
        :InitSkill("Excellent")
        :InitHeading(0, 359)
        :OnSpawnGroup(on_group_spawn, _side, _spawn_zone, _target_zone)
        :SpawnAtAirbase(_spawn_airbase, SPAWN.Takeoff.Runway)

    group_spawn_index = group_spawn_index + 1
end

local function group_task_land_at_zone(_group, _landing_zone)
    local _task_land = _group:TaskLandAtZone(_landing_zone, nil, true)
    local _waypoint = _landing_zone:GetCoordinate():WaypointAirTurningPoint()

    _group:SetTaskWaypoint(_waypoint, _task_land)
    _group:Route({ _waypoint }, 1)
end

local function group_task_orbit_at_zone(_group, _target_zone, _altitude, _speed)
    local _task_orbit = _group:TaskOrbitCircleAtVec2(_target_zone:GetRandomVec2(), _altitude, _speed)
    local _waypoint = _target_zone:GetCoordinate():WaypointAirTurningPoint()

    _group:SetTaskWaypoint(_waypoint, _task_orbit)
    _group:Route({ _waypoint }, 1)
end

local function group_options(_group)
    if not _group:IsGround() then
        -- Do not assign this to AA units as it will make them stop moving
        _group:OptionAlarmStateRed()
    end

    if _group:OptionROEHoldFirePossible() then
        _group:OptionROEHoldFire()
    end

    if _group:OptionROTNoReactionPossible() then
        _group:OptionROTNoReaction()
    end
end

-- On group spawn
on_group_spawn = function(_group, _side, _spawn_zone, _target_zone)
    if _group:IsHelicopter() then
        group_task_land_at_zone(_group, _target_zone)
    end

    if _group:IsAirPlane() then
        group_task_orbit_at_zone(_group, _target_zone, 1500, 150)
    end

    group_options(_group)
end

TIMER:New(group_spawn_random, SIDE.BLUE):Start(30, 30, 300)
TIMER:New(group_spawn_random, SIDE.RED):Start(30, 30, 300)

-- End of Groups

message_to_all("Mission.lua Loaded", 3) -- Debug
