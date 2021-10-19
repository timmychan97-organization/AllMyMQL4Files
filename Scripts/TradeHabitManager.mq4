//+------------------------------------------------------------------+
//|                                            TradeHabitManager.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
#include "Header/TradeHabit.mqh"

int maxLossCount = 4;


TradeHabit * habits[30];
int habitsCount = 0;
void OnStart()
  {
//---
   
   
  }
//+------------------------------------------------------------------+

void CreateNewHabit(){
   habits[habitsCount] = new TradeHabit(maxLossCount);
   habitsCount += 1;
}