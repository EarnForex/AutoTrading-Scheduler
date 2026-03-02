#include <Controls\Button.mqh>
#include <Controls\Dialog.mqh>
#include <Controls\CheckBox.mqh>
#include <Controls\Label.mqh>
#include <Controls\RadioGroup.mqh>
#include <Arrays\List.mqh>

// Additional checkbox bitmaps:
#resource "Images\\CheckBoxOnDark.bmp"
#resource "Images\\CheckBoxOffDark.bmp"
#resource "Images\\CheckBoxOnDark17.bmp"
#resource "Images\\CheckBoxOffDark17.bmp"
#resource "Images\\CheckBoxOn17.bmp"
#resource "Images\\CheckBoxOff17.bmp"

// Additional radiogroup button bitmaps:
#resource "Images\\RadioButtonOnDark.bmp"
#resource "Images\\RadioButtonOffDark.bmp"
#resource "Images\\RadioButtonOn16Dark.bmp"
#resource "Images\\RadioButtonOff16Dark.bmp"
#resource "Images\\RadioButtonOn16.bmp"
#resource "Images\\RadioButtonOff16.bmp"

color CONTROLS_EDIT_COLOR_ENABLE  = C'255,255,255';
color CONTROLS_EDIT_COLOR_DISABLE = C'221,221,211';

color CONTROLS_BUTTON_COLOR_ENABLE  = C'200,200,200';
color CONTROLS_BUTTON_COLOR_DISABLE = C'224,224,224';

color DARKMODE_BG_DARK_COLOR = 0x444444;
color DARKMODE_CONTROL_BRODER_COLOR = 0x888888;
color DARKMODE_MAIN_AREA_BORDER_COLOR = 0x333333;
color DARKMODE_MAIN_AREA_BG_COLOR = 0x666666;
color DARKMODE_EDIT_BG_COLOR = 0xAAAAAA;
color DARKMODE_BUTTON_BG_COLOR = 0xA19999;
color DARKMODE_TEXT_COLOR = 0x000000;

enum ENUM_TIME_TYPE
{
    Local,
    Server
};

// Used for the schedule's setting - whether it's showing allowed periods or forbidden ones.
enum ENUM_ALLOWDENY
{
    ALLOWDENY_ALLOW, // Allow
    ALLOWDENY_DENY // Deny
};

enum ENUM_TOGGLE
{
    TOGGLE_DONT_TOGGLE, // Don't toggle
    TOGGLE_TOGGLE_ON,   // Toggle ON
    TOGGLE_TOGGLE_OFF   // Toggle OFF
};

enum ENUM_WHAT_TO_CLOSE
{
    WTC_POSITIONS, // Positions only
    WTC_ORDERS, // Orders only
    WTC_ALL // Positions & orders
};

// An object class for storing timestamp + enable/disable state.
class CTimeStamp : public CObject
{
    public:
        datetime    time;
        bool        enable;
        CTimeStamp(datetime t, bool e) {time = t; enable = e;}
        virtual int Compare(const CObject *node, const int mode = 0) override const;
};

int CTimeStamp::Compare(const CObject *node, const int mode = 0) override const
{
    CTimeStamp *ts = (CTimeStamp*)node; // Cast the generic object pointer to the timestamp object pointer.
    
    if (mode == 0) // Ascending:
    {
        if (time > ts.time) return 1;
        else if (time < ts.time) return -1;
        return 0;
    }
    else // Descending:
    {
        if (time < ts.time) return 1;
        else if (time > ts.time) return -1;
        return 0;
    }
}

struct Settings
{
    ENUM_TIME_TYPE TimeType;
    bool ClosePos;
    bool TurnedOn;
    string Monday;
    string Tuesday;
    string Wednesday;
    string Thursday;
    string Friday;
    string Saturday;
    string Sunday;
    bool Enforce;
    datetime LastToggleTime; // For Enforce = false.
    ENUM_ALLOWDENY AllowDeny;
    string LongTermSchedule;
} sets;
//+------------------------------------------------------------------+