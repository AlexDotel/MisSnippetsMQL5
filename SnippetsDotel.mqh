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

void AbrirVenta(double _volume, double _bid, double _slPoints, double _tpPoints){
   if(
      !trade.Sell(
         _volume,
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

void AbrirCompra(double _volume, double _ask, double _slPoints, double _tpPoints){
   if(
      !trade.Buy(
         _volume,
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



//FUNCION PARA OBTENER EL HIGH EL LOW Y EL AVG PRICE.

double[] GetHighLowAvg(int LookBack){
   
   //Variable para la vela mas alta y mas baja.
   int HighestCandle, LowestCandle;   
   
   //Arrays para las los highs y los de las velas.
   double High[], Low[];
   
   //Convertimos los arrays a Series.
   ArraySetAsSeries(High, true);
   ArraySetAsSeries(Low, true);
   
   //Rellenamos los arrays.
   CopyHigh(_Symbol, _Period, 0,LookBack,High);
   CopyLow(_Symbol, _Period, 0,LookBack,Low);
   
   //Ubicamos INDICE el maximo y el minimo usando estas funciones.
   HighestCandle  = ArrayMaximum(High, 0, LookBack);
   LowestCandle   = ArrayMinimum(Low, 0, LookBack);
   
   //Creamos un arrays para almacenar el precio y lo convertimos a serie.
   MqlRates priceInfo[];
   ArraySetAsSeries(priceInfo, true);
   
   //Copiamos todas las velas disponibles dentro de nuestro array.
   //Usando Bars(Symbol(), Period())
   int data = CopyRates(Symbol(), Period(), 0,  Bars(Symbol(), Period()), priceInfo);
   
   //Como tenemos la lista de precios, y tenemos los indices de la vela mas alta, accedemos a sus respectivos valores. 
   double highesPrice = priceInfo[HighestCandle].high;
   double lowestPrice = priceInfo[LowestCandle].low;
   
   double averagePrice = NormalizeDouble(((highesPrice+lowestPrice)/2), Digits()+1);
   
   Comment("Price Information:",
         "\n High: ",highesPrice, 
         "\n Low: ", lowestPrice,
         "\n Avg: ", averagePrice
         );
         
   return [highesPrice, lowestPrice, averagePrice];
}



// === === === === === === === === === === === === === === === === === === === === === === === === === === === === //



