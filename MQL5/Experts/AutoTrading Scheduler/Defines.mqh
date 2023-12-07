#include <Controls\Button.mqh>
#include <Controls\Dialog.mqh>
#include <Controls\CheckBox.mqh>
#include <Controls\Label.mqh>
#include <Controls\RadioGroup.mqh>

color CONTROLS_EDIT_COLOR_DISABLE = C'221,221,211';

enum ENUM_TIME_TYPE
{
    Local,
    Server
};

enum ENUM_TOGGLE
{
    ENUM_TOGGLE_DONT_TOGGLE, // Don't toggle
    ENUM_TOGGLE_TOGGLE_ON,   // Toggle ON
    ENUM_TOGGLE_TOGGLE_OFF   // Toggle OFF
};

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
} sets;
//+------------------------------------------------------------------+