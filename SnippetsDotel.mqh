
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


