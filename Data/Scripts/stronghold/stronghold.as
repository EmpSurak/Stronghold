#include "timed_execution/timed_execution.as"
#include "timed_execution/delayed_job.as"
#include "timed_execution/on_input_pressed_job.as"
#include "timed_execution/on_input_down_job.as"
#include "stronghold/friend_controller.as"
#include "stronghold/timed_execution/nav_destination_job.as"
#include "stronghold/timed_execution/delayed_death_job.as"
#include "stronghold/common.as"

TimedExecution timer;
FriendController friend_controller(timer);

float current_time = 0.0f;

void Init(string level_name){
    timer.Add(OnInputPressedJob(0, "r", function(){
        friend_controller.Execute(function(_char){
            _char.Execute("p_aggression = 1.0f;");
            _char.Execute("p_ground_aggression = 1.0f;");
            _char.Execute("ResetMind();");
            friend_controller.Yell(_char.GetID(), "suspicious");
        });
        friend_controller.Yell(FindPlayerID(), "engage");
        return true;
    }));

    timer.Add(OnInputPressedJob(0, "t", function(){
        friend_controller.Execute(function(_char){
            _char.Execute("p_aggression = 0.1f;");
            _char.Execute("p_ground_aggression = 0.1f;");
            friend_controller.Yell(_char.GetID(), "suspicious");
        });
        friend_controller.Yell(FindPlayerID(), "suspicious");
        return true;
    }));

    timer.Add(OnInputPressedJob(0, "f", function(){
        friend_controller.Execute(function(_char){
            MovementObject@ player_char = FindPlayer();
            friend_controller.NavigateToTarget(_char, player_char.position);
            friend_controller.Yell(_char.GetID(), "attack");
        });
        friend_controller.Yell(FindPlayerID(), "attack");
        return true;
    }));

    timer.Add(OnInputPressedJob(0, "g", function(){
        friend_controller.Execute(function(_char){
            vec3 facing = camera.GetFacing();
            vec3 end = vec3(facing.x, max(-0.9, min(0.5f, facing.y)), facing.z) * 50.0f;
            vec3 hit = col.GetRayCollision(camera.GetPos(), camera.GetPos() + end);
            friend_controller.NavigateToTarget(_char, hit);
            friend_controller.Yell(_char.GetID(), "attack");
        });
        friend_controller.Yell(FindPlayerID(), "attack");
        return true;
    }));

    timer.Add(OnInputPressedJob(0, "h", function(){
        friend_controller.Execute(function(_char){
            int player_id = FindPlayerID();
            _char.Execute("escort_id = " + player_id + ";");
            _char.Execute("SetGoal(_escort);");
            friend_controller.Yell(_char.GetID(), "engage");
        });
        friend_controller.Yell(FindPlayerID(), "engage");
        return true;
    }));

    timer.Add(OnInputDownJob(0, "x", function(){
        friend_controller.ShowYellDistance();
        return true;
    }));

    timer.Add(OnInputDownJob(0, "n", function(){
        friend_controller.SetYellDistance(friend_controller.GetYellDistance() - 0.1f);
        friend_controller.ShowYellDistance();
        return true;
    }));

    timer.Add(OnInputDownJob(0, "m", function(){
        friend_controller.SetYellDistance(friend_controller.GetYellDistance() + 0.1f);
        friend_controller.ShowYellDistance();
        return true;
    }));

    timer.Add(OnInputPressedJob(0, "1", function(){
        friend_controller.SetYellDistance(2.0f);
        return true;
    }));

    timer.Add(OnInputPressedJob(0, "2", function(){
        friend_controller.SetYellDistance(5.0f);
        return true;
    }));

    timer.Add(OnInputPressedJob(0, "3", function(){
        friend_controller.SetYellDistance(10.0f);
        return true;
    }));

    timer.Add(OnInputPressedJob(0, "4", function(){
        friend_controller.SetYellDistance(20.0f);
        return true;
    }));

    timer.Add(OnInputPressedJob(0, "5", function(){
        friend_controller.SetYellDistance(40.0f);
        return true;
    }));

    // XXX: the hotspots that will dynamically create the characters will take care of registering the DelayedDeathJob
    RegisterCleanupJobs();
}

void Update(int is_paused){
    current_time += time_step;
    timer.Update();
}

bool HasFocus(){
    return false;
}

void DrawGUI(){}

void ReceiveMessage(string msg){
    timer.AddLevelEvent(msg);
}

void RegisterCleanupJobs(){
    int num = GetNumCharacters();
    for(int i = 0; i < num; ++i){
        MovementObject@ char = ReadCharacter(i);
        timer.Add(DelayedDeathJob(5.0f, char.GetID(), function(_char){
            int emitter_id = CreateObject("Data/Objects/Hotspots/emitter.xml", true);
            Object@ emitter_obj = ReadObjectFromID(emitter_id);
            emitter_obj.SetTranslation(_char.position);
            emitter_obj.SetScale(0.1f);
            ScriptParams@ emitter_params = emitter_obj.GetScriptParams();
            emitter_params.SetString("Type", "Smoke");

            Object@ char_obj = ReadObjectFromID(_char.GetID());
            ScriptParams@ char_params = char_obj.GetScriptParams();
            char_params.AddInt("Smoke Emitter ID", emitter_id);
        }));

        timer.Add(DelayedDeathJob(10.0f, char.GetID(), function(_char){
            Object@ char_obj = ReadObjectFromID(_char.GetID());
            ScriptParams@ char_params = char_obj.GetScriptParams();
            int emitter_id = char_params.GetInt("Smoke Emitter ID");
            DeleteObjectID(_char.GetID());
            DeleteObjectID(emitter_id);
        }));
    }
}
