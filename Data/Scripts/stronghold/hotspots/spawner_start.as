const string _event_name = "spawner_start";
const string _name_key = "Spawn Name (Prefix)";
const string _name_default = "";
const string _team_key = "Team Only";
const string _team_default = "";
const string _player_key = "Player Only";
const bool _player_default = true;

void Init(){}

void SetParameters(){
    params.AddString(_name_key, _name_default);
    params.AddString(_team_key, _team_default);
    params.AddIntCheckbox(_player_key, _player_default);
}

void HandleEvent(string event, MovementObject @mo){
    if(!params.HasParam(_name_key) || params.GetString(_name_key) == ""){
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
        level.SendMessage(_event_name + " " + target_hotspots[i]);
    }
}

void Update(){}

array<string> FindHotspotsByPrefix(string _prefix){
    array<string> target_hotspots;
    
    array<int> all_hotspots = GetObjectIDsType(_hotspot_object);
    for(uint i = 0; i < all_hotspots.length(); i++){
        Object@ current_hotspot = ReadObjectFromID(all_hotspots[i]);
        string current_name = current_hotspot.GetName();
        if(current_name.findFirst(_prefix) == 0){
            target_hotspots.insertLast(current_name);
        }
    }

    return target_hotspots;
}
