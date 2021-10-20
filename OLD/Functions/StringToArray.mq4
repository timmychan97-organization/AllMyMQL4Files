//+------------------------------------------------------------------+
//|                                                StringToArray.mq4 |
//|                                   Copyright 2015, FancyGamer Inc |
//|                                        www.fancygamer.weebly.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, FancyGamer Inc"
#property link      "www.fancygamer.weebly.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---

   //while (true){
      string array[];
      string a = "AUDNZD, AUDUSD, CADCHF, CADJPY, CHFJPY, ";
      StringToArray(a,", ",array);
      for(int i= 0; i<ArraySize(array); i++)
         Print(array[i]);
   //}
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