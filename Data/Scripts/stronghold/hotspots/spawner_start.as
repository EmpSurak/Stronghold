const string _event_name = "spawner_start";
const string _name_key = "Spawn Name";
const string _default_name = "";

void Init(){}

void SetParameters(){
    params.AddString(_name_key, _default_name);
}

void HandleEvent(string event, MovementObject @mo){
    if(!params.HasParam(_name_key)){
        return;
    }

    if(event == "enter" && mo.controlled){
        level.SendMessage(_event_name + " " + params.GetString(_name_key));
    }
}

void Update(){}
