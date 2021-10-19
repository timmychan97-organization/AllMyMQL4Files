//+------------------------------------------------------------------+
//|                                            TradeHabitManager.mq4 |
//|                                      Copyright 2018, Timmy Chan. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Timmy Chan."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "Header/TradeHabit.mqh"

int mode = 2; //{1,2 or 3}
int maxLossCount = 4;
TradeHabit * habits[30];
int habitsCount = 0; //number of habits active
int totalhabits = 0; //number of habits that have existed. To keep track of the next habitID

double profitPercentageOfBalance = 3;
double profitToLossRatio = 4; 
datetime previousHabitStart = 0;

//Can be done better with LinkedList



/*
 MODES:
   1. Open TradeHabit at 12 everyday
   2. Open TradeHabit on every bar based on the current timeframe
   3. Open TradeHabit every day for every bar within a specific timespan 

*/

//MODE 1:
int mode_1_timeHour = 12;
int mode_1_timeMinute = 0;
int mode_1_bufferSizePercentage = 50;


//MODE 2:
int mode_2_bufferSizePercentage = 50;


int OnInit() {
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason){
   for (int i = 0; i < habitsCount; i++){
      delete habits[i];
   }
   ObjectsDeleteAll(0);
}


int tickCount = 0;

void OnTick(){
   //don't run script for every single tick
   if (++tickCount >= 10){ //run once every 10 ticks
      tickCount = 0;
      
      
      //update all habits. Remove them if needed
      for (int i = 0; i < habitsCount; i++){
         habits[i].Update();
         if (habits[i].isEnded == true){
            delete habits[i]; //delete the TradeHabit
            for (int j = i; j < habitsCount - 1; j++) //shift the other habits' index backwards to fill the hole.
               habits[j] = habits[j + 1];
            habitsCount--;
            i--; //move the index back to compensate
            //print all the on-going TradeHabits
            string resultString = "";
            for (int j = 0; j < habitsCount; j++){
               resultString += (string)habits[j].id;
               if(j != habitsCount)
                  resultString += ", ";
            }
            Print("On-going TradeHabits are: ", resultString);
         }
      }
      
      //if max tradeHabits hit, stop starting newer ones
      if (habitsCount >= 30)
         return;
      
      
      int minutesSincePreviousHabitStart = ((int)TimeCurrent() - (int)previousHabitStart)/60;
      if (mode == 1){ 
         //Start new tradeHabit when there is a new bar at around 12 o'clock (use the bar before 12)
         if (TimeHour(Time[0]) == mode_1_timeHour &&
            TimeMinute(Time[0]) == mode_1_timeMinute &&
            minutesSincePreviousHabitStart > Period()){
            //if the current bar is opened at 12 o'clock and not the same bar as previous habitStart
            double high = High[1];
            double low = Low[1];
            high += getBufferSize(mode_1_bufferSizePercentage); //10%
            low -= getBufferSize(mode_1_bufferSizePercentage); //10%
            CreateNewHabit(maxLossCount,profitPercentageOfBalance, high, low, profitToLossRatio);
            
            previousHabitStart = Time[0]; //open time of the bar.
            //Now a new tradehabit has successfully been created
         }
      } else if (mode == 2) {
         if (minutesSincePreviousHabitStart > Period()){ //if it is a new bar
            double high = High[1];
            double low = Low[1];
            high += getBufferSize(mode_2_bufferSizePercentage); //10%
            low -= getBufferSize(mode_2_bufferSizePercentage); //10%
            CreateNewHabit(maxLossCount,profitPercentageOfBalance, high, low, profitToLossRatio);
            previousHabitStart = Time[0]; //open time of the bar.
         }
      } else if (mode == 3) {
         
      } else {
         Print("ERROR - this trading mode is not supported");
      }
      /*if this tick is a new bar{
         //calc buffer size by average
      
      }*/
      //calc buffer by average
      
      
   }
   
}
//+------------------------------------------------------------------+



void CreateNewHabit(int _maxLossCount, double _profitPercentageOfBalance, double high, double low, double _profitToLossRatio){
   /*profitToLossRatio = the ratio between the takeprofit to startprice and the stoploss to startprice:
    - sets the takeprofit line to be at a distance such that the ratio will be held
   */
   int id = totalhabits;
   printf(" --- Creating new TradeHabit with id: #",id," --- ");
   double tp_buy = NormalizeDouble(high + (high - low) * _profitToLossRatio, Digits);
   double tp_sell = NormalizeDouble(low - (high - low) * _profitToLossRatio, Digits);
   low =  NormalizeDouble(low,Digits);
   high = NormalizeDouble(high,Digits);
   double prof = _profitPercentageOfBalance/100;
   habits[habitsCount] = new TradeHabit(id, _maxLossCount, prof, low, tp_buy, high, tp_sell);
   //printf("isEnded:"+(string)habits[habitsCount].isEnded);
   habitsCount += 1;
   totalhabits += 1;
}

/*
maxloss
percentOfBalance
range

*/


double getBufferSize(double percentage){
   //returns the buffer size
   //buffer size is the extra percentage pips to be added high and low. 
   return percentage/100 * getAverageBarSize();
}


double getAverageBarSize(int barCount = 250){
   //average barsize based on high and low.
   //start from previous bar. (since the current bar is inconstant)
   
   //However if barCount too large, set it down to Bars. Since there could be some bars not available offline
   if(barCount > Bars - 2) // -2 so that the for-loop below won't get out of range
      barCount = Bars - 2;
   double totalBarSize = 0;
   for (int i = 1; i <= barCount + 1; i++){
      //Print(i,"/",Bars);
      double barSize = High[i] - Low[i];
      totalBarSize += barSize;
   }
   double averageBarSize = totalBarSize/barCount;
   return averageBarSize;
}


void deleteHabit(int index){
   delete habits[index];
   // remove the habit from list
   for (int i = index + 1; i < habitsCount; i++){
      habits[i - 1] = habits[i];
   }
   habitsCount--;
   habits[habitsCount] = NULL;
}