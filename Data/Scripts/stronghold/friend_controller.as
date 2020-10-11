#include "stronghold/common.as"

funcdef void CLOSE_FRIEND_CALLBACK(MovementObject@);

class FriendController {
    FriendController(){}

    void Execute(float _radius, CLOSE_FRIEND_CALLBACK @_callback){
        int player_id = FindPlayerID();
        array<int> close_friends = FindCloseFriends(player_id, _radius);
        for(uint i = 0; i < close_friends.length(); ++i){
            MovementObject@ _char = ReadCharacterID(close_friends[i]);
            _callback(_char);
        }
    }

    private array<int> FindCloseFriends(int _player_id, float _radius){
        MovementObject@ player_char = ReadCharacterID(_player_id);
        string player_team = GetTeam(_player_id);
        array<int> close_friends;

        int num = GetNumCharacters();
        for(int i = 0; i < num; ++i){
            MovementObject@ char = ReadCharacter(i);
            string char_team = GetTeam(char.GetID());

            bool is_player = char.GetID() == _player_id;
            bool is_same_team = player_team == char_team;

            if(is_player || !is_same_team){
                continue;
            }

            if(distance(player_char.position, char.position) < _radius){
                close_friends.insertLast(char.GetID());
            }
        }

        return close_friends;
    }
    
    private string GetTeam(int char_id){
        Object @_obj = ReadObjectFromID(char_id);
        ScriptParams @_params = _obj.GetScriptParams();
        return _params.GetString("Teams");
    }
}
