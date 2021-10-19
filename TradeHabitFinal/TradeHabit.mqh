//+------------------------------------------------------------------+
//|                                                   TradeHabit.mqh |
//|                                                       FancyGamer |
//|                                            fancygamer.weebly.com |
//+------------------------------------------------------------------+
#property copyright "FancyGamer"
#property link      "fancygamer.weebly.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

#include "TradeHabitManager.mqh"

/* TradeHabit is a sequence of many trades.
   - trade tickets will be saved in tradeHistory for historical purposes
   - bpo is the buy pending order
   - spo is the sell pending order
   
*/


class TradeHabit
  {
private:
         TradeHabitManager manager;
         //SCRIPT-SIDE*****
         int tradeHistory[]; //This stores the tickets for history
         int lossCount; //int lossCount = 0; only works in c++11 or later
         int totalProfit;
         datetime startTime;
         int bpo;
         int spo;
         
         //USEFULL private functions
         bool isOrderClosed(int ticket);
         bool isFixBufferNeeded();
         void fixBuffer();
         bool isOrderAGain(int ticket);
         int getEndedTicket();
         bool isCurTradeEnded();
         int renewPendingOrder(int ticket);
         int recordTradeAsEndedAndRenew(int ticket);
         
         int curTradeIndex = 0;
         
         
         //SETTINGS********
         int maxLossCount; 
         int maxTrades;
         double amountPercentEquity; // purchase amount in dollar (percentage of AccountBalance)
         double stoplossPercentMargin; //when loss = 25% of amount;          (APPROXIMATELY)
         double takeprofitPercentMargin; // profit = 25% of amount;          (APPROXIMATELY)
         
         
         
public:
         TradeHabit(int _maxTrades, int _maxLossCount); 
         ~TradeHabit(); //destructer
         void Update();
         
         bool removePendingOrder(int ticket); //done
         int setPendingOrder(int orderType, double price, double lot, double sl, double tp); //done
         
         bool stop();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+




TradeHabit::TradeHabit(int _maxTrades, int _maxLossCount){
   maxTrades = _maxTrades;
   maxLossCount = _maxLossCount;
   
   //default values
   ArrayResize(tradeHistory,maxTrades);
   for (int i = 0; i < maxTrades; i++){tradeHistory[i] = 0;}
   startTime = TimeCurrent();
   amountOfLoss = 0;
   totalProfit = 0;
   ongoingTrade = false; //if an order is set and not ended --> true
}
//+------------------------------------------------------------------+
//|   DESTRUCTION                                                    |
//+------------------------------------------------------------------+
TradeHabit::~TradeHabit() //on destruction
  {
   if (bpo != 0)
      OrderDelete(bpo);
   if (spo != 0)
      OrderDelete(spo);
   printf("removing TradeHabit #" + (string)startTime);
  }
//+------------------------------------------------------------------+


void TradeHabit::Update(){
   int endedTicket = 0;
   int winTicket = 0;
   //in case both bpo and spo are sold out since the previous loop, we need to do it like this.
   if (isOrderClosed(bpo)){ //if a pending order just ended, renew it no matter what
      if (!isProfit(bpo))
         lossCount += 1;
      else
         winTicket = bpo;
      endedTicket = bpo;
      tradeHistory[curTradeIndex] = bpo;
      curTradeIndex += 1;
      bpo = renewPendingOrder(bpo);
   }
   if (isOrderClosed(spo)){
      if (!isProfit(spo))
         lossCount += 1;
      else
         winTicket = spo;
      endedTicket = spo;
      tradeHistory[curTradeIndex] = bpo;
      spo = renewPendingOrder(spo);
   }
   if (endedTicket != 0){ 
      if(isOrderAGain(endedTicket)){
         //end this tradeHabit
         /*
            remove bpo and spo
            and save this tradeHabit to an excel file
         */
      }
      else {
         
      }
         
   }
   
   if (isCurTradeEnded()){
      if (maxLossCount < getCurTradeIndex()){ //if the cur trade is the 6th trade, when maxLossCount = 5, then the tradehabit ends
         //end tradeHABIT!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
         //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
         //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
         //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
         //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
         //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      }
      else {
         //an order reached the stoploss or takeprofit line, we need to either place new orders, or end the tradehabit
         if (isFixBufferNeeded()){
         
         }
         else {
            fixBuffer();
         }
      }
   }
   
}



void TradeHabit::fixBuffer(){ //fix the buys and stop pending orders
   //assume that a fix is needed
   int curBuyTicket = trades[getCurTradeIndex()][0];
   int curSellTicket = trades[getCurTradeIndex()][1];
   int lossTicket = getEndedTicket(); //this trade is assumed to be a loss.
   if (lossTicket == curBuyTicket)
      
   
   
}



void 





bool TradeHabit::isFixBufferNeeded(){
   int t = getEndedTicket();
   if (!isOrderAGain(t))
      return true;
   else
      return false;
}
bool TradeHabit::iProfit(int ticket){
   //assumes that all tickets are either gain or loss
   if (OrderSelect(ticket,SELECT_BY_TICKET)){
      if (OrderProfit() > 0)
         return true;
      else
         return false;
   }
   Print("End this Script immediately, something is WRONG!!!!!!!");
   return false;
}


bool TradeHabit::isOrderAGain(int ticket){
   //assumes that all tickets are either gain or loss
   if (OrderSelect(ticket,SELECT_BY_TICKET)){
      if (OrderProfit() > 0)
         return true;
      else
         return false;
   }
   Print("End this Script immediately, something is WRONG!!!!!!!");
   return false;
}

int TradeHabit::getEndedTicket(){
   //return the int of the ticket
   //use only after isCurTradeEnded()
   int curBuyTicket = trades[getCurTradeIndex()][0];
   int curSellTicket = trades[getCurTradeIndex()][1];
   //if the current buy/sell pending order tickets are closed or cancelled
   if (isOrderClosed(curBuyTicket))
      return curBuyTicket;
   else 
      return curSellTicket;
}


bool TradeHabit::isOrderClosed(int ticket){ //returns true if the order of the ticket is closed or cancelled
   for(int t = OrdersHistoryTotal() - 1; t >= 0; t--){
      if (OrderSelect(t,SELECT_BY_POS,MODE_HISTORY)){
         if (startTime > OrderCloseTime()) //if startTime of TradeHabit is after the closetime of cur picked ticket (no need to loop further)
            break;
         if(OrderTicket() == ticket)
            return true;
      }
   }
   return false;
}

int TradeHabit::setPendingOrder(int orderType, double price, double lot, double sl, double tp){
   int ticket = NULL;
   ticket = OrderSend(Symbol(),orderType,lot,price,3,sl,tp,"Order of TradeHabit"); //,,0,clrGreen);
   if(ticket < 0){
      Print("OrderSend failed with error #",GetLastError());
   }else{
      Print("OrderSend placed successfully");
   }
   return ticket;
}

int TradeHabit::renewPendingOrder(int ticket){ //might need to update so it place the order on current marked price
   if (OrderSelect(ticket, SELECT_BY_TICKET)){
      //returns the ticket
      return setPendingOrder(OrderType(),OrderOpenPrice(),OrderLots(),OrderStopLoss(),OrderTakeProfit());
   }
   //ADD ERROR HANDLING!!!!!!!!!!!!!!
   return 0;
}


bool TradeHabit::removePendingOrder(int ticket){
   if (OrderSelect(ticket, SELECT_BY_TICKET)){
      if (OrderType() == OP_BUYSTOP || OrderType() == OP_SELLSTOP){
         if (OrderDelete(ticket)){
            Print("The pending order deleted successfully");
            return true;
         }
      }
   }
   Print("The order is not a pernding order");
   return false;
}

