/*********************************************
 * OPL 22.1.1.0 Model
 * Author: Usuario
 * Creation Date: 21 jun. 2025 at 13:53:45
 *********************************************/
using CP;

// Parámetro: cantidad de centros a abrir
int N = ...;  // Se carga desde .dat

// Tuplas de datos
tuple LocationTuple {
  int location;
  int fixedCost;
  int capacity;
  float lat;
  float lon;
}

tuple CustomerTuple {
  int customer;
  int demand;
  float lat;
  float lon;
}

tuple CostTuple {
  int customer;
  int location;
  int cost;
}

// Datos desde .dat
{LocationTuple} locationTuples = ...;
{CustomerTuple} customerTuples = ...;
{CostTuple} costTuples = ...;

int nbLocation = max(lt in locationTuples) lt.location + 1;
int nbCustomer = max(ct in customerTuples) ct.customer + 1;

range Locations = 0..nbLocation-1;
range Customers = 0..nbCustomer-1;

// Variables de decisión
dvar int cust[Customers] in Locations;
dvar int open[Locations] in 0..1;
int maxCapacity = max(lt in locationTuples) lt.capacity;
dvar int load[Locations] in 0..maxCapacity;

// Arrays auxiliares
int fixedCost[Locations];
int capacity[Locations];
int demand[Customers];
int cost[Customers][Locations];






execute {
  for (var lt in locationTuples) {
    fixedCost[lt.location] = lt.fixedCost;
    capacity[lt.location] = lt.capacity;
  }
  for (var ct in customerTuples) {
    demand[ct.customer] = ct.demand;
  }
  for(var c in Customers)
    for(var l in Locations)
      cost[c][l] = 1000000;

  for(var ct in costTuples) {
    cost[ct.customer][ct.location] = ct.cost;
  }

}



dexpr int totalCost = sum(l in Locations) fixedCost[l]*open[l] + sum(c in Customers) cost[c][cust[c]];

minimize totalCost;
// Ocupación promedio del sistema
dexpr float occupancy = sum(c in Customers) demand[c] / 
                        sum(l in Locations) open[l]*capacity[l];

// Mínima ocupación relativa entre todas las plantas abiertas
dexpr float minOccupancy = min(l in Locations) 
                          ((load[l] / capacity[l]) + (1-open[l]));
subject to {
  sum(l in Locations) open[l] == N;
  forall(l in Locations)
    open[l] == (load[l] > 0);
  pack(all(l in Locations) load[l],
       all(c in Customers) cust[c],
       all(c in Customers) demand[c]);
}

tuple ResultadoAsignacion {
  int supermercado;
  int centro;
}

{ResultadoAsignacion} asignaciones = { <c, cust[c]> | c in Customers };

tuple ResultadoCarga {
  int centro;
  int carga;
  int capacidad;
  int abierto;
}

{ResultadoCarga} cargas = { <l, load[l], capacity[l], open[l]> | l in Locations };

tuple CentroAbierto {
  int centro;
  float lat;
  float lon;
}
{CentroAbierto} centrosAbiertos = {
  <lt.location, lt.lat, lt.lon> | lt in locationTuples : open[lt.location] == 1
};
execute {
  cp.addKPI(occupancy, "Occupancy");
  cp.addKPI(minOccupancy, "Min Occupancy");
  writeln("Costo total: ", totalCost);
  writeln("Ocupacion minima: ", minOccupancy);
  writeln("Ocupacion promedio: ", occupancy);
  writeln("Centros Abiertos (Tuplas): ", centrosAbiertos);
  writeln("Asignaciones Supermercado -> Centro (Tuplas): ", asignaciones);
  writeln("Cargas por Centro (Tuplas): ", cargas);
}
 