#include "timed_execution/basic_job_interface.as"
#include "stronghold/command_job_storage.as"
#include "stronghold/constants.as"

funcdef void NAV_DESTINATION_CALLBACK(MovementObject@, vec3);

class NavDestinationJob : BasicJobInterface {
    protected int player_id;
    protected vec3 target;
    protected NAV_DESTINATION_CALLBACK @callback;
    protected CommandJobStorage @command_job_storage;
    protected float _trigger_distance = 3.0f;
    protected bool skip_execution = false;
    protected int job_number = -1;

    NavDestinationJob(){}

    NavDestinationJob(int _player_id, vec3 _target, CommandJobStorage @_command_job_storage, NAV_DESTINATION_CALLBACK @_callback){
        player_id = _player_id;
        target = _target;
        @command_job_storage = @_command_job_storage;
        @callback = @_callback;
        job_number = command_job_storage.AddJob(player_id);
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
        bool has_new_job = command_job_storage.GetJob(player_id) > job_number;
        if(!is_navigating || has_new_job){
            skip_execution = true;
            return true;
        }

        return false;
    }

    bool IsRepeating(){
        return false;
    }
}
