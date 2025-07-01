using CP;

tuple CostTuple {
  int customer;
  int location;
  int value;
}

tuple DemandTuple {
  int customer;
  int value;
}

tuple LocationTuple {
  int location;
  int fixedCost;
  int capacity;
}

tuple CustValueTuple {
  int customer;
  int value;
}


{CostTuple} costTuples = ...;
{DemandTuple} demandTuples = ...;
{LocationTuple} locationTuples = ...;
{CustValueTuple} custValueTuples = ...;


int nbCustomer = max(ct in costTuples) ct.customer + 1;
int nbLocation = max(lt in locationTuples) lt.location + 1;
range Customers = 0..nbCustomer-1;
range Locations = 0..nbLocation-1;


dvar int cust[Customers] in Locations;      
dvar int open[Locations] in 0..1;          
dvar int load[l in Locations] in 0..(max(lt in locationTuples: lt.location == l) lt.capacity);


int cost[Customers][Locations];
int demand[Customers];
int fixedCost[Locations];
int capacity[Locations];
int custValues[Customers];


dexpr int totalCost = sum(l in Locations) fixedCost[l]*open[l] + 
                      sum(c in Customers) cost[c][cust[c]];

dexpr float occupancy = sum(c in Customers) demand[c] / 
                        sum(l in Locations) open[l]*capacity[l];

dexpr float minOccupancy = min(l in Locations) 
                          ((load[l] / capacity[l]) + (1-open[l]));


execute {

  for (var ct in costTuples) {
    cost[ct.customer][ct.location] = ct.value;
  }
  

  for (var dt in demandTuples) {
    demand[dt.customer] = dt.value;
  }
  

  for (var lt in locationTuples) {
    fixedCost[lt.location] = lt.fixedCost;
    capacity[lt.location] = lt.capacity;
  }
  

  for (var cvt in custValueTuples) {
    custValues[cvt.customer] = cvt.value;
  }
  

  cp.param.timeLimit = 10;
  cp.param.logPeriod = 10000;
  cp.addKPI(occupancy, "Occupancy");
  cp.addKPI(minOccupancy, "Min Occupancy");
}


minimize totalCost;


subject to {

  forall(l in Locations)
    open[l] == (load[l] > 0);
    

  pack(all(l in Locations) load[l],
       all(c in Customers) cust[c],
       all(c in Customers) demand[c]);
}

/*
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