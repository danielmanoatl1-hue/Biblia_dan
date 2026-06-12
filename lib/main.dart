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

  // VALUENOTIFIERS PARA AJUSTES
  static final ValueNotifier<double> tamanoLetra = ValueNotifier<double>(18.0);

  // CONTROLADOR DE TEMAS PERSONALIZADOS
  static final ValueNotifier<String> temaSeleccionado = ValueNotifier<String>(
    'dark',
  );

  static const String _keyFavs = 'biblia_favoritos';
  static const String _keyColores = 'biblia_colores';
  static const String _keyNotas = 'biblia_notes_v2';
  static const String _keyVersion = 'biblia_version_act';
  static const String _keyTamanoLetra = 'biblia_font_size';
  static const String _keyTemaPersonalizado = 'biblia_tema_personalizado';

  static Future<void> inicializar() async {
    final prefs = await SharedPreferences.getInstance();

    final String? versionGuardada = prefs.getString(_keyVersion);
    if (versionGuardada != null) {
      versionActual.value = versionGuardada;
    }

    // Cargar tamaño de letra guardado
    final double? letraGuardada = prefs.getDouble(_keyTamanoLetra);
    if (letraGuardada != null) {
      tamanoLetra.value = letraGuardada;
    }

    // Cargar tema guardado (por defecto 'dark')
    final String? temaGuardado = prefs.getString(_keyTemaPersonalizado);
    if (temaGuardado != null) {
      temaSeleccionado.value = temaGuardado;
    }

    // Inicialización de Favoritos
    final String? favsRaw = prefs.getString(_keyFavs);
    if (favsRaw != null) {
      try {
        final decoded = json.decode(favsRaw);
        if (decoded is Map) {
          favoritos.value = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    // Inicialización de Notas
    final String? notasRaw = prefs.getString(_keyNotas);
    if (notasRaw != null) {
      try {
        final decoded = json.decode(notasRaw);
        if (decoded is Map) {
          notas.value = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    // Inicialización de Colores
    final String? coloresRaw = prefs.getString(_keyColores);
    if (coloresRaw != null) {
      try {
        final decoded = json.decode(coloresRaw);
        if (decoded is Map) {
          final Map<String, dynamic> mapaColores = {};
          decoded.forEach((key, value) {
            if (value is int) {
              mapaColores[key] = Color(value);
            }
          });
          colores.value = mapaColores;
        }
      } catch (_) {}
    }
  }

  static Future<void> guardarVersion(String nuevaVersion) async {
    if (versionActual.value == nuevaVersion) return;
    versionActual.value = nuevaVersion;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyVersion, nuevaVersion);
  }

  static Future<void> guardarTamanoLetra(double nuevoTamano) async {
    tamanoLetra.value = nuevoTamano;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTamanoLetra, nuevoTamano);
  }

  static Future<void> cambiarTema(String nuevoTema) async {
    temaSeleccionado.value = nuevoTema;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTemaPersonalizado, nuevoTema);
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
      if (value is Color) mapaInts[key] = value.value;
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

  ThemeData _obtenerThemeData(String nombreTema) {
    switch (nombreTema) {
      case 'light':
        return ThemeData.light().copyWith(
          primaryColor: Colors.amber,
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
          ),
          colorScheme: const ColorScheme.light(
            primary: Colors.amber,
            surface: Colors.white,
          ),
          cardTheme: const CardThemeData(color: Colors.white),
        );
      case 'sepia':
        return ThemeData.light().copyWith(
          primaryColor: const Color(0xFF8B5A2B),
          scaffoldBackgroundColor: const Color(0xFFF4ECD8),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFE4D3B2),
            foregroundColor: Color(0xFF5B4636),
          ),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF8B5A2B),
            surface: Color(0xFFFDF8EC),
          ),
          cardTheme: const CardThemeData(color: Color(0xFFFDF8EC)),
        );
      case 'ocean':
        return ThemeData.dark().copyWith(
          primaryColor: Colors.cyan,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E293B),
            foregroundColor: Colors.cyan,
          ),
          colorScheme: const ColorScheme.dark(
            primary: Colors.cyan,
            surface: Color(0xFF1E293B),
          ),
          cardTheme: const CardThemeData(color: Color(0xFF1E293B)),
        );
      case 'forest':
        return ThemeData.dark().copyWith(
          primaryColor: const Color(0xFF81C784),
          scaffoldBackgroundColor: const Color(0xFF141F17),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E3324),
            foregroundColor: Color(0xFF81C784),
          ),
          colorScheme: const ColorScheme.dark(
            primary: const Color(0xFF81C784),
            surface: Color(0xFF1E3324),
          ),
          cardTheme: const CardThemeData(color: Color(0xFF1E3324)),
        );
      case 'lavender':
        return ThemeData.light().copyWith(
          primaryColor: Colors.deepPurpleAccent,
          scaffoldBackgroundColor: const Color(0xFFF3E5F5),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFE1BEE7),
            foregroundColor: Colors.deepPurple,
          ),
          colorScheme: const ColorScheme.light(
            primary: Colors.deepPurple,
            surface: Colors.white,
          ),
          cardTheme: const CardThemeData(color: Colors.white),
        );
      case 'amoled':
        return ThemeData.dark().copyWith(
          primaryColor: Colors.white,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF121212),
            foregroundColor: Colors.white,
          ),
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            surface: Color(0xFF121212),
          ),
          cardTheme: const CardThemeData(color: Color(0xFF121212)),
        );
      case 'dark':
      default:
        return ThemeData.dark().copyWith(
          primaryColor: Colors.amber,
          scaffoldBackgroundColor: const Color(0xFF121212),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1F1F1F),
            foregroundColor: Colors.amber,
          ),
          colorScheme: const ColorScheme.dark(
            primary: Colors.amber,
            surface: Color(0xFF1E1E1E),
          ),
          cardTheme: const CardThemeData(color: Color(0xFF1E1E1E)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppEstado.temaSeleccionado,
      builder: (context, _) {
        final currentTheme = _obtenerThemeData(
          AppEstado.temaSeleccionado.value,
        );
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Biblia Multi-Versión',
          theme: currentTheme,
          darkTheme: currentTheme,
          home: const Inicio(),
        );
      },
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
    if (mounted) cargarBibliaActual();
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

  bool _esTemaOscuro(String tema) {
    return ['dark', 'ocean', 'forest', 'amoled'].contains(tema);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppEstado.temaSeleccionado,
      builder: (context, tActual, _) {
        final bool esOscuro = _esTemaOscuro(tActual);
        final colorTexto = esOscuro ? Colors.white : Colors.black87;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Santa Biblia'),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Ajustes de la App',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AjustesScreen()),
                );
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.sticky_note_2,
                  color: Colors.lightBlueAccent,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotasGlobalScreen(),
                    ),
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
                                    : (esOscuro
                                          ? const Color(0xFF222222)
                                          : Colors.grey.shade300),
                                foregroundColor: esSeleccionado
                                    ? Colors.black
                                    : colorTexto,
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
                                      : Colors.grey.shade500,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: TextField(
                  controller: buscador,
                  style: TextStyle(color: colorTexto),
                  decoration: InputDecoration(
                    hintText: 'Buscar libro...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: esOscuro ? Colors.transparent : Colors.white,
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
                          final nombreMostrado =
                              libroItem['name'] ?? 'Desconocido';
                          return ListTile(
                            leading: const Icon(Icons.menu_book),
                            title: Text(
                              nombreMostrado,
                              style: TextStyle(color: colorTexto),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
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
      },
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
                return ListTile(
                  title: Text('Capítulo ${index + 1}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CapituloPagerScreen(
                          libro: nombreLibro,
                          capitulosReales: capitulosReales,
                          capituloInicialIndex: index,
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

/// --- CONTENEDOR DESLIZABLE CORREGIDO CON ADAPTACIÓN PARA LAPTOP ---
class CapituloPagerScreen extends StatefulWidget {
  final String libro;
  final List<dynamic> capitulosReales;
  final int capituloInicialIndex;

  const CapituloPagerScreen({
    super.key,
    required this.libro,
    required this.capitulosReales,
    required this.capituloInicialIndex,
  });

  @override
  State<CapituloPagerScreen> createState() => _CapituloPagerScreenState();
}

class _CapituloPagerScreenState extends State<CapituloPagerScreen> {
  late PageController _pageController;
  late FocusNode _focusNode;
  int _paginaActual = 0;

  @override
  void initState() {
    super.initState();
    _paginaActual = widget.capituloInicialIndex;
    _pageController = PageController(initialPage: widget.capituloInicialIndex);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _irAPaginaAnterior() {
    if (_paginaActual > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _irAPaginaSiguiente() {
    if (_paginaActual < widget.capitulosReales.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Solicitamos el foco para capturar eventos del teclado en la laptop automáticamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _irAPaginaSiguiente();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _irAPaginaAnterior();
          }
        }
      },
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.capitulosReales.length,
            onPageChanged: (index) {
              setState(() {
                _paginaActual = index;
              });
            },
            itemBuilder: (context, index) {
              final datosCapitulo = widget.capitulosReales[index];
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

              return CapituloScreen(
                libro: widget.libro,
                numero: index + 1,
                versiculos: versiculosFiltrados,
              );
            },
          ),

          // BOTÓN FLOTANTE IZQUIERDO (Capítulo anterior)
          if (_paginaActual > 0)
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Opacity(
                  opacity: 0.6,
                  child: FloatingActionButton.small(
                    heroTag: 'btn_prev_cap',
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                    onPressed: _irAPaginaAnterior,
                    child: const Icon(Icons.arrow_back_ios_new, size: 16),
                  ),
                ),
              ),
            ),

          // BOTÓN FLOTANTE DERECHO (Capítulo siguiente)
          if (_paginaActual < widget.capitulosReales.length - 1)
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Opacity(
                  opacity: 0.6,
                  child: FloatingActionButton.small(
                    heroTag: 'btn_next_cap',
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                    onPressed: _irAPaginaSiguiente,
                    child: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ),
              ),
            ),
        ],
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

  String _normalizarNombreLibro(String nombreOriginal) {
    String nombreLimpio = nombreOriginal.toLowerCase().trim();
    switch (nombreLimpio) {
      case 's. juan':
      case 'san juan':
      case 'juan':
        return 'juan';
      case 's. mateo':
      case 'san mateo':
      case 'mateo':
        return 'mateo';
      case 's. marcos':
      case 'san marcos':
      case 'marcos':
        return 'marcos';
      case 's. lucas':
      case 'san lucas':
      case 'lucas':
        return 'lucas';
      case 'hechos':
      case 'hechos de los apóstoles':
      case 'hechos de los apostoles':
        return 'hechos';
      case 'cantares':
      case 'cantar de los cantares':
        return 'cantares';
      default:
        return nombreLimpio;
    }
  }

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

      String libroAComparar = _normalizarNombreLibro(libro);

      var libroEncontrado = books.firstWhere(
        (b) => _normalizarNombreLibro(b['name'].toString()) == libroAComparar,
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
      return 'Versículo no encontrado.';
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
        final currentThemeName = AppEstado.temaSeleccionado.value;
        final bool esOscuro = [
          'dark',
          'ocean',
          'forest',
          'amoled',
        ].contains(currentThemeName);
        return AlertDialog(
          title: Text(
            'Comparador: $idVersiculo',
            style: const TextStyle(color: Colors.amber),
          ),
          backgroundColor: Theme.of(context).cardTheme.color,
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
                          ? 'Cargando...'
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
                                color: esOscuro
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade300,
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
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: esOscuro ? Colors.white : Colors.black87,
                              ),
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
        final currentThemeName = AppEstado.temaSeleccionado.value;
        final bool esOscuro = [
          'dark',
          'ocean',
          'forest',
          'amoled',
        ].contains(currentThemeName);

        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
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
                title: Text(
                  'Comparar Traducciones',
                  style: TextStyle(
                    color: esOscuro ? Colors.white : Colors.black87,
                  ),
                ),
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
                      style: TextStyle(
                        color: esOscuro ? Colors.white : Colors.black87,
                      ),
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
                title: Text(
                  'Escribir / Ver Nota',
                  style: TextStyle(
                    color: esOscuro ? Colors.white : Colors.black87,
                  ),
                ),
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
        backgroundColor: Theme.of(context).cardTheme.color,
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
    return ValueListenableBuilder<String>(
      valueListenable: AppEstado.temaSeleccionado,
      builder: (context, tActual, _) {
        final bool esOscuro = [
          'dark',
          'ocean',
          'forest',
          'amoled',
        ].contains(tActual);
        final colorTexto = esOscuro ? Colors.white : Colors.black87;

        return Scaffold(
          appBar: AppBar(
            title: ValueListenableBuilder<String>(
              valueListenable: AppEstado.versionActual,
              builder: (context, version, _) =>
                  Text('$libro $numero ($version)'),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ), // Agregamos padding horizontal para no chocar con las flechas flotantes
                  itemCount: versiculos.length,
                  itemBuilder: (context, index) {
                    final itemVersiculo =
                        versiculos[index] as Map<String, dynamic>;
                    int numVersiculo = itemVersiculo['number'] ?? (index + 1);
                    String textoCompleto = itemVersiculo['text'] ?? '';
                    final String idVersiculo = "$libro $numero:$numVersiculo";

                    return AnimatedBuilder(
                      animation: Listenable.merge([
                        AppEstado.colores,
                        AppEstado.favoritos,
                        AppEstado.tamanoLetra,
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
                        final double fontSz = AppEstado.tamanoLetra.value;

                        return GestureDetector(
                          onLongPress: () => _mostrarMenuContextual(
                            context,
                            idVersiculo,
                            textoCompleto,
                            numVersiculo,
                          ),
                          child: Card(
                            color: colorFondo,
                            elevation: esOscuro ? 1 : 2,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '$numVersiculo. $textoCompleto',
                                      style: TextStyle(
                                        fontSize: fontSz,
                                        height: 1.5,
                                        color: colorTexto,
                                      ),
                                    ),
                                  ),
                                  if (esFav) ...[
                                    const SizedBox(width: 8),
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2.0),
                                      child: Icon(
                                        Icons.favorite,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                    ),
                                  ],
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
      },
    );
  }
}

/// --- PANTALLA DE AJUSTES ---
class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppEstado.temaSeleccionado,
      builder: (context, tActual, _) {
        final bool esOscuro = [
          'dark',
          'ocean',
          'forest',
          'amoled',
        ].contains(tActual);
        final colorTexto = esOscuro ? Colors.white : Colors.black87;

        return Scaffold(
          appBar: AppBar(title: const Text('Ajustes')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const Icon(Icons.text_fields, color: Colors.amber),
                title: const Text(
                  'Tamaño de la Fuente (Lectura)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Ajusta el tamaño del texto a tu gusto',
                  style: TextStyle(
                    color: esOscuro ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: AppEstado.tamanoLetra,
                builder: (context, tamano, _) {
                  return Column(
                    children: [
                      Slider(
                        value: tamano,
                        min: 14.0,
                        max: 30.0,
                        divisions: 8,
                        activeColor: Colors.amber,
                        label: '${tamano.toInt()} px',
                        onChanged: (nuevoValor) =>
                            AppEstado.guardarTamanoLetra(nuevoValor),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Texto de ejemplo en ${tamano.toInt()} px',
                          style: TextStyle(fontSize: tamano, color: colorTexto),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Divider(height: 40),
              const ListTile(
                leading: Icon(Icons.palette, color: Colors.amber),
                title: Text(
                  'Modo / Tema de la Aplicación',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              _buildTemaOption(
                context,
                'light',
                'Modo Claro (Gris/Blanco)',
                tActual,
                colorTexto,
              ),
              _buildTemaOption(
                context,
                'dark',
                'Modo Oscuro (Gris/Ámbar)',
                tActual,
                colorTexto,
              ),
              _buildTemaOption(
                context,
                'sepia',
                'Modo Sepia (Histórico/Café)',
                tActual,
                colorTexto,
              ),
              _buildTemaOption(
                context,
                'ocean',
                'Océano Profundo (Azul Marino)',
                tActual,
                colorTexto,
              ),
              _buildTemaOption(
                context,
                'forest',
                'Bosque Místico (Verde Olivo)',
                tActual,
                colorTexto,
              ),
              _buildTemaOption(
                context,
                'lavender',
                'Amanecer Lavanda (Lila Pastel)',
                tActual,
                colorTexto,
              ),
              _buildTemaOption(
                context,
                'amoled',
                'Noche de Carbón (Negro Absoluto)',
                tActual,
                colorTexto,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemaOption(
    BuildContext context,
    String value,
    String title,
    String currentTheme,
    Color textCol,
  ) {
    return RadioListTile<String>(
      title: Text(title, style: TextStyle(color: textCol)),
      value: value,
      groupValue: currentTheme,
      activeColor: Colors.amber,
      onChanged: (val) {
        if (val != null) AppEstado.cambiarTema(val);
      },
    );
  }
}

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppEstado.temaSeleccionado,
      builder: (context, tActual, _) {
        final bool esOscuro = [
          'dark',
          'ocean',
          'forest',
          'amoled',
        ].contains(tActual);
        final colorTexto = esOscuro ? Colors.white : Colors.black87;

        return Scaffold(
          appBar: AppBar(title: const Text('Mis Favoritos')),
          body: ValueListenableBuilder<Map<String, dynamic>>(
            valueListenable: AppEstado.favoritos,
            builder: (context, mapaFavs, _) {
              if (mapaFavs.isEmpty) {
                return const Center(
                  child: Text(
                    'No has añadido versículos favoritos aún.',
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
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                              color: colorTexto,
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
      },
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
    return ValueListenableBuilder<String>(
      valueListenable: AppEstado.temaSeleccionado,
      builder: (context, tActual, _) {
        final bool esOscuro = [
          'dark',
          'ocean',
          'forest',
          'amoled',
        ].contains(tActual);
        final colorTexto = esOscuro ? Colors.white : Colors.black87;

        return Scaffold(
          appBar: AppBar(title: const Text('Mis Notas y Reflexiones')),
          body: ValueListenableBuilder<Map<String, dynamic>>(
            valueListenable: AppEstado.notas,
            builder: (context, mapaNotas, _) {
              if (mapaNotas.isEmpty) {
                return const Center(
                  child: Text(
                    'No tienes notas guardadas todavía.',
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
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                          style: TextStyle(
                            fontSize: 16,
                            color: colorTexto,
                            height: 1.4,
                          ),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () =>
                            _confirmarEliminarNota(context, citaId),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
