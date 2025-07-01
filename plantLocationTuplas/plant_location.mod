// Modelo de localización de plantas usando tuplas y CP Optimizer
/*Una compañía constructora de barcos tiene un cierto número de clientes. Cada cliente es abastecido por exactamente una planta. A su vez, una planta puede abastecer a varios clientes. 
 El problema es decidir dónde instalar las plantas para abastecer a cada cliente minimizando el costo de construir cada planta y el costo de transporte para abastecer a los clientes. 
 Para cada posible ubicación de planta hay un costo fijo y una capacidad de producción. Ambos tienen en cuenta el país y las condiciones geográficas. Para cada cliente, hay una demanda y un costo de transporte con respecto a cada ubicación de planta.*/
using CP;
// Tupla que representa el costo de transportar del cliente a la ubicación
tuple CostTuple {
  int customer;     // ID del cliente
  int location;   // ID de la ubicación (planta)
  int value;      // Costo de transporte entre ese cliente y esa planta
}
// Tupla con demanda por cliente
tuple DemandTuple {
  int customer;   // ID del cliente
  int value;  // Cantidad que necesita ese cliente
}

// Tupla con costo fijo y capacidad de cada ubicación
tuple LocationTuple {
  int location; // ID de la ubicación
  int fixedCost;  // Costo de abrir esa planta
  int capacity; // Capacidad máxima de producción de la planta
}

// Tupla con asignación inicial de cliente a planta 
tuple CustValueTuple {
  int customer; // ID del cliente
  int value;  // ID de planta asignada inicialmente 
}

// Conjuntos de datos
{CostTuple} costTuples = ...;
{DemandTuple} demandTuples = ...;
{LocationTuple} locationTuples = ...;
{CustValueTuple} custValueTuples = ...;

// Obtenemos el número de clientes y plantas a partir de los datos (en el ejercicio original ya estaban asignados esos valores)
int nbCustomer = max(ct in costTuples) ct.customer + 1;
int nbLocation = max(lt in locationTuples) lt.location + 1;
range Customers = 0..nbCustomer-1;
range Locations = 0..nbLocation-1;

// cust[c] = ubicación a la que se asigna el cliente c
dvar int cust[Customers] in Locations;      

dvar int open[Locations] in 0..1;          // open[l] = 1 si la planta l se crea, 0 si no

// load[l] = carga total asignada a la planta l
// El dominio es de 0 hasta la capacidad de esa planta, buscada dinámicamente
dvar int load[l in Locations] in 0..(max(lt in locationTuples: lt.location == l) lt.capacity);

// Inicialización de parámetros a partir de tuplas
// Creamos arrays auxiliares para trabajar con los datos en expresiones más simples

int cost[Customers][Locations];
int demand[Customers];
int fixedCost[Locations];
int capacity[Locations];
int custValues[Customers];

// Función objetivo
// Costo total = suma de los costos fijos de las plantas abiertas + transporte de clientes
dexpr int totalCost = sum(l in Locations) fixedCost[l]*open[l] + 
                      sum(c in Customers) cost[c][cust[c]];

// Ocupación promedio del sistema
dexpr float occupancy = sum(c in Customers) demand[c] / 
                        sum(l in Locations) open[l]*capacity[l];

// Mínima ocupación relativa entre todas las plantas abiertas
dexpr float minOccupancy = min(l in Locations) 
                          ((load[l] / capacity[l]) + (1-open[l]));


execute {
  // Cargamos matriz de costos desde costTuples
  for (var ct in costTuples) {
    cost[ct.customer][ct.location] = ct.value;
  }
  
  // Cargamos demandas desde demandTuples
  for (var dt in demandTuples) {
    demand[dt.customer] = dt.value;
  }
  
  // Cargamos costos fijos y capacidades desde locationTuples
  for (var lt in locationTuples) {
    fixedCost[lt.location] = lt.fixedCost;
    capacity[lt.location] = lt.capacity;
  }
  
  // Cargamos las asignaciones iniciales desde custValueTuples
  for (var cvt in custValueTuples) {
    custValues[cvt.customer] = cvt.value;
  }
  
  // Configuración de parámetros del solver
  cp.param.timeLimit = 10; // Límite de tiempo en segundos
  cp.param.logPeriod = 10000; // Cada cuánto imprimir log (en ms)

  // KPIs para medir la calidad de la solución
  cp.addKPI(occupancy, "Occupancy");
  cp.addKPI(minOccupancy, "Min Occupancy");
}


minimize totalCost;

// Una planta está abierta si su carga > 0
subject to {

  forall(l in Locations)
    open[l] == (load[l] > 0);
    
  // Asigna clientes a plantas respetando su capacidad (pack)
  pack(all(l in Locations) load[l], // Cargas por planta
       all(c in Customers) cust[c], // A qué planta va cada cliente
       all(c in Customers) demand[c]);  // Cuánto consume cada cliente
}

/*
Se comenta Porque Watson Studio necesita controlar el flujo para interpretar correctamente los resultados. 
Si se hace todo desde main {}, lo tratás como una caja negra y Watson no puede verificar el resultado por su cuenta.
execute {
  writeln("Solución encontrada:");
  writeln("Costo total = ", totalCost);
  writeln("Ocupación promedio = ", occupancy);
  writeln("Ocupación mínima = ", minOccupancy);
  
  for (var l in Locations) {
    if (open[l] == 1) {
      writeln("Ubicación ", l, " abierta con carga ", load[l], "/", capacity[l]);
    }
  }
}

main {
  thisOplModel.generate();
  

  var sol = new IloOplCPSolution();
  for (var c in thisOplModel.Customers) {
    sol.setValue(thisOplModel.cust[c], thisOplModel.custValues[c]);
  }
  
  cp.setStartingPoint(sol);
  if (cp.solve()) {
    thisOplModel.postProcess();
  } else {
    writeln("No se encontró solución");
  }
}*/
