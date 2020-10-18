#include "stronghold/common.as"

const string _event_name = "spawner_control";
const string _name_key = "Spawn Name (Prefix)";
const string _name_default = "";
const string _team_key = "Team Only";
const string _team_default = "";
const string _player_key = "Player Only";
const bool _player_default = true;
const string _variable_key = "Variable";
const string _variable_default = "max_char_count";
const string _value_key = "Value";
const string _value_default = "5";

void Init(){}

void SetParameters(){
    params.AddString(_name_key, _name_default);
    params.AddString(_team_key, _team_default);
    params.AddIntCheckbox(_player_key, _player_default);
    params.AddString(_variable_key, _variable_default);
    params.AddString(_value_key, _value_default);
}

void HandleEvent(string event, MovementObject @mo){
    if(!params.HasParam(_name_key) || params.GetString(_name_key) == ""){
        return;
    }

    if(!params.HasParam(_variable_key) || params.GetString(_variable_key) == ""){
        return;
    }

    if(!params.HasParam(_value_key) || params.GetString(_value_key) == ""){
        return;
    }

    if(event != "enter"){
        return;
    }

    if(params.HasParam(_player_key) && params.GetInt(_player_key) == 1 && !mo.controlled){
        return;
    }

    if(params.HasParam(_team_key) && params.GetString(_team_key) != ""){
        Object@ obj = ReadObjectFromID(mo.GetID());
        ScriptParams@ obj_params = obj.GetScriptParams();
        if(!obj_params.HasParam("Teams") || params.GetString(_team_key) != obj_params.GetString("Teams")){
            return;
        }
    }

    array<string> target_hotspots = FindHotspotsByPrefix(params.GetString(_name_key));
    for(uint i = 0; i < target_hotspots.length(); i++){
        level.SendMessage(_event_name + " " + target_hotspots[i] + " " + params.GetString(_variable_key) + " " + params.GetString(_value_key));
    }
}

void Update(){}
