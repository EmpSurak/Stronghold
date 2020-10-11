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
