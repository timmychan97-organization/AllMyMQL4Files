//+------------------------------------------------------------------+
//|                                             AutoTraderScript.mq4 |
//|                                   Copyright 2015, FancyGamer Inc |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, FancyGamer Inc"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
#include "Header\getSymbolDetails.mqh"
#include "Header\getOrderDetails.mqh"

//+-Scriptside variables---------------------------------------------+
int waitingTime = 60; //seconds for next iteration
//+-Order properties-------------------------------------------------+

double marginPercentEquity = 0.1; // purchase amount in dollar (10%)       (APPROXIMATELY)
double stoplossPercentMargin = 0.25; //when loss = 25% of amount;          (APPROXIMATELY)
double takeprofitPercentMargin = 0.25; // profit = 25% of amount;          (APPROXIMATELY)

int buyratinggoal = 1; //buy when rating gets above this value
int sellratinggoal = -1; //sell when rating gets below this value

double stopFreeMarginPercentBalance = 0.2;
int secondsAfterOrderClose = 3600*5;         //...2 hours


//+-Just info-------------------------------------------------------+
int accountLeverage = AccountLeverage(); //the margin multiplier
string accountCurrency = AccountCurrency();
double margin;

//CONSTANTS---DONT CHANGE--------------------------------------------+
int timeframe[] = {1,5,15,30,60,240,1440,10080,43200};
double rate_MACD_fastline_position[] = {2650,1347.5,795,441.7,265,122.3,53}; //from M1 to D1

double rate_MACD_M5_fastline_position = 1347.5; //7.95/0.0059
double rate_MACD_M30_fastline_position = 441.7; //7.95/0.018



double rate_MACD_M5_histogram = 1590; // = 7.95/0.005
double rate_MACD_M30_fastline_direction_0and1 = 3975; // 7.95/0.002
double rate_MACD_M30_histogram_cross = 1590; // 7.95/0.005

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

void OnStart()
{
if (MessageBox("Do you want to start AutoTrading?","AutoTrader2.0",MB_YESNO) == 7)
   return;
   
Print("Start looping...");

while(true){
   for (int i = 0; i < SymbolsTotal(true); i++){
      if (getSymbolLeverage(SymbolName(i,true),getPairString(SymbolName(i,true),"base", accountCurrency),accountCurrency) != accountLeverage){
         MessageBox("Wrong leverage on " + SymbolName(i,true) + ".");
         return;
      }
   }
   //Update(); //amount,stoploss,takeprofit PUT INSIDE TRADE
   int symbolsTotal = SymbolsTotal(true);          //stores the value of total symbols to save time           
   for (int i = 0; i < symbolsTotal; i++){         //loop through all symbols in Market Watch
      if (AccountFreeMargin() <= AccountBalance()*stopFreeMarginPercentBalance)   //if too low FreeMargin
         break;
      string symbol = SymbolName(i,true);          //stores the name of the current symbol
      if (needCheck(symbol) == false)              //if the symbol does not need a check
         continue;                                 //    then skip the symbol
         
      else{                                        //if the symbol is not ordered yet then...
         double rating = getRating(symbol);        //    get the rating for the symbol
         Print(symbol, ": ", rating);             
         if (rating >= buyratinggoal)              //    if the rating of the symbol gets over the predetemined buyrate.
            trade(symbol,"buy");                       //       goto buy section
         else if (rating <= sellratinggoal)        //    if the rating gets under the predetermined sellrate.
            trade(symbol, "sell");                       //       goto sell section
      }
   }
   Sleep(waitingTime*1000);                        //Sleep time before next iteration
}
return;


} //end of Start
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

bool needCheck(string s){
   if (isOrdered(s) == true)               //if the current symbol is already ordered
      return false;
                                                //if symbol is closed within...
   int ordersHistoryTotal = OrdersHistoryTotal();
   for (int i = ordersHistoryTotal; i >= 0; i--){
      if (OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) == true){
         if (TimeCurrent() < OrderCloseTime() + secondsAfterOrderClose)
            break;
         if (OrderSymbol() == s)
            return false;
      }
      else
         Print("OrderSelect ErrorCode: ",GetLastError());
   }
   
   return true;
}
               bool isOrdered(string s){                          //CHECK if the symbol is ordered
                  int total = OrdersTotal();                      //stores the number of orders
                  for (int i = 0; i < total; i++){                //loop through all orders
                     if (OrderSelect(i,SELECT_BY_POS)==true)      //if the it is no error while selecting the symbol
                        if (OrderSymbol() == s) return true;      //    if the symbol is the symbol we check, then it is true.
                  }
                  return false;                                   //else, it is false
               }



void trade(string s, string bos){                     //MAKE TRADE
   margin = AccountBalance()*marginPercentEquity;
   
   double quantity = getQuantity(bos,getPairString(s,"base",accountCurrency),margin,accountLeverage,accountCurrency);
   
   double lot = MathRound(quantity/1000)/100;
   
   double currentPrice, stoplossValue, takeprofitValue;
   int buyOrSell;
   if (bos == "buy"){  //if buy
      currentPrice = MarketInfo(s,MODE_ASK);
      buyOrSell = 0;
      double stocks = quantity / currentPrice;
      stoplossValue = (quantity - (quantity*stoplossPercentMargin/accountLeverage))/stocks;
      takeprofitValue = (quantity + (quantity*takeprofitPercentMargin/accountLeverage))/stocks;
   }
   else if (bos == "sell"){ //if sell
      currentPrice = MarketInfo(s,MODE_BID);
      buyOrSell = 1;
      double stocks = quantity / currentPrice;
      stoplossValue = (quantity + (quantity*stoplossPercentMargin/accountLeverage))/stocks;
      takeprofitValue = (quantity - (quantity*takeprofitPercentMargin/accountLeverage))/stocks;
   }
   
   int ticket = OrderSend(s,buyOrSell,lot,currentPrice, 3, stoplossValue, takeprofitValue);
   if (ticket < 0)
      Print("OrderSend failed with error #",GetLastError(), " , Symbol: ", s);
   else
      Print("OrderSend placed successfully");
   return;
}  
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+


double getRating(string symbol){
   double rating = 0;
   rating += step_MACD(symbol);
   return rating;
}

double step_MACD(string s){
   double rating = 0;
   int MACD[] = {5,35,10}; // Fast, Slow, Signal
   double currentPrice = MarketInfo(s,MODE_BID); // Sell price in the charts
   for (int i = 0; i < 6; i++){
      //----Retrieve MACD info----------------------------------------
      int p = timeframe[i]; //period 
      double histogram[5];
      double fastline[5];
      for (int j = 0; j < 5; j++){
         histogram[j] = iOsMA(s,p,MACD[0],MACD[1],MACD[2],PRICE_CLOSE,j);
         fastline[j] = iMA(s,p,MACD[0],0,MODE_EMA,PRICE_CLOSE,j) - iMA(s,p,MACD[1],0,MODE_EMA,PRICE_CLOSE,j);
      }//-------------------------------------------------------------
      rating += (fastline[0]/(currentPrice/rate_MACD_fastline_position[i]))*2; //rate for the position of last bar fastline
      
      //Print("Rating for M",p, ": ", (fastline[0]/(currentPrice/rate_MACD_fastline_position[i]))*-2);
      
   }
   return rating;
}



//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+