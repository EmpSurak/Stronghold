enum AIGoal {
    _patrol,
    _attack,
    _investigate,
    _get_help,
    _escort,
    _get_weapon,
    _navigate,
    _struggle,
    _hold_still,
    _flee
};

enum AISubGoal {
    _unknown = -1,
    _provoke_attack,
    _avoid_jump_kick,
    _knock_off_ledge,
    _wait_and_attack,
    _rush_and_attack,
    _defend,
    _surround_target,
    _escape_surround,
    _investigate_slow,
    _investigate_urgent,
    _investigate_body,
    _investigate_around,
    _investigate_attack
};

const int _TETHERED_FREE = 0;
const int _TETHERED_REARCHOKE = 1;
const int _TETHERED_REARCHOKED = 2;
const int _TETHERED_DRAGBODY = 3;
const int _TETHERED_DRAGGEDBODY = 4;

const string _key_reset = "r";
const string _key_stand_down = "t";
const string _key_come = "f";
const string _key_go_to = "g";
const string _key_follow = "h";
const string _key_decrease_distance = "n";
const string _key_increase_distance = "m";
const string _key_radius_1 = "1";
const string _key_radius_2 = "2";
const string _key_radius_3 = "3";
const string _key_radius_4 = "4";
const string _key_radius_5 = "5";

const string _smoke_emitter_key = "Smoke Emitter ID";
const string _magic_key = "STRONGHOLD";

const float _char_deactivation_radius = 250.0f;
const float _hotspot_deactivation_radius = 400.0f;
const float _win_radius = 100.0f;

enum UnitType {
    _no_type,
    _soldier,
    _tank,
    _giant,
    _bomber,
    _flag_bearer,
    _raider
};
