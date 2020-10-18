#include "timed_execution/timed_execution.as"
#include "timed_execution/after_init_job.as"
#include "timed_execution/after_char_init_job.as"
#include "timed_execution/repeating_dynamic_delayed_job.as"
#include "timed_execution/level_event_job.as"
#include "stronghold/timed_execution/delayed_death_job.as"
#include "stronghold/timed_execution/nav_destination_job.as"
#include "stronghold/constants.as"
#include "stronghold/common.as"
#include "stronghold/command_job_storage.as"

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

    timer.Add(LevelEventJob("spawner_start", function(_params){
        Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
        if(_params.length() < 2 || _params[1] != hotspot_obj.GetName()){
            return true;
        }

        timer.Add(RepeatingDynamicDelayedJob(GetRandDelay(), function(){
            int soldier_id = CreateSoldier();
            timer.Add(AfterCharInitJob(soldier_id, function(_char){
                RegisterCleanUpJob(_char);
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

int CreateSoldier(){
    array<string> soldier_prefabs = {
        "Data/Objects/stronghold/prefabs/characters/soldier_1.xml",
        "Data/Objects/stronghold/prefabs/characters/soldier_2.xml",
        "Data/Objects/stronghold/prefabs/characters/soldier_3.xml",
        "Data/Objects/stronghold/prefabs/characters/soldier_4.xml"
    };
    string soldier_file = soldier_prefabs[rand()%soldier_prefabs.length()];

    int soldier_id = CreateObject(soldier_file, true);
    MoveToHotspot(soldier_id);

    // TODO: spawn random weapon

    return soldier_id; 
}

void MoveToHotspot(int _id){
    Object@ obj = ReadObjectFromID(_id);
    Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
    obj.SetTranslation(hotspot_obj.GetTranslation());
}

void RegisterCleanUpJob(MovementObject@ _char){
    timer.Add(DelayedDeathJob(5.0f, _char.GetID(), function(_char){
        int emitter_id = CreateObject("Data/Objects/Hotspots/emitter.xml", true);
        Object@ emitter_obj = ReadObjectFromID(emitter_id);
        emitter_obj.SetTranslation(_char.position);
        emitter_obj.SetScale(0.1f);
        ScriptParams@ emitter_params = emitter_obj.GetScriptParams();
        emitter_params.SetString("Type", "Smoke");

        Object@ char_obj = ReadObjectFromID(_char.GetID());
        ScriptParams@ char_params = char_obj.GetScriptParams();
        char_params.AddInt(_smoke_emitter_key, emitter_id);
    }));

    timer.Add(DelayedDeathJob(10.0f, _char.GetID(), function(_char){
        Object@ char_obj = ReadObjectFromID(_char.GetID());
        ScriptParams@ char_params = char_obj.GetScriptParams();
        int emitter_id = char_params.GetInt(_smoke_emitter_key);
        DeleteObjectID(_char.GetID());
        DeleteObjectID(emitter_id);
    }));
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
