#include "timed_execution/timed_execution.as"
#include "timed_execution/after_init_job.as"
#include "timed_execution/after_char_init_job.as"
#include "timed_execution/char_damage_job.as"
#include "timed_execution/repeating_dynamic_delayed_job.as"
#include "timed_execution/level_event_job.as"
#include "stronghold/timed_execution/nav_destination_job.as"
#include "stronghold/timed_execution/flag_bearer_job.as"
#include "stronghold/timed_execution/flag_bearer_effect_job.as"
#include "stronghold/timed_execution/light_up_job.as"
#include "stronghold/constants.as"
#include "stronghold/common.as"
#include "stronghold/command_job_storage.as"

const string _unit_type_key = "Unit Type";
const string _unit_type_default = "";
const string _unit_type_raider = "raider";
const string _unit_type_soldier = "soldier";
const string _unit_type_tank = "tank";
const string _unit_type_giant = "giant";
const string _unit_type_bomber = "bomber";
const string _unit_type_flag_bearer = "flag_bearer";
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
const string _goal_attack = "attack";
const string _goal_default = _goal_none;
const string _escort_name_key = "Escort (Name)";
const string _escort_name_default = "";
const string _go_to_name_key = "Go to (Name)";
const string _go_to_name_default = "";
const string _fur_channel_key = "Fur Channel";

TimedExecution timer;
CommandJobStorage command_job_storage;
int char_count, max_char_count, team_color, last_triggered_by, player_id;
float min_spawn_delay, max_spawn_delay, difficulty;
string team, goal, escort_name, go_to_name;
UnitType type;

void Init(){
    level.ReceiveLevelEvents(hotspot.GetID());
    InitJobs();
}

void InitJobs(){
    char_count = 0;
    last_triggered_by = -1;
    player_id = -1;
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

    timer.Add(AfterInitJob(function(){
        player_id = FindPlayerID();
    }));

    timer.Add(LevelEventJob("spawner_start", function(_params){
        Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
        if(_params.length() < 2 || _params[1] != hotspot_obj.GetName()){
            return true;
        }
        last_triggered_by = atoi(_params[2]);

        timer.Add(RepeatingDynamicDelayedJob(GetRandDelay(), function(){
            int soldier_id = CreateUnit(type);
            timer.Add(AfterCharInitJob(soldier_id, function(_char){
                RegisterCharCleanUpJob(timer, _char);
                RegisterGoal(_char);
                ApplySettings(_char);
            }));
            char_count++;

            if(char_count >= max_char_count){
                // For performance reasons the hotspot is disabled when it is finished.
                ReadObjectFromID(hotspot.GetID()).SetEnabled(false);
                return 0.0f;
            }

            return GetRandDelay();
        }));

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

    // For performance reasons the hotspot is disabled by default.
    // The spawner_start hotspots enables this hotspot automatically.
    ReadObjectFromID(hotspot.GetID()).SetEnabled(false);
}

float GetRandDelay(){
    return RangedRandomFloat(min_spawn_delay, max_spawn_delay);
}

void Dispose(){
    level.StopReceivingLevelEvents(hotspot.GetID());
}

void Reset(){
    timer.DeleteAll();
    InitJobs();
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
                "Data/Objects/stronghold/prefabs/characters/soldier_4.xml",
                "Data/Objects/stronghold/prefabs/characters/soldier_5.xml",
                "Data/Objects/stronghold/prefabs/characters/soldier_6.xml"
            };
            break;
        }
        case _tank: {
            possible_files = {
                "Data/Objects/stronghold/prefabs/characters/tank_1.xml",
                "Data/Objects/stronghold/prefabs/characters/tank_2.xml",
                "Data/Objects/stronghold/prefabs/characters/tank_3.xml",
                "Data/Objects/stronghold/prefabs/characters/tank_4.xml",
                "Data/Objects/stronghold/prefabs/characters/tank_5.xml",
                "Data/Objects/stronghold/prefabs/characters/tank_6.xml"
            };
            break;
        }
        case _giant: {
            possible_files = {
                "Data/Objects/stronghold/prefabs/characters/giant_1.xml",
                "Data/Objects/stronghold/prefabs/characters/giant_2.xml",
                "Data/Objects/stronghold/prefabs/characters/giant_3.xml"
            };
            break;
        }
        case _bomber: {
            possible_files = {
                "Data/Objects/stronghold/prefabs/characters/bomber_1.xml",
                "Data/Objects/stronghold/prefabs/characters/bomber_2.xml",
                "Data/Objects/stronghold/prefabs/characters/bomber_3.xml",
                "Data/Objects/stronghold/prefabs/characters/bomber_4.xml",
                "Data/Objects/stronghold/prefabs/characters/bomber_5.xml",
                "Data/Objects/stronghold/prefabs/characters/bomber_6.xml"
            };
            break;
        }
        case _flag_bearer: {
            possible_files = {
                "Data/Objects/stronghold/prefabs/characters/flag_bearer_1.xml",
                "Data/Objects/stronghold/prefabs/characters/flag_bearer_2.xml",
                "Data/Objects/stronghold/prefabs/characters/flag_bearer_3.xml"
            };
            break;
        }
        case _raider: {
            possible_files = {
                "Data/Objects/stronghold/prefabs/characters/raider_1.xml",
                "Data/Objects/stronghold/prefabs/characters/raider_2.xml",
                "Data/Objects/stronghold/prefabs/characters/raider_3.xml",
                "Data/Objects/stronghold/prefabs/characters/raider_4.xml",
                "Data/Objects/stronghold/prefabs/characters/raider_5.xml",
                "Data/Objects/stronghold/prefabs/characters/raider_6.xml"
            };
            break;
        }
    }
    string random_file = possible_files[rand()%possible_files.length()];

    int unit_id = CreateObject(random_file, true);
    MoveToHotspot(unit_id);

    CreateAndAttachWeapon(_type, unit_id);

    if(_type == _bomber){
        AddBomberJob(unit_id);
    }else if(_type == _flag_bearer){
        AddFlagBearerJob(unit_id);
    }

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
        case _raider: {
            if(rand()%10 > 8){
                break;
            }
            possible_files = {
                "Data/Items/rabbit_weapons/rabbit_knife.xml",
                "Data/Items/DogWeapons/DogKnife.xml",
                "Data/Items/staffbasic.xml"
            };
            break;
        }
    }
    if(possible_files.length() == 0){
        // Not every unit type has a weapon.
        return;
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
    }else if(goal == _goal_attack){
        _char.Execute("attack_player_id = " + last_triggered_by + ";");
        _char.Execute("Notice(" + last_triggered_by + ");");
        _char.Execute("SetGoal(_attack);");
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
    }else if(_input == _unit_type_bomber){
        return _bomber;
    }else if(_input == _unit_type_flag_bearer){
        return _flag_bearer;
    }else if(_input == _unit_type_raider){
        return _raider;
    }
    return _no_type;
}

void AddBomberJob(int _char_id){
    timer.Add(CharDamageJob(_char_id, function(_char, _p_blood, _p_permanent){
        // Explosion effect inspired by Gyrth' rocket mod.
        float radius = 15.0f;
        float critical_radius = 5.0f;

        array<int> nearby_characters;
        GetCharactersInSphere(_char.position, radius, nearby_characters);

        for(uint i = 0; i < nearby_characters.length(); i++){
            MovementObject@ nearby_char = ReadCharacterID(nearby_characters[i]);

            if(nearby_char.GetIntVar("updated") < 1){
                continue;
            }

            vec3 explode_direction = normalize(nearby_char.position - _char.position);
            float center_distance = distance(_char.position, nearby_char.position);
            float distance_alpha = 1.0f - (center_distance / radius);

            if(nearby_char.GetBoolVar("invincible")){
                if(nearby_char.controlled){
                    nearby_char.Execute("camera_shake += 2.0f;");
                }
                continue;
            }

            if(nearby_char.controlled){
                nearby_char.Execute("camera_shake += 10.0f;");
            }

            if(center_distance < critical_radius){
                nearby_char.Execute("ko_shield = 0;");
                nearby_char.Execute("SetOnFire(true);");
            }

            nearby_char.Execute("GoLimp(); TakeDamage(" + 2.0f * distance_alpha + ");");
            nearby_char.rigged_object().ApplyForceToRagdoll(
                explode_direction * 40000 * distance_alpha,
                nearby_char.rigged_object().skeleton().GetCenterOfMass()
            );
        }

        for(uint i = 0; i < 50; i++){
            MakeParticle(
                "Data/Particles/stronghold/explosion_sparks.xml",
                _char.position,
                vec3(
                    RangedRandomFloat(-10.0f, 10.0f),
                    RangedRandomFloat(-10.0f, 10.0f),
                    RangedRandomFloat(-10.0f, 10.0f)
                )
            );
        }

        for(uint i = 0; i < 3; i++){
            MakeParticle(
                "Data/Particles/stronghold/explosion_smoke.xml",
                _char.position,
                vec3(-2.0f)
            );
        }

        int explosion_number = rand()%3+1;
        string explosion_sound = "Data/Sounds/explosives/explosion" + explosion_number + ".wav";
        PlaySound(explosion_sound, _char.position);

        return false;
    }));
}

void AddFlagBearerJob(int _char_id){
    timer.Add(FlagBearerJob(2.0f, _char_id, function(_job, _char){
        timer.Add(LightUpJob(0.05f, 10.0f, _char.GetID(), function(_char, _light, _return_value){
            _light.SetTranslation(_char.position + vec3(0.0f, 2.5f, 0.0f));
            _light.SetTint(vec3(10.0f, _return_value, _return_value));
            return _return_value - 1.0f;
        }));

        float radius = 20.0f;
        string char_team = GetTeam(_char.GetID());

        array<int> nearby_characters;
        GetCharactersInSphere(_char.position, radius, nearby_characters);

        for(uint i = 0; i < nearby_characters.length(); i++){
            MovementObject@ _nearby_char = ReadCharacterID(nearby_characters[i]);
            bool is_flag_bearer = nearby_characters[i] == _char.GetID();
            bool is_dead = _char.GetIntVar("knocked_out") != _awake || _nearby_char.GetIntVar("knocked_out") != _awake;
            bool is_same_team = char_team == GetTeam(nearby_characters[i]);
            bool has_running_job = _nearby_char.GetBoolVar("invincible"); // FIXME: should be more generic
            if(is_flag_bearer || is_dead || !is_same_team || has_running_job){
                continue;
            }

            timer.Add(FlagBearerEffectJob(5.0f, _char.GetID(), nearby_characters[i], function(_char){
                _char.Execute("invincible = true;");

                for(uint i = 0; i < 3; i++){
                    MakeParticle(
                        "Data/Particles/stronghold/flag_smoke.xml",
                        _char.position,
                        vec3(-1.0f)
                    );
                }
            }, function(_char){
                _char.Execute("invincible = false;");
            }));
        }
    }));
}
