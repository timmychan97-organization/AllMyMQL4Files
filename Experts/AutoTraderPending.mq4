//+------------------------------------------------------------------+
//|                                            AutoTraderPending.mq4 |
//|                                                       FancyGamer |
//|                                            fancygamer.weebly.com |
//+------------------------------------------------------------------+
#property copyright "FancyGamer"
#property link      "fancygamer.weebly.com"
#property version   "1.00"
#property strict

#include "Header/getSymbolDetails.mqh"
#include "Header/getOrderDetails.mqh"

//--- input parameters
input int      tpPercentage=4;
input int      slPercentage=1;
input int      timeOfDay=12;
input int      timespan=8;
input string   timeOfDate="12:00"; //it is the server time!!!!!!!!!!!
//uses current timeframe for this

double pip = 0.0001;

//+-Scriptside variables---------------------------------------------+
int waitingTime = 4; //seconds for next iteration
string basePair;
string quotePair;
string accountCurrency = AccountCurrency();
int accountLeverage = AccountLeverage();

double curBuyPendingPrice, curBuyTP, curBuySL;
double curSellPendingPrice, curSellTP, curSellSL;
double lossCount = 0; //if it reaches (tpPercentage/slPercentage) + 1   //iaw 5


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
   
   basePair = getPairString(Symbol(),"base",accountCurrency);
   quotePair = getPairString(Symbol(),"quote",accountCurrency);
   
   
   
   
   
   datetime todayAt0 = TimeCurrent() - (TimeCurrent()%(60*60*24)); //today at 00:00:00
   //find how many seconds there are to the specified time
   int hours = (int)StringSubstr(timeOfDate,0,2);
   int minutes = (int)StringSubstr(timeOfDate,3,2);
   int specifiedTime = hours*60*60 + minutes*60;
   int currentTime = (int)(TimeCurrent()%(60*60*24));
   int waitDuration;
   if (currentTime > specifiedTime) //if that time is next day
      waitDuration = 24*60*60-currentTime + specifiedTime;
   else
      waitDuration = specifiedTime - currentTime;
   Print("Start waiting for ", waitDuration, " seconds...");
   EventSetTimer(waitDuration);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnTimer(){
   EventSetTimer(waitingTime);
   Print("next");
   //find if the last trade was a win or not
   
   // some work with order
   }
   return;
}
/*
void OnChartEvent(const int id,         // Event ID
                  const long& lparam,   // Parameter of type long event
                  const double& dparam, // Parameter of type double event
                  const string& sparam){
   Print(id, " ",sparam);
   if(id == CHARTEVENT_KEYDOWN){ //THIS WILL MAKE THE INPUT INTEGER-ONLY
      Print(id);
      Print(sparam);
      Print(lparam);
   }
}*/

void OnDeinit(const int reason){
   Print("Closed AutoTrader");
}
//+------------------------------------------------------------------+
