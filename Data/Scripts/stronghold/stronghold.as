#include "timed_execution/timed_execution.as"
#include "timed_execution/on_input_pressed_job.as"
#include "timed_execution/on_input_down_job.as"
#include "stronghold/friend_controller.as"
#include "stronghold/timed_execution/nav_destination_job.as"
#include "stronghold/common.as"

TimedExecution timer;
FriendController friend_controller(timer);

float current_time = 0.0f;

void Init(string level_name){
    timer.Add(OnInputPressedJob(0, "r", function(){
        friend_controller.Execute(friend_controller.GetYellDistance(), function(_char){
            _char.Execute("p_aggression = 1.0f;");
            _char.Execute("p_ground_aggression = 1.0f;");
        });
        return true;
    }));

    timer.Add(OnInputPressedJob(0, "t", function(){
        friend_controller.Execute(friend_controller.GetYellDistance(), function(_char){
            _char.Execute("p_aggression = 0.1f;");
            _char.Execute("p_ground_aggression = 0.1f;");
        });
        return true;
    }));

    timer.Add(OnInputPressedJob(0, "f", function(){
        friend_controller.Execute(friend_controller.GetYellDistance(), function(_char){
            MovementObject@ player_char = FindPlayer();
            friend_controller.NavigateToTarget(_char, player_char.position);
        });
        return true;
    }));

    timer.Add(OnInputPressedJob(0, "g", function(){
        friend_controller.Execute(friend_controller.GetYellDistance(), function(_char){
            vec3 facing = camera.GetFacing();
            vec3 end = vec3(facing.x, max(-0.9, min(0.5f, facing.y)), facing.z) * 50.0f;
            vec3 hit = col.GetRayCollision(camera.GetPos(), camera.GetPos() + end);
            friend_controller.NavigateToTarget(_char, hit);
        });
        return true;
    }));

    timer.Add(OnInputPressedJob(0, "h", function(){
        friend_controller.Execute(friend_controller.GetYellDistance(), function(_char){
            int player_id = FindPlayerID();
            _char.Execute("escort_id = " + player_id + ";");
            _char.Execute("SetGoal(_escort);");
        });
        return true;
    }));

    timer.Add(OnInputDownJob(0, "x", function(){
        friend_controller.ShowYellDistance();
        return true;
    }));

    // TODO: play sound group after action
}

void Update(int is_paused){
    current_time += time_step;
    timer.Update();
}

bool HasFocus(){
    return false;
}

void DrawGUI(){
}

void ReceiveMessage(string msg){
    timer.AddLevelEvent(msg);
}

