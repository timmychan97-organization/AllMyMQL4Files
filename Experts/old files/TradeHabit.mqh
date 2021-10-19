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

/* TradeHabit is a sequence of many trades.





*/


class TradeHabit
  {
private:
         //SCRIPT-SIDE*****
         int trades[][2]; //trades[index of the trades][0 = buy, 1 = sell]  This stores the tickets
         int amountOfLoss; //int amountOfLoss = 0; only works in c++11 or later
         int totalProfit;
         datetime startTime;
         bool ongoingTrade; //if an order is set and not ended --> true
         
         //USEFULL private functions
         int getCurTradeIndex();
         bool isOrderClosed(int ticket);
         bool isFixBufferNeeded();
         void fixBuffer();
         bool isOrderAGain(int ticket);
         int getEndedTicket();
         bool isCurTradeEnded();
         
         
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
   ArrayResize(trades,maxTrades);
   for (int i = 0; i < maxTrades; i++){ //initialize everything with 0
      trades[i][0] = 0;
      trades[i][1] = 0;
   }
   //default values
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
   
  }
//+------------------------------------------------------------------+


void TradeHabit::Update(){
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





//***************************************************************************************************
//***************************************************************************************************
//****  ######        ###     ##      #  #########  *************************************************
//****  #     ##    ##   ##   ###     #  #          *************************************************
//****  #       #  #       #  # ##    #  #          *************************************************
//****  #       #  #       #  #  ##   #  #          *************************************************
//****  #       #  #       #  #   ##  #  ########   *************************************************
//****  #       #  #       #  #    ## #  #          *************************************************
//****  #     ##    ##   ##   #     ###  #          *************************************************
//****  ######        ###     #      ##  #########  *************************************************
//***************************************************************************************************
//***************************************************************************************************


bool TradeHabit::isFixBufferNeeded(){
   int t = getEndedTicket();
   if (!isOrderAGain(t))
      return true;
   else
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

bool TradeHabit::isCurTradeEnded(){
   //true if either the stoploss or takeprofit line is hit
   int curBuyTicket = trades[getCurTradeIndex()][0];
   int curSellTicket = trades[getCurTradeIndex()][1];
   //if the current buy/sell pending order tickets are closed or cancelled
   if (isOrderClosed(curBuyTicket) || isOrderClosed(curSellTicket)){ //exclusive OR-operator
      if (isOrderClosed(curBuyTicket) && isOrderClosed(curSellTicket)){
         Print("End this Script immediately, something is WRONG!!!!!!!");
      }
      return true;
   }
   return false;
}

bool TradeHabit::isOrderClosed(int ticket){ //returns true if the order of the ticket is closed or cancelled
   for(int t = OrdersHistoryTotal() - 1; t >= 0; t--){
      if (OrderSelect(t,SELECT_BY_POS,MODE_HISTORY)){
         if (startTime > OrderCloseTime()) //if startTime of TradeHabit is after the closetime of cur picked ticket
            break;
         if(OrderTicket() == ticket)
            return true;
      }
   }
   return false;
}

int TradeHabit::getCurTradeIndex(){ //returns the number of trades issued . Return -1 if failed
   for (int i = 1; i < maxTrades; i++){
      if (trades[i][0] == 0 && trades[i][1] == 0) //if there are no tickets for that trade, the previous trade is the curTrade
         return i-1;
   }
   Print("End this Script immediately, something is WRONG!!!!!!!");
   return -1;
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

