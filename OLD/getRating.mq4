//+------------------------------------------------------------------+
//|                                                    getRating.mq4 |
//|                                   Copyright 2015, FancyGamer Inc |
//|                                        www.fancygamer.weebly.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, FancyGamer Inc"
#property link      "www.fancygamer.weebly.com"
#property version   "1.00"
#property strict
#property show_inputs
#include <WinUser32.mqh>

input string symbol;
int timeframe[] = {1,5,15,30,60,240,1440,10080,43200};
double rate_MACD_fastline_position[] = {2650,1347.5,795,441.7,265,122.3,53}; //from M1 to D1
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   double rating = getRating(symbol);
   Print(symbol, " rating = ", rating);
  }
//+------------------------------------------------------------------+

double getRating(string s){
   double rating = 0;
   rating += step_MACD(s);
   return rating;
}

double step_MACD(string s){
   double rating = 0;
   int MACD[] = {5,35,10}; // Fast, Slow, Signal
   double currentPrice = MarketInfo(s,MODE_BID); // Sell price in the charts
   for (int i = 0; i < 7; i++){
      //----Retrieve MACD info----------------------------------------
      int p = timeframe[i]; //period 
      double histogram[5];
      double fastline[5];
      for (int j = 0; j < 5; j++){
         histogram[j] = iOsMA(s,p,MACD[0],MACD[1],MACD[2],PRICE_CLOSE,j);
         fastline[j] = iMA(s,p,MACD[0],0,MODE_EMA,PRICE_CLOSE,j) - iMA(s,p,MACD[1],0,MODE_EMA,PRICE_CLOSE,j);
      }//-------------------------------------------------------------
      rating += (fastline[0]/(currentPrice/rate_MACD_fastline_position[i]))*-2; //rate for the position of last bar fastline
      
      //Print("Rating for M",p, ": ", (fastline[0]/(currentPrice/rate_MACD_fastline_position[i]))*-2);
      
   }
   return rating;
}