#include "timed_execution/timed_execution.as"
#include "timed_execution/after_init_job.as"
#include "timed_execution/on_input_pressed_job.as"
#include "timed_execution/on_input_down_job.as"
#include "timed_execution/after_char_init_job.as"
#include "timed_execution/char_damage_job.as"
#include "timed_execution/level_event_job.as"
#include "stronghold/friend_controller.as"
#include "stronghold/timed_execution/nav_destination_job.as"
#include "stronghold/timed_execution/delayed_death_job.as"
#include "stronghold/common.as"
#include "stronghold/constants.as"
#include "stronghold/hudgui.as"

TimedExecution timer;
FriendController friend_controller(timer);
HUDGUI@ hud_gui = HUDGUI();

float current_time = 0.0f;

void Init(string level_name){
    timer.Add(OnInputPressedJob(0, _key_reset, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.Execute(function(_char){
            _char.Execute("combat_allowed = true;");
            _char.Execute("ResetMind();");
            friend_controller.Yell(_char.GetID(), "suspicious");
        });
        friend_controller.Yell(FindPlayerID(), "engage");
        return true;
    }));

    timer.Add(OnInputPressedJob(0, _key_stand_down, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.Execute(function(_char){
            _char.Execute("combat_allowed = false;");
        });
        friend_controller.Yell(FindPlayerID(), "suspicious");
        return true;
    }));

    timer.Add(OnInputPressedJob(0, _key_come, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.Execute(function(_char){
            MovementObject@ player_char = FindPlayer();
            friend_controller.NavigateToTarget(_char, player_char.position);
            friend_controller.Yell(_char.GetID(), "attack");
        });
        friend_controller.Yell(FindPlayerID(), "attack");
        return true;
    }));

    timer.Add(OnInputPressedJob(0, _key_go_to, function(){
        if(EditorModeActive()){
            return true;
        }
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

    timer.Add(OnInputPressedJob(0, _key_follow, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.Execute(function(_char){
            int player_id = FindPlayerID();
            _char.Execute("escort_id = " + player_id + ";");
            _char.Execute("SetGoal(_escort);");
            friend_controller.Yell(_char.GetID(), "engage");
        });
        friend_controller.Yell(FindPlayerID(), "engage");
        return true;
    }));

    timer.Add(OnInputDownJob(0, _key_decrease_distance, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.SetYellDistance(friend_controller.GetYellDistance() - 0.1f);
        hud_gui.SetDistance(friend_controller.GetYellDistance());
        return true;
    }));

    timer.Add(OnInputDownJob(0, _key_increase_distance, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.SetYellDistance(friend_controller.GetYellDistance() + 0.1f);
        hud_gui.SetDistance(friend_controller.GetYellDistance());
        return true;
    }));

    timer.Add(OnInputPressedJob(0, _key_radius_1, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.SetYellDistance(2.0f);
        hud_gui.SetDistance(friend_controller.GetYellDistance());
        return true;
    }));

    timer.Add(OnInputPressedJob(0, _key_radius_2, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.SetYellDistance(5.0f);
        hud_gui.SetDistance(friend_controller.GetYellDistance());
        return true;
    }));

    timer.Add(OnInputPressedJob(0, _key_radius_3, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.SetYellDistance(10.0f);
        hud_gui.SetDistance(friend_controller.GetYellDistance());
        return true;
    }));

    timer.Add(OnInputPressedJob(0, _key_radius_4, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.SetYellDistance(20.0f);
        hud_gui.SetDistance(friend_controller.GetYellDistance());
        return true;
    }));

    timer.Add(OnInputPressedJob(0, _key_radius_5, function(){
        if(EditorModeActive()){
            return true;
        }
        friend_controller.SetYellDistance(40.0f);
        hud_gui.SetDistance(friend_controller.GetYellDistance());
        return true;
    }));

    timer.Add(AfterInitJob(function(){
        MovementObject@ char = FindPlayer();
        hud_gui.SetHealth(1.0f);
        hud_gui.SetDistance(friend_controller.GetYellDistance());

        timer.Add(CharDamageJob(FindPlayerID(), function(_char, _p_blood, _p_permanent){
            if(_char.GetIntVar("knocked_out") != _awake){
                hud_gui.SetHealth(0.0f);
            }else if(_p_blood < _p_permanent){
                hud_gui.SetHealth(_p_blood);
            }else{
                hud_gui.SetHealth(_p_permanent);
            }
            return true;
        }));

        RegisterCleanupJobs();
    }));
}

void Update(int is_paused){
    current_time += time_step;
    timer.Update();
    hud_gui.ShowPressedButtons();
}

bool HasFocus(){
    return false;
}

void DrawGUI(){
    hud_gui.Update();
    hud_gui.Render();
}

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
            char_params.AddInt(_smoke_emitter_key, emitter_id);
        }));

        timer.Add(DelayedDeathJob(10.0f, char.GetID(), function(_char){
            Object@ char_obj = ReadObjectFromID(_char.GetID());
            ScriptParams@ char_params = char_obj.GetScriptParams();
            int emitter_id = char_params.GetInt(_smoke_emitter_key);
            DeleteObjectID(_char.GetID());
            DeleteObjectID(emitter_id);
        }));
    }

    timer.Add(LevelEventJob("reset", function(_params){
        int num_chars = GetNumCharacters();
        for(int i = 0; i < num_chars; ++i){
            MovementObject@ char = ReadCharacter(i);
            Object@ char_obj = ReadObjectFromID(char.GetID());
            if(char_obj.IsExcludedFromSave()){
                QueueDeleteObjectID(char.GetID());
            }
        }

        int num_items = GetNumItems();
        for(int i = 0; i < num_items; ++i){
            ItemObject@ item = ReadItem(i);
            Object@ item_obj = ReadObjectFromID(item.GetID());
            if(item_obj.IsExcludedFromSave()){
                QueueDeleteObjectID(item.GetID());
            }
        }
        return true;
    }));
}
