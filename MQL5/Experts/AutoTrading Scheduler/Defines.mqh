#include <Controls\Button.mqh>
#include <Controls\Dialog.mqh>
#include <Controls\CheckBox.mqh>
#include <Controls\Label.mqh>
#include <Controls\RadioGroup.mqh>
#include <Arrays\List.mqh>

color CONTROLS_EDIT_COLOR_DISABLE = C'221,221,211';

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