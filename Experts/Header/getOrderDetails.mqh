//+------------------------------------------------------------------+
//|                                              getOrderDetails.mqh |
//|                                   Copyright 2015, FancyGamer Inc |
//|                                        www.fancygamer.weebly.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, FancyGamer Inc"
#property link      "www.fancygamer.weebly.com"
#property strict



double getQuantity(string _bos, string _basePair, double _margin, int _leverage, string _accountCurrency){
   if (_basePair == _accountCurrency + _accountCurrency)         
      return _margin*_leverage;
   else{
      if (_bos == "buy"){
         if (StringSubstr(_basePair,0,3) == _accountCurrency)
            return _margin*(double)_leverage*MarketInfo(_basePair,MODE_ASK);
         else
            return _margin*(double)_leverage/MarketInfo(_basePair,MODE_ASK);
      }
      else{ //sell
         if (StringSubstr(_basePair,0,3) == _accountCurrency)
            return _margin*(double)_leverage*MarketInfo(_basePair,MODE_BID);
         else
            return _margin*(double)_leverage/MarketInfo(_basePair,MODE_BID);
      }
   }
}
