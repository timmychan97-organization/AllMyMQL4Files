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

#include "getSymbolDetails.mqh"
#include "getOrderDetails.mqh"

/* TradeHabit is a sequence of many trades.
   - trade tickets will be saved in tradeHistory for historical purposes
   - bpo is the buy pending order
   - spo is the sell pending order
   
*/


class TradeHabit
  {
private:
         double pip;
         int timeframe;
         int numberOfBarsToFindAverageOf;
         int averageHeight;

         string basePair;
         string quotePair;
         
         
         //--------------------------------------------------
         int tradeHistory[20]; //This stores the tickets for history
         int lossCount; //int lossCount = 0; only works in c++11 or later
         int totalProfit;
         datetime startTime;
         int bpo;
         int spo;
         int curTradeIndex;
         
         //USEFULL private functions
         bool isOrderClosed(int ticket);
         bool isOrderProfit(int ticket);
         int renewPendingOrder(int ticket);
         double findLot(double startPrice, double endPrice, double percentage);
         
         
         
         //SETTINGS********
         int maxLossCount;
         double amountPercentEquity; // purchase amount in dollar (percentage of AccountBalance)
         double stoplossPercentMargin; //when loss = 25% of amount;          (APPROXIMATELY)
         double takeprofitPercentMargin; // profit = 25% of amount;          (APPROXIMATELY)
         
public:
         TradeHabit(int _maxLossCount); 
         //TradeHabit(){}; 
         ~TradeHabit(); //destructer
         void Update();
         bool removePendingOrder(int ticket); //done
         int setPendingOrder(int orderType, double price, double lot, double sl, double tp); //done
         bool stop();
         bool isEnded;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+




TradeHabit::TradeHabit(int _maxLossCount){ //same as max trades allowed
   maxLossCount = _maxLossCount;
   int maxTrades = maxLossCount + 2;
   ArrayResize(tradeHistory, maxTrades);
   for (int i = 0; i < maxTrades; i++){tradeHistory[i] = 0;}
   startTime = TimeCurrent();
   curTradeIndex = 0;
   lossCount = 0;
   totalProfit = 0;
   isEnded = false;
   
   basePair = getPairString(Symbol(),"base",AccountCurrency());
   quotePair = getPairString(Symbol(),"quote",AccountCurrency());
   
   //---------------------------------------------------------------------
   // Calculate prices
   //---------------------------------------------------------------------
   
   
}
//+------------------------------------------------------------------+
//|   DESTRUCTION                                                    |
//+------------------------------------------------------------------+
TradeHabit::~TradeHabit() //on destruction
  {
   if (bpo != 0)
      if (!OrderDelete(bpo)) printf("Could not remove bpo");
   if (spo != 0)
      if (!OrderDelete(spo)) printf("Could not remove spo");
   printf("removing TradeHabit #" + (string)startTime);
  }
//+------------------------------------------------------------------+



void TradeHabit::Update(){
   int endedTicket = 0;
   int winTicket = 0;
   //in case both bpo and spo are sold out since the previous loop, we need to do it like this.
   if (isOrderClosed(bpo)){ //if a pending order just ended, renew it no matter what
      if (!isOrderProfit(bpo))
         lossCount += 1;
      else
         winTicket = bpo;
      endedTicket = bpo;
      tradeHistory[curTradeIndex] = bpo;
      curTradeIndex += 1;
      bpo = renewPendingOrder(bpo);
   }
   if (isOrderClosed(spo)){
      if (!isOrderProfit(spo))
         lossCount += 1;
      else
         winTicket = spo;
      endedTicket = spo;
      tradeHistory[curTradeIndex] = bpo;
      curTradeIndex += 1;
      spo = renewPendingOrder(spo);
   }
   if (endedTicket != 0){ 
      if (winTicket != 0){
         isEnded = true;
         //save to excel
         //end TradeHabit
         
      } else {
         if (lossCount >= maxLossCount){
            //save to excel
            //end TradeHabit
         }
      }
   }
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

bool TradeHabit::isOrderProfit(int ticket){
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










//------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------

double TradeHabit::findLot(double startPrice, //findLotToEarnPercentageAtPrice   //MORE DETAILS: Find the lot value that gives us a profit that is equal to a certain percentage of AccountBalance, IF the market moves the take profit price is reached
               double endPrice,
               double percentage){ //missing iOpen XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   //predicts the profit by using the currect quotePairPrice
   string s = quotePair;
   double quotePairPrice;              //get homePair price
   string AC = AccountCurrency();
   if (quotePair == AC + AC)         
      quotePairPrice = 1;
   else{
      if (startPrice < endPrice){ //implies a (predicted) buy order
         if (StringSubstr(quotePair,0,3) == AC)
            quotePairPrice = 1/MarketInfo(s,MODE_BID);
         else
            quotePairPrice = MarketInfo(s,MODE_BID);
      }
      else{ //sell
         if (StringSubstr(quotePair,0,3) == AC)
            quotePairPrice = 1/MarketInfo(s,MODE_ASK);
         else
            quotePairPrice = MarketInfo(s,MODE_ASK);
      }
   }
   if(quotePairPrice == 0)
      Print("This is not a currency pair!!");
   return percentage*AccountBalance()/(MathAbs(endPrice-startPrice)*100000*quotePairPrice);
}
