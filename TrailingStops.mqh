#include <Trade/Trade.mqh>

CTrade trade;


//FUNCION PARA ACTIVAR TRAILING SL de COMPRA.
void CheckTrailingStop (double _bid, double _profitTriggerDollars, double _slOffetPoints){
   
   //Colocamos el SL deseado
   double sl = NormalizeDouble(_bid - (_slOffetPoints * _Point), _Digits);
   
   //Verificamos la posiciones abiertas
   Print("Posiciones Abiertas: ", PositionsTotal());
   
   //Recorremos todas las posiciones abiertas del simbolo actual
   for(int i = PositionsTotal() -1 ; i >= 0 ; i--){
      Print("Posicion Index: ", i);
      
      //Extraemos el simbolo de la posicion.
      string symbol = PositionGetSymbol(i);
      
      if(_Symbol == symbol){
         
         //Extramos el numero de ticket
         ulong positionTicket = PositionGetInteger(POSITION_TICKET);
         
         //Obtenemos el SL ACTUAL de la posicion
         double currentSL = PositionGetDouble(POSITION_SL);
         //Obtenemos el recorrido actual de la posicion
         double currentProfitPoints = NormalizeDouble(_bid - PositionGetDouble(POSITION_PRICE_OPEN), _Digits);
         //Obtenemos el PROFIT ACTUAL de la posicion en CURRENCY.
         double currentProfit = NormalizeDouble(PositionGetDouble(POSITION_PROFIT), _Digits);
            
         //Verificamos que el profit es mayor al Profit Trigger y tambien ↓
         //Verificamos que el SL esta por debajo del trigger...
         if(currentProfit >= _profitTriggerDollars && currentSL < sl){
         
            //Modificamos la posicion actualizando el SL 10 puntos
            trade.PositionModify(positionTicket, sl, 0);
         
         }
               
      } //Symbol Loop
      
   } //Trailing Function

}  