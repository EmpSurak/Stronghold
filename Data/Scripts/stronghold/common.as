int FindPlayerID(){
    int num = GetNumCharacters();
    for(int i = 0; i < num; ++i){
        MovementObject@ char = ReadCharacter(i);
        if(char.controlled){
            return char.GetID();
        }
    }
    return -1;
}

MovementObject@ FindPlayer(){
    int player_id = FindPlayerID();
    MovementObject@ player_char = ReadCharacterID(player_id);
    return player_char;
}

array<string> FindHotspotsByNamePrefix(string _prefix){
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

