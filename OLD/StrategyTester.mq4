//+------------------------------------------------------------------+
//|                                               StrategyTester.mq4 |
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

//USER VARIABLES-------------------------------------

datetime startdate = D'2014.01.02 00:00';
datetime enddate = D'2014.11.30 23:59';
double startEquity = 1500;
double amountPercentEquity = 0.1;
double stoplossPercentAmount = 0.25;
double takeprofitPercentAmount = 0.25;

double stopFreeMarginPercentBalance = 0.2;

int secondsAfterOrderClose = 3600*5;         //...2 hours

int buyratinggoal = 30; //buy when rating gets above this value
int sellratinggoal = -30; //sell when rating gets below this value


int timeframe[] = {1,5,15,30,60,240,1440,10080,43200};
double rate_MACD_fastline_position[] = {2650,1347.5,795,441.7,265,122.3,53}; //from M1 to D1
//-----only this time variables---START-----------------

int accountLeverage = AccountLeverage(); //the margin multiplier
int symbolsTotal = SymbolsTotal(true);
string accountCurrency = AccountCurrency();

double amount, stoploss, takeprofit;
int shiftM1 = 0;
int orderCount = 0;
//---TERMINAL-------------
datetime realStartDate = startdate;

string arrSymbol[] = {};
bool arrIsOrdered[] = {};
datetime arrStartTime[] = {};
datetime arrEndTime[] = {};
string arrType[] = {};
double arrLot[] = {};
double arrMargin[] = {};
double arrStartPrice[] = {};
double arrTPValue[] = {};
double arrSLValue[] = {};
double arrCurrentPrice[] = {};
//__________double arrSwap[] = {};
double arrProfit[] = {};
string arrBasePair[] = {};
string arrQuotePair[] = {};
double arrLeverage[] = {};


double accountBalance = startEquity;
double totalEquity = accountBalance;
double totalMargin = 0;
double totalFreeMargin = totalEquity - totalMargin;
double totalProfit = 0;
double lowestEquity = totalEquity;


//-----only this time variables---END--------------------

void OnStart()
  {
//---PREPARING---------
   ArrayResize(arrSymbol,symbolsTotal);
   ArrayResize(arrIsOrdered,symbolsTotal);
   ArrayResize(arrStartTime,symbolsTotal);
   ArrayResize(arrEndTime,symbolsTotal);
   ArrayResize(arrType,symbolsTotal);
   ArrayResize(arrLot,symbolsTotal);
   ArrayResize(arrMargin,symbolsTotal);
   ArrayResize(arrStartPrice,symbolsTotal);
   ArrayResize(arrTPValue,symbolsTotal);
   ArrayResize(arrSLValue,symbolsTotal);
   ArrayResize(arrCurrentPrice,symbolsTotal);
   //ArrayResize(arrSwap,symbolsTotal);        //coming soon............XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   ArrayResize(arrProfit,symbolsTotal);
   ArrayResize(arrBasePair,symbolsTotal);
   ArrayResize(arrQuotePair,symbolsTotal);
   ArrayResize(arrLeverage,symbolsTotal);
   
   for (int i = 0; i < symbolsTotal; i++){
      arrSymbol[i] = SymbolName(i,true); //store the names of the symbols
      arrIsOrdered[i] = false; //all orders = 0 (not ordered)
   }
   for (int i = 0; i < symbolsTotal; i++){         //get the homePairs
      arrBasePair[i] = getBasePairString(i);
      arrQuotePair[i] = getQuotePairString(i);
   }
   
   if (missingPair() == true) return;
   
   for (int i = 0; i < symbolsTotal; i++){
      arrLeverage[i] = getSymbolLeverage(i);
   }
   
   //--Prepared everything--------------------------------------------
      
      
      
   int resultFirstMsgBox = MessageBox("Everything is ready, do you want to start Strategy Tester?","Strategy Tester",MB_YESNO);
   if (resultFirstMsgBox == 7) return;
   
//--Start LOOP-----------------------------------------------------
   Print("Start looping...");
   
   for (int a = 60; startdate <= enddate; startdate += a){ //10min/600sec per time
      Update();         //update money, amount and profits.... 
      CheckOrders();    //Close finished orders
      for (int s = 0; s < symbolsTotal; s++){
         if (totalFreeMargin <= accountBalance*amountPercentEquity){ //if no money to order, skip
            if (totalFreeMargin <= 0){
               Print("FreeMargin: ", totalFreeMargin, "  Equity: ", totalEquity);
               for (int z = 0; z < symbolsTotal; z++){
                  if (arrIsOrdered[z] == true){
                     Print(arrMargin[z]);
                     Print(" |", arrSymbol[z], "|",TimeToStr(arrStartTime[z]) , "-", TimeToStr(startdate), "|", arrType[z], "|Start:",  MathRound(arrStartPrice[z]*100000)/100000, "|TP:", MathRound(arrTPValue[z]*100000)/100000, "|SL:",  MathRound(arrSLValue[z]*100000)/100000, "|End:", MathRound(arrCurrentPrice[z]*100000)/100000, "|Profit:",MathRound(arrProfit[z]*100)/100, "|Lot:", arrLot[z]); 
                  }
               }  
               return;
            }
            break;
         }
         shiftM1 = iBarShift(arrSymbol[s],1,startdate);
         if (needCheck(s) == false)                         //if the current symbol doesn't need check, skip
            continue;
         else{                                        //if this symbol is not ordered yet
            double rating = getRating(s);        //    stores the symbol rating
            if (rating >= buyratinggoal)              //    if the rating of the symbol gets over the predetemined buyrate.
               trade(s,"buy");                       //       goto buy section
            else if (rating <= sellratinggoal)        //    if the rating gets under the predetermined sellrate.
               trade(s,"sell");                       //       goto sell section
         }
      }
      Update();
   }
   Print("Equity: ",totalEquity, ". Orders total: ", orderCount, ". Lowest equity: ", lowestEquity);
   int filehandle = FileOpen("Results.csv",FILE_READ|FILE_CSV|FILE_WRITE);
   FileSeek(filehandle,0,SEEK_END);
   FileWrite(filehandle,TimeLocal(),realStartDate,enddate,startEquity,totalEquity,lowestEquity,buyratinggoal,sellratinggoal,amountPercentEquity,takeprofitPercentAmount,stoplossPercentAmount,orderCount,symbolsTotal,secondsAfterOrderClose);
   FileFlush(filehandle);
   FileClose(filehandle);

   return;
  }
//+------------------------------------------------------------------+

void trade(int s, string bos){                     //bos = buy or sell (As String)
   double quantity = amount*accountLeverage;
   double lot = MathRound(quantity/1000)/100; //round lot to 2 decimal places
   double price, stoplossValue, takeprofitValue;
   if (bos == "buy"){
      price = iOpen(arrSymbol[s],1,shiftM1);
      double stocks = quantity / price;
      stoplossValue = (quantity - stoploss)/stocks;
      takeprofitValue = (quantity + takeprofit)/stocks;
      arrType[s] = "buy";
   }
   else if (bos == "sell"){ //if sell
      price = iClose(arrSymbol[s],1,shiftM1);
      double stocks = quantity / price;
      stoplossValue = (quantity + stoploss)/stocks;
      takeprofitValue = (quantity - takeprofit)/stocks;
      arrType[s] = "sell";
   }
   arrIsOrdered[s] = true;
   arrStartTime[s] = iTime(arrSymbol[s],1,shiftM1);
   arrTPValue[s] = takeprofitValue;
   arrSLValue[s] = stoplossValue;
   arrLot[s] = lot;
   arrStartPrice[s] = price;

   //update money and equity--------
   double margin = getMargin(s);
   arrMargin[s] = margin;
   totalMargin += margin;
   totalFreeMargin -= margin;
   orderCount++; //-------------Just something to add too----------
}  

void orderClose(int s){
   accountBalance += arrProfit[s];
   totalProfit -= arrProfit[s];
   totalFreeMargin += arrMargin[s];
   totalMargin -= arrMargin[s];
   Print(" |", arrSymbol[s], "|",TimeToStr(arrStartTime[s]) , "-", TimeToStr(startdate), "|", arrType[s], "|Start:",  MathRound(arrStartPrice[s]*100000)/100000, "|TP:", MathRound(arrTPValue[s]*100000)/100000, "|SL:",  MathRound(arrSLValue[s]*100000)/100000, "|End:", MathRound(arrCurrentPrice[s]*100000)/100000, "|Profit:",MathRound(arrProfit[s]*100)/100, "|Lot:",arrLot[s]); 
   
   arrEndTime[s] = startdate;
   arrIsOrdered[s] = false;
}

bool needCheck(int s){
   if (arrIsOrdered[s] == true)
      return false;
   if (iTime(arrSymbol[s],1,shiftM1) < arrEndTime[s] + secondsAfterOrderClose)
      return false;
   return true;
}


void Update(){
   amount = totalEquity*amountPercentEquity; // purchase amount in dollar
   stoploss = amount*stoplossPercentAmount; //when loss = 25;
   takeprofit = amount*takeprofitPercentAmount; //profit = 25;
   
   double a_totalProfit = 0;
   for (int s = 0; s < symbolsTotal; s++){
      if (arrIsOrdered[s] == true){                               //update only ordered symbols
         arrCurrentPrice[s] = getCurrentPrice(s);         //get current price
         arrProfit[s] = getProfit(s);                                //get profit
         //arrSwap[s] = getSwap(s);    //-----------COMING SOON------XXXXXXXXX
         a_totalProfit += arrProfit[s];
      }
   }  
   totalProfit = a_totalProfit;
   totalEquity = totalProfit + accountBalance;
   totalFreeMargin = totalEquity - totalMargin;
   if (totalEquity < lowestEquity)
      lowestEquity = totalEquity;
}


      void CheckOrders(){
         for (int s = 0; s < symbolsTotal; s++){
            if (arrIsOrdered[s] == true){     
               if (arrType[s] == "buy"){
                  if (arrCurrentPrice[s] >= arrTPValue[s] || arrCurrentPrice[s] <= arrSLValue[s])
                     orderClose(s);
               }
               else if (arrType[s] == "sell"){
                  if (arrCurrentPrice[s] <= arrTPValue[s] || arrCurrentPrice[s] >= arrSLValue[s])
                     orderClose(s);
               }
            }
         }
      }
      
double getMargin(int s){ //for TRADE purpose
   double basePairPrice;                                          //get homePair price
   if (arrBasePair[s] == accountCurrency + accountCurrency)         
      basePairPrice = 1;
   else{
      if (arrType[s] == "buy"){
         if (StringSubstr(arrBasePair[s],0,3) == accountCurrency)
            basePairPrice = 1/iClose(arrBasePair[s],1,iBarShift(arrBasePair[s],1,startdate));
         else
            basePairPrice = iClose(arrBasePair[s],1,iBarShift(arrBasePair[s],1,startdate));
      }
      else{ //sell
         if (StringSubstr(arrBasePair[s],0,3) == accountCurrency)
            basePairPrice = 1/iOpen(arrBasePair[s],1,iBarShift(arrBasePair[s],1,startdate));
         else
            basePairPrice = iOpen(arrBasePair[s],1,iBarShift(arrBasePair[s],1,startdate));
      }
   }
   return arrLot[s]*basePairPrice*100000/(double)arrLeverage[s];
}


double getProfit(int s){ //missing iOpen XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   double quotePairPrice;                                          //get homePair price
   if (arrQuotePair[s] == accountCurrency + accountCurrency)         
      quotePairPrice = 1;
   else{
      if (arrType[s] == "buy"){
         if (StringSubstr(arrQuotePair[s],0,3) == accountCurrency)
            quotePairPrice = 1/iClose(arrQuotePair[s],1,iBarShift(arrQuotePair[s],1,startdate));
         else
            quotePairPrice = iClose(arrQuotePair[s],1,iBarShift(arrQuotePair[s],1,startdate));
      }
      else{ //sell
         if (StringSubstr(arrQuotePair[s],0,3) == accountCurrency)
            quotePairPrice = 1/iOpen(arrQuotePair[s],1,iBarShift(arrQuotePair[s],1,startdate));
         else
            quotePairPrice = iOpen(arrQuotePair[s],1,iBarShift(arrQuotePair[s],1,startdate));
      }
   }
   if (arrType[s] == "buy")                                       //get profit
      return (arrCurrentPrice[s]-arrStartPrice[s])*arrLot[s]*100000*quotePairPrice;
   else //sell
      return (arrStartPrice[s]-arrCurrentPrice[s])*arrLot[s]*100000*quotePairPrice;
   
}

      double getCurrentPrice(int s){
         if (arrType[s] == "buy")
            return iClose(arrSymbol[s],1,iBarShift(arrSymbol[s],1,startdate));
         else //sell
            return iOpen(arrSymbol[s],1,iBarShift(arrSymbol[s],1,startdate));
      }

      int getSymbolLeverage(int s){
         if (arrBasePair[s] == accountCurrency + accountCurrency)
            return (int)MathRound(100000/MarketInfo(arrSymbol[s],MODE_MARGINREQUIRED));
         else if (StringSubstr(arrBasePair[s],0,3) == accountCurrency)
            return (int)MathRound(100000/(MarketInfo(arrSymbol[s],MODE_MARGINREQUIRED)*MarketInfo(arrBasePair[s],MODE_BID)));
         else
            return (int)MathRound(100000/(MarketInfo(arrSymbol[s],MODE_MARGINREQUIRED)/MarketInfo(arrBasePair[s],MODE_BID)));
      }

      string getBasePairString(int s){
         string strSymbol = arrSymbol[s];
         string base = StringSubstr(strSymbol, 0, 3);
         if (base == accountCurrency)
            return accountCurrency + accountCurrency;
         if (StringFind(strSymbol,accountCurrency) >=0)
            return strSymbol;
         for (int i=0; i<symbolsTotal;i++){ //for other quotes != USD
            if (StringFind(arrSymbol[i],base) >=0){
               if (StringFind(arrSymbol[i],accountCurrency) >= 0)
                  return arrSymbol[i];
            }
         }
         return "0";
      }
      
      string getQuotePairString(int s){ //returns "USDUSD" if it is USDUSD
         string strSymbol = arrSymbol[s];
         string quote = StringSubstr(strSymbol, 3, 3);
         if (quote == accountCurrency)
            return accountCurrency + accountCurrency;
         if (StringFind(strSymbol,accountCurrency) >=0)
            return strSymbol;
         for (int i=0; i<symbolsTotal;i++){ //for other quotes != USD
            if (StringFind(arrSymbol[i],quote) >=0){
               if (StringFind(arrSymbol[i],accountCurrency) >= 0)
                  return arrSymbol[i];
            }
         }
         return "0";
      }
      
      bool missingPair(){
         string msgString = "";
         for (int i = 0; i < symbolsTotal; i++){
            bool toBreak = false;
            if (arrBasePair[i] == "0"){
               string base = StringSubstr(arrSymbol[i],0,3);
               for(int j = 0; j < SymbolsTotal(false); j++){
                  if (StringFind(SymbolName(j,false),base) >=0){
                     if (StringFind(SymbolName(j,false),accountCurrency) >= 0){
                        msgString += SymbolName(j,false) + ", ";
                        toBreak = true;
                     }
                  }
               }
            } 
            if (arrQuotePair[i] == "0"){
               string quote = StringSubstr(arrSymbol[i],3,3);
               for(int j = 0; j < SymbolsTotal(false); j++){
                  if (StringFind(SymbolName(j,false),quote) >=0){
                     if (StringFind(SymbolName(j,false),accountCurrency) >= 0){
                        msgString += SymbolName(j,false) + ", ";
                        toBreak = true;
                     }
                  }
               }
            }
            if (toBreak == true) break;
         }
         if (msgString == "")
            return false;
         else{
            MessageBox("You have to show " + StringSubstr(msgString,0,StringLen(msgString)-2) + " on MarketWatch");
            return true;
         }
      }







double getRating(int s){
   double rating = 0;
   rating += step_MACD(s);
   return rating;
}

double step_MACD(int s){
   double rating = 0;
   int MACD[] = {5,35,10}; // Fast, Slow, Signal
   double currentPrice = iClose(arrSymbol[s],1,shiftM1); // Sell price in the charts
   //if (currentPrice == 0)
     // return 0;
   //Print("Symbol ", arrSymbol[s], currentPrice);
   for (int i = 0; i < 6; i++){
      //----Retrieve MACD info----------------------------------------
      int p = timeframe[i]; //period 
      int newshift = iBarShift(arrSymbol[s],p,startdate); //shift
      double fastline[5];
      for (int j = 0; j < 5; j++){
         fastline[j] = iMA(arrSymbol[s],p,MACD[0],0,MODE_EMA,PRICE_CLOSE,newshift) - iMA(arrSymbol[s],p,MACD[1],0,MODE_EMA,PRICE_CLOSE,newshift);
      }//-------------------------------------------------------------
      
      rating += (fastline[0]/(currentPrice/rate_MACD_fastline_position[i]))*2; //rate for the position of last bar fastline
   }
   return rating;
}
