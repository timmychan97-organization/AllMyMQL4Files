//+------------------------------------------------------------------+
//|                                            ArrayListInt_Item.mqh |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ArrayListInt_Item
  {
public:
   ArrayListInt_Item(int val);
   ~ArrayListInt_Item();
   ArrayListInt_Item *next;
   ArrayListInt_Item *prev;
   int value;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ArrayListInt_Item::ArrayListInt_Item(int val)
  {
   value = val;
   next = NULL;
   prev = NULL;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ArrayListInt_Item::~ArrayListInt_Item()
  {
  }
//+------------------------------------------------------------------+
