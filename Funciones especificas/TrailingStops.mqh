#include <Trade/Trade.mqh>

CTrade trade;


//FUNCION PARA ACTIVAR TRAILING SL de COMPRA.
void DotTrailingStop (double _profitTriggerDollars, double _slOffetPoints){
   
   //Obtener el ask
   double _ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double _bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   
   //Declaramos el SL deseado
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
         //Obtenemos el PROFIT ACTUAL de la posicion en CURRENCY.
         double currentProfit = NormalizeDouble(PositionGetDouble(POSITION_PROFIT), _Digits);
         
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
            
            //Declaramos el SL deseado
            double sl = NormalizeDouble(_bid - (_slOffetPoints * _Point), _Digits);
            
            //Verificamos que el profit es mayor al Profit Trigger y que el SL esta por debajo del Offset...
            if(currentProfit >= _profitTriggerDollars && currentSL < sl){
            
               //Modificamos la posicion actualizando el SL
               trade.PositionModify(positionTicket, sl, 0);
            }
            
         }else if((PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)){
         
            //Declaramos el SL deseado
            double sl = NormalizeDouble(_ask + (_slOffetPoints * _Point), _Digits);
            
            //Verificamos que el profit es mayor al Profit Trigger y que el SL esta por debajo del Offset...
            if(currentProfit >= _profitTriggerDollars && currentSL > sl){
            
               //Modificamos la posicion actualizando el SL
               trade.PositionModify(positionTicket, sl, 0);
            }
         }
        
               
      } //Symbol Loop
      
   } //Trailing Function

}  

//POR SI EN UN FUTURO QUEREMOS BASAR EL TRIGGER EN LA DISTANCIA EN PUNTOS EN VEZ DEL PROFIT.
////Obtenemos el recorrido actual de la posicion
//double currentProfitPointsBUY = NormalizeDouble(_bid - PositionGetDouble(POSITION_PRICE_OPEN), _Digits);
//double currentProfitPointsSELL = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN) - _ask, _Digits);