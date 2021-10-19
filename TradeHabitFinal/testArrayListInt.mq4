//+------------------------------------------------------------------+
//|                                             testArrayListInt.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

#include "ArrayListInt.mqh"

void OnStart()
  {
//---
   ArrayListInt arr();
   arr.add(4);
   int a = 10;
   string b = (string)a;
   printf(b);
  }
//+------------------------------------------------------------------+
