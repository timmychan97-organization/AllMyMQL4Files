
#property copyright   "2006-2015, FancyGamer Inc."
#property link        "http://www.fancygamer.weebly.com"
#property description "Period Converter to updated format of history base"
#property strict
#property show_inputs
#include <WinUser32.mqh>

input string TheSymbols = "";
int       ExtHandle=-1;


int timeframe[] = {1,5,15,30,60,240,1440,10080,43200};

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   string arrSymbol[] = {};
   StringToArray(TheSymbols,", ", arrSymbol);    //place all symbols in arrSymbol
   
   
   for (int z = 0; z < ArraySize(arrSymbol);z++){
   
      for (int y = 1; y < 6; y++){ //loop for M5 to M240
   
         ExtHandle=-1;
         
         datetime time0;
         ulong    last_fpos=0;
         long     last_volume=0;
         int      i,start_pos,periodseconds;
         int      hwnd=0,cnt=0;
      //---- History header
         int      file_version=401;
         string   c_copyright;
         string   c_symbol=arrSymbol[z];
         int      i_period=timeframe[y];
         int      i_digits=(int)MarketInfo(arrSymbol[z],MODE_DIGITS);
         int      i_unused[13];
         MqlRates rate;
      //---  
         ExtHandle=FileOpenHistory(c_symbol+(string)i_period+".hst",FILE_BIN|FILE_WRITE|FILE_SHARE_WRITE|FILE_SHARE_READ|FILE_ANSI);
         if(ExtHandle<0)
            return;
         c_copyright="(C)opyright 2015, FancyGamer Inc.";
         ArrayInitialize(i_unused,0);
      //--- write history file header
         FileWriteInteger(ExtHandle,file_version,LONG_VALUE);
         FileWriteString(ExtHandle,c_copyright,64);
         FileWriteString(ExtHandle,c_symbol,12);
         FileWriteInteger(ExtHandle,i_period,LONG_VALUE);
         FileWriteInteger(ExtHandle,i_digits,LONG_VALUE);
         FileWriteInteger(ExtHandle,0,LONG_VALUE);
         FileWriteInteger(ExtHandle,0,LONG_VALUE);
         FileWriteArray(ExtHandle,i_unused,0,13);
      //--- write history file
         periodseconds=i_period*60;
         start_pos=iBars(arrSymbol[z],1)-1;
         rate.open=iOpen(arrSymbol[z],1,start_pos);
         rate.low=iLow(arrSymbol[z],1,start_pos);
         rate.high=iHigh(arrSymbol[z],1,start_pos);
         rate.tick_volume=(long)iVolume(arrSymbol[z],1,start_pos);
         rate.spread=0;
         rate.real_volume=0;
         //--- normalize open time
         rate.time=iTime(arrSymbol[z],1,start_pos)/periodseconds;
         rate.time*=periodseconds;
         for(i=start_pos-1; i>=0; i--)
            {
            if(IsStopped())
               break;
            time0=iTime(arrSymbol[z],1,i);
            //--- history may be updated
            if(i==0)
               {
               //--- modify index if history was updated
               if(RefreshRates())
                  i=iBarShift(arrSymbol[z],1,time0);
               }
            //---
            if(time0>=rate.time+periodseconds || i==0)
               {
               if(i==0 && time0<rate.time+periodseconds)
                  {
                  rate.tick_volume+=(long)iVolume(arrSymbol[z],1,0);
                  if(rate.low>iLow(arrSymbol[z],1,0))
                     rate.low=iLow(arrSymbol[z],1,0);
                  if(rate.high<iHigh(arrSymbol[z],1,0))
                     rate.high=iHigh(arrSymbol[z],1,0);
                  rate.close=iClose(arrSymbol[z],1,0);
                  }
               last_fpos=FileTell(ExtHandle);
               last_volume=(long)iVolume(arrSymbol[z],1,i);
               FileWriteStruct(ExtHandle,rate);
               cnt++;
               if(time0>=rate.time+periodseconds)
                  {
                  rate.time=time0/periodseconds;
                  rate.time*=periodseconds;
                  rate.open=iOpen(arrSymbol[z],1,i);
                  rate.low=iLow(arrSymbol[z],1,i);
                  rate.high=iHigh(arrSymbol[z],1,i);
                  rate.close=iClose(arrSymbol[z],1,i);
                  rate.tick_volume=last_volume;
                  }
               }
               else
               {
               rate.tick_volume+=(long)iVolume(arrSymbol[z],1,i);
               if(rate.low>iLow(arrSymbol[z],1,i))
                  rate.low=iLow(arrSymbol[z],1,i);
               if(rate.high<iHigh(arrSymbol[z],1,i))
                  rate.high=iHigh(arrSymbol[z],1,i);
               rate.close=iClose(arrSymbol[z],1,i);
               }
            } 
         FileFlush(ExtHandle);
         Print(" | ",arrSymbol[z] , " | ",cnt," records written to M", i_period);
      //--- collect incoming ticks
         datetime last_time=LocalTime()-5;
     }  //end of for loop
  }
//---
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   if(ExtHandle>=0)
     {
      FileClose(ExtHandle);
      ExtHandle=-1;
     }
//---
  }
//+------------------------------------------------------------------+

void StringToArray(string str, string sep, string &out_arr[]){
   int pos = 0;
   for (int i = 0;pos >= 0;i++){
      if (StringLen(str) == 0)
         break;
      pos = StringFind(str,", ");
      ArrayResize(out_arr,i+1);
      if (pos == -1){
         out_arr[i] = str;
         break;
      }
      out_arr[i] = StringSubstr(str,0,pos);
      str = StringSubstr(str,pos+2,StringLen(str)-pos - 2);
   }
}