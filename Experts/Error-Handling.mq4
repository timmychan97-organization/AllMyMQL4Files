//+------------------------------------------------------------------+
//|                                              Error-Handling .mq4 |
//|                                  Copyright 2017 Jansen Invest AS |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017 Jansen Invest AS"
#property link      "https://www.mql5.com"
#property version   "1.00"


//+-----------------------------------------------------------------+
//|                                                                 |
//|         Trade Identification Using <MagicNumber>                |
//|                                                                 |
//+-----------------------------------------------------------------+

// Slik som jeg forsår det så er MagicNumer et nummer man kan tilordne en ordre slik at man kan identifisere den senere ved å referere til MagicNumber-tallet.
// Dette er et forslag basert på noe jeg husker du sa
// Altså hvorden vet algoritmen hvilken ordre som er hvem dersom en Trade-Habit på t=1 åpner sin andre ordre i serien på t=2, 
// Og samtidig så skal algoritmen åpne en ny "Trade-Habit" på t=2
//       - Siden Trade-Habit åpner hver [Dag,Uke, Måned]

OPEN Trade-Habit Intervall = (Daily, Weekly, Monthly)
OPEN Trade_Habit Intervall at; TIME = hh:mm            // Ex: TIME = 08:00 


Habit #1
   
   OPEN Trade-Habit with MagicNumber = 001
         IF Stoploss Hits
            THEN retrieve <MagicNumber> of previous lost trade.
               THEN Count <number of losses> of trades with this <MagicNumber>
         
            IF "number of losses with MagicNumber = 001" < "max no. of losses per Trade-Habit"            // Losses with MN = 001 < 
               Then ready to open new order with MagicNumber = 001
               
               
Habit #2

   OPEN New Trade-Habit with MagigNumber:
   Retrieve "highest MagicNumber" from (Live Trades, Closed Trades)          // Active, Prevoius Trades
   Assign "highest MagicNumber + 1" to  Trade-Habit                          // In this case "highest MagicNumber + 1" = 002
   