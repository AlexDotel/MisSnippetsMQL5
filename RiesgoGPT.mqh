// Crea una funcion  que reciba el porcentaje que quiero arriesgar de mi cuenta (Ejemplo 2%), que reciba la distancia en pips, (ejemplo 43 pips), y con esta informacion calcule automaticamente el lotaje que debo utilizar independientemente del simbolo.
// Para crear una función en MQL5 que calcule automáticamente el tamaño del lote basado en el porcentaje de riesgo de la cuenta y la distancia en pips, debemos considerar varios factores, como el saldo de la cuenta, el valor del pip para el símbolo en cuestión y el apalancamiento. Aquí tienes un ejemplo de cómo podrías implementar esta función:
// 

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

// 
// ### Explicación:
// 
// 1. **Balance de la Cuenta**: Obtenemos el balance actual de la cuenta para calcular cuánto dinero se está dispuesto a arriesgar.
// 
// 2. **Monto a Arriesgar**: Calculamos el monto a arriesgar multiplicando el balance por el porcentaje de riesgo proporcionado.
// 
// 3. **Símbolo y Valor del Pip**: Obtenemos el símbolo actual y calculamos el valor del pip. Esto es crucial ya que el valor del pip puede variar entre diferentes pares de divisas.
// 
// 4. **Cálculo del Tamaño del Lote**: Calculamos el tamaño del lote dividiendo el monto a arriesgar por el producto de la distancia en pips y el valor del pip por lote.
// 
// 5. **Restricciones de Tamaño del Lote**: Aseguramos que el tamaño del lote calculado no sea menor que el mínimo permitido ni mayor que el máximo permitido por el broker. También ajustamos el tamaño del lote al paso más cercano permitido.
// 
// Esta función debería funcionar para cualquier símbolo, siempre que el mercado esté abierto y los valores de los símbolos estén disponibles. Asegúrate de probarla en un entorno de demostración antes de usarla en una cuenta real.
// 
