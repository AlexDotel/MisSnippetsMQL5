
//OBTENER HIGH AND LOW
void GetHighLowOfLastCandles(double &_high, double &_low) {
    // Inicializar variables para almacenar el high y low
    double highest = -DBL_MAX;
    double lowest = DBL_MAX;

    // Iterar sobre las últimas 5 velas
    for (int i = 0; i < 5; i++) {
        // Obtener el high y low de la vela actual
        double currentHigh = iHigh(NULL, 0, i);
        double currentLow = iLow(NULL, 0, i);

        // Actualizar el high más alto encontrado
        if (currentHigh > highest) {
            highest = currentHigh;
        }

        // Actualizar el low más bajo encontrado
        if (currentLow < lowest) {
            lowest = currentLow;
        }
    }
      
    _high = highest;
    _low  = lowest;
   
}

//PENDIENTE DE PRUEBA!!!