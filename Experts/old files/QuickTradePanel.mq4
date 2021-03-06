//+------------------------------------------------------------------+
//|                                              QuickTradePanel.mq4 |
//|                                                       FancyGamer |
//|                                            fancygamer.weebly.com |
//+------------------------------------------------------------------+
#property copyright "FancyGamer"
#property link      "fancygamer.weebly.com"
#property version   "1.00"
#property strict

#include "Header/getSymbolDetails.mqh"
#include "Header/getOrderDetails.mqh"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

double pip = 0.0001;

/*double marginPercentEquity = 0.1; // purchase amount in dollar (10%)       (APPROXIMATELY)
double stoplossPercentMargin = 0.25; //when loss = 25% of amount;          (APPROXIMATELY)
double takeprofitPercentMargin = 0.25; // profit = 25% of amount;          (APPROXIMATELY)*/

const string accountCurrency = AccountCurrency();
const int accountLeverage = AccountLeverage();

string basePair;
string quotePair;

int OnInit()
  {
//---
   basePair = getPairString(Symbol(),"base",accountCurrency);
   quotePair = getPairString(Symbol(),"quote",accountCurrency);

   int tlX = 5, tlY = 15;
   
   ButtonCreate("Button_BuyStop",tlX,tlY,80,41," Buy Stop",12,clrWhite,clrBlue);
   ButtonCreate("Button_SellStop",tlX +85,tlY,80,41," Sell Stop",12,clrWhite,clrRed);
   tlY += 44;
   RectLabelCreate("Rect_1",tlX,tlY,165,71,0,clrLavender);
   LabelCreate("Label_TP",tlX+12,tlY+6,"Take profit (%):");
   EditCreate("Edit_TP",tlX + 120,tlY + 6,30,18,"4");
   LabelCreate("Label_SL",tlX+12,tlY+26,"Stop loss (%):");
   EditCreate("Edit_SL",tlX + 120,tlY + 26,30,18,"1");
   
   LabelCreate("Label_Distance",tlX+12,tlY+46,"Distance (pip):");
   EditCreate("Edit_Distance",tlX + 120,tlY + 46,30,18,"0");
   

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){ObjectsDeleteAll(0);}
void OnTick(){}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   if(id == CHARTEVENT_OBJECT_ENDEDIT){ //THIS WILL MAKE THE INPUT INTEGER-ONLY
      bool inputOK = true;
      string text = "";
      EditTextGet(text,sparam);
      for (int i = 0; i < StringLen(text); i++){
         int asc = StringGetChar(text,i);
         Print(asc);
         if (asc < 48 || asc > 57){
            Print("The input can only be digits");
            ObjectSetString(0,sparam,OBJPROP_TEXT,"0");
            inputOK = false;
            break;
         }
      }
      if (inputOK == true){
         if ((int)text > 999){
            Print("The max value is 999");
            ObjectSetString(0,sparam,OBJPROP_TEXT,"999");
         }
      }
   }
   
   if(id == CHARTEVENT_OBJECT_CLICK){
      ObjectSetInteger(0,sparam,OBJPROP_STATE,false); //reset the clicked state of the button
      
      Print(basePair, " and ", quotePair);
      
      double prevHigh = iHigh("",0,1);
      double prevLow = iLow("",0,1);
      int additionalPip = (int)ObjectGetString(0,"Edit_Distance",OBJPROP_TEXT);
      int tpDistance = (int)ObjectGetString(0,"Edit_TP",OBJPROP_TEXT);
      int slDistance = (int)ObjectGetString(0,"Edit_SL",OBJPROP_TEXT);
      
      if(sparam == "Button_BuyStop"){
         double pendingOrderPrice = NormalizeDouble(prevHigh + additionalPip*pip,Digits);
         
         double slPrice = NormalizeDouble(prevLow, Digits);
         double tpPrice = NormalizeDouble((prevHigh - prevLow)*tpDistance/slDistance + prevHigh,Digits); //"prevHigh" in this formula might need to change to pendingOrderPrice
         double lot = findLot(pendingOrderPrice,tpPrice,tpDistance/100.0);
         lot = NormalizeDouble(lot, 2);
         /*Print(slPrice);
         Print(pendingOrderPrice);
         Print(tpPrice);
         Print("lot ",lot);*/
         /*int margin = 100; // in dollar
         double quantity = getQuantity("buy", basePair, margin, accountLeverage, accountCurrency);
         double lot = MathRound(quantity/1000)/100;*/
         
         makePendingOrder(OP_BUYSTOP,pendingOrderPrice,lot,slPrice,tpPrice);
      }
      else if(sparam == "Button_SellStop"){
         double pendingOrderPrice = NormalizeDouble(prevLow - additionalPip*pip, Digits);
         double slPrice = NormalizeDouble(prevHigh, Digits);
         double tpPrice = NormalizeDouble((prevLow - prevHigh)*tpDistance/slDistance + prevLow,Digits); //"prevHigh" in this formula might need to change to pendingOrderPrice
         double lot = findLot(pendingOrderPrice,tpPrice,tpDistance/100.0);
         lot = NormalizeDouble(lot, 2);
         Print(slPrice);
         Print(pendingOrderPrice);
         Print(tpPrice);
         Print("lot ",lot);
         /*int margin = 100; // in dollar
         double quantity = getQuantity("buy", basePair, margin, accountLeverage, accountCurrency);
         double lot = MathRound(quantity/1000)/100;*/
         
         makePendingOrder(OP_SELLSTOP,pendingOrderPrice,lot,slPrice,tpPrice);
              
         
         //makePendingOrder(OP_SELLSTOP);
      }
      
      
      /*for(int i=OrdersTotal()-1; i>=0; i–)
      {
         OrderSelect(i,SELECT_BY_POS);
         if(OrderType()==OP_BUY || OrderType()==OP_SELL)
            OrderClose(OrderTicket(),OrderLots(),OrderClosePrice(),5);
         else
            OrderDelete(OrderTicket());
      }
      ObjectSetInteger(0,”CloseButton”,OBJPROP_STATE,false);
      */
   }
}
//+------------------------------------------------------------------+

void makePendingOrder(int orderType, double price, double lot, double sl, double tp){
   int ticket = 0;
   ticket = OrderSend(Symbol(),orderType,lot,price,3,sl,tp,"My order",16384,0,clrGreen);
   if(ticket < 0)
      Print("OrderSend failed with error #",GetLastError());
   else
      Print("OrderSend placed successfully");
}


double findLot(double startPrice, //findLotToEarnPercentageAtPrice   //MORE DETAILS: Find the lot value that gives us a profit that is equal to a certain percentage of AccountBalance, IF the market moves the take profit price is reached
               double endPrice,
               double percentage){ //missing iOpen XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   //predicts the profit by using the currect quotePairPrice
   string s = quotePair;
   double quotePairPrice;                                          //get homePair price
   if (quotePair == accountCurrency + accountCurrency)         
      quotePairPrice = 1;
   else{
      if (startPrice < endPrice){ //implies a (predicted) buy order
         if (StringSubstr(quotePair,0,3) == accountCurrency)
            quotePairPrice = 1/MarketInfo(s,MODE_BID);
         else
            quotePairPrice = MarketInfo(s,MODE_BID);
         Print(quotePairPrice);
      }
      else{ //sell
         if (StringSubstr(quotePair,0,3) == accountCurrency)
            quotePairPrice = 1/MarketInfo(s,MODE_ASK);
         else
            quotePairPrice = MarketInfo(s,MODE_ASK);
      }
   }
   if(quotePairPrice == 0)
      Print("This is not a currency pair!!");
   return percentage*AccountBalance()/(MathAbs(endPrice-startPrice)*100000*quotePairPrice);
}






















//+------------------------------------------------------------------+

bool ButtonCreate(const string            name="Button",            // button name
                  const int               x=0,                      // X coordinate
                  const int               y=0,                      // Y coordinate
                  const int               width=60,                 // button width
                  const int               height=30,                // button height
                  const string            text="Button",            // text
                  const int               font_size=12,             // font size
                  const color             clr=clrBlack,             // text color
                  const color             bg_clr=clrWhite,          // background color
                  const string            font="Arial",             // font
                  const bool              state=false,              // pressed/released
                  const long              chart_ID=0,               // chart's ID
                  const int               sub_window=0,             // subwindow index
                  const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                  const bool              back=false,               // in the background
                  const bool              selection=false,          // highlight to move
                  const bool              hidden=true,              // hidden in the object list
                  const long              z_order=0)                // priority for mouse click
  {
//--- reset the error value
   ResetLastError();
//--- create the button
   if(!ObjectCreate(chart_ID,name,OBJ_BUTTON,sub_window,0,0))
     {
      /*Print(__FUNCTION__,
            ": failed to create the button! Error code = ",GetLastError());
      return(false);*/
     }
//--- set button coordinates
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set button size
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
//--- set the chart's corner, relative to which point coordinates are defined
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- set the text
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set text color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set background color
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,bg_clr);
//--- set border color
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,bg_clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- set button state
   ObjectSetInteger(chart_ID,name,OBJPROP_STATE,state);
//--- enable (true) or disable (false) the mode of moving the button by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }
  
  
  
  
 
 
 bool EditCreate(const string           name="Edit",              // object name
                const int              x=0,                      // X coordinate
                const int              y=0,                      // Y coordinate
                const int              width=50,                 // width
                const int              height=18,                // height
                const string           text="Text",              // text
                const int              font_size=10,             // font size
                const color            clr=clrBlack,             // text color
                const color            back_clr=clrWhite,        // background color
                const color            border_clr=clrNONE,       // border color
                const string           font="Arial",             // font
                const long             chart_ID=0,               // chart's ID
                const int              sub_window=0,             // subwindow index
                const ENUM_ALIGN_MODE  align=ALIGN_CENTER,       // alignment type
                const bool             read_only=false,          // ability to edit
                const ENUM_BASE_CORNER corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                const bool             back=false,               // in the background
                const bool             selection=false,          // highlight to move
                const bool             hidden=true,              // hidden in the object list
                const long             z_order=0)                // priority for mouse click
  {
//--- reset the error value
   ResetLastError();
//--- create edit field
   if(!ObjectCreate(chart_ID,name,OBJ_EDIT,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create \"Edit\" object! Error code = ",GetLastError());
      //return(false);
     }
//--- set object coordinates
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
//--- set object size
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
//--- set the text
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set the type of text alignment in the object
   ObjectSetInteger(chart_ID,name,OBJPROP_ALIGN,align);
//--- enable (true) or cancel (false) read-only mode
   ObjectSetInteger(chart_ID,name,OBJPROP_READONLY,read_only);
//--- set the chart's corner, relative to which object coordinates are defined
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
//--- set text color
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set background color
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
//--- set border color
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr);
//--- display in the foreground (false) or background (true)
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the label by mouse
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }
  
  
  bool EditTextGet(string      &text,        // text
                 const string name="Edit", // object name
                 const long   chart_ID=0)  // chart's ID
  {
//--- reset the error value
   ResetLastError();
//--- get object text
   if(!ObjectGetString(chart_ID,name,OBJPROP_TEXT,0,text))
     {
      Print(__FUNCTION__,
            ": failed to get the text! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }
  
  
  bool RectLabelCreate(const string           name="RectLabel",         // label name
                     const int              x=0,                      // X coordinate
                     const int              y=0,                      // Y coordinate
                     const int              width=50,                 // width
                     const int              height=18,                // height
                     const int              line_width=1,             // flat border width
                     const color            bg_clr=clrAzure,  // background color
                     const color            border_clr=clrRed,               // flat border color (Flat)
                     const ENUM_BORDER_TYPE border=BORDER_SUNKEN,     // border type
                     const ENUM_BASE_CORNER corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                     const ENUM_LINE_STYLE  style=STYLE_SOLID,        // flat border style
                     const bool             back=false,               // in the background
                     const long             chart_ID=0,               // chart's ID
                     const int              sub_window=0,             // subwindow index
                     const bool             selection=false,          // highlight to move
                     const bool             hidden=true,              // hidden in the object list
                     const long             z_order=0)                // priority for mouse click
  {
//--- reset the error value
   ResetLastError();
//--- create a rectangle label
   if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE_LABEL,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create a rectangle label! Error code = ",GetLastError());
      //return(false);
     }
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,bg_clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_TYPE,border);
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,border_clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,line_width);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }
  
  
  
  
  bool LabelCreate(const string            name="Label",             // label name
                 const int               x=0,                      // X coordinate
                 const int               y=0,                      // Y coordinate
                 const string            text="Label",             // text
                 const int               font_size=10,             // font size
                 const color             clr=clrBlack,               // color
                 const long              chart_ID=0,               // chart's ID
                 const int               sub_window=0,             // subwindow index
                 const string            font="Arial",             // font
                 const double            angle=0.0,                // text slope
                 const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring
                 const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // anchor type
                 const bool              back=false,               // in the background
                 const bool              selection=false,          // highlight to move
                 const bool              hidden=true,              // hidden in the object list
                 const long              z_order=0)                // priority for mouse click
  {
//--- reset the error value
   ResetLastError();
//--- create a text label
   if(!ObjectCreate(chart_ID,name,OBJ_LABEL,sub_window,0,0))
     {
      Print(__FUNCTION__,
            ": failed to create text label! Error code = ",GetLastError());
      //return(false);
     }
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution
   return(true);
  }