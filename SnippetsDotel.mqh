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


//Consultar si no hay posiciones.
bool FlatMarket(){
  return PositionsTotal() == 0;
  //Devuelve true si no hay posiciones abiertas.
}


// === === === === === === === === === === === === === === === === === === === === === === === === === === === === //


double CalculateLotSize(double riskPercentage, double pipDistance) {
    
    // Pasando los puntos de distancia del SL a puntos del simbolo actual.
    pipDistance = pipDistance * _Point;
    
    // Obtener el balance de la cuenta
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    // Calcular el monto a arriesgar
    double riskAmount = MathRound(accountBalance * (riskPercentage / 100.0));
    
    // Obtener el símbolo actual
    string symbol = Symbol();
    
    // Obtener el valor del pip para el símbolo actual
    double pipValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double pipSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);

    
    // Calcular el valor del pip en términos de la moneda de la cuenta
    double pipValuePerLot = MathRound(pipValue / pipSize);
    
    // Calcular el tamaño del lote
    double lotSize = riskAmount / (pipDistance * pipValuePerLot);
    
    // Asegurarse de que el tamaño del lote no sea menor que el mínimo permitido
    double minLotSize = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double maxLotSize = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    
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

void AbrirVenta(double _volume, double _bid, double _slPoints, double _tpPoints, bool _isFixedRisk, double _fixedRisk){
   if(
      !trade.Sell(
         _isFixedRisk ? _fixedRisk : _volume,
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

void AbrirCompra(double _volume, double _ask, double _slPoints, double _tpPoints, bool _isFixedRisk, double _fixedRisk){
   
   
   if(
      !trade.Buy(
         _isFixedRisk ? _fixedRisk : _volume,
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



// === === === === === === === === === === === === === === === === === === === === === === === === === === === === //
   
   // Función para verificar si hay órdenes de compra abiertas
   bool HayOrdenCompraAbierta() {
      
      // Recorremos todas las posiciones abiertas
      for (int i = 0; i < PositionsTotal(); i++) {
         // Obtenemos el ticket de la posición por índice
         ulong ticket = PositionGetTicket(i);
         if (ticket != 0) {
            // Seleccionamos la posición con el ticket obtenido
            if (PositionSelectByTicket(ticket)) {
               // Obtenemos el tipo de posición
               ENUM_POSITION_TYPE tipo = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   
               // Verificamos si es una posición de compra
               if (tipo == POSITION_TYPE_BUY) {
                  return true; // Hay al menos una orden de compra abierta
               }
            }
         }
      }
      return false; // No hay órdenes de compra abiertas
   }
   
   
   // Función para verificar si hay órdenes de venta abiertas
   bool HayOrdenVentaAbierta() {
      
      // Recorremos todas las posiciones abiertas
      for (int i = 0; i < PositionsTotal(); i++) {
         // Obtenemos el ticket de la posición por índice
         ulong ticket = PositionGetTicket(i);
         if (ticket != 0) {
            // Seleccionamos la posición con el ticket obtenido
            if (PositionSelectByTicket(ticket)) {
               // Obtenemos el tipo de posición
               ENUM_POSITION_TYPE tipo = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   
               // Verificamos si es una posición de venta
               if (tipo == POSITION_TYPE_SELL) {
                  return true; // Hay al menos una orden de venta abierta
               }
            }
         }
      }
      return false; // No hay órdenes de venta abiertas
   }
   
   
   
   

// === === === === === === === === === === === === === === === === === === === === === === === === === === === === //
   
   
   


// === === === === === === === === === === === === === === === === === === === === === === === === === === === === //
   
   
   
   // Función para cerrar todas las órdenes de compra abiertas
   void CerrarOrdenesCompra() {
      // Recorremos todas las posiciones abiertas
      for (int i = 0; i < PositionsTotal(); i++) {
         // Obtenemos el ticket de la posición por índice
         ulong ticket = PositionGetTicket(i);
         if (ticket != 0) {
            // Seleccionamos la posición con el ticket obtenido
            if (PositionSelectByTicket(ticket)) {
               // Obtenemos el tipo de posición
               ENUM_POSITION_TYPE tipo = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
               
               // Verificamos si es una posición de compra
               if (tipo == POSITION_TYPE_BUY) {
                  // Cerramos la posición de compra
                  if (trade.PositionClose(ticket)) {
                     Print("Orden de compra cerrada: Ticket ", ticket);
                  } else {
                     Print("Error al cerrar la orden de compra: Ticket ", ticket, 
                           ". Error: ", GetLastError());
                  }
               }
            }
         }
      }
   }
   
   
      
   // Función para cerrar todas las órdenes de venta abiertas
   void CerrarOrdenesVenta() {
      // Recorremos todas las posiciones abiertas
      for (int i = 0; i < PositionsTotal(); i++) {
         // Obtenemos el ticket de la posición por índice
         ulong ticket = PositionGetTicket(i);
         if (ticket != 0) {
            // Seleccionamos la posición con el ticket obtenido
            if (PositionSelectByTicket(ticket)) {
               // Obtenemos el tipo de posición
               ENUM_POSITION_TYPE tipo = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
               
               // Verificamos si es una posición de venta
               if (tipo == POSITION_TYPE_SELL) {
                  // Cerramos la posición de venta
                  if (trade.PositionClose(ticket)) {
                     Print("Orden de venta cerrada: Ticket ", ticket);
                  } else {
                     Print("Error al cerrar la orden de venta: Ticket ", ticket, 
                           ". Error: ", GetLastError());
                  }
               }
            }
         }
      }
   }