#include "timed_execution/timer_job_interface.as"
#include "stronghold/timed_execution/flag_bearer_job.as"

funcdef void FLAG_BEARER_EFFECT_ENTRY_CALLBACK(MovementObject@);
funcdef void FLAG_BEARER_EFFECT_EXIT_CALLBACK(MovementObject@);

class FlagBearerEffectJob : TimerJobInterface {
    protected float wait;
    protected int char_id;
    protected int flag_bearer_id;
    protected FLAG_BEARER_EFFECT_ENTRY_CALLBACK @entry_callback;
    protected FLAG_BEARER_EFFECT_EXIT_CALLBACK @exit_callback;
    protected float started;

    FlagBearerEffectJob(){}

    FlagBearerEffectJob(
                        float _wait,
                        int _flag_bearer_id,
                        int _char_id,
                        FLAG_BEARER_EFFECT_ENTRY_CALLBACK @_entry_callback,
                        FLAG_BEARER_EFFECT_EXIT_CALLBACK @_exit_callback
                       ){
        wait = _wait;
        char_id = _char_id;
        flag_bearer_id = _flag_bearer_id;
        @entry_callback = @_entry_callback;
        @exit_callback = @_exit_callback;

        MovementObject@ _char = ReadCharacterID(char_id);
        entry_callback(_char);
    }

    void ExecuteExpired(){
        if(!MovementObjectExists(char_id)){
            return;
        }

        MovementObject@ char = ReadCharacterID(char_id);
        exit_callback(char);
    }

    bool IsExpired(float time){
        if(!IsActive()){
            return true;
        }
        return time > GetEndTime();
    }

    bool IsRepeating(){
        return IsActive();
    }

    void SetStarted(float time){
        started = time;
    }

    private float GetEndTime(){
        return started+wait;
    }

    private bool IsActive(){
        if(!MovementObjectExists(char_id)){
            return false;
        }
        MovementObject@ _char = ReadCharacterID(char_id);
        if (_char.GetIntVar("knocked_out") != _awake){
            return false;
        }

        if(!MovementObjectExists(flag_bearer_id)){
            return false;
        }
        MovementObject@ _flag_bearer_char = ReadCharacterID(flag_bearer_id);
        if (_flag_bearer_char.GetIntVar("knocked_out") != _awake){
            return false;
        }

        return true;
    }
}
