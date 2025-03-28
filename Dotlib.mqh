
//Importaciones necesarias para el manejo de ordenes.
#include <Trade/Trade.mqh>;
CTrade trade;

//Funcion para saber si estamos en horario.
bool EnHorario (int _horaInicial, int _horaFinal, int _minutoInicial, int _minutoFinal){

   //Creamos los structs con los parametros recibidos.
   MqlDateTime dt_inicio, dt_final;
   TimeGMT(dt_inicio);
   TimeGMT(dt_final);

   dt_inicio.hour = _horaInicial;
   dt_inicio.min = _minutoInicial;
   dt_inicio.sec = 0;
   
   dt_final.hour = _horaFinal;
   dt_final.min = _minutoFinal;
   dt_final.sec = 0;
 
   //Ahora convertimos esos Structs al tipo DateTime para poder comprarlos con el tiempo actual que viene en formato datetime.
   datetime tiempoActual = TimeGMT();
   datetime tiempo_inicio = StructToTime(dt_inicio);
   datetime tiempo_final = StructToTime(dt_final);
   
   //Finalmente comparamos el tiempo actual para saber si esta dentro del rango que le dimos.
   return tiempoActual > tiempo_inicio && tiempoActual < tiempo_final;
   
}

// === === === === === === === === === === === === === === === === === === === === === === === === === === === === //

   
double getAsk(){
   return NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
}

double getBid(){
   return NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
}

// === === === === === === === === === === === === === === === === === === === === === === === === === === === === //


//Consultar si no hay posiciones.
bool FlatMarket(){
  return PositionsTotal() == 0;
  //Devuelve true si no hay posiciones abiertas.
}


// === === === === === === === === === === === === === === === === === === === === === === === === === === === === //


double CalcularLotajeCash(double _riesgo, double stopLossPuntos){

    double lotMinimo  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN); // Lote mínimo permitido
    double lotMaximo  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX); // Lote máximo permitido
    double lotStep    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP); // Paso del lote
    double tickValue  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE); // Valor del tick
    double tickSize   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE); // Tamaño del tick
    
    if (tickValue <= 0 || tickSize <= 0) {
        Print("Error: No se pudo obtener información del símbolo.");
        return 0;
    }
    
    // Calcular el valor en dólares de un punto del activo
    double valorPorPunto = tickValue / tickSize;
    
    // Calcular el lotaje en base al riesgo y el tamaño del stop loss
    double _lotaje = (_riesgo / (stopLossPuntos * valorPorPunto));
    
    // Ajustar el lotaje al paso permitido
    _lotaje = NormalizeDouble(_lotaje / lotStep, 0) * lotStep;
    
    // Asegurar que el lotaje esté dentro de los límites permitidos
    _lotaje = MathMax(lotMinimo, MathMin(_lotaje, lotMaximo));
    
    return _lotaje;
}


// === === === === === === === === === === === === === === === === === === === === === === === === === === === === //


double CalculateLotSize(double _riskPercentage, double pipDistance) {

    double riskPercentage = _riskPercentage / 100;
    
    // Pasando los puntos de distancia del SL a puntos del simbolo actual.
    pipDistance = pipDistance * _Point;
    
    // Obtener el balance de la cuenta
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    // Calcular el monto a arriesgar
    double riskAmount = MathRound(accountBalance * (riskPercentage / 100.0));
    
    // Obtener el símbolo actual
    string _symbol = Symbol();
    
    // Obtener el valor del pip para el símbolo actual
    double pipValue = SymbolInfoDouble(_symbol, SYMBOL_TRADE_TICK_VALUE);
    double pipSize = SymbolInfoDouble(_symbol, SYMBOL_TRADE_TICK_SIZE);

    
    // Calcular el valor del pip en términos de la moneda de la cuenta
    double pipValuePerLot = MathRound(pipValue / pipSize);
    
    // Calcular el tamaño del lote
    double lotSize = riskAmount / (pipDistance * pipValuePerLot);
    
    // Asegurarse de que el tamaño del lote no sea menor que el mínimo permitido
    double minLotSize = SymbolInfoDouble(_symbol, SYMBOL_VOLUME_MIN);
    double maxLotSize = SymbolInfoDouble(_symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_symbol, SYMBOL_VOLUME_STEP);
    
    // Ajustar el tamaño del lote al paso más cercano
    double _lotSize = MathMax(minLotSize, MathMin(maxLotSize, NormalizeDouble(lotSize, int(log10(1.0 / lotStep)))));
    Comment(
      " || Riesgo en dinero: ", riskAmount,
      "\n || Pip VALUE: ", pipValue,
      "\n || Pip SIZE: ", pipSize,
      "\n || Pip VALUE X LOT: ", pipValuePerLot,
      "\n || LotSize RAW: ", lotSize,
      "\n || LotSize Final: ", _lotSize
    );
    
    return _lotSize;
}


// === === === === === === === === === === === === === === === === === === === === === === === === === === === === //

//Abrir operacion de venta

void AbrirVenta(double _volume, double _bid, double _slPoints, double _tpPoints, bool _isFixedRisk, double _fixedSize){
   if(
      !trade.Sell(
         _isFixedRisk ? _fixedSize : _volume,
         _Symbol,
         _bid,
         _slPoints == 0 ? 0 : _bid + _slPoints * _Point,
         _tpPoints == 0 ? 0 : _bid - _tpPoints * _Point
      )){
      Print("No se pudo abrir la venta: ", GetLastError());
    }
}


// === === === === === === === === === === === === === === === === === === === === === === === === === === === === //

//Abrir operacion de Compra

void AbrirCompra(double _volume, double _ask, double _slPoints, double _tpPoints, bool _isFixedRisk, double _fixedSize){
   if(
      !trade.Buy(
         _isFixedRisk ? _fixedSize : _volume,
         _Symbol,
         _ask,
         _slPoints == 0 ? 0 : _ask - _slPoints * _Point,
         _tpPoints == 0 ? 0 : _ask + _tpPoints * _Point
      )){
      Print("No se pudo abrir la compra: ", GetLastError());
    }
}

// === === === === === === === === === === === === === === === === === === === === === === === === === === === === //

//Comprobar si el precio cerro por encima o por debajo de una media movil previamente establecida.

bool precioAlcista(MqlRates  &_velas[], double&_ma[]){
   //Devuelve true si el precio esta encima de la media movil 
   return _velas[1].close > _ma[1];
   //return iClose(_Symbol, PERIOD_CURRENT, 0) > ema[0]; //Otra forma de hacerlo.
}

bool precioBajista(MqlRates  &_velas[], double&_ma[]){
   //Devuelve true si el precio esta debajo de la media movil
   return _velas[1].close < _ma[1];
}



// === === === === === === === === === === === === === === === === === === === === === === === === === === === === //



//Comprobar si rsi CRUZO un nivel hacia arriba o hacia abajo.

bool rsiCompra (double &_rsi[], short _lowLevel){
   return _rsi[2] < _lowLevel && _rsi[1] > _lowLevel;
}

bool rsiVenta (double &_rsi[], short _upLevel){
   return _rsi[2] > _upLevel && _rsi[1] < _upLevel;
}


//CERRAR ORDENES PENDIENTES MENOS LA ABIERTA
void CerrarOrdenesPendientes(){
   
   ulong ticketOrdenAbierta = 0;
      
   // Buscar la orden de mercado abierta
   for (int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if (ticket > 0) {
         ticketOrdenAbierta = ticket;
         break;
      }
   }
   
   ulong ordersCount = OrdersTotal();
   
   while(ordersCount > 1){
      ulong ticket = OrderGetTicket(OrdersTotal()-1);
       if (ticket != ticketOrdenAbierta) trade.OrderDelete(ticket);
      ordersCount -= 1;

   }
   
   }
   
 //METODO PARA NUEVA VELA
 
 bool IsNewCandle() {
    static datetime lastTime = 0;
    datetime currentTime = iTime(_Symbol, _Period, 0);

    if (currentTime != lastTime) {
        lastTime = currentTime;
        Print("NUEVA VELA");
        return true; // Hay una nueva vela
    }
    return false; // No hay nueva vela
}


// =================================================================== //

   // Función para cerrar todas las posiciones del expero actual en el activo actual
   void CloseAllExpertPositionsOnSymbol(long _magic){
      
      for(int i= PositionsTotal() ; i > 0 ; i--){
         
         ulong    positionTicket = PositionGetTicket(i);
         string   positionSymbol = PositionGetString(POSITION_SYMBOL);
         long     positionMagic  = PositionGetInteger(POSITION_MAGIC);
         
         if(positionMagic == _magic && positionSymbol == _Symbol){
            if(!trade.PositionClose(positionTicket)){
               Print("No se pudo cerrar la posicion: ", GetLastError());
            }
         }        
      }      
   }


// =================================================================== //

   // Función para cerrar todas las posiciones del activo actual
   void CloseAllPositionsOnSymbol(){
      
      for(int i= PositionsTotal() ; i > 0 ; i--){
         
         ulong    positionTicket = PositionGetTicket(i);
         string   positionSymbol = PositionGetString(POSITION_SYMBOL);
         
         if(positionSymbol == _Symbol){
            if(!trade.PositionClose(positionTicket)){
               Print("No se pudo cerrar la posicion: ", GetLastError());
            }
         }        
      }      
   }

// =================================================================== //

   // Función para cerrar todas las posiciones del experto actual
   void CloseAllExpertPositions(long _magic){
      
      for(int i = PositionsTotal() ; i > 0 ; i--){
         
         ulong    positionTicket = PositionGetTicket(i);
         long     positionMagic  = PositionGetInteger(POSITION_MAGIC);
         
         if(positionMagic == _magic){
            if(!trade.PositionClose(positionTicket)){
               Print("No se pudo cerrar la posicion: ", GetLastError());
            }
         }        
      }      
   }


// =================================================================== //

   // Función para cerrar todas las posiciones 
   void CloseAllPositions(){
      
      for(int i= PositionsTotal() ; i > 0 ; i--){
         
         ulong positionTicket = PositionGetTicket(i);
         
            if(!trade.PositionClose(positionTicket)){
               Print("No se pudo cerrar la posicion: ", GetLastError());
            }    
      }      
   }


// =================================================================================//


//FUNCION PARA ACTIVAR TRAILING SL.
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

// ============================================================================== //

//OBTENER HIGH AND LOW
void GetHighLowOfLastCandles(int _lookback, double &_high, double &_low, ENUM_TIMEFRAMES _timeframe) {
    // Inicializar variables para almacenar el high y low
    double highest = -DBL_MAX;
    double lowest = DBL_MAX;
    
    int highIndex  = -1;
    int lowIndex   = -1;
   
    string highTime;
    string lowTime; 

    // Iterar sobre las últimas 5 velas
    for (int i = 1; i < _lookback; i++) {
        // Obtener el high y low de la vela actual
        double currentHigh = iHigh(NULL, 0, i);
        double currentLow = iLow(NULL, 0, i);

        // Actualizar el high más alto encontrado
        if (currentHigh > highest) {
            highest = currentHigh;
            highIndex = i;
            highTime = TimeToString(iTime(_Symbol, _Period ,i));
        }

        // Actualizar el low más bajo encontrado
        if (currentLow < lowest) {
            lowest = currentLow;
            lowIndex = i;
            lowTime = TimeToString(iTime(_Symbol, _Period ,i));
        }
    }
    
    _high = NormalizeDouble(highest, _Digits);
    _low  = NormalizeDouble(lowest, _Digits);
    
    Print(" == High [", highIndex, "]: ", _high, " || HIGH TIME = ", highTime);
    Print(" == LOW [" , lowIndex,  "]: ", _low,  " || LOW TIME = ", lowTime);
    
}

// ================================================================================== //


// Función para abrir una orden stop de compra o venta
void OpenStopOrder(string _orderType, double _lotSize, int _magicNumber, double _price, double _slPoints, double _tpPoints)
{
    double stopLoss, takeProfit;  // Variables para el stop loss y take profit

    // Validar los parámetros
    if (_lotSize <= 0){
        Print("Error: El tamaño del lote debe ser mayor que 0.");
        return;
    }

    if (_slPoints <= 0 || _tpPoints <= 0){
        Print("Error: SL y TP deben ser mayores que 0.");
        return;
    }

    // Definir el precio, stop loss y take profit dependiendo del tipo de orden
    if (_orderType == "buy"){
        stopLoss = _price - _slPoints * _Point;  // Stop loss en puntos
        takeProfit = _price + _tpPoints * _Point;  // Take profit en puntos
    }
    else if (_orderType == "sell"){
        stopLoss = _price + _slPoints * _Point;  // Stop loss en puntos
        takeProfit = _price - _tpPoints * _Point;  // Take profit en puntos
    }else{
        Print("Error: Tipo de orden no válido. Use 'buy' o 'sell'.");
        return;
    }

    // Abrir la orden stop de compra o venta
    if (_orderType == "buy"){
    
        if (trade.BuyStop(_lotSize, _price, _Symbol, stopLoss, takeProfit, 0, _magicNumber)){
            Print("Orden de compra stop abierta con éxito. Precio: ", _price);
        }
        else{
            Print("Error al abrir la orden de compra stop: ", trade.ResultRetcode());
        }
    }
    else if (_orderType == "sell"){
    
        if (trade.SellStop(_lotSize, _price, _Symbol, stopLoss, takeProfit, 0, _magicNumber)){
            Print("Orden de venta stop abierta con éxito. Precio: ", _price);
        }
        else{
            Print("Error al abrir la orden de venta stop: ", trade.ResultRetcode());
        }
    }
}


// ================================================================================================ //


//Funcion para saber si hay una compra abierta
bool isSellOpen()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
            return true;  // Hay al menos una venta abierta
        }
    }
    return false;  // No hay ventas abiertas
}


// ---------------------------------------------------------------------------------- //

//Funcion para saber si hay una compra abierta

bool isBuyOpen()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (PositionGetSymbol(i)  == _Symbol && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
            return true;  // Hay al menos una compra abierta
        }
    }
    return false;  // No hay compras abiertas
}



// ----------------------------------------------------------------------------//

// FUNCION PARA ACTIVAR TRAILING SL BASADO EN MEDIA MOVIL.
void DotTrailingStopMA(double _maPrevious, double _profitTriggerDollars) {
   
   // Obtener el ask y bid
   double _ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double _bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   
   // Recorremos todas las posiciones abiertas del símbolo actual
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      
      // Seleccionamos la posición actual
      ulong positionTicket = PositionGetTicket(i);
      if (positionTicket == 0) continue; // Evitamos errores en caso de fallo

      // Obtenemos información de la posición
      PositionSelect((string)positionTicket);
      string symbol = PositionGetString(POSITION_SYMBOL);
      
      if (_Symbol == symbol) {
         
         // Obtenemos el SL actual de la posición
         double currentSL = PositionGetDouble(POSITION_SL);
         // Obtenemos el profit actual de la posición en moneda de la cuenta
         double currentProfit = NormalizeDouble(PositionGetDouble(POSITION_PROFIT), _Digits);
         
         if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            
            // SL deseado basado en la media móvil de la vela anterior
            double sl = NormalizeDouble(_maPrevious, _Digits);
            
            // Verificamos que el profit es mayor al Profit Trigger y que el SL está por debajo de la media móvil
            if (currentProfit >= _profitTriggerDollars && (currentSL == 0 || currentSL < sl)) {
               // Modificamos la posición actualizando el SL
               trade.PositionModify(positionTicket, sl, 0);
            }
            
         } else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
         
            // SL deseado basado en la media móvil de la vela anterior
            double sl = NormalizeDouble(_maPrevious, _Digits);
            
            // Verificamos que el profit es mayor al Profit Trigger y que el SL está por encima de la media móvil
            if (currentProfit >= _profitTriggerDollars && (currentSL == 0 || currentSL > sl)) {
               // Modificamos la posición actualizando el SL
               trade.PositionModify(positionTicket, sl, 0);
            }
         }
      } 
   }
}
