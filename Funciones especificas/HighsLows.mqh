
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
