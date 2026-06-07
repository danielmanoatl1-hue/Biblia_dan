import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const BibliaApp());
}

/// --- GESTOR DE ESTADO GLOBAL ---
class AppEstado {
  static final ValueNotifier<Map<String, String>> favoritos = ValueNotifier({});
  static final ValueNotifier<Map<String, Color>> colores = ValueNotifier({});
  static final ValueNotifier<Map<String, String>> notas = ValueNotifier({});

  static void alternarFavorito(
    String id,
    String textoVersiculo,
    BuildContext context,
  ) {
    final copia = Map<String, String>.from(favoritos.value);
    bool seAgrego = false;

    if (copia.containsKey(id)) {
      copia.remove(id);
    } else {
      copia[id] = textoVersiculo;
      seAgrego = true;
    }
    favoritos.value = copia;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              seAgrego ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              seAgrego ? '¡Agregado a favoritos!' : 'Quitado de favoritos',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: seAgrego ? Colors.redAccent : Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void cambiarColor(String id, Color? color) {
    final copia = Map<String, Color>.from(colores.value);
    if (color == null) {
      copia.remove(id);
    } else {
      copia[id] = color;
    }
    colores.value = copia;
  }

  static void guardarNota(String id, String texto, BuildContext context) {
    final copia = Map<String, String>.from(notas.value);
    if (texto.trim().isEmpty) {
      copia.remove(id);
    } else {
      copia[id] = texto;
    }
    notas.value = copia;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Nota guardada exitosamente',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.lightBlueAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class BibliaApp extends StatelessWidget {
  const BibliaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Biblia',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(primary: Colors.amber),
      ),
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
  List<dynamic> libros = [];
  List<dynamic> resultados = [];
  TextEditingController buscador = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarBiblia();
  }

  Future<void> cargarBiblia() async {
    try {
      String data = await rootBundle.loadString('assets/biblia.json');
      final decodedData = json.decode(data);

      setState(() {
        if (decodedData is Map && decodedData.containsKey('books')) {
          libros = decodedData['books'];
        } else {
          libros = [];
        }
        resultados = libros;
      });
    } catch (e) {
      print("Error leyendo el archivo JSON: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Santa Biblia'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.sticky_note_2,
              color: Colors.lightBlueAccent,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotasGlobalScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark, color: Colors.amber),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritosScreen()),
              );
            },
          ),
        ],
      ),
      body: libros.isEmpty
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
                        String sinAcentos(String input) {
                          var conAcento = 'áéíóúÁÉÍÓÚ';
                          var sinAcento = 'aeiouAEIOU';
                          String res = input;
                          for (int i = 0; i < conAcento.length; i++) {
                            res = res.replaceAll(conAcento[i], sinAcento[i]);
                          }
                          return res;
                        }

                        resultados = libros.where((libro) {
                          final nombreLibro = sinAcentos(
                            (libro['name'] ?? '').toString().toLowerCase(),
                          );
                          final textoBusqueda = sinAcentos(texto.toLowerCase());
                          return nombreLibro.contains(textoBusqueda);
                        }).toList();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: resultados.length,
                    itemBuilder: (context, index) {
                      final libroItem = resultados[index];
                      final nombreMostrado = libroItem['name'] ?? 'Desconocido';
                      return ListTile(
                        leading: const Icon(Icons.menu_book),
                        title: Text(nombreMostrado),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LibroScreen(libro: libroItem),
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
    // Filtrar únicamente los elementos que representen capítulos reales
    List<dynamic> todosLosCapitulos = libro['chapters'] ?? [];
    List<dynamic> capitulosReales = todosLosCapitulos
        .where((c) => c['is_chapter'] == true)
        .toList();

    final nombreLibro = libro['name'] ?? 'Libro';

    return Scaffold(
      appBar: AppBar(title: Text(nombreLibro)),
      body: capitulosReales.isEmpty
          ? const Center(child: Text('No se encontraron capítulos válidos.'))
          : ListView.builder(
              itemCount: capitulosReales.length,
              itemBuilder: (context, index) {
                final datosCapitulo = capitulosReales[index];

                // Mapeo dinámico y seguro de los ítems de tipo verso
                List<dynamic> itemsCapitulo = datosCapitulo['items'] ?? [];
                List<Map<String, dynamic>> versiculosFiltrados = [];

                for (var item in itemsCapitulo) {
                  if (item is Map && item['type'] == 'verse') {
                    List<dynamic> numList = item['verse_numbers'] ?? [];
                    List<dynamic> linesList = item['lines'] ?? [];

                    int numeroVerso = numList.isNotEmpty
                        ? (int.tryParse(numList.first.toString()) ??
                              (versiculosFiltrados.length + 1))
                        : (versiculosFiltrados.length + 1);
                    String textoVerso = linesList.isNotEmpty
                        ? linesList.first.toString()
                        : '';

                    if (textoVerso.isNotEmpty) {
                      versiculosFiltrados.add({
                        'number': numeroVerso,
                        'text': textoVerso,
                      });
                    }
                  }
                }

                return ListTile(
                  title: Text('Capítulo ${index + 1}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CapituloScreen(
                          libro: nombreLibro,
                          numero: index + 1,
                          versiculos: versiculosFiltrados,
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
  final List<Map<String, dynamic>> versiculos;

  const CapituloScreen({
    super.key,
    required this.libro,
    required this.numero,
    required this.versiculos,
  });

  void _mostrarMenuContextual(
    BuildContext context,
    String idVersiculo,
    String textoVersiculo,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final textController = TextEditingController(
          text: AppEstado.notas.value[idVersiculo] ?? '',
        );

        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                idVersiculo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),

              ValueListenableBuilder(
                valueListenable: AppEstado.colores,
                builder: (context, mapaColores, _) {
                  List<Color> misColores = [
                    Colors.green.withOpacity(0.4),
                    Colors.blue.withOpacity(0.4),
                    Colors.amber.withOpacity(0.4),
                    Colors.pink.withOpacity(0.4),
                  ];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ...misColores.map((color) {
                        bool esSeleccionado =
                            mapaColores[idVersiculo]?.value == color.value;
                        return GestureDetector(
                          onTap: () {
                            AppEstado.cambiarColor(idVersiculo, color);
                            Navigator.pop(dialogContext);
                          },
                          child: CircleAvatar(
                            backgroundColor: color.withOpacity(1),
                            radius: 18,
                            child: esSeleccionado
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        );
                      }),
                      IconButton(
                        icon: const Icon(
                          Icons.format_color_reset,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          AppEstado.cambiarColor(idVersiculo, null);
                          Navigator.pop(dialogContext);
                        },
                      ),
                    ],
                  );
                },
              ),
              const Divider(height: 24, color: Colors.grey),

              ValueListenableBuilder(
                valueListenable: AppEstado.favoritos,
                builder: (context, favs, _) {
                  bool esFav = favs.containsKey(idVersiculo);
                  return ListTile(
                    leading: Icon(
                      esFav ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    title: Text(
                      esFav ? 'Quitar de Favoritos' : 'Añadir a Favoritos',
                    ),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      AppEstado.alternarFavorito(
                        idVersiculo,
                        textoVersiculo,
                        context,
                      );
                    },
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.note_add, color: Colors.lightBlue),
                title: const Text('Escribir / Ver Nota'),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _mostrarDialogoNota(context, idVersiculo, textController);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDialogoNota(
    BuildContext context,
    String idVersiculo,
    TextEditingController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nota para $idVersiculo'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Escribe tu reflexión aquí...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              AppEstado.guardarNota(idVersiculo, controller.text, context);
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$libro $numero')),
      body: versiculos.isEmpty
          ? const Center(
              child: Text(
                'Este capítulo no contiene versículos visibles.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: versiculos.length,
              itemBuilder: (context, index) {
                final itemVersiculo = versiculos[index];

                int numVersiculo = itemVersiculo['number'];
                String textoCompleto = itemVersiculo['text'];
                final String idVersiculo = "$libro $numero:$numVersiculo";

                return AnimatedBuilder(
                  animation: Listenable.merge([
                    AppEstado.colores,
                    AppEstado.favoritos,
                    AppEstado.notas,
                  ]),
                  builder: (context, _) {
                    final colorFondo = AppEstado.colores.value[idVersiculo];
                    final esFav = AppEstado.favoritos.value.containsKey(
                      idVersiculo,
                    );

                    return GestureDetector(
                      onLongPress: () => _mostrarMenuContextual(
                        context,
                        idVersiculo,
                        textoCompleto,
                      ),
                      child: Card(
                        color: colorFondo,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  '$numVersiculo. $textoCompleto',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    height: 1.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (esFav)
                                const Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                  size: 16,
                                ),
                            ],
                          ),
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

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Favoritos')),
      body: ValueListenableBuilder(
        valueListenable: AppEstado.favoritos,
        builder: (context, mapaFavs, _) {
          if (mapaFavs.isEmpty) {
            return const Center(
              child: Text(
                'No has añadido versículos favoritos aún.\nMantén presionado uno para empezar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final keys = mapaFavs.keys.toList();

          return ListView.builder(
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final citaId = keys[index];
              final textoVersiculo = mapaFavs[citaId] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            citaId,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: () => AppEstado.alternarFavorito(
                              citaId,
                              textoVersiculo,
                              context,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        textoVersiculo,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
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

class NotasGlobalScreen extends StatelessWidget {
  const NotasGlobalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Notas y Reflexiones')),
      body: ValueListenableBuilder(
        valueListenable: AppEstado.notas,
        builder: (context, mapaNotas, _) {
          if (mapaNotas.isEmpty) {
            return const Center(
              child: Text(
                'No tienes notas guardadas todavía.\nMantén presionado un versículo para escribir una.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final keys = mapaNotas.keys.toList();

          return ListView.builder(
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final citaId = keys[index];
              final cuerpoNota = mapaNotas[citaId] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: const Color(0xFF1E2530),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  title: Text(
                    citaId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.lightBlueAccent,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      cuerpoNota,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () {
                      AppEstado.guardarNota(citaId, '', context);
                    },
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
