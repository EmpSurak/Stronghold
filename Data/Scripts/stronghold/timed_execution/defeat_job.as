#include "timed_execution/basic_job_interface.as"

funcdef void ON_DEFEAT_CALLBACK();

class DefeatJob : BasicJobInterface {
    protected ON_DEFEAT_CALLBACK @callback;

    DefeatJob(){}

    DefeatJob(ON_DEFEAT_CALLBACK @_callback){
        @callback = @_callback;
    }

    void ExecuteExpired(){
        callback();
    }

    bool IsExpired(){
        int num = GetNumCharacters();
        for(int i = 0; i < num; ++i){
            MovementObject@ char = ReadCharacter(i);
            if(char.controlled){
                if(char.GetIntVar("knocked_out") != _awake){
                    return true;
                };
            }
        }
        return false;
    }

    bool IsRepeating(){
        return false;
    }
}
