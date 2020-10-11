#include "timed_execution/basic_job_interface.as"
#include "stronghold/constants.as"

funcdef void NAV_DESTINATION_CALLBACK(MovementObject@, vec3);

class NavDestinationJob : BasicJobInterface {
    protected int player_id;
    protected vec3 target;
    protected NAV_DESTINATION_CALLBACK @callback;
    protected float _trigger_distance = 3.0f;
    protected bool skip_execution = false;

    NavDestinationJob(){}

    NavDestinationJob(int _player_id, vec3 _target, NAV_DESTINATION_CALLBACK @_callback){
        player_id = _player_id;
        target = _target;
        @callback = @_callback;
    }

    void ExecuteExpired(){
        if(skip_execution || !MovementObjectExists(player_id)){
            return;
        }
        MovementObject @player_char = ReadCharacterID(player_id);

        callback(player_char, target);
    }

    bool IsExpired(){
        if(!MovementObjectExists(player_id)){
            return false;
        }
        MovementObject @player_char = ReadCharacterID(player_id);
        
        // TODO: remove heigth from vectors

        bool is_close = distance(target, player_char.position) < _trigger_distance;
        if(is_close){
            return true;
        }

        bool is_navigating = player_char.GetIntVar("goal") == _navigate;
        if(!is_navigating){
            skip_execution = true;
            return true;
        }

        return false;
    }

    bool IsRepeating(){
        return false;
    }
}
