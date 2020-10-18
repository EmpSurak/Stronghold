#include "timed_execution/timed_execution.as"
#include "timed_execution/after_init_job.as"
#include "timed_execution/after_char_init_job.as"
#include "timed_execution/repeating_dynamic_delayed_job.as"
#include "timed_execution/level_event_job.as"
#include "stronghold/timed_execution/nav_destination_job.as"
#include "stronghold/constants.as"
#include "stronghold/common.as"
#include "stronghold/command_job_storage.as"

const string _unit_type_key = "Unit Type";
const string _unit_type_default = "";
const string _unit_type_soldier = "soldier";
const string _unit_type_tank = "tank";
const string _unit_type_giant = "giant";
const string _char_count_key = "Number of Characters";
const int _char_count_default = 5;
const string _team_key = "Team";
const string _team_default = "Nobody";
const string _team_color_key = "Team Color";
const int _team_color_default = 1;
const string _min_spawn_delay_key = "Min. Spawn Delay";
const float _min_spawn_delay_default = 0.5f;
const string _max_spawn_delay_key = "Max. Spawn Delay";
const float _max_spawn_delay_default = 5.0f;
const string _difficulty_key = "Difficulty";
const float _difficulty_default = 0.5f;
const string _goal_key = "Goal";
const string _goal_none = "none";
const string _goal_follow = "follow";
const string _goal_go_to = "go_to";
const string _goal_default = _goal_none;
const string _escort_name_key = "Escort (Name)";
const string _escort_name_default = "";
const string _go_to_name_key = "Go to (Name)";
const string _go_to_name_default = "";
const string _fur_channel_key = "Fur Channel";

TimedExecution timer;
CommandJobStorage command_job_storage;
int char_count, max_char_count, team_color;
float min_spawn_delay, max_spawn_delay, difficulty;
string team, goal, escort_name, go_to_name;
UnitType type;

void Init(){
    level.ReceiveLevelEvents(hotspot.GetID());
    char_count = 0;
    max_char_count = params.HasParam(_char_count_key) ? params.GetInt(_char_count_key) : _char_count_default;
    team_color = params.HasParam(_team_color_key) ? params.GetInt(_team_color_key) : _team_color_default;
    min_spawn_delay = params.HasParam(_min_spawn_delay_key) ? params.GetFloat(_min_spawn_delay_key) : _min_spawn_delay_default;
    max_spawn_delay = params.HasParam(_max_spawn_delay_key) ? params.GetFloat(_max_spawn_delay_key) : _max_spawn_delay_default;
    difficulty = params.HasParam(_difficulty_key) ? params.GetFloat(_difficulty_key) : _difficulty_default;
    team = params.HasParam(_team_key) ? params.GetString(_team_key) : _team_default;
    goal = params.HasParam(_goal_key) ? params.GetString(_goal_key) : _goal_default;
    escort_name = params.HasParam(_escort_name_key) ? params.GetString(_escort_name_key) : _escort_name_default;
    go_to_name = params.HasParam(_go_to_name_key) ? params.GetString(_go_to_name_key) : _go_to_name_default;
    type = UnitTypeFromString(params.HasParam(_unit_type_key) ? params.GetString(_unit_type_key) : _unit_type_default);

    timer.Add(LevelEventJob("spawner_start", function(_params){
        Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
        if(_params.length() < 2 || _params[1] != hotspot_obj.GetName()){
            return true;
        }

        timer.Add(RepeatingDynamicDelayedJob(GetRandDelay(), function(){
            int soldier_id = CreateUnit(type);
            timer.Add(AfterCharInitJob(soldier_id, function(_char){
                RegisterCharCleanUpJob(timer, _char);
                RegisterGoal(_char);
                ApplySettings(_char);
            }));
            char_count++;

            if(char_count >= max_char_count){
                return 0.0f;
            }

            return GetRandDelay();
        }));

        return false;
    }));

    timer.Add(LevelEventJob("spawner_reset", function(_params){
        Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
        if(_params.length() < 2 || _params[1] != hotspot_obj.GetName()){
            return true;
        }

        Reset();
        return false;
    }));

    timer.Add(LevelEventJob("reset", function(_params){
        Reset();
        return false;
    }));

    timer.Add(LevelEventJob("spawner_control", function(_params){
        Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
        if(_params.length() < 4 || _params[1] != hotspot_obj.GetName()){
            return true;
        }

        if(_params[2] == "max_char_count"){
            max_char_count = atoi(_params[3]);
        }else if(_params[2] == "difficulty"){
            difficulty = atof(_params[3]);
        }

        return true;
    }));
}

float GetRandDelay(){
    return RangedRandomFloat(min_spawn_delay, max_spawn_delay);
}

void Dispose(){
    level.StopReceivingLevelEvents(hotspot.GetID());
}

void Reset(){
    timer.DeleteAll();
    Init();
}

void SetParameters(){
    params.AddString(_unit_type_key, _unit_type_default);
    params.AddInt(_char_count_key, _char_count_default);
    params.AddInt(_team_color_key, _team_color_default);
    params.AddString(_team_key, _team_default);
    params.AddFloat(_min_spawn_delay_key, _min_spawn_delay_default);
    params.AddFloat(_max_spawn_delay_key, _max_spawn_delay_default);
    params.AddFloat(_difficulty_key, _difficulty_default);
    params.AddString(_goal_key, _goal_default);
    params.AddString(_escort_name_key, _escort_name_default);
    params.AddString(_go_to_name_key, _go_to_name_default);
}

void HandleEvent(string event, MovementObject @mo){}

void Update(){
    timer.Update();
}

void ReceiveMessage(string msg){
    timer.AddEvent(msg);
}

int CreateUnit(UnitType _type){
    array<string> possible_files;
    switch(_type){
        case _soldier: {
            possible_files = {
                "Data/Objects/stronghold/prefabs/characters/soldier_1.xml",
                "Data/Objects/stronghold/prefabs/characters/soldier_2.xml",
                "Data/Objects/stronghold/prefabs/characters/soldier_3.xml",
                "Data/Objects/stronghold/prefabs/characters/soldier_4.xml"
            };
            break;
        }
        case _tank: {
            possible_files = {
                "Data/Objects/stronghold/prefabs/characters/tank_1.xml"
            };
            break;
        }
        case _giant: {
            break;
        }
    }
    string random_file = possible_files[rand()%possible_files.length()];

    int unit_id = CreateObject(random_file, true);
    MoveToHotspot(unit_id);

    CreateAndAttachWeapon(_type, unit_id);

    return unit_id; 
}

void CreateAndAttachWeapon(UnitType _type, int _char_id){
    array<string> possible_files;
    switch(_type){
        case _soldier: {
            possible_files = {
                "Data/Items/DogWeapons/DogSword.xml",
                "Data/Items/DogWeapons/DogSpear.xml",
                "Data/Items/DogWeapons/DogKnife.xml"
            };
            break;
        }
        case _tank: {
            possible_files = {
                "Data/Items/DogWeapons/DogBroadSword.xml",
                "Data/Items/DogWeapons/DogSword.xml"
            };
            break;
        }
        case _giant: {
            break;
        }
    }
    string random_file = possible_files[rand()%possible_files.length()];

    int weapon_id = CreateObject(random_file, true);
    MoveToHotspot(weapon_id);

    Object@ char_obj = ReadObjectFromID(_char_id);
    ScriptParams@ char_params = char_obj.GetScriptParams();
    bool mirrored = char_params.HasParam("Left handed") && char_params.GetInt("Left handed") != 0;

    Object@ weapon_obj = ReadObjectFromID(weapon_id);
    char_obj.AttachItem(weapon_obj, _at_grip, mirrored);
}

void MoveToHotspot(int _id){
    Object@ obj = ReadObjectFromID(_id);
    Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
    obj.SetTranslation(hotspot_obj.GetTranslation());
}

void RegisterGoal(MovementObject@ _char){
    if(goal == _goal_go_to){
        int obj_id = FindFirstObjectByName(go_to_name);
        if(obj_id < 0){
            return;
        }

        Object@ obj = ReadObjectFromID(obj_id);
        vec3 _target = obj.GetTranslation();

        _char.Execute("nav_target.x = " + _target.x + ";");
        _char.Execute("nav_target.y = " + _target.y + ";");
        _char.Execute("nav_target.z = " + _target.z + ";");
        _char.Execute("SetGoal(_navigate);");

        timer.Add(NavDestinationJob(_char.GetID(), _target, command_job_storage, function(_char, _target){
            _char.Execute("ResetMind();");
        }));
    }else if(goal == _goal_follow){
        int escort_id = FindFirstObjectByName(go_to_name);
        if(escort_id < 0){
            return;
        }

        _char.Execute("escort_id = " + escort_id + ";");
        _char.Execute("SetGoal(_escort);");
    }
}

void ApplySettings(MovementObject@ _char){
    Object@ char_obj = ReadObjectFromID(_char.GetID());
    ScriptParams@ char_params = char_obj.GetScriptParams();

    int fur_channel = 1;
    if(char_params.HasParam(_fur_channel_key)){
        fur_channel = char_params.GetInt(_fur_channel_key);
    }

    for(int i = 0; i < 4; ++i){
        vec3 color = FloatTintFromByte(RandReasonableColor());
        float tint_amount = 0.5f;
        color = mix(color, ColorFromTeam(team_color), tint_amount);
        color = mix(color, vec3(1.0-difficulty), 0.5f);
        char_obj.SetPaletteColor(i, color);
    }
    char_obj.SetPaletteColor(fur_channel, GetRandomFurColor());

    ScriptParams@ params = char_obj.GetScriptParams();
    params.SetString("Teams", team);
    params.SetFloat("Ear Size", RangedRandomFloat(0.5f, 1.5f));
    params.SetFloat("Aggression", RangedRandomFloat(0.25f, 0.75f));
    params.SetFloat("Ground Aggression", mix(0.0f, 1.0f, difficulty));
    params.SetFloat("Damage Resistance", mix(RangedRandomFloat(0.6f, 0.8f), RangedRandomFloat(0.9f, 1.1f), difficulty));
    params.SetInt("Left handed", (rand()%5 == 0) ? 1 : 0);
    char_obj.UpdateScriptParams();
}

UnitType UnitTypeFromString(const string _input){
    if(_input == _unit_type_soldier){
        return _soldier;
    }else if(_input == _unit_type_tank){
        return _tank;
    }else if(_input == _unit_type_giant){
        return _giant;
    }
    return _no_type;
}
