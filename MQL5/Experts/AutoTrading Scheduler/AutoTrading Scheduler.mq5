#property copyright "EarnForex.com"
#property link      "https://www.earnforex.com/metatrader-expert-advisors/AutoTrading-Scheduler/"
#property version   "1.03"
string    Version = "1.03";
#property strict

#property description "Creates a weekly schedule when AutoTrading is enabled."
#property description "Disables AutoTrading during all other times."
#property description "Time is in 24h timeframe. Empty line means disabled trading."
#property description "Can also close all trades before disabling AutoTrading.\r\n"
#property description "WARNING: There is no guarantee that the expert advisor will work as intended. Use at your own risk."
#property icon        "EF-Icon-64x64px.ico"

#include "AutoTrading Scheduler.mqh";

input group "Notifications"
input bool EnableNativeAlerts = false;
input bool EnableEmailAlerts = false;
input bool EnablePushAlerts = false;
input group "Defaults"
input bool DefaultTurnedOn = false; // Default state of the scheduler: ON or OFF
input ENUM_TIME_TYPE DefaultTime = Local; // Default time type
input string DefaultMonday = ""; // Default enabled Monday periods
input string DefaultTuesday = ""; // Default enabled Tuesday periods
input string DefaultWednesday = ""; // Default enabled Wednesday periods
input string DefaultThursday = ""; // Default enabled Thursday periods
input string DefaultFriday = ""; // Default enabled Friday periods
input string DefaultSaturday = ""; // Default enabled Saturday periods
input string DefaultSunday = ""; // Default enabled Sunday periods
input bool DefaultClosePos = false; // Close all positions before turning AutoTrading OFF?
input bool DefaultEnforce = true; // Always enforce schedule?
input ENUM_ALLOWDENY DefaultAllowDeny = ALLOWDENY_ALLOW; // Schedule for allowing or denying AutoTrading?
input group "Miscellaneous"
input int Slippage = 2; // Slippage
input string ScheduleFile = ""; // ScheduleFile (optional)
input bool WaitForNoPositions = false; // Switch A/T off only when there are no open positions?
input bool WaitForNoOrders = false; // Switch A/T off only when there are no pending orders?

CScheduler Panel;

int DeinitializationReason = -1;

//+------------------------------------------------------------------+
//| Initialization function                                          |
//+------------------------------------------------------------------+
int OnInit()
{
    if (DeinitializationReason != REASON_CHARTCHANGE)
    {
        if (!Panel.LoadSettingsFromDisk())
        {
            sets.TurnedOn = DefaultTurnedOn;
            sets.TimeType = DefaultTime;
            sets.Monday = DefaultMonday;
            sets.Tuesday = DefaultTuesday;
            sets.Wednesday = DefaultWednesday;
            sets.Thursday = DefaultThursday;
            sets.Friday = DefaultFriday;
            sets.Saturday = DefaultSaturday;
            sets.Sunday = DefaultSunday;
            sets.Enforce = DefaultEnforce;
            sets.ClosePos = DefaultClosePos;
            sets.LastToggleTime = 0;
            sets.AllowDeny = DefaultAllowDeny;
            sets.LongTermSchedule = "";
        }

        if (!Panel.Create(0, "AutoTrading Scheduler (ver. " + Version + ")", 0, 20, 20)) return(-1);
        Panel.Run();
        Panel.IniFileLoad();

        if (ScheduleFile != "") Panel.LoadScheduleFile();

        // Brings panel on top of other objects without actual maximization of the panel.
        Panel.HideShowMaximize();
    
        Panel.RefreshPanelControls();
        Panel.RefreshValues();
    }

    EventSetTimer(1);

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Deinitialization function                                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    DeinitializationReason = reason; // Remember reason to avoid recreating the panel in the OnInit() if it is not deleted here.
    EventKillTimer();
    if ((reason == REASON_REMOVE) || (reason == REASON_CHARTCLOSE) || (reason == REASON_PROGRAM))
    {
        Panel.DeleteSettingsFile();
        Print("Trying to delete ini file.");
        if (!FileIsExist(Panel.IniFileName() + ".dat")) Print("File doesn't exist.");
        else if (!FileDelete(Panel.IniFileName() + ".dat")) Print("Failed to delete file: " + Panel.IniFileName() + ".dat. Error: " + IntegerToString(GetLastError()));
        else Print("Deleted ini file successfully.");
    }
    else if (reason != REASON_CHARTCHANGE)
    {
        // It is deinitialization due to input parameters change - save current parameters values (that are also changed via panel) to global variables.
        if (reason == REASON_PARAMETERS) GlobalVariableSet("ATS-" + IntegerToString(ChartID()) + "-Parameters", 1);
        Panel.SaveSettingsOnDisk();
        Panel.IniFileSave();
    }

    if (reason != REASON_CHARTCHANGE) Panel.Destroy();
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    // Remember the panel's location to have the same location for minimized and maximized states.
    if ((id == CHARTEVENT_CUSTOM + ON_DRAG_END) && (lparam == -1))
    {
        Panel.remember_top = Panel.Top();
        Panel.remember_left = Panel.Left();
    }

    // Call Panel's event handler only if it is not a CHARTEVENT_CHART_CHANGE - workaround for minimization bug on chart switch.
    if (id != CHARTEVENT_CHART_CHANGE) Panel.OnEvent(id, lparam, dparam, sparam);

    // Handle a potential panel-out-of-view situation.
    if ((id == CHARTEVENT_CLICK) || (id == CHARTEVENT_CHART_CHANGE))
    {
        static bool prev_chart_on_top = false;
        // If this is an active chart, make sure the panel is visible (not behind the chart's borders). For inactive chart, this will work poorly, because inactive charts get minimized by MetaTrader.
        if (ChartGetInteger(ChartID(), CHART_BRING_TO_TOP))
        {
            if (Panel.Top() < 0) Panel.Move(Panel.Left(), 0);
            int chart_height = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
            if (Panel.Top() > chart_height) Panel.Move(Panel.Left(), chart_height - Panel.Height());
            int chart_width = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
            if (Panel.Left() > chart_width) Panel.Move(chart_width - Panel.Width(), Panel.Top());
        }
        // Remember if the chart is on top or is minimized.
        prev_chart_on_top = ChartGetInteger(ChartID(), CHART_BRING_TO_TOP);
    }

    if (Panel.Top() < 0) Panel.Move(Panel.Left(), 0);
    ChartRedraw();
}

void OnTick()
{
    Panel.RefreshValues();
    Panel.CheckTimer();
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Timer event handler                                              |
//+------------------------------------------------------------------+
void OnTimer()
{
    Panel.RefreshValues();
    Panel.CheckTimer();
    ChartRedraw();
}
//+------------------------------------------------------------------+