#include "Defines.mqh"
#include "WinUser32.mqh"

#import "user32.dll"
int GetAncestor(int, int);
#import

class CScheduler : public CAppDialog
{
private:
    // Buttons
    CButton     m_BtnSwitch, m_BtnSetToAll, m_BtnAllowDeny;
    // Labels
    CLabel      m_LblStatus, m_LblTurnedOn, m_LblURL, m_LblAllow, m_LblExample, m_LblMonday, m_LblTuesday, m_LblWednesday, m_LblThursday, m_LblFriday, m_LblSaturday, m_LblSunday;
    //Checkbox
    CCheckBox   m_ChkClosePos, m_ChkEnforce;;
    // Edits
    CEdit       m_EdtMonday, m_EdtTuesday, m_EdtWednesday, m_EdtThursday, m_EdtFriday, m_EdtSaturday, m_EdtSunday;
    // Radio Group
    CRadioGroup m_RgpTimeType;

    string      m_FileName;
    bool        IsANeedToContinueClosingPositions, IsANeedToContinueDeletingPendingOrders;
    double      m_DPIScale;
    bool        NoPanelMaximization; // Crutch variable to prevent panel maximization when Maximize() is called at the indicator's initialization.
    bool        StartedToggling; // To avoid consecutive triggering.
    // List of timestamps and enabled/disabled states for all days:
    CList             Schedule;

public:
    CScheduler(void);

    virtual bool Create(const long chart, const string name, const int subwin, const int x1, const int y1);
    virtual void Destroy();
    virtual bool SaveSettingsOnDisk();
    virtual bool LoadSettingsFromDisk();
    virtual bool DeleteSettingsFile();
    virtual bool LoadScheduleFile();
    virtual bool OnEvent(const int id, const long& lparam, const double& dparam, const string& sparam);
    virtual bool RefreshValues();
    virtual void RefreshPanelControls();
    void         CheckTimer();
    virtual void HideShowMaximize();

    // Remember the panel's location to have the same location for minimized and maximized states.
    int          remember_top, remember_left;
private:
    virtual bool CreateObjects();
    virtual void MoveAndResize();
    virtual bool ButtonCreate     (CButton&     Btn, const int X1, const int Y1, const int X2, const int Y2, const string Name, const string Text, string Tooltip = "\n");
    virtual bool CheckBoxCreate   (CCheckBox&   Chk, const int X1, const int Y1, const int X2, const int Y2, const string Name, const string Text);
    virtual bool EditCreate       (CEdit&       Edt, const int X1, const int Y1, const int X2, const int Y2, const string Name, const string Text);
    virtual bool LabelCreate      (CLabel&      Lbl, const int X1, const int Y1, const int X2, const int Y2, const string Name, const string Text, string Tooltip = "\n");
    virtual bool RadioGroupCreate (CRadioGroup& Rgp, const int X1, const int Y1, const int X2, const int Y2, const string Name, const string &Text[]);
    virtual void Maximize();
    virtual void Minimize();
    virtual void SeekAndDestroyDuplicatePanels();

    virtual void Check_Status();
            void ProcessWeeklySchedule();
            void ProcessLongTermSchedule();
            void ProcessScheduleDayForWeekday(string &time, CEdit &edt, const datetime time_base);
            void ProcessScheduleDay(string &sets_time, const datetime time_base);
    virtual int  Close_All_Positions();
    virtual int  Close_Current_Position(ulong ticket);
    virtual int  Delete_All_Pending_Orders();
    virtual int  Delete_Current_Pending_Order(ulong ticket);
    ENUM_TOGGLE  CompareTime(const datetime time);
    void         Toggle_AutoTrading();
    void         Notify(const int count_closed, const int count_deleted, const bool enable_or_disable);
    bool         ExistsPosition();
    bool         ExistsOrder();
    bool         CheckFilterMagic(const long magic);

    // Event handlers
    void OnChangeChkClosePos();
    void OnChangeChkEnforce();
    void OnChangeRgpTimeType();
    void OnEndEditEdtMonday();
    void OnEndEditEdtTuesday();
    void OnEndEditEdtWednesday();
    void OnEndEditEdtThursday();
    void OnEndEditEdtFriday();
    void OnEndEditEdtSaturday();
    void OnEndEditEdtSunday();
    void OnClickBtnSwitch();
    void OnClickBtnSetToAll();
    void OnClickBtnAllowDeny();

    // Supplementary functions:
    void RefreshConditions(const bool SettingsCheckBoxValue, const double SettingsEditValue, CCheckBox& CheckBox, CEdit& Edit, const int decimal_places);
    int  AddTimeStamp(CTimeStamp *new_node);
};

// Event Map
EVENT_MAP_BEGIN(CScheduler)
ON_EVENT(ON_CHANGE, m_ChkClosePos, OnChangeChkClosePos)
ON_EVENT(ON_CHANGE, m_ChkEnforce, OnChangeChkEnforce)
ON_EVENT(ON_CHANGE, m_RgpTimeType, OnChangeRgpTimeType)
ON_EVENT(ON_END_EDIT, m_EdtMonday, OnEndEditEdtMonday)
ON_EVENT(ON_END_EDIT, m_EdtTuesday, OnEndEditEdtTuesday)
ON_EVENT(ON_END_EDIT, m_EdtWednesday, OnEndEditEdtWednesday)
ON_EVENT(ON_END_EDIT, m_EdtThursday, OnEndEditEdtThursday)
ON_EVENT(ON_END_EDIT, m_EdtFriday, OnEndEditEdtFriday)
ON_EVENT(ON_END_EDIT, m_EdtSaturday, OnEndEditEdtSaturday)
ON_EVENT(ON_END_EDIT, m_EdtSunday, OnEndEditEdtSunday)
ON_EVENT(ON_CLICK, m_BtnSwitch, OnClickBtnSwitch)
ON_EVENT(ON_CLICK, m_BtnSetToAll, OnClickBtnSetToAll)
ON_EVENT(ON_CLICK, m_BtnAllowDeny, OnClickBtnAllowDeny)
EVENT_MAP_END(CAppDialog)

//+-------------------+
//| Class constructor |
//+-------------------+
CScheduler::CScheduler()
{
    m_FileName = "S_" + IntegerToString(ChartID()) + ".txt";
    IsANeedToContinueClosingPositions = false;
    IsANeedToContinueDeletingPendingOrders = false;
    NoPanelMaximization = false;
    remember_left = -1;
    remember_top = -1;
}

//+--------+
//| Button |
//+--------+
bool CScheduler::ButtonCreate(CButton &Btn, int X1, int Y1, int X2, int Y2, string Name, string Text, string Tooltip = "\n")
{
    if (!Btn.Create(m_chart_id, m_name + Name, m_subwin, X1, Y1, X2, Y2))       return false;
    if (!Add(Btn))                                                              return false;
    if (!Btn.Text(Text))                                                        return false;
    ObjectSetString(ChartID(), m_name + Name, OBJPROP_TOOLTIP, Tooltip);

    return true;
}

//+----------+
//| Checkbox |
//+----------+
bool CScheduler::CheckBoxCreate(CCheckBox &Chk, int X1, int Y1, int X2, int Y2, string Name, string Text)
{
    if (!Chk.Create(m_chart_id, m_name + Name, m_subwin, X1, Y1, X2, Y2))       return false;
    if (!Add(Chk))                                                              return false;
    if (!Chk.Text(Text))                                                        return false;

    return true;
}

//+------+
//| Edit |
//+------+
bool CScheduler::EditCreate(CEdit &Edt, int X1, int Y1, int X2, int Y2, string Name, string Text)
{
    if (!Edt.Create(m_chart_id, m_name + Name, m_subwin, X1, Y1, X2, Y2))       return false;
    if (!Add(Edt))                                                              return false;
    if (!Edt.Text(Text))                                                        return false;

    return true;
}

//+-------+
//| Label |
//+-------+
bool CScheduler::LabelCreate(CLabel &Lbl, int X1, int Y1, int X2, int Y2, string Name, string Text, string Tooltip = "\n")
{
    if (!Lbl.Create(m_chart_id, m_name + Name, m_subwin, X1, Y1, X2, Y2))       return false;
    if (!Add(Lbl))                                                              return false;
    if (!Lbl.Text(Text))                                                        return false;
    ObjectSetString(ChartID(), m_name + Name, OBJPROP_TOOLTIP, Tooltip);

    return true;
}

//+------------+
//| RadioGroup |
//+------------+
bool CScheduler::RadioGroupCreate(CRadioGroup &Rgp, int X1, int Y1, int X2, int Y2, string Name, const string &Text[])
{
    if (!Rgp.Create(m_chart_id, m_name + Name, m_subwin, X1, Y1, X2, Y2))       return false;
    if (!Add(Rgp))                                                              return false;

    int size = ArraySize(Text);
    for (int i = 0; i < size; i++)
    {
        if (!Rgp.AddItem(Text[i], i))                return false;
    }

    return true;
}

//+-----------------------+
//| Create a panel object |
//+-----------------------+
bool CScheduler::Create(const long chart, const string name, const int subwin, const int x1, const int y1)
{
    double screen_dpi = (double)TerminalInfoInteger(TERMINAL_SCREEN_DPI);
    m_DPIScale = screen_dpi / 96.0;

    int x2 = x1 + (int)MathRound(405 * m_DPIScale);
    int y2 = y1 + (int)MathRound(380 * m_DPIScale);

    if (!CAppDialog::Create(chart, name, subwin, x1, y1, x2, y2))               return false;
    if (!CreateObjects())                                                     return false;
    return true;
}

void CScheduler::Destroy()
{
    m_chart.Detach();
    // Call parent destroy.
    CDialog::Destroy();
}

bool CScheduler::CreateObjects()
{
    int row_start = (int)MathRound(10 * m_DPIScale);
    int element_height = (int)MathRound(20 * m_DPIScale);
    int v_spacing = (int)MathRound(4 * m_DPIScale);
    int h_spacing = (int)MathRound(10 * m_DPIScale);

    int normal_label_width = (int)MathRound(108 * m_DPIScale);
    int normal_edit_width = (int)MathRound(85 * m_DPIScale);
    int narrow_label_width = (int)MathRound(85 * m_DPIScale);
    int narrowest_edit_width = (int)MathRound(55 * m_DPIScale);
    int narrowest_label_width = (int)MathRound(30 * m_DPIScale);

    int timer_radio_width = (int)MathRound(100 * m_DPIScale);

    int first_column_start = (int)MathRound(5 * m_DPIScale);

    int second_column_start = first_column_start + narrowest_label_width;

    int third_column_start = second_column_start + (int)MathRound(250 * m_DPIScale);

    int panel_end = third_column_start + narrow_label_width;

    // Start
    int y = row_start;
    if (!LabelCreate(m_LblTurnedOn, first_column_start, y, first_column_start + narrow_label_width, y + element_height, "m_LblTurnedOn", "Scheduler is OFF."))                      return false;
    if (!ButtonCreate(m_BtnSwitch, first_column_start + normal_label_width, y, first_column_start + normal_label_width + normal_edit_width, y + element_height, "m_BtnSwitch", "Switch", "Switch Scheduler ON and OFF.")) return false;
    string m_RgpTimeType_Text[2] = {"Local time", "Server time"};
    if (!RadioGroupCreate(m_RgpTimeType, third_column_start - 2 * h_spacing, y, third_column_start - 2 * h_spacing + timer_radio_width, y + element_height * 2, "m_RgpTimeType", m_RgpTimeType_Text))       return false;

    y += element_height + 4 * v_spacing;
    if (!LabelCreate(m_LblStatus, first_column_start, y, first_column_start + normal_label_width, y + element_height, "m_LblStatus", "Status: "))                      return false;

    y += element_height + v_spacing;
    if (!ButtonCreate(m_BtnAllowDeny, first_column_start, y, first_column_start + narrowest_edit_width, y + element_height, "m_BtnAllowDeny", "Allow", "Switch between allowed periods and denied periods.")) return false;
    if (!LabelCreate(m_LblAllow, first_column_start + narrowest_edit_width, y, first_column_start + panel_end, y + element_height, "m_LblAllow", " trading only during these times:"))                      return false;

    y += element_height + v_spacing;
    if (!LabelCreate(m_LblExample, first_column_start, y, first_column_start + panel_end, y + element_height, "m_LblExample", "Example: 12-13, 14:00-16:45, 19:55 - 21"))                      return false;
    if (!m_LblExample.Color(clrDimGray)) return false;

    y += element_height + v_spacing;
    if (!LabelCreate(m_LblMonday, first_column_start, y, first_column_start + narrowest_edit_width, y + element_height, "m_LblMonday", "Mon", "Monday"))                      return false;
    if (!EditCreate(m_EdtMonday, second_column_start, y, third_column_start, y + element_height, "m_EdtMonday", ""))                                             return false;
    if (!ButtonCreate(m_BtnSetToAll, third_column_start + h_spacing, y, third_column_start + normal_label_width, y + element_height, "m_BtnSetToAll", "Set to all empty", "Set the Monday schedule to all days of the week with empty schedule.")) return false;

    y += element_height + v_spacing;
    if (!LabelCreate(m_LblTuesday, first_column_start, y, first_column_start + narrowest_edit_width, y + element_height, "m_LblTuesday", "Tue", "Monday"))                      return false;
    if (!EditCreate(m_EdtTuesday, second_column_start, y, third_column_start, y + element_height, "m_EdtTuesday", ""))                                             return false;

    y += element_height + v_spacing;
    if (!LabelCreate(m_LblWednesday, first_column_start, y, first_column_start + narrowest_edit_width, y + element_height, "m_LblWednesday", "Wed", "Tuesday"))                      return false;
    if (!EditCreate(m_EdtWednesday, second_column_start, y, third_column_start, y + element_height, "m_EdtWednesday", ""))                                             return false;

    y += element_height + v_spacing;
    if (!LabelCreate(m_LblThursday, first_column_start, y, first_column_start + narrowest_edit_width, y + element_height, "m_LblThursday", "Thu", "Thursday"))                      return false;
    if (!EditCreate(m_EdtThursday, second_column_start, y, third_column_start, y + element_height, "m_EdtThursday", ""))                                             return false;

    y += element_height + v_spacing;
    if (!LabelCreate(m_LblFriday, first_column_start, y, first_column_start + narrowest_edit_width, y + element_height, "m_LblFriday", "Fri", "Friday"))                      return false;
    if (!EditCreate(m_EdtFriday, second_column_start, y, third_column_start, y + element_height, "m_EdtFriday", ""))                                             return false;

    y += element_height + v_spacing;
    if (!LabelCreate(m_LblSaturday, first_column_start, y, first_column_start + narrowest_edit_width, y + element_height, "m_LblSaturday", "Sat", "Saturday"))                      return false;
    if (!EditCreate(m_EdtSaturday, second_column_start, y, third_column_start, y + element_height, "m_EdtSaturday", ""))                                             return false;

    y += element_height + v_spacing;
    if (!LabelCreate(m_LblSunday, first_column_start, y, first_column_start + narrowest_edit_width, y + element_height, "m_LblSunday", "Sun", "Sunday"))                      return false;
    if (!EditCreate(m_EdtSunday, second_column_start, y, third_column_start, y + element_height, "m_EdtSunday", ""))                                             return false;

    y += element_height + v_spacing;
    if (!CheckBoxCreate(m_ChkClosePos, first_column_start, y, panel_end, y + element_height, "m_ChkClosePos", "Attempt to close all trades before disabling AutoTrading"))       return false;

    y += element_height + v_spacing;
    if (!CheckBoxCreate(m_ChkEnforce, first_column_start, y, panel_end, y + element_height, "m_ChkEnforce", "Always enforce schedule"))           return false;

    y += element_height + v_spacing;

    if (!LabelCreate(m_LblURL, first_column_start, y, first_column_start + normal_label_width, y + element_height, "m_LblURL", "www.earnforex.com"))                      return false;
    if (!m_LblURL.FontSize(8)) return false;
    if (!m_LblURL.Color(clrGreen)) return false;

    SeekAndDestroyDuplicatePanels();

    return true;
}

void CScheduler::Minimize()
{
    CAppDialog::Minimize();
    if (remember_left != -1) Move(remember_left, remember_top);
}

// Processes click on the panel's Maximize button of the panel.
void CScheduler::Maximize()
{
    if (!NoPanelMaximization) CAppDialog::Maximize();
    else if (m_minimized) CAppDialog::Minimize();

    if (remember_left != -1) Move(remember_left, remember_top);
}

// Refreshes OFF/ON and Status.
bool CScheduler::RefreshValues()
{
    Check_Status();

    RefreshPanelControls();

    return true;
}

// Updates all panel controls depending on the settings in sets struct.
void CScheduler::RefreshPanelControls()
{
    // Refresh time type radio group.
    m_RgpTimeType.Value(sets.TimeType);

    datetime time;
    if (sets.TimeType == Local) time = TimeLocal();
    else time = TimeCurrent();
    static datetime last_time = time;
    if (sets.LongTermSchedule == "") // Re-check weekly schedule only when no long-term scedule is given.
    {
        int current_day_of_week = TimeDayOfWeek(time);
        if (current_day_of_week == 0) current_day_of_week = 7;
        int last_day_of_week = TimeDayOfWeek(last_time);
        if (last_day_of_week == 0) last_day_of_week = 7;
        if (current_day_of_week < last_day_of_week) // New week.
        {
            ProcessWeeklySchedule(); // Reload schedule for changed dates.
        }
    }
    last_time = time;

    // Check whether autotrading is enabled and set Last Toggle Time accordingly if a change was detected.
    static int allowed = TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
    if (allowed != TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) sets.LastToggleTime = time; // Manual toggle detected.
    allowed = TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);

    string s;
    s = m_EdtMonday.Text(); // Trim functions work by reference in MT5.
    StringTrimLeft(s);
    StringTrimRight(s);
    if ((s != sets.Monday) && (m_EdtMonday.Text() != "<<FILE>>"))
    {
        m_EdtMonday.Text(sets.Monday);
        ProcessWeeklySchedule();
    }
    s = m_EdtTuesday.Text();
    StringTrimLeft(s);
    StringTrimRight(s);
    if ((s != sets.Tuesday) && (m_EdtTuesday.Text() != "<<FILE>>"))
    {
        m_EdtTuesday.Text(sets.Tuesday);
        ProcessWeeklySchedule();
    }
    s = m_EdtWednesday.Text();
    StringTrimLeft(s);
    StringTrimRight(s);
    if ((s != sets.Wednesday) && (m_EdtWednesday.Text() != "<<FILE>>"))
    {
        m_EdtWednesday.Text(sets.Wednesday);
        ProcessWeeklySchedule();
    }
    s = m_EdtThursday.Text();
    StringTrimLeft(s);
    StringTrimRight(s);
    if ((s != sets.Thursday) && (m_EdtThursday.Text() != "<<FILE>>"))
    {
        m_EdtThursday.Text(sets.Thursday);
        ProcessWeeklySchedule();
    }
    s = m_EdtFriday.Text();
    StringTrimLeft(s);
    StringTrimRight(s);
    if ((s != sets.Friday) && (m_EdtFriday.Text() != "<<FILE>>"))
    {
        m_EdtFriday.Text(sets.Friday);
        ProcessWeeklySchedule();
    }
    s = m_EdtSaturday.Text();
    StringTrimLeft(s);
    StringTrimRight(s);
    if ((s != sets.Saturday) && (m_EdtSaturday.Text() != "<<FILE>>"))
    {
        m_EdtSaturday.Text(sets.Saturday);
        ProcessWeeklySchedule();
    }
    s = m_EdtSunday.Text();
    StringTrimLeft(s);
    StringTrimRight(s);
    if ((s != sets.Sunday) && (m_EdtSunday.Text() != "<<FILE>>"))
    {
        m_EdtSunday.Text(sets.Sunday);
        ProcessWeeklySchedule();
    }

    m_ChkClosePos.Checked(sets.ClosePos);
    m_ChkEnforce.Checked(sets.Enforce);

    if (sets.TurnedOn) m_LblTurnedOn.Text("Scheduler is ON.");
    else m_LblTurnedOn.Text("Scheduler is OFF.");

    if (sets.AllowDeny == ALLOWDENY_ALLOW) m_BtnAllowDeny.Text("Allow");
    else m_BtnAllowDeny.Text("Deny");
}

void CScheduler::SeekAndDestroyDuplicatePanels()
{
    int ot = ObjectsTotal(ChartID(), 0, OBJ_LABEL);
    for (int i = ot - 1; i >= 0; i--)
    {
        string object_name = ObjectName(ChartID(), i, 0, OBJ_LABEL);
        // Found Caption object.
        if (StringSubstr(object_name, StringLen(object_name) - 11) == "m_LblMonday")
        {
            string prefix = StringSubstr(object_name, 0, StringLen(Name()));
            // Found Caption object with prefix different than current.
            if (prefix != Name())
            {
                ObjectsDeleteAll(ChartID(), prefix);
                // Reset object counter.
                ot = ObjectsTotal(ChartID());
                i = ot;
                Print("Deleted duplicate panel objects with prefix = ", prefix, ".");
                continue;
            }
        }
    }
}

//+--------------------------------------------+
//|                                            |
//|                   EVENTS                   |
//|                                            |
//+--------------------------------------------+

// Changes Checkbox "Attempt to close all trades".
void CScheduler::OnChangeChkClosePos()
{
    if (sets.ClosePos != m_ChkClosePos.Checked())
    {
        sets.ClosePos = m_ChkClosePos.Checked();
        SaveSettingsOnDisk();
    }
}

// Changes Checkbox "Always enforce schedule".
void CScheduler::OnChangeChkEnforce()
{
    if (sets.Enforce != m_ChkEnforce.Checked())
    {
        sets.Enforce = m_ChkEnforce.Checked();
        if (sets.Enforce == false) ProcessWeeklySchedule(); // Might need last week's values.
        SaveSettingsOnDisk();
    }
}

// Switch Scheduler ON/OFF.
void CScheduler::OnClickBtnSwitch()
{
    if (!sets.TurnedOn) sets.TurnedOn = true;
    else sets.TurnedOn = false;
    Panel.RefreshValues();
    SaveSettingsOnDisk();
}

// Set text value from Monday to all days of the week.
void CScheduler::OnClickBtnSetToAll()
{
    string monday = m_EdtMonday.Text();
    StringTrimRight(monday);
    StringTrimLeft(monday);
    if (monday != "")
    {
        string tuesday = m_EdtTuesday.Text();
        StringTrimRight(tuesday);
        StringTrimLeft(tuesday);
        if (tuesday == "")
        {
            m_EdtTuesday.Text(monday);
            sets.Tuesday = sets.Monday;
        }
        string wednesday = m_EdtWednesday.Text();
        StringTrimRight(wednesday);
        StringTrimLeft(wednesday);
        if (wednesday == "")
        {
            m_EdtWednesday.Text(monday);
            sets.Wednesday = sets.Monday;
        }
        string thursday = m_EdtThursday.Text();
        StringTrimRight(thursday);
        StringTrimLeft(thursday);
        if (thursday == "")
        {
            m_EdtThursday.Text(monday);
            sets.Thursday = sets.Monday;
        }
        string friday = m_EdtFriday.Text();
        StringTrimRight(friday);
        StringTrimLeft(friday);
        if (friday == "")
        {
            m_EdtFriday.Text(monday);
            sets.Friday = sets.Monday;
        }
        string saturday = m_EdtSaturday.Text();
        StringTrimRight(saturday);
        StringTrimLeft(saturday);
        if (saturday == "")
        {
            m_EdtSaturday.Text(monday);
            sets.Saturday = sets.Monday;
        }
        string sunday = m_EdtSunday.Text();
        StringTrimRight(sunday);
        StringTrimLeft(sunday);
        if (sunday == "")
        {
            m_EdtSunday.Text(monday);
            sets.Sunday = sets.Monday;
        }
        ProcessWeeklySchedule();
        SaveSettingsOnDisk();
    }
}

// Switch Scheduler between Allow and Deny.
void CScheduler::OnClickBtnAllowDeny()
{
    if (sets.AllowDeny == ALLOWDENY_ALLOW) sets.AllowDeny = ALLOWDENY_DENY;
    else sets.AllowDeny = ALLOWDENY_ALLOW;
    Panel.RefreshValues();
    SaveSettingsOnDisk();
}

void CScheduler::ProcessWeeklySchedule()
{
    if (sets.LongTermSchedule != "") return; // No processing of weekly schedule, if a long-term one is given.
    // Prepare by getting base time to calculate timestamps based days of the week.
    datetime time_base;
    if (sets.TimeType == Local) time_base = TimeLocal();
    else time_base = TimeCurrent();
    int day_of_week = TimeDayOfWeek(time_base);
    if (day_of_week == 0) day_of_week = 7; // Fix Sunday.
    time_base -= (day_of_week - 1) * 86400 + TimeHour(time_base) * 3600 + TimeMinute(time_base) * 60 + TimeSeconds(time_base); // Start of the week (Monday 00:00).

    Schedule.Clear(); // Start anew each time to avoid managing existing entries.

    // Fill the current week's schedule:
    
    // Monday:
    if (sets.Monday != "")
    {
        ProcessScheduleDayForWeekday(sets.Monday, m_EdtMonday, time_base);
    }
    time_base += 24 * 3600; // Moving on to the next day.
    // Tuesday:
    if (sets.Tuesday != "")
    {
        ProcessScheduleDayForWeekday(sets.Tuesday, m_EdtTuesday, time_base);
    }
    time_base += 24 * 3600; // Moving on to the next day.
    // Wednesday:
    if (sets.Wednesday != "")
    {
        ProcessScheduleDayForWeekday(sets.Wednesday, m_EdtWednesday, time_base);
    }
    time_base += 24 * 3600; // Moving on to the next day.
    // Thursday:
    if (sets.Thursday != "")
    {
        ProcessScheduleDayForWeekday(sets.Thursday, m_EdtThursday, time_base);
    }
    time_base += 24 * 3600; // Moving on to the next day.
    // Friday:
    if (sets.Friday != "")
    {
        ProcessScheduleDayForWeekday(sets.Friday, m_EdtFriday, time_base);
    }
    time_base += 24 * 3600; // Moving on to the next day.
    // Saturday:
    if (sets.Saturday != "")
    {
        ProcessScheduleDayForWeekday(sets.Saturday, m_EdtSaturday, time_base);
    }
    time_base += 24 * 3600; // Moving on to the next day.
    // Sunday:
    if (sets.Sunday != "")
    {
        ProcessScheduleDayForWeekday(sets.Sunday, m_EdtSunday, time_base);
    }
    Schedule.Sort(0); // Sort schedule by time in ascending mode.

    // Check if the previous week's last switch might be needed. It might be needed to know whether to toggle autotrading when we are inside the first period of the current week in non-enforced mode.
    if ((sets.Enforce == false) && (Schedule.Total() > 0)) // Only in non-enforced mode and if some schedule is given.
    {
        CTimeStamp* ts = Schedule.GetFirstNode();
        datetime current_time;
        if (sets.TimeType == Local) current_time = TimeLocal();
        else current_time = TimeCurrent();
        if (ts.time > current_time) // The current week's first toggling time is still ahead. Need to check the previous week.
        {
            // Need to add the latest interval of the previous week. This should be done by adding full days since the intervals may be unsorted inside them. The fact that we could add extra intervals doesn't matter much at this point.
            time_base -= 7 * 24 * 3600; // Last Sunday start.
            if (sets.Sunday != "") // There is some schedule for Sunday.
            {
                ProcessScheduleDayForWeekday(sets.Sunday, m_EdtSunday, time_base);
            }
            else if (sets.Saturday != "") // There is some schedule for Saturday.
            {
                time_base -= 24 * 3600;
                ProcessScheduleDayForWeekday(sets.Saturday, m_EdtSaturday, time_base);
            }
            else if (sets.Friday != "") // There is some schedule for Friday.
            {
                time_base -= 2 * 24 * 3600;
                ProcessScheduleDayForWeekday(sets.Friday, m_EdtFriday, time_base);
            }
            else if (sets.Thursday != "") // There is some schedule for Thursday.
            {
                time_base -= 3 * 24 * 3600;
                ProcessScheduleDayForWeekday(sets.Thursday, m_EdtThursday, time_base);
            }
            else if (sets.Wednesday != "") // There is some schedule for Wednesday.
            {
                time_base -= 4 * 24 * 3600;
                ProcessScheduleDayForWeekday(sets.Wednesday, m_EdtWednesday, time_base);
            }
            else if (sets.Tuesday != "") // There is some schedule for Tuesday.
            {
                time_base -= 5 * 24 * 3600;
                ProcessScheduleDayForWeekday(sets.Tuesday, m_EdtTuesday, time_base);
            }
            else if (sets.Monday != "") // There is some schedule for Monday.
            {
                time_base -= 6 * 24 * 3600;
                ProcessScheduleDayForWeekday(sets.Monday, m_EdtMonday, time_base);
            }
            else return; // No schedule at all.
            Schedule.Sort(0); // Sort schedule by time in ascending mode.
        }
    }
}

void CScheduler::ProcessLongTermSchedule()
{
    datetime time_base;

    Schedule.Clear(); // Start anew each time to avoid managing existing entries.

    string date_schedule_pairs[];
    int n_dates = StringSplit(sets.LongTermSchedule, '|', date_schedule_pairs);

    for (int i = 0; i < n_dates; i++) // Cycle through all date/schedule pairs.
    {
        string date_schedule[];
        StringSplit(date_schedule_pairs[i], '~', date_schedule);
        string date = date_schedule[0]; // "YYYY-MM-DD"
        StringReplace(date, "-", "."); // To "YYYY.MM.DD".
        string schedule = date_schedule[1];
        time_base = StringToTime(date + " 00:00");
        ProcessScheduleDay(schedule, time_base);
    }

    Schedule.Sort(0); // Sort schedule by time in ascending mode.
}

void CScheduler::ProcessScheduleDay(string &sets_time, const datetime time_base)
{
    sets_time = FormatScheduleDay(sets_time);
    // Replace dashes with commas to split the string in a sequence if single HH:MM times. Odd will be set as Enabled; even - as Disabled.
    string time = sets_time;
    int n_dashes = StringReplace(time, "-", ",");
    StringReplace(time, " ", ""); // Remove spacebars.

    // Split.
    string times[];
    int n = StringSplit(time, ',', times);
    if (n != n_dashes * 2)
    {
        Print("Error with input string: ", time, ".");
        return;
    }
    for (int i = 0; i < n; i++)
    {
        int hours = 0;
        int minutes = 0;
        string hours_minutes[];
        int sub_n = StringSplit(times[i], ':', hours_minutes); // Split hours and minutes by colon.
        if (sub_n == 1) // Colon failed.
        {
            sub_n = StringSplit(times[i], '.', hours_minutes); // Split hours and minutes by period.
            if (sub_n == 1) // Period failed.
            {
                // Only hours given.
                hours = (int)StringToInteger(times[i]);
            }
            else
            {
                hours = (int)StringToInteger(hours_minutes[0]);
                minutes = (int)StringToInteger(hours_minutes[1]);
            }
        }
        else
        {
            hours = (int)StringToInteger(hours_minutes[0]);
            minutes = (int)StringToInteger(hours_minutes[1]);
        }

        if (i % 2 == 1) // Odd - finish time.
        {
            if ((hours == 0) && (minutes == 0)) hours = 24; // A special case for the end of the day.
        }
        datetime new_time = time_base + hours * 3600 + minutes * 60;

        if (i % 2 == 1) // Odd - finish time.
        {
            CTimeStamp* ts = Schedule.GetLastNode();
            if (new_time <= ts.time) // Finish time earlier than start time.
            {
                Print("Error with time range: ", TimeToString(ts.time, TIME_MINUTES), " - ", TimeToString(new_time, TIME_MINUTES));
                Schedule.DeleteCurrent();
                // And skip adding the finish time.
            }
            else // Normal time range.
            {
                ts = new CTimeStamp(new_time, false); // Toggle OFF.
                AddTimeStamp(ts); // Safe addition with checks for uniqueness of the timestamp.
            }
        }
        else // Even - start time.
        {
            CTimeStamp* ts = new CTimeStamp(new_time, true); // Toggle ON.
            AddTimeStamp(ts); // Safe addition with checks for uniqueness of the timestamp.
        }
    }
}

void CScheduler::ProcessScheduleDayForWeekday(string &sets_time, CEdit &edt, const datetime time_base)
{
    ProcessScheduleDay(sets_time, time_base);

    if (edt.ReadOnly()) edt.Text("<<FILE>>");
    else edt.Text(sets_time); // Formatted.
}

string FormatScheduleDay(string time)
{
    StringTrimLeft(time);
    StringTrimRight(time);
    int length = StringLen(time);

    // For empty string, just clear everything.
    if (length == 0)
    {
        return "";
    }

    // Clean up.
    for (int i = 0; i < length; i++)
    {
        if (((time[i] < '0') || (time[i] > '9')) && (time[i] != ' ') && (time[i] != ',') && (time[i] != ':') && (time[i] != '.') && (time[i] != '-'))
        {
            // Wrong character found.
            int replaced_characters = StringReplace(time, CharToString((uchar)time[i]), "");
            length -= replaced_characters;
            i--;
        }
    }
    return time;
}

void CScheduler::OnEndEditEdtMonday()
{
    sets.Monday = m_EdtMonday.Text();
    ProcessWeeklySchedule();
}

void CScheduler::OnEndEditEdtTuesday()
{
    sets.Tuesday = m_EdtTuesday.Text();
    ProcessWeeklySchedule();
}

void CScheduler::OnEndEditEdtWednesday()
{
    sets.Wednesday = m_EdtWednesday.Text();
    ProcessWeeklySchedule();
}

void CScheduler::OnEndEditEdtThursday()
{
    sets.Thursday = m_EdtThursday.Text();
    ProcessWeeklySchedule();
}

void CScheduler::OnEndEditEdtFriday()
{
    sets.Friday = m_EdtFriday.Text();
    ProcessWeeklySchedule();
}

void CScheduler::OnEndEditEdtSaturday()
{
    sets.Saturday = m_EdtSaturday.Text();
    ProcessWeeklySchedule();
}

void CScheduler::OnEndEditEdtSunday()
{
    sets.Sunday = m_EdtSunday.Text();
    ProcessWeeklySchedule();
}

// Saves input from the time type radio group.
void CScheduler::OnChangeRgpTimeType()
{
    if (sets.TimeType != m_RgpTimeType.Value())
    {
        sets.TimeType = (ENUM_TIME_TYPE)m_RgpTimeType.Value();
        SaveSettingsOnDisk();
    }
}

//+-----------------------+
//| Working with settings |
//|+----------------------+

// Saves settings from the panel into a file.
bool CScheduler::SaveSettingsOnDisk()
{
    int fh = FileOpen(m_FileName, FILE_TXT | FILE_WRITE);
    if (fh == INVALID_HANDLE)
    {
        Print("Failed to open file for writing: " + m_FileName + ". Error: " + IntegerToString(GetLastError()));
        return false;
    }

    // Order does not matter.
    FileWrite(fh, "TimeType");
    FileWrite(fh, IntegerToString(sets.TimeType));
    FileWrite(fh, "ClosePos");
    FileWrite(fh, IntegerToString(sets.ClosePos));
    FileWrite(fh, "Enforce");
    FileWrite(fh, IntegerToString(sets.Enforce));
    FileWrite(fh, "TurnedOn");
    FileWrite(fh, IntegerToString(sets.TurnedOn));
    FileWrite(fh, "Monday");
    FileWrite(fh, sets.Monday);
    FileWrite(fh, "Tuesday");
    FileWrite(fh, sets.Tuesday);
    FileWrite(fh, "Wednesday");
    FileWrite(fh, sets.Wednesday);
    FileWrite(fh, "Thursday");
    FileWrite(fh, sets.Thursday);
    FileWrite(fh, "Friday");
    FileWrite(fh, sets.Friday);
    FileWrite(fh, "Saturday");
    FileWrite(fh, sets.Saturday);
    FileWrite(fh, "Sunday");
    FileWrite(fh, sets.Sunday);
    FileWrite(fh, "LastToggleTime");
    FileWrite(fh, IntegerToString(sets.LastToggleTime));
    FileWrite(fh, "AllowDeny");
    FileWrite(fh, IntegerToString(sets.AllowDeny));
    FileWrite(fh, "LongTermSchedule");
    FileWrite(fh, sets.LongTermSchedule);

    // These are not part of settings but are panel-related input parameters.
    // When the EA is reloaded due to its input parameters change, these should be compared to the new values.
    // If the value is changed, it should be updated in the panel too.
    // Is the EA reloading due to the input parameters change?
    if (GlobalVariableGet("ATS-" + IntegerToString(ChartID()) + "-Parameters") > 0)
    {
        FileWrite(fh, "Parameter_DefaultTurnedOn");
        FileWrite(fh, IntegerToString(DefaultTurnedOn));
        FileWrite(fh, "Parameter_DefaultTime");
        FileWrite(fh, IntegerToString(DefaultTime));
        FileWrite(fh, "Parameter_DefaultMonday");
        FileWrite(fh, DefaultMonday);
        FileWrite(fh, "Parameter_DefaultTuesday");
        FileWrite(fh, DefaultTuesday);
        FileWrite(fh, "Parameter_DefaultWednesday");
        FileWrite(fh, DefaultWednesday);
        FileWrite(fh, "Parameter_DefaultThursday");
        FileWrite(fh, DefaultThursday);
        FileWrite(fh, "Parameter_DefaultFriday");
        FileWrite(fh, DefaultFriday);
        FileWrite(fh, "Parameter_DefaultSaturday");
        FileWrite(fh, DefaultSaturday);
        FileWrite(fh, "Parameter_DefaultSunday");
        FileWrite(fh, DefaultSunday);
        FileWrite(fh, "Parameter_DefaultClosePos");
        FileWrite(fh, IntegerToString(DefaultClosePos));
        FileWrite(fh, "Parameter_DefaultEnforce");
        FileWrite(fh, IntegerToString(DefaultEnforce));
        FileWrite(fh, "Parameter_DefaultAllowDeny");
        FileWrite(fh, IntegerToString(DefaultAllowDeny));
    }

    FileClose(fh);

    return true;
}

// Loads settings from a file to the panel.
bool CScheduler::LoadSettingsFromDisk()
{
    if (!FileIsExist(m_FileName)) return false;
    int fh = FileOpen(m_FileName, FILE_TXT | FILE_READ);
    if (fh == INVALID_HANDLE)
    {
        Print("Failed to open file for reading: " + m_FileName + ". Error: " + IntegerToString(GetLastError()));
        return false;
    }

    while (!FileIsEnding(fh))
    {
        string var_name = FileReadString(fh);
        string var_content = FileReadString(fh);
        if (var_name == "TimeType")
            sets.TimeType = (ENUM_TIME_TYPE)StringToInteger(var_content);
        else if (var_name == "ClosePos")
            sets.ClosePos = (bool)StringToInteger(var_content);
        else if (var_name == "Enforce")
            sets.Enforce = (bool)StringToInteger(var_content);
        else if (var_name == "TurnedOn")
            sets.TurnedOn = (bool)StringToInteger(var_content);
        else if (var_name == "Monday")
            sets.Monday = var_content;
        else if (var_name == "Tuesday")
            sets.Tuesday = var_content;
        else if (var_name == "Wednesday")
            sets.Wednesday = var_content;
        else if (var_name == "Thursday")
            sets.Thursday = var_content;
        else if (var_name == "Friday")
            sets.Friday = var_content;
        else if (var_name == "Saturday")
            sets.Saturday = var_content;
        else if (var_name == "Sunday")
            sets.Sunday = var_content;
        else if (var_name == "LastToggleTime")
            sets.LastToggleTime = (datetime)var_content;
        else if (var_name == "AllowDeny")
            sets.AllowDeny = (ENUM_ALLOWDENY)var_content;
        else if (var_name == "LongTermSchedule")
            sets.LongTermSchedule = var_content;
        // Is the expert advisor reloading due to the input parameters change?
        else if (GlobalVariableGet("ATS-" + IntegerToString(ChartID()) + "-Parameters") > 0)
        {
            // These are not part of settings but are panel-related input parameters.
            // When the expert advisor is reloaded due to its input parameters change, these should be compared to the new values.
            // If the value is changed, it should be updated in the panel too.
            if (var_name == "Parameter_DefaultTurnedOn")
            {
                if ((bool)StringToInteger(var_content) != DefaultTurnedOn) sets.TurnedOn = DefaultTurnedOn;
            }
            else if (var_name == "Parameter_DefaultTime")
            {
                if ((ENUM_TIME_TYPE)StringToInteger(var_content) != DefaultTime) sets.TimeType = DefaultTime;
            }
            else if (var_name == "Parameter_DefaultMonday")
            {
                if (var_content != DefaultMonday) sets.Monday = DefaultMonday;
            }
            else if (var_name == "Parameter_DefaultTuesday")
            {
                if (var_content != DefaultTuesday) sets.Tuesday = DefaultTuesday;
            }
            else if (var_name == "Parameter_DefaultWednesday")
            {
                if (var_content != DefaultWednesday) sets.Wednesday = DefaultWednesday;
            }
            else if (var_name == "Parameter_DefaultThursday")
            {
                if (var_content != DefaultThursday) sets.Thursday = DefaultThursday;
            }
            else if (var_name == "Parameter_DefaultFriday")
            {
                if (var_content != DefaultFriday) sets.Friday = DefaultFriday;
            }
            else if (var_name == "Parameter_DefaultSaturday")
            {
                if (var_content != DefaultSaturday) sets.Saturday = DefaultSaturday;
            }
            else if (var_name == "Parameter_DefaultSunday")
            {
                if (var_content != DefaultSunday) sets.Sunday = DefaultSunday;
            }
            else if (var_name == "Parameter_DefaultClosePos")
            {
                if ((bool)StringToInteger(var_content) != DefaultClosePos) sets.ClosePos = DefaultClosePos;
            }
            else if (var_name == "Parameter_DefaultEnforce")
            {
                if ((bool)StringToInteger(var_content) != DefaultEnforce) sets.Enforce = DefaultEnforce;
            }
            else if (var_name == "Parameter_DefaultAllowDeny")
            {
                if ((ENUM_ALLOWDENY)StringToInteger(var_content) != DefaultAllowDeny) sets.AllowDeny = DefaultAllowDeny;
            }
        }
    }

    // To avoid keeping the FILE schedule when we remove or change the Schedule File.
    if (m_EdtMonday.ReadOnly())
    {
        sets.Monday = "";
        m_EdtMonday.Text("");
        m_EdtMonday.ReadOnly(false);
        m_EdtMonday.ColorBackground(clrWhite);
    }
    if (m_EdtTuesday.ReadOnly())
    {
        sets.Tuesday = "";
        m_EdtTuesday.Text("");
        m_EdtTuesday.ReadOnly(false);
        m_EdtTuesday.ColorBackground(clrWhite);
    }
    if (m_EdtWednesday.ReadOnly())
    {
        sets.Wednesday = "";
        m_EdtWednesday.Text("");
        m_EdtWednesday.ReadOnly(false);
        m_EdtWednesday.ColorBackground(clrWhite);
    }
    if (m_EdtThursday.ReadOnly())
    {
        sets.Thursday = "";
        m_EdtThursday.Text("");
        m_EdtThursday.ReadOnly(false);
        m_EdtThursday.ColorBackground(clrWhite);
    }
    if (m_EdtFriday.ReadOnly())
    {
        sets.Friday = "";
        m_EdtFriday.Text("");
        m_EdtFriday.ReadOnly(false);
        m_EdtFriday.ColorBackground(clrWhite);
    }
    if (m_EdtSaturday.ReadOnly())
    {
        sets.Saturday = "";
        m_EdtSaturday.Text("");
        m_EdtSaturday.ReadOnly(false);
        m_EdtSaturday.ColorBackground(clrWhite);
    }
    if (m_EdtSunday.ReadOnly())
    {
        sets.Sunday = "";
        m_EdtSunday.Text("");
        m_EdtSunday.ReadOnly(false);
        m_EdtSunday.ColorBackground(clrWhite);
    }

    FileClose(fh);

    // Is expert advisor reloading due to the input parameters change? Delete the flag variable.
    if (GlobalVariableGet("ATS-" + IntegerToString(ChartID()) + "-Parameters") > 0) GlobalVariableDel("ATS-" + IntegerToString(ChartID()) + "-Parameters");

    return true;
}

// Deletes the settings file.
bool CScheduler::DeleteSettingsFile()
{
    if (!FileIsExist(m_FileName)) return false;
    if (!FileDelete(m_FileName))
    {
        Print("Failed to delete file: " + m_FileName + ". Error: " + IntegerToString(GetLastError()));
        return false;
    }
    return true;
}

bool CScheduler::LoadScheduleFile()
{
    if (!FileIsExist(ScheduleFile))
    {
        Print("Schedule file not found: ", ScheduleFile, ".");
        return false;
    }
    int fh = FileOpen(ScheduleFile, FILE_TXT | FILE_READ | FILE_ANSI);
    if (fh == INVALID_HANDLE)
    {
        Print("Failed to open file for reading: " + ScheduleFile + ". Error: " + IntegerToString(GetLastError()));
        return false;
    }

    sets.LongTermSchedule = ""; // Will be updated if a date is found.
    Print("Reading schedule from file: ", ScheduleFile, ".");
    while (!FileIsEnding(fh))
    {
        string weekday = FileReadString(fh);
        string schedule = FileReadString(fh);
        if ((weekday == "Monday") || (weekday == "Mon"))
        {
            sets.Monday = schedule;
            m_EdtMonday.ReadOnly(true);
            m_EdtMonday.ColorBackground(CONTROLS_EDIT_COLOR_DISABLE);
        }
        else if ((weekday == "Tuesday") || (weekday == "Tue"))
        {
            sets.Tuesday = schedule;
            m_EdtTuesday.ReadOnly(true);
            m_EdtTuesday.ColorBackground(CONTROLS_EDIT_COLOR_DISABLE);
        }
        else if ((weekday == "Wednesday") || (weekday == "Wed"))
        {
            sets.Wednesday = schedule;
            m_EdtWednesday.ReadOnly(true);
            m_EdtWednesday.ColorBackground(CONTROLS_EDIT_COLOR_DISABLE);
        }
        else if ((weekday == "Thursday") || (weekday == "Thu"))
        {
            sets.Thursday = schedule;
            m_EdtThursday.ReadOnly(true);
            m_EdtThursday.ColorBackground(CONTROLS_EDIT_COLOR_DISABLE);
        }
        else if ((weekday == "Friday") || (weekday == "Fri"))
        {
            sets.Friday = schedule;
            m_EdtFriday.ReadOnly(true);
            m_EdtFriday.ColorBackground(CONTROLS_EDIT_COLOR_DISABLE);
        }
        else if ((weekday == "Saturday") || (weekday == "Sat"))
        {
            sets.Saturday = schedule;
            m_EdtSaturday.ReadOnly(true);
            m_EdtSaturday.ColorBackground(CONTROLS_EDIT_COLOR_DISABLE);
        }
        else if ((weekday == "Sunday") || (weekday == "Sun"))
        {
            sets.Sunday = schedule;
            m_EdtSunday.ReadOnly(true);
            m_EdtSunday.ColorBackground(CONTROLS_EDIT_COLOR_DISABLE);
        }
        // Not a weekday?
        else if (IsWeekdayADate(weekday))
        {
            if (sets.LongTermSchedule != "") sets.LongTermSchedule += "|"; // Delimiter between dates.
            sets.LongTermSchedule += weekday + "~" + schedule;
        }
        Print(weekday);
        Print(schedule);
    }
    FileClose(fh);

    if (sets.LongTermSchedule != "") // Loaded a long-term schedule.
    {
        // Disable all day entries.
        m_EdtMonday.Text("<<FILE>>");
        m_EdtMonday.ReadOnly(true);
        m_EdtMonday.ColorBackground(CONTROLS_EDIT_COLOR_DISABLE);
        m_EdtTuesday.Text("<<FILE>>");
        m_EdtTuesday.ReadOnly(true);
        m_EdtTuesday.ColorBackground(CONTROLS_EDIT_COLOR_DISABLE);
        m_EdtWednesday.Text("<<FILE>>");
        m_EdtWednesday.ReadOnly(true);
        m_EdtWednesday.ColorBackground(CONTROLS_EDIT_COLOR_DISABLE);
        m_EdtThursday.Text("<<FILE>>");
        m_EdtThursday.ReadOnly(true);
        m_EdtThursday.ColorBackground(CONTROLS_EDIT_COLOR_DISABLE);
        m_EdtFriday.Text("<<FILE>>");
        m_EdtFriday.ReadOnly(true);
        m_EdtFriday.ColorBackground(CONTROLS_EDIT_COLOR_DISABLE);
        m_EdtSaturday.Text("<<FILE>>");
        m_EdtSaturday.ReadOnly(true);
        m_EdtSaturday.ColorBackground(CONTROLS_EDIT_COLOR_DISABLE);
        m_EdtSunday.Text("<<FILE>>");
        m_EdtSunday.ReadOnly(true);
        m_EdtSunday.ColorBackground(CONTROLS_EDIT_COLOR_DISABLE);
        ProcessLongTermSchedule();
    }
    else ProcessWeeklySchedule(); // Loaded a weekly schedule.

    SaveSettingsOnDisk();

    return true;
}

void CScheduler::HideShowMaximize()
{
    // Remember the panel's location.
    remember_left = Left();
    remember_top = Top();

    Hide();
    Show();
    NoPanelMaximization = true;
    Maximize();
    NoPanelMaximization = false;
}

//+------------------------------------------------+
//|                                                |
//|              Operational Functions             |
//|                                                |
//+------------------------------------------------+

// Check if enabling/disabling is due.
void CScheduler::CheckTimer()
{
    if (!sets.TurnedOn) return;

    datetime time;
    ENUM_TOGGLE toggle = TOGGLE_DONT_TOGGLE; // Will be switched to either Toggle OFF or Toggle ON in Enforce mode or might be left in Don't Toggle state for non-Enforce mode.

    if (sets.TimeType == Local) time = TimeLocal();
    else time = TimeCurrent();

    toggle = CompareTime(time);
    if (sets.AllowDeny == ALLOWDENY_DENY) // If the schedule is set for denying instead of allowing, invert the signal.
    {
        if (toggle == TOGGLE_TOGGLE_OFF) toggle = TOGGLE_TOGGLE_ON;
        else if (toggle == TOGGLE_TOGGLE_ON) toggle = TOGGLE_TOGGLE_OFF;
    }
    if ((toggle == TOGGLE_TOGGLE_OFF) && (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)))
    {
        if (StartedToggling) return;
        StartedToggling = true;
        sets.LastToggleTime = time;
        int n_closed = 0;
        int n_deleted = 0;
        if (sets.ClosePos)
        {
            n_closed = Close_All_Positions();
            n_deleted = Delete_All_Pending_Orders();
        }
        if (((WaitForNoPositions) && (ExistsPosition())) || ((WaitForNoOrders) && (ExistsOrder())))
        {
            StartedToggling = false;
            return;
        }
        if (IsANeedToContinueClosingPositions) Print("Not all positions have been closed! Disabling AutoTrading anyway.");
        if (IsANeedToContinueDeletingPendingOrders) Print("Not all pending orders have been deleted! Disabling AutoTrading anyway.");
        Toggle_AutoTrading();
        Notify(n_closed, n_deleted, false);
        StartedToggling = false;
        return;
    }

    if ((toggle == TOGGLE_TOGGLE_ON) && (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)))
    {
        if (StartedToggling) return;
        StartedToggling = true;
        sets.LastToggleTime = time;
        Toggle_AutoTrading();
        Notify(0, 0, true);
        StartedToggling = false;
    }
}

// Checks EA status.
void CScheduler::Check_Status()
{
    string s = "";

    if (!TerminalInfoInteger(TERMINAL_CONNECTED))
    {
        s += " No connection";
    }
    if ((!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) && (sets.ClosePos))
    {
        if (s != "") s += ",";
        s += " No autotrading";
    }
    else if (!MQLInfoInteger(MQL_DLLS_ALLOWED))
    {
        if (s != "") s += ",";
        s += " DLLs disabled";
    }
    if (s == "") m_LblStatus.Text("Status: OK.");
    else m_LblStatus.Text("Status:" + s + ".");
}

ENUM_TOGGLE CScheduler::CompareTime(const datetime time)
{
    if (Schedule.Total() == 0) // No schedule yet.
    {
        if (sets.Enforce) return TOGGLE_TOGGLE_OFF;
        return TOGGLE_DONT_TOGGLE;
    }
    for (CTimeStamp *ts = Schedule.GetFirstNode(); ts != NULL; ts = Schedule.GetNextNode())
    {
        if (time < ts.time) // Found the nearest future timestamp.
        {
            if (sets.Enforce)
            {
                if (ts.enable == false) return TOGGLE_TOGGLE_ON; // If that timestamp is for toggling OFF, then the current period is ON.
                else return TOGGLE_TOGGLE_OFF; // If that timestamp is for toggling OFF, then the current period is ON.
            }
            else // Do not enforce. Switch only once per period.
            {
                // If both current time and last toggle time are inside the same period, then don't toggle again:
                if (sets.LastToggleTime < ts.time)
                {
                    CTimeStamp *ts_prev = Schedule.GetPrevNode();
                    if (ts_prev.time <= sets.LastToggleTime) return TOGGLE_DONT_TOGGLE; // Already toggled during this period.
                }
                if (ts.enable == false) return TOGGLE_TOGGLE_ON; // If that timestamp is for toggling OFF, then the current period is ON.
                else return TOGGLE_TOGGLE_OFF; // If that timestamp is for toggling OFF, then the current period is ON.
            }
            break;
        }
        if (Schedule.IndexOf(ts) == Schedule.Total() - 1) // Came to the last node - the schedule ended before current time.
        {
            if (sets.Enforce) return TOGGLE_TOGGLE_OFF; // Schedule ended. Turn everything OFF.
            else // Do not enforce. Switch only if there wasn't any switch during this period.
            {
                if (sets.LastToggleTime < ts.time) return TOGGLE_TOGGLE_OFF; // Schedule ended. Turn everything OFF.
                return TOGGLE_DONT_TOGGLE; // Otherwise - don't toggle.
            }
        }
    }
    return TOGGLE_DONT_TOGGLE;
}


void CScheduler::Toggle_AutoTrading()
{
    // Toggle AutoTrading button. "2" in GetAncestor call is the "root window".
    PostMessageA(GetAncestor((int)ChartGetInteger(0, CHART_WINDOW_HANDLE), 2/*GA_ROOT*/), WM_COMMAND, 32851, 0);
    Print("AutoTrading toggled by Scheduler.");
}

// Closes all positions.
int CScheduler::Close_All_Positions()
{
    int error = -1;
    bool AreAllPositionsClosed = true;

    IsANeedToContinueClosingPositions = false;

    if ((!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) || (!TerminalInfoInteger(TERMINAL_CONNECTED)) || (!MQLInfoInteger(MQL_TRADE_ALLOWED)))
    {
        if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) Print("AutoTrading disabled (platform)!");
        if (!TerminalInfoInteger(TERMINAL_CONNECTED)) Print("No connection!");
        if (!MQLInfoInteger(MQL_TRADE_ALLOWED)) Print("AutoTrading disabled (EA)!");
        return 0;
    }

    // Closing positions.
    int total = PositionsTotal();
    for (int i = total - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket <= 0)
        {
            error = GetLastError();
            Print("AutoTrading Scheduler: PositionGetTicket failed " + IntegerToString(error) + ".");
            IsANeedToContinueClosingPositions = true;
            continue;
        }
        
        if (CheckFilterMagic(PositionGetInteger(POSITION_MAGIC))) continue; // Skip if the magic number filter says to.

        if (SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_DISABLED)
        {
            Print("AutoTrading Scheduler: Trading disabled by broker for symbol " + PositionGetString(POSITION_SYMBOL) + ".");
            IsANeedToContinueClosingPositions = true;
            continue;
        }
        else
        {
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            {
                error = Close_Current_Position(ticket);
                if (error != 0) Print("AutoTrading Scheduler: PositionClose Buy failed. Error #" + IntegerToString(error));
            }
            else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            {
                error = Close_Current_Position(ticket);
                if (error != 0) Print("AutoTrading Scheduler: PositionClose Sell failed. Error #" + IntegerToString(error));
            }
        }
    }

    // Check if all positions have been eliminated.
    if (!IsANeedToContinueClosingPositions) return total;

    AreAllPositionsClosed = true;

    int new_total = PositionsTotal();
    for (int i = new_total - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket <= 0)
        {
            error = GetLastError();
            Print("AutoTrading Scheduler: PositionGetTicket failed " + IntegerToString(error));
            continue;
        }
        if ((PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) || (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL))
        {
            if (CheckFilterMagic(PositionGetInteger(POSITION_MAGIC))) continue; // Skip if the magic number filter says to.
            AreAllPositionsClosed = false;
            break;
        }
        if (!AreAllPositionsClosed) break;
    }

    if (AreAllPositionsClosed) IsANeedToContinueClosingPositions = false;
    
    return new_total;
}

// Closes a position by its ticket.
int CScheduler::Close_Current_Position(ulong ticket)
{
    MqlTradeRequest request;
    MqlTradeResult  result;

    string position_symbol = PositionGetString(POSITION_SYMBOL);
    int    digits = (int)SymbolInfoInteger(position_symbol, SYMBOL_DIGITS);
    ulong  magic = PositionGetInteger(POSITION_MAGIC);
    double volume = PositionGetDouble(POSITION_VOLUME);
    ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

    ZeroMemory(request);
    ZeroMemory(result);

    request.action    = TRADE_ACTION_DEAL;
    request.position  = ticket;
    request.symbol    = position_symbol;
    request.volume    = volume;
    request.deviation = Slippage;
    request.magic     = PositionGetInteger(POSITION_MAGIC);
    long type_filling = SymbolInfoInteger(position_symbol, SYMBOL_FILLING_MODE);
    if (type_filling == 1)
        request.type_filling = ORDER_FILLING_FOK;
    else if (type_filling == 2)
        request.type_filling = ORDER_FILLING_IOC;

    if (type == POSITION_TYPE_BUY)
    {
        request.price = SymbolInfoDouble(position_symbol, SYMBOL_BID);
        request.type = ORDER_TYPE_SELL;
    }
    else
    {
        request.price = SymbolInfoDouble(position_symbol, SYMBOL_ASK);
        request.type  = ORDER_TYPE_BUY;
    }

    string action = "closed";
    if (AsyncMode)
    {
        if (!OrderSendAsync(request, result))
        {
            IsANeedToContinueClosingPositions = true;
            return GetLastError();
        }
        action = "sent for closing asynchronously";
    }
    else
    {
        if (!OrderSend(request, result))
        {
            IsANeedToContinueClosingPositions = true;
            return GetLastError();
        }
    }
    if (type == POSITION_TYPE_BUY)
        Print("AutoTrading Scheduler: " + PositionGetString(POSITION_SYMBOL) + " Buy position #" + IntegerToString(ticket) + "; Lotsize = " + DoubleToString(PositionGetDouble(POSITION_VOLUME), 2) + ", OpenPrice = " + DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN), (int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_DIGITS)) + ", SL = " + DoubleToString(PositionGetDouble(POSITION_SL), (int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_DIGITS)) + ", TP = " + DoubleToString(PositionGetDouble(POSITION_TP), (int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_DIGITS)) + " was " + action + " at " + DoubleToString(SymbolInfoDouble(PositionGetString(POSITION_SYMBOL), SYMBOL_BID), (int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_DIGITS)) + ".");
    else if (type == POSITION_TYPE_SELL)
        Print("AutoTrading Scheduler: " + PositionGetString(POSITION_SYMBOL) + " Sell position #" + IntegerToString(ticket) + "; Lotsize = " + DoubleToString(PositionGetDouble(POSITION_VOLUME), 2) + ", OpenPrice = " + DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN), (int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_DIGITS)) + ", SL = " + DoubleToString(PositionGetDouble(POSITION_SL), (int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_DIGITS)) + ", TP = " + DoubleToString(PositionGetDouble(POSITION_TP), (int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_DIGITS)) + " was " + action + " at " + DoubleToString(SymbolInfoDouble(PositionGetString(POSITION_SYMBOL), SYMBOL_ASK), (int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_DIGITS)) + ".");

    return 0;
}

// Deletes all pending orders.
int CScheduler::Delete_All_Pending_Orders()
{
    int error = -1;
    bool AreAllOrdersDeleted = true;

    IsANeedToContinueDeletingPendingOrders = false;

    if ((!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) || (!TerminalInfoInteger(TERMINAL_CONNECTED)) || (!MQLInfoInteger(MQL_TRADE_ALLOWED)))
    {
        if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) Print("AutoTrading disabled!");
        if (!TerminalInfoInteger(TERMINAL_CONNECTED)) Print("No connection!");
        if (!MQLInfoInteger(MQL_TRADE_ALLOWED)) Print("Trade not allowed!");
        return 0;
    }

    // Closing market orders.
    int total = OrdersTotal();
    for (int i = total - 1; i >= 0; i--)
    {
        ulong ticket = OrderGetTicket(i);
        if (ticket <= 0)
        {
            error = GetLastError();
            Print("AutoTrading Scheduler: OrderSelect failed " + IntegerToString(error) + ".");
            IsANeedToContinueDeletingPendingOrders = true;
        }
        
        
        if (CheckFilterMagic(OrderGetInteger(ORDER_MAGIC))) continue; // Skip if the magic number filter says to.
        if (SymbolInfoInteger(OrderGetString(ORDER_SYMBOL), SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_DISABLED)
        {
            Print("AutoTrading Scheduler: Trading disabled by broker for symbol " + OrderGetString(ORDER_SYMBOL) + ".");
            IsANeedToContinueDeletingPendingOrders = true;
            continue;
        }
        else
        {
            if ((OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_LIMIT) || (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_LIMIT) || (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP) || (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_STOP) || (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP_LIMIT) || (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_STOP_LIMIT))
            {
                error = Delete_Current_Pending_Order(ticket);
                if (error != 0) Print("AutoTrading Scheduler: OrderDelete failed. Error #" + IntegerToString(error));
                else
                {
                    string action = "deleted";
                    if (AsyncMode) action = "sent asynchronously for deletion";
                    Print("AutoTrading Scheduler: " + OrderGetString(ORDER_SYMBOL) + " Pending order #" + IntegerToString(ticket) + "; Lotsize = " + DoubleToString(OrderGetDouble(ORDER_VOLUME_CURRENT), 2) + ", OpenPrice = " + DoubleToString(OrderGetDouble(ORDER_PRICE_OPEN), (int)SymbolInfoInteger(OrderGetString(ORDER_SYMBOL), SYMBOL_DIGITS)) + ", SL = " + DoubleToString(OrderGetDouble(ORDER_SL), (int)SymbolInfoInteger(OrderGetString(ORDER_SYMBOL), SYMBOL_DIGITS)) + ", TP = " + DoubleToString(OrderGetDouble(ORDER_TP), (int)SymbolInfoInteger(OrderGetString(ORDER_SYMBOL), SYMBOL_DIGITS)) + " was " + action + ".");
                }
            }
        }
    }

    // Check if all orders have been eliminated.
    if (!IsANeedToContinueDeletingPendingOrders) return total;

    AreAllOrdersDeleted = true;

    int new_total = OrdersTotal();
    for (int i = new_total - 1; i >= 0; i--)
    {
        ulong ticket = OrderGetTicket(i);
        if (ticket <= 0)
        {
            error = GetLastError();
            Print("AutoTrading Scheduler: OrderSelect failed " + IntegerToString(error) + ".");
            continue;
        }

        if ((OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_LIMIT) || (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_LIMIT) || (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP) || (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_STOP) || (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY_STOP_LIMIT) || (OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL_STOP_LIMIT))
        {
            if (CheckFilterMagic(OrderGetInteger(ORDER_MAGIC))) continue; // Skip if the magic number filter says to.
            AreAllOrdersDeleted = false;
            break;
        }

        if (!AreAllOrdersDeleted) break;
    }

    if (AreAllOrdersDeleted) IsANeedToContinueDeletingPendingOrders = false;
    
    return new_total;
}

// Deletes a pending order by its ticket.
int CScheduler::Delete_Current_Pending_Order(ulong ticket)
{
    int error = -1;

    MqlTradeRequest request;
    MqlTradeResult  result;

    ZeroMemory(request);
    ZeroMemory(result);

    request.action = TRADE_ACTION_REMOVE;
    request.order  = ticket;

    if (AsyncMode)
    {
        if (!OrderSendAsync(request, result))
        {
            IsANeedToContinueDeletingPendingOrders = true;
            return GetLastError();
        }
    }
    else
    {
        if (!OrderSend(request, result))
        {
            IsANeedToContinueDeletingPendingOrders = true;
            return GetLastError();
        }
    }
    return 0;
}

// Issue relevant alerts.
// count_closed: how many positions have been closed.
// count_deleted: how many orders have been deleted.
// enable_or_disable: true - autotrading has been enabled; false - autotrading has been disabled.
void CScheduler::Notify(const int count_closed, const int count_deleted, const bool enable_or_disable)
{
    if ((!EnableNativeAlerts) && (!EnableEmailAlerts) && (!EnablePushAlerts)) return;

    string Text, EmailSubject, EmailBody, AlertText, AppText;

    if (enable_or_disable == false) // Disabled autotrading.
    {
        Text = "Disabled autotrading.";
        EmailSubject = "AutoTrading Scheduler: toggled AutoTrading OFF";
        if (sets.ClosePos)
        {
            Text += " Closed " + IntegerToString(count_closed) + " positions, deleted " + IntegerToString(count_deleted) + " orders.";
            EmailSubject += " (Closed " + IntegerToString(count_closed) + " positions, deleted " + IntegerToString(count_deleted) + " orders)";
        }
        EmailBody = AccountInfoString(ACCOUNT_COMPANY) + " - " + AccountInfoString(ACCOUNT_NAME) + " - " + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) + "\r\n" + "AutoTrading Scheduler: ";
        AlertText = "";
        AppText = AccountInfoString(ACCOUNT_COMPANY) + " - " + AccountInfoString(ACCOUNT_NAME) + " - " + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) + " AutoTrading Scheduler: ";
   
    }
    else // Enabled autotrading.
    {
        Text = "Enabled autotrading.";
        EmailSubject = "AutoTrading Scheduler: toggled AutoTrading ON";
        EmailBody = AccountInfoString(ACCOUNT_COMPANY) + " - " + AccountInfoString(ACCOUNT_NAME) + " - " + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) + "\r\n" + "AutoTrading Scheduler: ";
        AlertText = "";
        AppText = AccountInfoString(ACCOUNT_COMPANY) + " - " + AccountInfoString(ACCOUNT_NAME) + " - " + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) + " AutoTrading Scheduler: ";
    }

    EmailBody += Text;
    AlertText += Text;
    AppText += Text;

    if (EnableNativeAlerts) Alert(AlertText);
    if (EnableEmailAlerts)
    {
        if (!SendMail(EmailSubject, EmailBody)) Print("Error sending email: " + IntegerToString(GetLastError()));
    }
    if (EnablePushAlerts)
    {
        if (!SendNotification(AppText)) Print("Error sending notification: " + IntegerToString(GetLastError()));
    }
}

// Returns true if at least one position is open (filtered by magic numbers).
bool CScheduler::ExistsPosition()
{
    int total = PositionsTotal();
    for (int i = 0; i < total; i++)
    {
        if (PositionGetTicket(i) > 0)
        {
            if (CheckFilterMagic(PositionGetInteger(POSITION_MAGIC))) continue; // Skip if the magic number filter says to.
            else return true;
        }
    }
    return false;    
}

// Returns true if there is at least one pending order (filtered by magic numbers).
bool CScheduler::ExistsOrder()
{
    int total = OrdersTotal();
    for (int i = 0; i < total; i++)
    {
        if (OrderGetTicket(i) > 0)
        {
            if (CheckFilterMagic(OrderGetInteger(ORDER_MAGIC))) continue; // Skip if the magic number filter says to.
            else return true;
        }
    }
    return false;   
}

int CScheduler::AddTimeStamp(CTimeStamp *new_node)
{
    // Check if a node with the time exists. If it exists, don't add the new node and delete the existing one.
    for (CTimeStamp *ts = Schedule.GetFirstNode(); ts != NULL; ts = Schedule.GetNextNode())
    {
        if (ts.time == new_node.time) // An existing node with the same time found.
        {
            Schedule.DeleteCurrent(); // Delete the existing node.
            return Schedule.Total(); // Return the number of nodes after deletion.
        }
    }
    // Existing node with the same time wasn't found at this point.
    Schedule.Add(new_node); // Add the new node.
    
    return Schedule.Total(); // Return the number of nodes after adding the new one to the list.
}

// Returns true if order should be filtered out based on its magic number and filter settings.
bool CScheduler::CheckFilterMagic(const long magic)
{
    int total = ArraySize(MagicNumbers_array);
    if (total == 0) return false; // Empty array - don't filter.

    for (int i = 0; i < total; i++)
    {
        // Skip order if its magic number is in the array, and "Ignore" option is turned on.
        if ((magic == MagicNumbers_array[i]) && (IgnoreMagicNumbers)) return true;
        // Do not skip order if its magic number is in the array, and "Ignore" option is turned off.
        if ((magic == MagicNumbers_array[i]) && (!IgnoreMagicNumbers)) return false;
    }

    if (IgnoreMagicNumbers) return false; // If not found in the array and should ignore listed magic numbers, then default ruling is - don't filter out this order.
    else return true;
}

int TimeSeconds(const datetime date)
{
    MqlDateTime dt;
    TimeToStruct(date, dt);
    return dt.sec;
}

int TimeMinute(const datetime date)
{
    MqlDateTime dt;
    TimeToStruct(date, dt);
    return dt.min;
}

int TimeHour(const datetime date)
{
    MqlDateTime dt;
    TimeToStruct(date, dt);
    return dt.hour;
}

int TimeDayOfWeek(const datetime date)
{
    MqlDateTime dt;
    TimeToStruct(date, dt);
    return dt.day_of_week;
}

int TimeDay(const datetime date)
{
    MqlDateTime dt;
    TimeToStruct(date, dt);
    return dt.day;
}

// Returns true if weekday is actually a date for a long-term schedule.
bool IsWeekdayADate(const string wd)
{
    for (int i = 0; i < StringLen(wd); i++)
        if ((wd[i] >= '0') && (wd[i] <= '9')) return true;
    return false;
}
//+------------------------------------------------------------------+