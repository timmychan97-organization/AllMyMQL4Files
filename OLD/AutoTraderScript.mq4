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


//+-Scriptside variables---------------------------------------------+
int waitingTime = 30; //seconds for next iteration
//+-Order properties-------------------------------------------------+
int leverage = AccountLeverage(); //the margin multiplier
int amount = 100; // purchase amount in dollar

int stoploss = amount/4; //when loss = $100;
int takeprofit = amount/4; // profit = $100;

int buyratinggoal = 10; //buy when rating gets above this value
int sellratinggoal = -10; //sell when rating gets below this value

//+------------------------------------------------------------------+
//CONSTANTS---DONT CHANGE--------------------------------------------+
int timeframe[] = {1,5,15,30,60,240,1440,10080,43200};
double rate_MACD_fastline_position[] = {2650,1347.5,795,441.7,265,122.3,53}; //from M1 to D1
double rate_MACD_fastline_direction[] = {};

double rate_MACD_M5_fastline_position = 1347.5; //7.95/0.0059
double rate_MACD_M30_fastline_position = 441.7; //7.95/0.018



double rate_MACD_M5_histogram = 1590; // = 7.95/0.005
double rate_MACD_M30_fastline_direction_0and1 = 3975; // 7.95/0.002
double rate_MACD_M30_histogram_cross = 1590; // 7.95/0.005

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

void OnStart()
{
Sleep(5000);                                       //Sleep
while(true){
   int symbolsTotal = SymbolsTotal(true);          //stores the value of total symbols to save time           
   for (int i = 0; i < symbolsTotal; i++){         //loop through all symbols in Market Watch
      string symbol = SymbolName(i,true);          //stores the name of the current symbol
      if (isOrdered(symbol) == true)               //if the current symbol is already ordered
         continue;                                 //    then skip the symbol
      else{                                        //if this symbol is not ordered yet
         double rating = getRating(symbol);        //    stores the symbol rating
         Print(symbol, ": ", rating);             
         if (rating >= buyratinggoal)              //    if the rating of the symbol gets over the predetemined buyrate.
            trade(symbol,0);                       //       goto buy section
         else if (rating <= sellratinggoal)        //    if the rating gets under the predetermined sellrate.
            trade(symbol,1);                       //       goto sell section
      }
   }
   Sleep(waitingTime*1000);                        //Sleep time before next iteration
}
return;


} //end of Start
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool isOrdered(string s){                          //CHECK if the symbol is ordered
   int total = OrdersTotal();                      //stores the number of orders
   for (int i = 0; i < total; i++){                //loop through all orders
      if (OrderSelect(i,SELECT_BY_POS)==true)      //if the it is no error while selecting the symbol
         if (OrderSymbol() == s) return true;      //    if the symbol is the symbol we check, then it is true.
   }
   return false;                                   //else, it is false
}
void trade(string s, int bos){                     //MAKE TRADE
   int quantity = amount*leverage;
   double lot = (double)quantity/100000;
   double value, stoplossValue, takeprofitValue;
   if (bos == 0){  //if buy
      value = MarketInfo(s,MODE_ASK);
      double stocks = quantity / value;
      stoplossValue = (quantity - takeprofit)/stocks;
      takeprofitValue = (quantity + takeprofit)/stocks;
   }
   else if (bos == 1){ //if sell
      value = MarketInfo(s,MODE_BID);
      double stocks = quantity / value;
      stoplossValue = (quantity + takeprofit)/stocks;
      takeprofitValue = (quantity - takeprofit)/stocks;
   }
   int ticket = OrderSend(s,bos,lot,value, 3, stoplossValue, takeprofitValue);
   if (ticket < 0)
      Print("OrderSend failed with error #",GetLastError());
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
   /*rating += step1(symbol);
   Print("step1 M30: ",rating);
   rating += step2(symbol);
   Print("step2 M5: ",step2(symbol));*/
   return rating;
}



double step1(string s){ //M30 MACD
   double rating = 0;
   int MACD[3] = {5,35,10}; // Fast, Slow, Signal
   int p = 30; //period M30
   double currentPrice = Bid; // Sell price in the charts
   double histogram[6];
   double fastline[6];
   for (int i = 0; i < 6; i++){  //getting the values of MACD
      histogram[i] = iOsMA(s,p,MACD[0],MACD[1],MACD[2],PRICE_CLOSE,i);
      fastline[i] = iMA(s,p,MACD[0],0,MODE_EMA,PRICE_CLOSE,i) - iMA(s,p,MACD[1],0,MODE_EMA,PRICE_CLOSE,i);
   }
   
   rating += (fastline[0]/(currentPrice/rate_MACD_M30_fastline_position))*-2; //rate for the position of last bar fastline
   rating += (fastline[0] - fastline[2])/(currentPrice/rate_MACD_M30_fastline_direction_0and1)*1; //rate for the direction of fastline
   if ((histogram[0] < 0 && histogram[3] > 0) || (histogram[0] > 0 && histogram[3] < 0)){ //if theres a cross
      rating += MathPow((histogram[0] - histogram[3])/(currentPrice/rate_MACD_M30_histogram_cross),2)*1.3;     //rate for cross power up 2
   }
   return rating;
}

double step2(string s){ //M5 MACD and CCI
   double rating = 0;
   int MACD[3] = {5,35,10}; // Fast, Slow, Signal
   int p = 5; //period M5
   double currentPrice = Bid; // Sell price in the charts
   double histogram[4];
   double fastline[4];
   for (int i = 0; i < 4; i++){
      histogram[i] = iOsMA(s,p,MACD[0],MACD[1],MACD[2],PRICE_CLOSE,i);
      fastline[i] = iMA(s,p,MACD[0],0,MODE_EMA,PRICE_CLOSE,i) - iMA(s,p,MACD[1],0,MODE_EMA,PRICE_CLOSE,i);
   }
   
   if (histogram[0] > 0 && histogram[3] < 0){ //if there is a upwards cross
      rating += 0.5;
   }
   else if (histogram[0] < 0 && histogram[3] > 0){ //if there is a downwards cross
      rating -= 0.5;
   }
   if (rating > 0){  
      double largestbar = 0;
      for (int i = 0; i < 4; i++)   //find the largestbar in histogram
         if (histogram[i] > largestbar) largestbar = histogram[i];
      if (largestbar >= currentPrice/rate_MACD_M5_histogram){ //if any of the bars is > 0.005
         if (iCCI(s,p,90,PRICE_CLOSE,0) > -100 && iCCI(s,p,90,PRICE_CLOSE,3) < -100) //going up
            rating += 6;
         if (iCCI(s,p,90,PRICE_CLOSE,0) < 100 && iCCI(s,p,90,PRICE_CLOSE,3) > 100) //going down
            rating -= 6;
      }
   }
   rating += (fastline[0]/(currentPrice/rate_MACD_M5_fastline_position))*-2; //rate for the position of last bar fastline
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



//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+