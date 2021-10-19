//+------------------------------------------------------------------+
//|                                          get_symbolProperties.mqh |
//|                                   Copyright 2015, FancyGamer Inc |
//|                                        www.fancygamer.weebly.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, FancyGamer Inc"
#property link      "www.fancygamer.weebly.com"
#property strict

int getSymbolLeverage(string _symbol, string _basePair, string _accountCurrency){ //hello
   if (_basePair == _accountCurrency + _accountCurrency)
      return (int)MathRound(100000/MarketInfo(_symbol,MODE_MARGINREQUIRED));
   else if (StringSubstr(_basePair,0,3) == _accountCurrency)
      return (int)MathRound(100000/(MarketInfo(_symbol,MODE_MARGINREQUIRED)*MarketInfo(_basePair,MODE_BID)));
   else
      return (int)MathRound(100000/(MarketInfo(_symbol,MODE_MARGINREQUIRED)/MarketInfo(_basePair,MODE_BID)));
}


string getPairString(string _symbol, string _pairType, string _accountCurrency){ // base or quote
   string pairPart;
   if (_pairType == "base")
      pairPart = StringSubstr(_symbol, 0, 3);
   else //== "quote"
      pairPart = StringSubstr(_symbol, 3, 3);
   if (pairPart == _accountCurrency)
      return _accountCurrency + _accountCurrency;
   if (StringFind(_symbol,_accountCurrency) >=0)
      return _symbol;
   for (int i=0; i<SymbolsTotal(false);i++){ //for other quotes != USD
      if (StringFind(SymbolName(i,false),pairPart) >=0){
         if (StringFind(SymbolName(i,false),_accountCurrency) >= 0)
            return SymbolName(i,false);
      }
   }
   return "0";
}