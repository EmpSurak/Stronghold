#include "timed_execution/timer_job_interface.as"

funcdef void FLAG_BEARER_CALLBACK(FlagBearerJob@, MovementObject@);

class FlagBearerJob : TimerJobInterface {
    protected float wait;
    protected int char_id;
    protected FLAG_BEARER_CALLBACK @callback;
    protected float started;

    FlagBearerJob(){}

    FlagBearerJob(float _wait, int _char_id, FLAG_BEARER_CALLBACK @_callback){
        wait = _wait;
        char_id = _char_id;
        @callback = @_callback;
    }

    void ExecuteExpired(){
        if(!IsActive()){
            return;
        }
        MovementObject@ char = ReadCharacterID(char_id);
        callback(this, char);
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
        MovementObject@ char = ReadCharacterID(char_id);
        return char.GetIntVar("knocked_out") == _awake;
    }
}
