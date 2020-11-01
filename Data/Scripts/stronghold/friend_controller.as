#include "timed_execution/timed_execution.as"
#include "stronghold/timed_execution/delayed_friend_controller_job.as"
#include "stronghold/timed_execution/light_up_job.as"
#include "stronghold/command_job_storage.as"
#include "stronghold/common.as"

funcdef void CLOSE_FRIEND_CALLBACK(MovementObject@);

const float _min_yell_distance = 2.0f;
const float _max_yell_distance = 40.0f;
const float _min_delay_default = 0.1f;
const float _max_delay_default = 0.3f;
const string _min_delay_label = "Min. Command Delay";
const string _max_delay_label = "Max. Command Delay";

class FriendController {
    private TimedExecution@ timer;
    private float yell_distance = 10.0f;
    private CommandJobStorage command_job_storage;

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

            timer.Add(LightUpJob(0.05f, 10.0f, close_friends[i], function(_char, _light, _return_value){
                _light.SetTranslation(_char.position + vec3(0.0f, 2.5f, 0.0f));
                _light.SetTint(vec3(_return_value));
                return _return_value - 1.0f;
            }));
        }
    }

    void NavigateToTarget(MovementObject@ _char, vec3 _target){
        _char.Execute("nav_target.x = " + _target.x + ";");
        _char.Execute("nav_target.y = " + _target.y + ";");
        _char.Execute("nav_target.z = " + _target.z + ";");
        _char.Execute("SetGoal(_navigate);");

        timer.Add(NavDestinationJob(_char.GetID(), _target, command_job_storage, function(_char, _target){
            _char.Execute("ResetMind();");
        }));
    }

    void Yell(int char_id, string type){
        MovementObject@ char = ReadCharacterID(char_id);
        char.Execute("this_mo.PlaySoundGroupVoice(\"" + type + "\", 0.0f);");
        string pos_str = "vec3(" + char.position.x + ", " + char.position.y + ", " + char.position.z + ")";
        char.Execute("AISound(" + pos_str + ", " + yell_distance + ", _sound_type_loud_foley);");
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
            bool is_dead = char.GetIntVar("knocked_out") != _awake;

            if(is_player || is_dead || !is_same_team){
                continue;
            }

            if(distance(player_char.position, char.position) < yell_distance){
                close_friends.insertLast(char.GetID());
            }
        }

        return close_friends;
    }
}
