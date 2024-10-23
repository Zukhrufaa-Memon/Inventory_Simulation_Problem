import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(SimulationApp());
}

class SimulationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Simulation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: RulesScreen(), // Start with the Rules screen
    );
  }
}

// Rules Screen to display the rules and navigate to the simulation form
class RulesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simulation Rules'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Simulation Rules:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  '(a) Whenever the inventory level falls to or below 10 units, an order is placed. Only one order can be outstanding at a time.\n\n'
                  '(b) The size of each order is equal to 20 - I, where I is the inventory level when the order is placed.\n\n'
                  '(c) If a demand occurs during a period when the inventory level is zero, the sale is lost.\n\n'
                  '(d) Daily demand is normally distributed, with a mean of 5 units and a standard deviation of 1.5 units. (Round off demands to the closest integer during the simulation, and, if a negative value results, give it a demand of zero.)\n\n'
                  '(e) Lead time is distributed uniformly between zero and 5 days (integers only).\n\n'
                  '(f) The simulation will start with 18 units in inventory.\n\n'
                  '(g) For simplicity, assume that orders are placed at the close of the business day and received after the lead time has occurred.\n\n'
                  '(h) Let the simulation run for 5 weeks.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SimulationFormScreen(),
                    ),
                  );
                },
                child: Text('Proceed to Simulation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simulation Form Screen
class SimulationFormScreen extends StatefulWidget {
  @override
  _SimulationFormScreenState createState() => _SimulationFormScreenState();
}

class _SimulationFormScreenState extends State<SimulationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for input fields
  final TextEditingController initialInventoryController = TextEditingController();
  final TextEditingController reorderPointController = TextEditingController();
  final TextEditingController orderSizeController = TextEditingController();
  final TextEditingController leadTimeMinController = TextEditingController();
  final TextEditingController leadTimeMaxController = TextEditingController();
  final TextEditingController simulationWeeksController = TextEditingController();

  List<Map<String, dynamic>> simulationData = [];
  double averageLostSalesPerWeek = 0.0;

  void runSimulation() {
    // Parsing the input values
    int initialInventory = int.parse(initialInventoryController.text);
    int reorderPoint = int.parse(reorderPointController.text);
    int baseOrderSize = int.parse(orderSizeController.text);
    int leadTimeMin = int.parse(leadTimeMinController.text);
    int leadTimeMax = int.parse(leadTimeMaxController.text);
    int simulationWeeks = int.parse(simulationWeeksController.text);

    int simulationDays = simulationWeeks * 5; // 5-day workweek
    final Random random = Random();
    int inventory = initialInventory;
    int lostSales = 0;
    int outstandingOrder = 0;
    int leadTimeRemaining = -1;

    simulationData.clear();

    for (int day = 0; day < simulationDays; day++) {
      int week = (day / 5).floor() + 1;

      // Generate an RNN using the Box-Muller transform
      double rnn = generateRandomNormal(random);

      // Calculate daily demand using the formula: D = 5 + 1.5 * RNN
      int demand = max(0, (5 + 1.5 * rnn).round());

      // Track beginning inventory
      int beginInventory = inventory;

      // Fulfill demand or record lost sales
      int salesLoss = 0;
      if (inventory >= demand) {
        inventory -= demand;
      } else {
        salesLoss = demand - inventory;
        lostSales += salesLoss;
        inventory = 0;
      }

      // Check if an order needs to be placed
      int orderQuantity = 0;
      if (inventory <= reorderPoint && outstandingOrder == 0) {
        // Calculate the order size based on the formula: Order Size = baseOrderSize - inventory level
        orderQuantity = max(0, baseOrderSize - inventory);
        leadTimeRemaining = random.nextInt(leadTimeMax - leadTimeMin + 1) + leadTimeMin;
        outstandingOrder = orderQuantity;
      }

      // Update lead time and check if order is received
      if (leadTimeRemaining > 0) {
        leadTimeRemaining--;
      } else if (leadTimeRemaining == 0) {
        inventory += outstandingOrder;
        outstandingOrder = 0;
        leadTimeRemaining = -1;
      }

      // Collect data for each day
      simulationData.add({
        'Week': week,
        'Day': (day % 5) + 1,
        'Begin Inventory': beginInventory,
        'RNN': rnn.toStringAsFixed(2),
        'Demand': demand,
        'Ending Inventory': inventory,
        'Order Quantity': orderQuantity,
        'Lead Time': leadTimeRemaining >= 0 ? leadTimeRemaining : '',
        'Lost Sale': salesLoss,
      });
    }

    // Calculate average lost sales per week
    averageLostSalesPerWeek = lostSales / simulationWeeks;

    setState(() {});
  }

  double generateRandomNormal(Random random) {
    // Box-Muller transform to generate a standard normal distribution
    double u1 = random.nextDouble();
    double u2 = random.nextDouble();
    double rnn = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
    return rnn;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory Simulation Problem'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              buildTextField('Initial Inventory', initialInventoryController),
              buildTextField('Reorder Point', reorderPointController),
              buildTextField('Base Order Size', orderSizeController),
              buildTextField('Lead Time Min (Days)', leadTimeMinController),
              buildTextField('Lead Time Max (Days)', leadTimeMaxController),
              buildTextField('Simulation Weeks', simulationWeeksController),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    runSimulation();
                  }
                },
                child: Text('Run Simulation'),
              ),
              SizedBox(height: 20),
              if (simulationData.isNotEmpty) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Week')),
                      DataColumn(label: Text('Day')),
                      DataColumn(label: Text('Begin Inventory')),
                      DataColumn(label: Text('RNN')),
                      DataColumn(label: Text('Demand')),
                      DataColumn(label: Text('Ending Inventory')),
                      DataColumn(label: Text('Order Quantity')),
                      DataColumn(label: Text('Lead Time')),
                      DataColumn(label: Text('Lost Sale')),
                    ],
                    rows: simulationData
                        .map(
                          (row) => DataRow(
                            cells: [
                              DataCell(Text(row['Week'].toString())),
                              DataCell(Text(row['Day'].toString())),
                              DataCell(Text(row['Begin Inventory'].toString())),
                              DataCell(Text(row['RNN'].toString())),
                              DataCell(Text(row['Demand'].toString())),
                              DataCell(Text(row['Ending Inventory'].toString())),
                              DataCell(Text(row['Order Quantity'].toString())),
                              DataCell(Text(row['Lead Time'].toString())),
                              DataCell(Text(row['Lost Sale'].toString())),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Average Lost Sales per Week: ${averageLostSalesPerWeek.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a value';
          }
          return null;
        },
      ),
    );
  }
}