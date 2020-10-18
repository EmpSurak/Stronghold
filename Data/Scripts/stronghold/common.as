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
