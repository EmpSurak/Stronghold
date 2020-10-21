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
        timer.Add(AfterCharInitJob(FindPlayerID(), function(_char){
            hud_gui.SetHealth(1.0f);
            hud_gui.SetDistance(friend_controller.GetYellDistance());

            timer.Add(CharDamageJob(FindPlayerID(), function(_char, _p_blood, _p_permanent){
                float _blood = _char.GetFloatVar("blood_health");
                float _permanent = _char.GetFloatVar("permanent_health");
            
                if(_char.GetIntVar("knocked_out") != _awake){
                    hud_gui.SetHealth(0.0f);
                }else if(_blood < _permanent){
                    hud_gui.SetHealth(_blood);
                }else{
                    hud_gui.SetHealth(_permanent);
                }
                return true;
            }));

            RegisterCleanupJobs();
        }));
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
        if(!char.controlled){
            RegisterCharCleanUpJob(timer, char);
        }
    }

    timer.Add(LevelEventJob("reset", function(_params){
        uint num_chars = GetNumCharacters();
        for(uint i = 0; i < num_chars; ++i){
            MovementObject@ char = ReadCharacter(i);
            Object@ char_obj = ReadObjectFromID(char.GetID());
            if(char_obj.IsExcludedFromSave()){
                QueueDeleteObjectID(char.GetID());
            }
        }

        uint num_items = GetNumItems();
        for(uint i = 0; i < num_items; ++i){
            ItemObject@ item = ReadItem(i);
            Object@ item_obj = ReadObjectFromID(item.GetID());
            if(item_obj.IsExcludedFromSave()){
                QueueDeleteObjectID(item.GetID());
            }
        }

        uint num_hotspots = GetNumHotspots();
        for(uint i = 0; i < num_hotspots; ++i){
            Hotspot@ hot = ReadHotspot(i);
            Object@ hot_obj = ReadObjectFromID(hot.GetID());
            if(hot_obj.IsExcludedFromSave()){
                QueueDeleteObjectID(hot.GetID());
            }
        }

        array<int> dynamic_lights = GetObjectIDsType(_dynamic_light_object);
        for(uint i = 0; i < dynamic_lights.length(); i++){
            Object@ light_obj = ReadObjectFromID(dynamic_lights[i]);
            ScriptParams@ _light_params = light_obj.GetScriptParams();
            if(light_obj.IsExcludedFromSave() && _light_params.HasParam(_magic_key)){
                QueueDeleteObjectID(dynamic_lights[i]);
            }
        }

        array<int> envs = GetObjectIDsType(_env_object);
        for(uint i = 0; i < envs.length(); i++){
            Object@ env_obj = ReadObjectFromID(envs[i]);
            if(env_obj.IsExcludedFromSave()){
                QueueDeleteObjectID(envs[i]);
            }
        }

        timer.DeleteAll();
        Init("");

        return true;
    }));
}
