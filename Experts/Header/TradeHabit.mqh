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
         
         int endedTicket;
         int winTicket;
         
         //USEFULL private functions
         bool isOrderClosed(int ticket);
         bool isOrderProfit(int ticket);
         int initPendingOrder(int orderType, double price, double lot, double sl, double tp, int curTry=0);
         int renewPendingOrder(int ticket);
         double findLot(double startPrice, double endPrice, double percentage);
         
         
         //SETTINGS********
         int maxLossCount;
         double profitPercentage;
         double amountPercentEquity; // purchase amount in dollar (percentage of AccountBalance)
         double stoplossPercentMargin; //when loss = 25% of amount;          (APPROXIMATELY)
         double takeprofitPercentMargin; // profit = 25% of amount;          (APPROXIMATELY)
         
public:
         TradeHabit(int _id, int _maxLossCount, double _profitPercentage, double sl_buy, double tp_buy, double sl_sell, double tp_sell); 
         //TradeHabit(){}; 
         ~TradeHabit(); //destructer
         void Update();
         void OnOrderClosedByBroker(int ticket, int orderType);
         bool removePendingOrder(int ticket); //done
         bool removeOrder(int ticket); //done
         int setPendingOrder(int orderType, double price, double lot, double sl, double tp); //done
         bool stop();
         bool isEnded;
         int id;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+




TradeHabit::TradeHabit(int _id, int _maxLossCount, double _profitPercentage, double sl_buy, double tp_buy, double sl_sell, double tp_sell){ //same as max trades allowed
   // profitPercentage = percentage of balance to be put be expected to win at takeprofit. (for one trade in a tradehabit)
   
   // initial values
   id = _id;
   maxLossCount = _maxLossCount;
   int maxTrades = maxLossCount + 2;
   ArrayResize(tradeHistory, maxTrades);
   for (int i = 0; i < maxTrades; i++){tradeHistory[i] = 0;}
   startTime = TimeCurrent();
   profitPercentage = _profitPercentage;
   curTradeIndex = 0;
   lossCount = 0;
   totalProfit = 0;
   isEnded = false;
   
   basePair = getPairString(Symbol(),"base",AccountCurrency());
   quotePair = getPairString(Symbol(),"quote",AccountCurrency());
   
   //calculate lot
   double lot_buy = findLot(sl_sell, tp_buy, profitPercentage);
   double lot_sell = findLot(sl_buy, tp_sell, profitPercentage);
   
   //start the first order
   printf(" --- Placing pending orders --- ");
   bpo = initPendingOrder(OP_BUYSTOP, sl_sell, lot_buy, sl_buy, tp_buy);
   spo = initPendingOrder(OP_SELLSTOP, sl_buy, lot_sell, sl_sell, tp_sell);
   if (bpo == -1 || spo == -1){
      printf("Something went wrong!, bpo or spo could not be set, Destroying this TradeHabit");
   }
}


TradeHabit::~TradeHabit() //on destruction
  {
   if (bpo > 0){
      if (!removeOrder(bpo))
         Print("ERROR - Could not remove the remaning bpo");
      else
         Print(" --- Removed the remaning bpo ---");
   }
   if (spo > 0){
      if (!removeOrder(spo))
         Print("ERROR - Could not remove the remaning spo");
      else
         Print(" --- Removed the remaning spo ---");
   }
   Print("Removed TradeHabit #", id);
  }
//+------------------------------------------------------------------+



void TradeHabit::Update(){
   if (isEnded) return;
   endedTicket = 0;
   winTicket = 0;
   //in case both bpo and spo are sold out since the previous loop, we need to do it like this.
   if (isOrderClosed(bpo)) //if a pending order just ended, renew if needed
      OnOrderClosedByBroker(bpo,OP_BUYSTOP);
   if (isOrderClosed(spo))
      OnOrderClosedByBroker(spo,OP_SELLSTOP);
   
   if (endedTicket != 0){ //it could be that both orders are closed simultanously
      if (winTicket != 0){
         Print(" - TradeHabit #",id," has WON - ");
         //save to excel
         //end TradeHabit
         isEnded = true; //such that the manager knows that this TradeHabit is ended.
         
      } else { //if it was not a profit
         if (lossCount >= maxLossCount){
            Print(" - TradeHabit #",id," has LOST - ");
            //save to excel
            //end TradeHabit
            isEnded = true;
         }
      }
   }
}


void TradeHabit::OnOrderClosedByBroker(int ticket, int orderType){ // "Automatically" called when an order is closed by the broker
   string strOrderType;
   if (orderType == OP_BUY || orderType == OP_BUYSTOP)
      strOrderType = "BUYSTOP";
   else
      strOrderType = "SELLSTOP";
   Print(" --- ", strOrderType," Order #", ticket, " is closed by the broker ---");
   endedTicket = ticket;
   tradeHistory[curTradeIndex] = ticket;
   curTradeIndex += 1;
   if (!isOrderProfit(ticket)){
      lossCount += 1;
      if (strOrderType == "BUYSTOP")
         bpo = renewPendingOrder(ticket);
      else
         spo = renewPendingOrder(ticket);
      Print(" -- TradeHabit #",id," status: ", lossCount, "/", maxLossCount, " remaining --");
   } else {
      winTicket = ticket;
      if (winTicket == bpo)
         bpo = -1;
      else
         spo = -1;
      //renewing won't work here, since the marketPrice will make at a level where the order will not be a stop order, but rather a limit order.
   }
}



bool TradeHabit::isOrderClosed(int ticket){ //returns true if the order of the ticket is closed or cancelled
   for(int t = OrdersHistoryTotal() - 1; t >= 0; t--){
      if (OrderSelect(t,SELECT_BY_POS,MODE_HISTORY)){
         if (startTime > OrderCloseTime()) //if startTime of TradeHabit is after the closetime of cur picked ticket (no need to loop further)
            break;
         if(OrderTicket() == ticket){
            return true;
         }
      }
   }
   return false;
}

int TradeHabit::setPendingOrder(int orderType, double price, double lot, double sl, double tp){
   int ticket = -1; //maybe = NULL is better????????????????????????
   ticket = OrderSend(Symbol(),orderType,lot,price,3,sl,tp,"Order of TradeHabit"); //,,0,clrGreen);
   if(ticket < 0){
      Print("ERROR - OrderSend() failed with error #",GetLastError());
   }else{
      //Print("OrderSend placed successfully");
   }
   return ticket;
}



int TradeHabit::initPendingOrder(int orderType, double price, double lot, double sl, double tp, int curTry=0){ //might need to update so it place the order on current marked price
   //tries to set a stop pending order.
   //when it is not possible, it will set a direct order (not pending)
   //returning -1 means it did not manage to set an order.
   if (curTry == 0)
      Print(" --- Setting pending order at ", price, "  sl: ", sl,"  tp: ",tp , " ---");
   else
      Print(" --- Setting pending order once more. " + (string)(5-curTry) + "/5 tries left) --- ");
   if (orderType == OP_BUY)
      orderType = OP_BUYSTOP;
   else if (orderType == OP_SELL)
      orderType = OP_SELLSTOP;
   curTry += 1;
   int ticket = setPendingOrder(orderType, price, lot, sl, tp);
   if (ticket < 0){ //if pending order could not be set
      Print(" -- Pending order failed, try direct order --");
      //set the order directly.
      int directOrderType;
      if (orderType == OP_BUYSTOP)
         directOrderType = OP_BUY;
      else
         directOrderType = OP_SELL;
      ticket = OrderSend(Symbol(),directOrderType,lot,price,3,sl,tp,"Order of TradeHabit"); //,,0,clrGreen);
      if(ticket < 0){
         Print(" --- Direct order failed ---");
         //max 5 tries
         if (curTry >= 5){
            Print(" --- 0/5 tries left. Stopping trying to set order ---");
            return -1;
         } else {
            ticket = initPendingOrder(orderType,price,lot,sl,tp,curTry);
            return ticket; //this ticket could also be -1.
         }
      }else{
         Print(" --- Direct order placed successfully ---");
      }
   } else
      Print(" --- Pending order placed successfully ---");
   return ticket;
}




int TradeHabit::renewPendingOrder(int ticket){ //might need to update so it place the order on current marked price
   if (OrderSelect(ticket, SELECT_BY_TICKET)){
      int newTicket = initPendingOrder(OrderType(),OrderOpenPrice(),OrderLots(),OrderStopLoss(),OrderTakeProfit());
      if (newTicket < 0)
         Print("ERROR - Order #",ticket," cannot be renewed");
      else
         return newTicket;
   } else
      Print("ERROR - Order #",ticket," not selectable by ticket");
   return -1;
}

bool TradeHabit::removePendingOrder(int ticket){
   if (OrderSelect(ticket, SELECT_BY_TICKET)){
      if (OrderType() == OP_BUYSTOP || OrderType() == OP_SELLSTOP){
         if (OrderDelete(ticket)){
            Print(" --- The pending order #",ticket," removed successfully");
            return true;
         } else
            Print("ERROR - The pending order #",ticket," is not removable");
      } else
         Print("ERROR - Order #",ticket," is not a pending order");
   } else
      Print("ERROR - Order #",ticket," not selectable by ticket");
   return false;
}

bool TradeHabit::removeOrder(int ticket){
   if (OrderSelect(ticket, SELECT_BY_TICKET)){
      if (OrderType() == OP_BUY || OrderType() == OP_SELL){
         switch(OrderType()) {
            case OP_BUY:
               if(OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),3,Violet)){
                  Print(" --- The order #",ticket," removed successfully");
                  return true;
               } 
               break;
            case OP_SELL:
               if (OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),3,Violet)){
                  Print(" --- The order #",ticket," removed successfully");
                  return true;
               } 
               break;
         }
      } else { //it is a pending order
         if (OrderDelete(ticket)){
            Print(" --- The pending order #",ticket," removed successfully");
            return true;
         }
         Print("ERROR - The order #",ticket," is a pending order, but not deletable");
      }
      Print("ERROR - The order #",ticket," is not removable");
   } else
      Print("ERROR - Order #",ticket," not selectable by ticket");
   return false;
}


bool TradeHabit::isOrderProfit(int ticket){
   //assumes that all tickets are either gain or loss
   if (OrderSelect(ticket,SELECT_BY_TICKET)){
      if (OrderProfit() > 0)
         return true;
      else
         return false;
   } else
      Print("ERROR - Order #",ticket," not selectable by ticket");
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
