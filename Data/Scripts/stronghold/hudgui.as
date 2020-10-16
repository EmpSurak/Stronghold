#include "stronghold/friend_controller.as"
#include "stronghold/constants.as"

const string _come_image_1 = "come_1";
const string _come_image_2 = "come_2";
const string _follow_image_1 = "follow_1";
const string _follow_image_2 = "follow_2";
const string _go_to_image_1 = "go_to_1";
const string _go_to_image_2 = "go_to_2";
const string _reset_image_1 = "reset_1";
const string _reset_image_2 = "reset_2";
const string _stand_down_image_1 = "stand_down_1";
const string _stand_down_image_2 = "stand_down_2";
const string _health_image = "health";
const string _distance_image = "distance";
const string _images_base = "Images/stronghold/";
const string _images_extension = ".png";

class HUDGUI {
    private IMGUI@ guiHUD = CreateIMGUI();

    HUDGUI(){
        this.Clear();
        this.LoadImages();
        this.Update();
    }

    void ShowPressedButtons(){
        IMImage@ img_follow_1 = cast<IMImage>(this.FindElement(_follow_image_1));
        IMImage@ img_follow_2 = cast<IMImage>(this.FindElement(_follow_image_2));
        IMImage@ img_come_1 = cast<IMImage>(this.FindElement(_come_image_1));
        IMImage@ img_come_2 = cast<IMImage>(this.FindElement(_come_image_2));
        IMImage@ img_go_to_1 = cast<IMImage>(this.FindElement(_go_to_image_1));
        IMImage@ img_go_to_2 = cast<IMImage>(this.FindElement(_go_to_image_2));
        IMImage@ img_stand_down_1 = cast<IMImage>(this.FindElement(_stand_down_image_1));
        IMImage@ img_stand_down_2 = cast<IMImage>(this.FindElement(_stand_down_image_2));
        IMImage@ img_reset_1 = cast<IMImage>(this.FindElement(_reset_image_1));
        IMImage@ img_reset_2 = cast<IMImage>(this.FindElement(_reset_image_2));

        img_follow_1.setVisible(!GetInputDown(0, _key_follow));
        img_follow_2.setVisible(GetInputDown(0, _key_follow));
        img_come_1.setVisible(!GetInputDown(0, _key_come));
        img_come_2.setVisible(GetInputDown(0, _key_come));
        img_go_to_1.setVisible(!GetInputDown(0, _key_go_to));
        img_go_to_2.setVisible(GetInputDown(0, _key_go_to));
        img_reset_1.setVisible(!GetInputDown(0, _key_reset));
        img_reset_2.setVisible(GetInputDown(0, _key_reset));
        img_stand_down_1.setVisible(!GetInputDown(0, _key_stand_down));
        img_stand_down_2.setVisible(GetInputDown(0, _key_stand_down));
    }

    void Clear(){
        this.guiHUD.clear();
        this.guiHUD.setup();
    }

    void Update(){
        this.guiHUD.update();
    }

    void Render(){
        this.guiHUD.render();
    }

    void SetHealth(float _health){
        int rounded_health = RoundFloatPercent(_health);
        for(int i = 0; i <= 100; i += 10){
            IMImage@ img_health = cast<IMImage>(this.FindElement(_health_image + "_" + i));
            img_health.setVisible(i == rounded_health);
        }
    }

    void SetDistance(float _distance){
        int rounded_distance = RoundFloatPercent(_distance / _max_yell_distance);
        for(int i = 0; i <= 100; i += 10){
            IMImage@ img_distance = cast<IMImage>(this.FindElement(_distance_image + "_" + i));
            img_distance.setVisible(i == rounded_distance);
        }
    }

    private int RoundFloatPercent(float _float){
        if(_float <= 0.0f){
            return 0;
        }
        return int(_float * 10) * 10;
    }

    private IMElement@ FindElement(const string name){
        array<IMElement@> elements = this.guiHUD.getMain().getFloatingContents();
        for(uint i = 0; i < elements.length(); i++){
            if(elements[i].getName() == name){
                return elements[i];
            }
        }

        return null;
    }

    private void AddImage(string _file, float _offset){
        float height = screenMetrics.getScreenHeight();
        float pos_y = height - _offset;
        IMImage img(_images_base + _file + _images_extension);
        img.setVisible(false);
        vec2 pos(this.guiHUD.getMain().getSizeX() - img.getSizeX() - 10.0f, pos_y);
        this.guiHUD.getMain().addFloatingElement(img, _file, pos, 1);
    }

    private void LoadImages(){
        AddImage(_follow_image_1, 700);
        AddImage(_follow_image_2, 700);
        AddImage(_come_image_1, 600);
        AddImage(_come_image_2, 600);
        AddImage(_go_to_image_1, 500);
        AddImage(_go_to_image_2, 500);
        AddImage(_stand_down_image_1, 400);
        AddImage(_stand_down_image_2, 400);
        AddImage(_reset_image_1, 300);
        AddImage(_reset_image_2, 300);

        for(int i = 0; i <= 100; i += 10){
            AddImage(_health_image + "_" + i, 200);
        }

        for(int i = 0; i <= 100; i += 10){
            AddImage(_distance_image + "_" + i, 100);
        }
    }
}