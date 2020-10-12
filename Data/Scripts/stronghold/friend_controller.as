#include "timed_execution/timed_execution.as"
#include "stronghold/common.as"

funcdef void CLOSE_FRIEND_CALLBACK(MovementObject@);

const float _min_yell_distance = 2.0f;
const float _max_yell_distance = 50.0f;

class FriendController {
    private TimedExecution@ timer;
    private float yell_distance = 20.0f;

    FriendController(){}

    FriendController(TimedExecution@ _timer){
        @timer = @_timer;
    }

    void Execute(CLOSE_FRIEND_CALLBACK @_callback){
        int player_id = FindPlayerID();
        array<int> close_friends = FindCloseFriends(player_id);
        for(uint i = 0; i < close_friends.length(); ++i){
            MovementObject@ _char = ReadCharacterID(close_friends[i]);
            _callback(_char);
        }
    }

    void NavigateToTarget(MovementObject@ _char, vec3 _target){
        _char.Execute("nav_target.x = " + _target.x + ";");
        _char.Execute("nav_target.y = " + _target.y + ";");
        _char.Execute("nav_target.z = " + _target.z + ";");
        _char.Execute("SetGoal(_navigate);");

        timer.Add(NavDestinationJob(_char.GetID(), _target, function(_char, _target){
            // FIXME: job has to be cleaned up when target gets a new goal before this one is reached;
            //        I could also add a timeout in case the goal is never reached
            _char.Execute("ResetMind();");
        }));
    }

    void ShowYellDistance(){
        MovementObject@ player_char = FindPlayer();
        DebugDrawWireSphere(player_char.position, yell_distance, vec3(1.0f), _delete_on_update);
    }

    float GetYellDistance(){
        return yell_distance;
    }

    void SetYellDistance(float _yell_distance){
        if(_yell_distance < _min_yell_distance || _yell_distance > _max_yell_distance){
            return;
        }
        yell_distance = _yell_distance;
    }

    private array<int> FindCloseFriends(int _player_id){
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

            if(distance(player_char.position, char.position) < yell_distance){
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
