//+------------------------------------------------------------------+
//|                                     TestSettingPendingOrders.mq4 |
//|                                       Copyright 2018, Timmy Chan |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Timmy Chan"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   double lot = 0.01;
   /* Works
   double slPrice = Ask-30*Point;
   double tpPrice = Ask+30*Point;
   makePendingOrder(OP_BUY,Ask,lot,slPrice,tpPrice);
   makePendingOrder(OP_BUY,Ask,lot,slPrice,tpPrice);
   */
   double askPrice = Ask + 100*Point;
   double slPrice = askPrice-300*Point;
   double tpPrice = askPrice+300*Point;
   makePendingOrder(OP_BUYSTOP,askPrice,lot,slPrice,tpPrice);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int error = GetLastError();
   if (error == ERR_INVALID_STOPS /*130*/){
      /*if it setting a pending order failed: 
         - it could be that the price is too close the market price.
         - 
      
      */
   }
  }
//+------------------------------------------------------------------+



void makePendingOrder(int orderType, double price, double lot, double sl, double tp){
   int ticket = 0;
   ticket = OrderSend(Symbol(),orderType,lot,price,3,sl,tp,"My order",16384,0,clrGreen);
   if(ticket < 0)
      Print("OrderSend failed with error #",GetLastError());
   else
      Print("OrderSend placed successfully");
   Print("last error is: ", GetLastError());
}
