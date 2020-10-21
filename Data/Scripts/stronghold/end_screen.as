#include "ui_effects.as"
#include "ui_tools.as"

enum EndScreenState {
    agsFighting,
    agsMsgScreen,
    agsEndScreen,
    agsInvalidState
};

const int _text_size = 60;
const vec4 _text_color = vec4(0.8, 0.8, 0.8, 1.0);
const string _text_font = "OpenSans-Regular";

class EndScreen : AHGUI::GUI {
    private float time = 0;
    private string message = "";

    private EndScreenState current_state = agsFighting;
    private EndScreenState last_state = agsInvalidState;

    EndScreen(){
        super();
    }

    void HandleStateChange(){
        if(last_state == current_state){
            return;
        }
        last_state = current_state;
        clear();
        switch(current_state){
            case agsInvalidState:{
                DisplayError("GUI Error", "GUI in invalid state");
            }
            break;
            case agsMsgScreen:
            case agsEndScreen:{
                ShowEndScreenUI();
            }
        }
    }

    private void ShowEndScreenUI(){
        AHGUI::Divider@ main_pane = root.addDivider(DDTop, DOVertical, ivec2(2562, 1440));
        main_pane.setHorizontalAlignment(BALeft);

		AHGUI::Divider@ title1 = main_pane.addDivider(DDTop, DOHorizontal, ivec2(AH_UNDEFINEDSIZE, 150));
		DisplayText(title1, DDCenter, "Stronghold by Surak", _text_color, true);
		AHGUI::Divider@ title2 = main_pane.addDivider(DDTop, DOHorizontal, ivec2(AH_UNDEFINEDSIZE, 50));
		DisplayText(title2, DDCenter, "October 2020 Jam: Ancient Times", _text_color, true);
		AHGUI::Divider@ title3 = main_pane.addDivider(DDTop, DOHorizontal, ivec2(AH_UNDEFINEDSIZE, 250));

        AHGUI::Divider@ message_title = main_pane.addDivider(DDTop, DOHorizontal, ivec2(AH_UNDEFINEDSIZE, 250));
        DisplayText(message_title, DDCenter, message, _text_color, true);

        AHGUI::Divider@ score_pane = main_pane.addDivider(DDTop, DOVertical, ivec2(AH_UNDEFINEDSIZE, 250));
        DisplayText(score_pane, DDTop, "Your time: " + GetTime(int(time)), _text_color, true);

        if(current_state == agsEndScreen){
            AHGUI::Divider@ footer = main_pane.addDivider(DDBottom, DOHorizontal, ivec2(AH_UNDEFINEDSIZE, 300));
            DisplayText(footer, DDCenter, "Press escape to return to menu or space to restart", _text_color, true);
        }
    }

    private string GetTime(int seconds){
        int num_seconds = seconds % 60;
        int num_minutes = seconds / 60;
        if(num_minutes == 0){
            return num_seconds + " seconds";
        }else if(num_minutes == 1){
            return num_minutes + " minute and " + num_seconds + " seconds";
        }else{
            return num_minutes + " minutes and " + num_seconds + " seconds";
        }
    }

    void Update() {
        HandleStateChange();
        AHGUI::GUI::update();
    }

    void Reset(){
        current_state = agsFighting;
    }

    void Render() {
       hud.Draw();
       AHGUI::GUI::render();
    }

    private void DisplayText(AHGUI::Divider@ div, DividerDirection dd, string text, vec4 color, bool shadowed){
        AHGUI::Text single_sentence(text, _text_font, _text_size, color.x, color.y, color.z, color.a);
        single_sentence.setShadowed(shadowed);
        div.addElement(single_sentence, dd);
        single_sentence.setBorderSize(1);
        single_sentence.setBorderColor(1.0, 1.0, 1.0, 1.0);
        single_sentence.showBorder(false);
    }

    void ShowMessage(string _message, float _time){
        time = _time;
        message = _message;
        current_state = agsMsgScreen;
    }

    void ShowControls(){
        current_state = agsEndScreen;
    }
}
