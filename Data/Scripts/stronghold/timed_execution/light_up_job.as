#include "timed_execution/timer_job_interface.as"

funcdef float LIGHT_UP_CALLBACK(MovementObject@, Object@, float);

class LightUpJob : TimerJobInterface {
    protected float wait;
    protected int char_id;
    protected LIGHT_UP_CALLBACK @callback;
    protected float started;
    protected float return_value;
    protected int light_id;

    LightUpJob(){}

    LightUpJob(float _wait, float _start_value, int _char_id, LIGHT_UP_CALLBACK @_callback){
        wait = _wait;
        return_value = _start_value;
        char_id = _char_id;
        @callback = @_callback;
        light_id = CreateObject("Data/Objects/default_light.xml", true);
        ExecuteExpired();
    }

    void ExecuteExpired(){
        if(!ObjectExists(light_id)){
            return;
        }else if(!ObjectExists(char_id)){
            DeleteObjectID(light_id);
            return;
        }
        MovementObject@ _char = ReadCharacterID(char_id);
        Object@ _light = ReadObjectFromID(light_id);
        return_value = callback(_char, _light, return_value);
    }

    bool IsExpired(float time){
        return time > GetEndTime();
    }

    bool IsRepeating(){
        bool repeating = return_value > 0.0f;
        if(!repeating){
            DeleteObjectID(light_id);
        }
        return repeating;
    }

    void SetStarted(float time){
        started = time;
    }

    private float GetEndTime(){
        return started+wait;
    }
}
