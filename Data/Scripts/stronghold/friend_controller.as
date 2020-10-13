#include "timed_execution/timed_execution.as"
#include "stronghold/timed_execution/delayed_friend_controller_job.as"
#include "stronghold/common.as"

funcdef void CLOSE_FRIEND_CALLBACK(MovementObject@);

const float _min_yell_distance = 2.0f;
const float _max_yell_distance = 40.0f;
const float _min_delay_default = 0.1f;
const float _max_delay_default = 1.0f;
const string _min_delay_label = "Min. Command Delay";
const string _max_delay_label = "Max. Command Delay";

class FriendController {
    private TimedExecution@ timer;
    private float yell_distance = 10.0f;

    FriendController(){}

    FriendController(TimedExecution@ _timer){
        @timer = @_timer;
    }

    void Execute(CLOSE_FRIEND_CALLBACK @_callback){
        int player_id = FindPlayerID();
        array<int> close_friends = FindCloseFriends(player_id);
        for(uint i = 0; i < close_friends.length(); ++i){
            Object@ char_obj = ReadObjectFromID(close_friends[i]);
            ScriptParams @char_params = char_obj.GetScriptParams();

            float min_delay = _min_delay_default;
            if(char_params.HasParam(_min_delay_label)){
                min_delay = char_params.GetFloat(_min_delay_label);
            }

            float max_delay = _max_delay_default;
            if(char_params.HasParam(_max_delay_label)){
                max_delay = char_params.GetFloat(_max_delay_label);
            }

            float delay = RangedRandomFloat(min_delay, max_delay);
            timer.Add(DelayedFriendControllerJob(delay, close_friends[i], _callback));
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

    void Yell(int char_id, string type){
        MovementObject@ char = ReadCharacterID(char_id);
        char.Execute("this_mo.PlaySoundGroupVoice(\"" + type + "\", 0.0f);");
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
