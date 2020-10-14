#include "timed_execution/timer_job_interface.as"

funcdef void DELAYED_DEATH_CALLBACK(MovementObject@);

class DelayedDeathJob : TimerJobInterface {
    protected float wait;
    protected int char_id;
    protected DELAYED_DEATH_CALLBACK @callback;
    protected float started;
    protected bool dead = false;

    DelayedDeathJob(){}

    DelayedDeathJob(float _wait, int _char_id, DELAYED_DEATH_CALLBACK @_callback){
        wait = _wait;
        char_id = _char_id;
        @callback = @_callback;
    }

    void ExecuteExpired(){
        if(!ObjectExists(char_id)){
            return;
        }
        MovementObject@ _char = ReadCharacterID(char_id);
        callback(_char);
    }

    bool IsExpired(float time){
        if(!ObjectExists(char_id)){
            return true;
        }

        if(dead){
            return time > GetEndTime();
        }

        MovementObject@ _char = ReadCharacterID(char_id);
        if(_char.GetIntVar("knocked_out") != _awake){
            dead = true;
            started = time;
        }

        return false;
    }

    bool IsRepeating(){
        return false;
    }

    void SetStarted(float time){}

    private float GetEndTime(){
        return started+wait;
    }
}
