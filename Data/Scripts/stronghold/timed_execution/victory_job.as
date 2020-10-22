#include "timed_execution/basic_job_interface.as"
#include "stronghold/common.as"

funcdef void ON_VICTORY_CALLBACK();

class VictoryJob : BasicJobInterface {
    protected ON_VICTORY_CALLBACK @callback;

    VictoryJob(){}

    VictoryJob(ON_VICTORY_CALLBACK @_callback){
        @callback = @_callback;
    }

    void ExecuteExpired(){
        callback();
    }

    bool IsExpired(){
        // A story of pain. I wanted to do this with level messages first, but when you send a level message
        // from a hotspot it seems it runs in a different context.
        return IsTriumphant();
    }

    bool IsRepeating(){
        return false;
    }
}
