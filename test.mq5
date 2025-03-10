#include <Trade/Trade.mqh>

CTrade trade;

input double Threshold = 10.0;  // Minimum OFI for signal
input double LotSize = 0.1;     // Handelsstørrelse

// Funktion til at generere tilfældig volumen inden for et interval
double RandomVolume(double mean, double std_dev, double min_vol, double max_vol)
{
   double rand_val = mean + std_dev * (MathRand() / 32767.0 - 0.5) * 2.0;  // Normalfordelt ca.
   return MathMax(min_vol, MathMin(max_vol, rand_val)); // Trunkér volumen
}

void OnTick()
{
   MqlBookInfo book[];

   if(!MarketBookGet(_Symbol, book))  
   {
      Print("MarketBookGet() failed, error: ", GetLastError());

      // Dummy order book med stokastisk volumen
      if(MQLInfoInteger(MQL_TESTER))
      {
         ArrayResize(book, 2);

         // Simuler volumen med trunkeret normalfordeling
         double buy_vol = RandomVolume(100.0, 30.0, 10.0, 500.0);
         double sell_vol = RandomVolume(100.0, 30.0, 10.0, 500.0);

         book[0].type = BOOK_TYPE_BUY;
         book[0].price = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID) - 0.0001, _Digits);
         book[0].volume = (long) buy_vol;

         book[1].type = BOOK_TYPE_SELL;
         book[1].price = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK) + 0.0001, _Digits);
         book[1].volume = (long) sell_vol;
      }
   }

   // Beregn OFI
   double buy_volume = 0.0;
   double sell_volume = 0.0;

   for(int i = 0; i < ArraySize(book); i++)
   {
      if(book[i].type == BOOK_TYPE_BUY)
         buy_volume += (double) book[i].volume;
      else if(book[i].type == BOOK_TYPE_SELL)
         sell_volume += (double) book[i].volume;
   }

   double OFI = buy_volume - sell_volume;
   Print("OFI: ", OFI, " | Buy Volume: ", buy_volume, " | Sell Volume: ", sell_volume);

   // Handelslogik
   if (OFI > Threshold && PositionsTotal() == 0)
   {
      trade.Buy(LotSize, _Symbol);
      Print("BUY Signal - OFI exceeded threshold!");
   }
   else if (OFI < -Threshold && PositionsTotal() == 0)
   {
      trade.Sell(LotSize, _Symbol);
      Print("SELL Signal - OFI below negative threshold!");
   }
   else if (PositionsTotal() > 0 && fabs(OFI) < (Threshold / 2))
   {
      trade.PositionClose(_Symbol);
      Print("CLOSE Position - OFI returned to neutral.");
   }
}
