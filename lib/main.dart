import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEstado.inicializar();
  runApp(const BibliaApp());
}

/// --- GESTOR DE ESTADO GLOBAL CON PERSISTENCIA ---
class AppEstado {
  static final ValueNotifier<Map<String, dynamic>> favoritos =
      ValueNotifier<Map<String, dynamic>>({});
  static final ValueNotifier<Map<String, dynamic>> colores =
      ValueNotifier<Map<String, dynamic>>({});
  static final ValueNotifier<Map<String, dynamic>> notas =
      ValueNotifier<Map<String, dynamic>>({});
  static final ValueNotifier<String> versionActual = ValueNotifier<String>(
    'RV1960',
  );

  static const String _keyFavs = 'biblia_favoritos';
  static const String _keyColores = 'biblia_colores';
  static const String _keyNotas = 'biblia_notes_v2';
  static const String _keyVersion = 'biblia_version_act';

  static Future<void> inicializar() async {
    final prefs = await SharedPreferences.getInstance();

    final String? versionGuardada = prefs.getString(_keyVersion);
    if (versionGuardada != null) {
      versionActual.value = versionGuardada;
    }

    // Inicialización de Favoritos
    final String? favsRaw = prefs.getString(_keyFavs);
    if (favsRaw != null) {
      try {
        final decoded = json.decode(favsRaw);
        if (decoded is Map) {
          favoritos.value = Map<String, dynamic>.from(decoded);
        } else {
          favoritos.value = {};
        }
      } catch (_) {
        favoritos.value = {};
      }
    }

    // Inicialización de Notas
    final String? notasRaw = prefs.getString(_keyNotas);
    if (notasRaw != null) {
      try {
        final decoded = json.decode(notasRaw);
        if (decoded is Map) {
          notas.value = Map<String, dynamic>.from(decoded);
        } else {
          notas.value = {};
        }
      } catch (_) {
        notas.value = {};
      }
    }

    // Inicialización Inteligente y Defensiva de Colores (Soporta int y String corruptos)
    final String? coloresRaw = prefs.getString(_keyColores);
    if (coloresRaw != null) {
      try {
        final decoded = json.decode(coloresRaw);
        if (decoded is Map) {
          final Map<String, dynamic> mapaColores = {};
          decoded.forEach((key, value) {
            if (value is int) {
              mapaColores[key] = Color(value);
            } else if (value is String) {
              // Si se guardó como texto por error, lo reparamos dinámicamente al vuelo
              final int? parsedColor = int.tryParse(value);
              if (parsedColor != null) {
                mapaColores[key] = Color(parsedColor);
              }
            }
          });
          colores.value = mapaColores;
        } else {
          colores.value = {};
        }
      } catch (_) {
        colores.value = {};
      }
    }
  }

  static Future<void> guardarVersion(String nuevaVersion) async {
    if (versionActual.value == nuevaVersion) return;
    versionActual.value = nuevaVersion;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyVersion, nuevaVersion);
  }

  static Future<void> _persistirFavoritos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFavs, json.encode(favoritos.value));
  }

  static Future<void> _persistirNotas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNotas, json.encode(notas.value));
  }

  static Future<void> _persistirColores() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, int> mapaInts = {};

    colores.value.forEach((key, value) {
      if (value is Color) {
        mapaInts[key] = value.value;
      } else if (value is int) {
        mapaInts[key] = value;
      }
    });

    await prefs.setString(_keyColores, json.encode(mapaInts));
  }

  static void alternarFavorito(
    String id,
    String textoVersiculo,
    BuildContext context,
  ) async {
    final copia = Map<String, dynamic>.from(favoritos.value);
    bool seAgrego = false;

    if (copia.containsKey(id)) {
      copia.remove(id);
    } else {
      copia[id] = textoVersiculo;
      seAgrego = true;
    }
    favoritos.value = copia;
    await _persistirFavoritos();

    if (!context.mounted) return;
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

  static void cambiarColor(String id, Color? color) async {
    final copia = Map<String, dynamic>.from(colores.value);
    if (color == null) {
      copia.remove(id);
    } else {
      copia[id] = color;
    }
    colores.value = copia;
    await _persistirColores();
  }

  static void guardarNota(String id, String texto, BuildContext context) async {
    final copia = Map<String, dynamic>.from(notas.value);
    bool esEliminacion = texto.trim().isEmpty;

    if (esEliminacion) {
      copia.remove(id);
    } else {
      copia[id] = texto;
    }
    notas.value = copia;
    await _persistirNotas();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              esEliminacion ? Icons.delete : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              esEliminacion ? 'Nota eliminada' : 'Nota guardada exitosamente',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: esEliminacion
            ? Colors.redAccent
            : Colors.lightBlueAccent,
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
      title: 'Biblia Multi-Versión',
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
    AppEstado.versionActual.addListener(_alCambiarVersion);
    cargarBibliaActual();
  }

  @override
  void dispose() {
    AppEstado.versionActual.removeListener(_alCambiarVersion);
    buscador.dispose();
    super.dispose();
  }

  void _alCambiarVersion() {
    if (mounted) {
      cargarBibliaActual();
    }
  }

  Future<void> cargarBibliaActual() async {
    try {
      String path = 'assets/biblia.json';
      if (AppEstado.versionActual.value == 'NTV') {
        path = 'assets/bibliaNTV.json';
      } else if (AppEstado.versionActual.value == 'TLA') {
        path = 'assets/bibliaTLA.json';
      }

      String data = await rootBundle.loadString(path);
      final decodedData = json.decode(data);

      if (!mounted) return;

      setState(() {
        if (decodedData is Map && decodedData.containsKey('books')) {
          libros = decodedData['books'];
        } else {
          libros = [];
        }
        resultados = libros;
        buscador.clear();
      });
    } catch (e) {
      debugPrint("Error leyendo archivo JSON de la Biblia: $e");
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
      body: Column(
        children: [
          ValueListenableBuilder<String>(
            valueListenable: AppEstado.versionActual,
            builder: (context, version, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['RV1960', 'NTV', 'TLA'].map((v) {
                    bool esSeleccionado = (v == version);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: esSeleccionado
                                ? Colors.amber
                                : const Color(0xFF222222),

                            foregroundColor: esSeleccionado
                                ? Colors.black
                                : Colors.white,

                            textStyle: TextStyle(
                              fontWeight: esSeleccionado
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(
                              color: esSeleccionado
                                  ? Colors.amber
                                  : Colors.grey.shade800,
                            ),
                          ),
                          onPressed: () => AppEstado.guardarVersion(v),
                          child: Text(v),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            child: libros.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
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
                List<dynamic> itemsCapitulo = datosCapitulo['items'] ?? [];
                List<dynamic> versiculosFiltrados = [];

                for (var item in itemsCapitulo) {
                  if (item is Map && item['type'] == 'verse') {
                    List<dynamic> numList = item['verse_numbers'] ?? [];
                    List<dynamic> linesList = item['lines'] ?? [];

                    int numeroVerso = numList.isNotEmpty
                        ? (int.tryParse(numList.first.toString()) ??
                              (versiculosFiltrados.length + 1))
                        : (versiculosFiltrados.length + 1);

                    String textoVerso = linesList
                        .map((e) => e.toString())
                        .join(" ")
                        .trim();

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
  final List<dynamic> versiculos;

  const CapituloScreen({
    super.key,
    required this.libro,
    required this.numero,
    required this.versiculos,
  });

  Future<String> _obtenerVersiculoDeVersion(
    String versionTarget,
    int numVersiculo,
  ) async {
    try {
      String path = 'assets/biblia.json';
      if (versionTarget == 'NTV') path = 'assets/bibliaNTV.json';
      if (versionTarget == 'TLA') path = 'assets/bibliaTLA.json';

      String data = await rootBundle.loadString(path);
      final decoded = json.decode(data);
      List<dynamic> books = decoded['books'] ?? [];

      var libroEncontrado = books.firstWhere(
        (b) => b['name'].toString().toLowerCase() == libro.toLowerCase(),
        orElse: () => null,
      );

      if (libroEncontrado != null) {
        List<dynamic> chapters = libroEncontrado['chapters'] ?? [];
        List<dynamic> reales = chapters
            .where((c) => c['is_chapter'] == true)
            .toList();

        if (numero <= reales.length) {
          var datosCapitulo = reales[numero - 1];
          List<dynamic> items = datosCapitulo['items'] ?? [];

          for (var item in items) {
            if (item is Map && item['type'] == 'verse') {
              List<dynamic> numList = item['verse_numbers'] ?? [];
              if (numList.isNotEmpty &&
                  numList.first.toString() == numVersiculo.toString()) {
                List<dynamic> linesList = item['lines'] ?? [];
                return linesList.map((e) => e.toString()).join(" ").trim();
              }
            }
          }
        }
      }
      return 'Versículo no encontrado en esta traducción.';
    } catch (e) {
      return 'Error al cargar traducción.';
    }
  }

  void _mostrarComparadorTraducciones(
    BuildContext context,
    String idVersiculo,
    int numVersiculo,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Comparador: $idVersiculo',
            style: const TextStyle(color: Colors.amber),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: ['RV1960', 'NTV', 'TLA'].map((v) {
                  return FutureBuilder<String>(
                    future: _obtenerVersiculoDeVersion(v, numVersiculo),
                    builder: (context, snapshot) {
                      String textoTraduccion =
                          snapshot.connectionState == ConnectionState.waiting
                          ? 'Cargando traducción...'
                          : (snapshot.data ?? '');

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                v,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              textoTraduccion,
                              style: const TextStyle(fontSize: 15, height: 1.4),
                            ),
                            const Divider(color: Colors.grey),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarMenuContextual(
    BuildContext context,
    String idVersiculo,
    String textoVersiculo,
    int numVersiculo,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final textController = TextEditingController(
          text: AppEstado.notas.value[idVersiculo]?.toString() ?? '',
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

              ValueListenableBuilder<Map<String, dynamic>>(
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
                        final colorGuardado = mapaColores[idVersiculo];
                        bool esSeleccionado =
                            colorGuardado is Color &&
                            colorGuardado.value == color.value;
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

              ListTile(
                leading: const Icon(Icons.compare_arrows, color: Colors.amber),
                title: const Text('Comparar Traducciones'),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _mostrarComparadorTraducciones(
                    context,
                    idVersiculo,
                    numVersiculo,
                  );
                },
              ),

              ValueListenableBuilder<Map<String, dynamic>>(
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
      appBar: AppBar(
        title: ValueListenableBuilder<String>(
          valueListenable: AppEstado.versionActual,
          builder: (context, version, _) => Text('$libro $numero ($version)'),
        ),
      ),
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
                final itemVersiculo = versiculos[index] as Map<String, dynamic>;
                int numVersiculo = itemVersiculo['number'] ?? (index + 1);
                String textoCompleto = itemVersiculo['text'] ?? '';
                final String idVersiculo = "$libro $numero:$numVersiculo";

                return ValueListenableBuilder<String>(
                  valueListenable: AppEstado.versionActual,
                  builder: (context, _, __) {
                    return AnimatedBuilder(
                      animation: Listenable.merge([
                        AppEstado.colores,
                        AppEstado.favoritos,
                        AppEstado.notas,
                      ]),
                      builder: (context, _) {
                        final colorDinamico =
                            AppEstado.colores.value[idVersiculo];
                        final Color? colorFondo = colorDinamico is Color
                            ? colorDinamico
                            : null;

                        final esFav = AppEstado.favoritos.value.containsKey(
                          idVersiculo,
                        );

                        return GestureDetector(
                          onLongPress: () => _mostrarMenuContextual(
                            context,
                            idVersiculo,
                            textoCompleto,
                            numVersiculo,
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
      body: ValueListenableBuilder<Map<String, dynamic>>(
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
              final textoVersiculo = mapaFavs[citaId]?.toString() ?? '';

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

  void _confirmarEliminarNota(BuildContext context, String citaId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la nota de $citaId?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(dialogContext);
              AppEstado.guardarNota(citaId, '', context);
            },
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Notas y Reflexiones')),
      body: ValueListenableBuilder<Map<String, dynamic>>(
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
              final cuerpoNota = mapaNotas[citaId]?.toString() ?? '';

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
                    onPressed: () => _confirmarEliminarNota(context, citaId),
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
