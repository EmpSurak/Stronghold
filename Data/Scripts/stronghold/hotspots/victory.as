#include "stronghold/constants.as"
#include "stronghold/common.as"

bool has_triggered = false;

void Init(){}

void SetParameters(){
}

void HandleEvent(string event, MovementObject @mo){
    if(has_triggered || !ReadObjectFromID(hotspot.GetID()).GetEnabled()){
        return;
    }

    if(!mo.controlled){
        return;
    }

    if(event == "exit"){
        level.SendMessage("cleartext");
        return;
    }

    if(event != "enter"){
        return;
    }

    if(EnemiesNearby(mo)){
        level.SendMessage("displaytext \"There are enemies nearby.\"");
    }else{
        SetTriumphant(true);
        has_triggered = true;
    }
}

void Update(){}

void Reset(){
    has_triggered = false;
}

bool EnemiesNearby(MovementObject @_player){
    Object@ player_obj = ReadObjectFromID(_player.GetID());
    ScriptParams @player_params = player_obj.GetScriptParams(); 

    uint num_chars = GetNumCharacters();
    for(uint i = 0; i < num_chars; ++i){
        MovementObject@ char = ReadCharacter(i);

        if(char.GetID() == _player.GetID()){
            continue;
        }

        bool far_away = distance(_player.position, char.position) > _win_radius;
        if(far_away){
            continue;
        }

        Object@ char_obj = ReadObjectFromID(char.GetID());
        ScriptParams @char_params = char_obj.GetScriptParams();
        if(char_params.GetString("Teams") != player_params.GetString("Teams")){
            return true;
        }
    }

    return false;
}
