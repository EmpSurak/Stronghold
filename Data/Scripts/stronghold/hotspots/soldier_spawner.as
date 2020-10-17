#include "timed_execution/timed_execution.as"
#include "timed_execution/after_init_job.as"
#include "timed_execution/after_char_init_job.as"
#include "timed_execution/repeating_dynamic_delayed_job.as"
#include "timed_execution/level_event_job.as"
#include "stronghold/timed_execution/delayed_death_job.as"
#include "stronghold/timed_execution/nav_destination_job.as"
#include "stronghold/constants.as"
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

    timer.Add(LevelEventJob("reset", function(_params){
        timer.DeleteAll();
        Init();
        return false;
    }));

    timer.Add(LevelEventJob("spawner_control", function(_params){
        if(_params.length() < 5 || !params.HasParam(_params[1]) || params.GetString(_params[1]) != _params[2]){
            return true;
        }

        if(_params[3] == "max_char_count"){
            max_char_count = atoi(_params[4]);
        }else if(_params[3] == "difficulty"){
            difficulty = atof(_params[4]);
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
    int soldier_id = CreateObject("Data/Objects/stronghold/prefabs/characters/soldier_1.xml", true);
    Object@ soldier_obj = ReadObjectFromID(soldier_id);
    Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
    soldier_obj.SetTranslation(hotspot_obj.GetTranslation());
    return soldier_id; 
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

int FindFirstObjectByName(string _name){
    if(_name == ""){
        return -1;
    }

    array<int> objects = GetObjectIDs();
    for(uint i = 0; i < objects.length(); i++){
        Object@ obj = ReadObjectFromID(objects[i]);
        if(obj.GetName() == _name){
            return obj.GetID();
        }
    }

    return -1;
}

// based on (but modified) arena_level.as

void ApplySettings(MovementObject@ _char, int fur_channel = 1){
    Object@ char_obj = ReadObjectFromID(_char.GetID());

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
    params.SetFloat("Damage Resistance", mix(RangedRandomFloat(0.6f,0.8f), RangedRandomFloat(0.9f, 1.1f), difficulty));
    params.SetInt("Left handed", (rand()%5 == 0) ? 1 : 0);
    char_obj.UpdateScriptParams();
}

vec3 GetRandomFurColor(){
    vec3 fur_color_byte;
    int rnd = rand()%6;
    switch(rnd){
        case 0: fur_color_byte = vec3(255); break;
        case 1: fur_color_byte = vec3(34); break;
        case 2: fur_color_byte = vec3(137); break;
        case 3: fur_color_byte = vec3(105, 73, 54); break;
        case 4: fur_color_byte = vec3(53, 28, 10); break;
        case 5: fur_color_byte = vec3(172, 124, 62); break;
    }
    return FloatTintFromByte(fur_color_byte);
}

vec3 ColorFromTeam(int which_team){
    switch(which_team){
        case 0: return vec3(1, 0, 0);
        case 1: return vec3(0, 0, 1);
        case 2: return vec3(0, 0.5f, 0.5f);
        case 3: return vec3(1, 1, 0);
    }
    return vec3(1, 1, 1);
}

vec3 FloatTintFromByte(const vec3 &in tint){
    vec3 float_tint;
    float_tint.x = tint.x / 255.0f;
    float_tint.y = tint.y / 255.0f;
    float_tint.z = tint.z / 255.0f;
    return float_tint;
}

vec3 RandReasonableColor(){
    vec3 color;
    color.x = rand()%255;
    color.y = rand()%255;
    color.z = rand()%255;
    float avg = (color.x + color.y + color.z) / 3.0f;
    color = mix(color, vec3(avg), 0.7f);
    return color;
}
