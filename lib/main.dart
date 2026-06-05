import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const BibliaApp());
}

class BibliaApp extends StatelessWidget {
  const BibliaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Biblia',
      theme: ThemeData.dark(),
      home: const Inicio(),
    );
  }
}

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  List<dynamic> biblia = [];
  List<dynamic> resultados = [];

  TextEditingController buscador = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarBiblia();
  }

  Future<void> cargarBiblia() async {
    String data = await rootBundle.loadString('assets/biblia.json');

    setState(() {
      biblia = json.decode(data);
      resultados = biblia;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Santa Biblia'), centerTitle: true),

      body: biblia.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: buscador,
                    decoration: InputDecoration(
                      hintText: 'Buscar libro...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    onChanged: (texto) {
                      setState(() {
                        resultados = biblia.where((libro) {
                          return libro['name']
                              .toString()
                              .toLowerCase()
                              .contains(texto.toLowerCase());
                        }).toList();
                      });
                    },
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: resultados.length,

                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.menu_book),

                        title: Text(resultados[index]['name']),

                        trailing: const Icon(Icons.arrow_forward_ios),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LibroScreen(libro: resultados[index]),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class LibroScreen extends StatelessWidget {
  final dynamic libro;

  const LibroScreen({super.key, required this.libro});

  @override
  Widget build(BuildContext context) {
    List capitulos = libro['chapters'];

    return Scaffold(
      appBar: AppBar(title: Text(libro['name'])),

      body: ListView.builder(
        itemCount: capitulos.length,

        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Capítulo ${index + 1}'),

            trailing: const Icon(Icons.arrow_forward_ios),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CapituloScreen(
                    libro: libro['name'],

                    numero: index + 1,

                    versiculos: capitulos[index],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CapituloScreen extends StatelessWidget {
  final String libro;
  final int numero;
  final List versiculos;

  const CapituloScreen({
    super.key,
    required this.libro,
    required this.numero,
    required this.versiculos,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$libro $numero')),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),

        itemCount: versiculos.length,

        itemBuilder: (context, index) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),

              child: Text(
                '${index + 1}. ${versiculos[index]}',

                style: const TextStyle(fontSize: 20, height: 1.5),
              ),
            ),
          );
        },
      ),
    );
  }
}
