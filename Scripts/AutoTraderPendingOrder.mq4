//+------------------------------------------------------------------+
//|                                       AutoTraderPendingOrder.mq4 |
//|                                                       FancyGamer |
//|                                            fancygamer.weebly.com |
//+------------------------------------------------------------------+
#property copyright "FancyGamer"
#property link      "fancygamer.weebly.com"
#property version   "1.00"
#property strict
#property script_show_inputs

#include "Header/getSymbolDetails.mqh"
#include "Header/getOrderDetails.mqh"

//--- input parameters
input int      tpPercentage=4;
input int      slPercentage=1;
input int      timeOfDay=12;
input int      timespan=8;
//uses current timeframe for this

double pip = 0.0001;

//+-Scriptside variables---------------------------------------------+
int waitingTime = 1; //seconds for next iteration
string basePair;
string quotePair;
string accountCurrency = AccountCurrency();
int accountLeverage = AccountLeverage();

bool exit = false;


//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart() {
   if (MessageBox("Do you want to start AutoTrading?","AutoTrader",MB_YESNO) == 7)
      return;
   
   Print(TimeCurrent());
   datetime a = TimeCurrent() - (TimeCurrent()%(60*60*24));
   Print(a);
   
   
   basePair = getPairString(Symbol(),"base",accountCurrency);
   quotePair = getPairString(Symbol(),"quote",accountCurrency);

   Print("Start looping...");
   
   while(true){
      if (exit){
         Print("CLOSED AUTOTRADER");
         return;
      }
      Sleep(waitingTime*1000);
   }
}
//+------------------------------------------------------------------+

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
  

};












double findLot(double startPrice, //findLotToEarnPercentageAtPrice   //MORE DETAILS: Find the lot value that gives us a profit that is equal to a certain percentage of AccountBalance, IF the market moves the take profit price is reached
               double endPrice,
               double percentage){ //missing iOpen XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   //predicts the profit by using the currect quotePairPrice
   string s = quotePair;
   double quotePairPrice;                                          //get homePair price
   if (quotePair == accountCurrency + accountCurrency)         
      quotePairPrice = 1;
   else{
      if (startPrice < endPrice){ //implies a (predicted) buy order
         if (StringSubstr(quotePair,0,3) == accountCurrency)
            quotePairPrice = 1/MarketInfo(s,MODE_BID);
         else
            quotePairPrice = MarketInfo(s,MODE_BID);
         Print(quotePairPrice);
      }
      else{ //sell
         if (StringSubstr(quotePair,0,3) == accountCurrency)
            quotePairPrice = 1/MarketInfo(s,MODE_ASK);
         else
            quotePairPrice = MarketInfo(s,MODE_ASK);
      }
   }
   return percentage*AccountBalance()/(MathAbs(endPrice-startPrice)*100000*quotePairPrice);
}



/*
bool makeOrder(int orderType, double lot, double sl, double tp){         //OP_BUY or OP_SELL
   //uses the current MarketPrice
   //uses account leverage
   if (orderType == OP_BUY){
      int ticket = OrderSend(Symbol(),OP_BUY,lot,MarketInfo(Symbol,Bid), 3, sl, tp);
   else if (orderType == OP_SELL)
      int ticket = OrderSend(Symbol(),OP_SELL,lot,MarketInfo(Symbol,Ask), 3, sl, tp);
   else
      return false; //other order operations are not allowed
   if (ticket < 0){
      //Print("OrderSend failed with error #",GetLastError(), " , Symbol: ", s);
      return false;
   } else {
      Print("OrderSend placed successfully");
      return true;
   }
}  */


bool makePendingOrder(int orderType, double price, double lot, double sl, double tp){
   int ticket = 0;
   ticket = OrderSend(Symbol(),orderType,lot,price,3,sl,tp,"My order",16384,0,clrGreen);
   if(ticket < 0)
      return false;
   else
      return true;
}