#include "timed_execution/timer_job_interface.as"

class DelayedFriendControllerJob : TimerJobInterface {
    protected float wait;
    protected int char_id;
    protected CLOSE_FRIEND_CALLBACK @callback;
    protected float started;

    DelayedFriendControllerJob(){}

    DelayedFriendControllerJob(float _wait, int _char_id, CLOSE_FRIEND_CALLBACK @_callback){
        wait = _wait;
        char_id = _char_id;
        @callback = @_callback;
    }

    void ExecuteExpired(){
        MovementObject@ _char = ReadCharacterID(char_id);
        callback(_char);
    }

    bool IsExpired(float time){
        return time > GetEndTime();
    }

    bool IsRepeating(){
        return false;
    }

    void SetStarted(float time){
        started = time;
    }

    private float GetEndTime(){
        return started+wait;
    }
}
