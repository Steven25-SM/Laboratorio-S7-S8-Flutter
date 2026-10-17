import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';

void main() => runApp(const MiApp());

const azul = Color(0xFF2563EB);
const fondo = Color(0xFFF6F8FC);
const oscuro = Color(0xFF17233B);
const gris = Color(0xFF718096);

class Producto {
  final String nombre;
  final double precio;
  final String? imagen;
  final bool esInternet;
  Producto(this.nombre, this.precio, this.imagen, {this.esInternet = true});
}

class MiApp extends StatefulWidget {
  const MiApp({super.key});
  @override
  State<MiApp> createState() => _MiAppState();
}

class _MiAppState extends State<MiApp> {
  bool sesion = false;
  bool mostrarClave = false;
  int pagina = 0;
  final usuario = TextEditingController();
  final clave = TextEditingController();
  final nombre = TextEditingController();
  final precio = TextEditingController();
  String? fotoPerfil;
  String? fotoNueva;

  // Datos precargados. Las fotos se obtienen desde Wikimedia Commons.
  final List<Producto> productos = [
    Producto('Pringles Original', 7.99,
      'https://commons.wikimedia.org/wiki/Special:FilePath/2020-09-06_16_12_15_An_open_can_of_Original_Pringles_in_the_Franklin_Farm_section_of_Oak_Hill,_Fairfax_County,_Virginia.jpg?width=400'),
    Producto('Nutella 350 g', 32.00,
      'https://commons.wikimedia.org/wiki/Special:FilePath/Nutella_ak.jpg?width=400'),
    Producto('KitKat', 4.00,
      'https://commons.wikimedia.org/wiki/Special:FilePath/2020-03-14_05_53_23_A_Kit_Kat_bar_in_the_Franklin_Farm_section_of_Oak_Hill,_Fairfax_County,_Virginia.jpg?width=400'),
  ];

  @override
  void dispose() {
    usuario.dispose();
    clave.dispose();
    nombre.dispose();
    precio.dispose();
    super.dispose();
  }

  void mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), behavior: SnackBarBehavior.floating),
    );
  }

  void iniciarSesion() {
    if (usuario.text.trim() == 'StevenSM' && clave.text == 'Tecsup00') {
      setState(() { sesion = true; pagina = 0; });
    } else {
      mensaje('Usuario o contraseña incorrectos');
    }
  }

  void cerrarSesion() {
    setState(() { sesion = false; pagina = 0; clave.clear(); });
  }

  // Este selector usa la API del navegador (Flutter Web / DartPad).
  // FileReader transforma la foto elegida en una URL de datos Base64.
  Future<String?> seleccionarFoto() async {
    final selector = html.FileUploadInputElement()..accept = 'image/*';
    selector.click();
    await selector.onChange.first;
    if (selector.files == null || selector.files!.isEmpty) return null;
    final lector = html.FileReader();
    lector.readAsDataUrl(selector.files!.first);
    await lector.onLoadEnd.first;
    return lector.result as String?;
  }

  // Las fotos web emplean el elemento HTML como respaldo en caso de CORS.
  // Las fotos del usuario se leen directamente desde memoria.
  Widget imagenProducto(Producto producto) {
    if (producto.imagen == null) {
      return const Icon(Icons.image_outlined, color: gris, size: 40);
    }
    if (producto.esInternet) {
      return Image.network(
        producto.imagen!,
        fit: BoxFit.contain,
        webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image_outlined, color: gris),
      );
    }
    return Image.memory(
      base64Decode(producto.imagen!.split(',').last),
      fit: BoxFit.contain,
    );
  }

  void guardarProducto() {
    final n = nombre.text.trim();
    final p = double.tryParse(precio.text.trim().replaceAll(',', '.'));
    if (n.isEmpty || p == null || !p.isFinite || p <= 0) {
      mensaje('Ingresa un nombre y precio válidos');
      return;
    }
    // setState notifica a Flutter que debe volver a dibujar la pantalla.
    setState(() {
      productos.add(Producto(n, p, fotoNueva, esInternet: false));
      nombre.clear();
      precio.clear();
      fotoNueva = null;
      pagina = 1;
    });
    mensaje('Producto registrado correctamente');
  }

  Widget titulo(String texto, String descripcion) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(texto, style: const TextStyle(
        fontSize: 27, fontWeight: FontWeight.bold, color: oscuro)),
      const SizedBox(height: 7),
      Text(descripcion, style: const TextStyle(color: gris, fontSize: 14)),
    ],
  );

  Widget icono(IconData dato, Color color) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: color.withOpacity(0.09),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Icon(dato, color: color, size: 26),
  );

  Widget boton(String texto, VoidCallback accion, IconData dato) => SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton.icon(
      onPressed: accion,
      icon: Icon(dato),
      label: Text(texto, style: const TextStyle(fontWeight: FontWeight.w600)),
    ),
  );

  Widget campo(String etiqueta, TextEditingController control, IconData dato,
    {bool ocultar = false, Widget? sufijo,
      TextInputType teclado = TextInputType.text}) {
    return TextField(
      controller: control,
      obscureText: ocultar,
      keyboardType: teclado,
      onSubmitted: etiqueta == 'Contraseña' ? (_) => iniciarSesion() : null,
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(dato, color: gris),
        suffixIcon: sufijo,
      ),
    );
  }

  Widget tarjetaMenu(String texto, String descripcion, IconData dato,
    Color color, VoidCallback accion) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: accion,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFEDF0F5)),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icono(dato, color),
              const Spacer(),
              Text(texto, style: const TextStyle(
                color: oscuro, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(descripcion,
                style: const TextStyle(color: gris, fontSize: 12)),
              const SizedBox(height: 9),
              Icon(Icons.arrow_forward_rounded, color: color, size: 19),
            ],
          ),
        ),
      ),
    );
  }

  Widget login() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(29),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(27)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icono(Icons.inventory_2_rounded, azul),
            const SizedBox(height: 26),
            titulo('Bienvenido de nuevo', 'Inicia sesión para continuar.'),
            const SizedBox(height: 30),
            campo('Usuario', usuario, Icons.person_outline),
            const SizedBox(height: 17),
            campo('Contraseña', clave, Icons.lock_outline,
              ocultar: !mostrarClave,
              sufijo: IconButton(
                icon: Icon(mostrarClave
                  ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => mostrarClave = !mostrarClave),
              ),
            ),
            const SizedBox(height: 26),
            boton('Iniciar sesión', iniciarSesion, Icons.login_rounded),
            const SizedBox(height: 25),
            const Center(child: Text('Sistema de gestión de productos',
              style: TextStyle(color: gris, fontSize: 12))),
          ],
        ),
      ),
    ),
  );

  // El menú es una pantalla completa, no un panel lateral.
  Widget menu() => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            titulo('¡Hola, Steven! 👋', 'Bienvenido. ¿Qué deseas hacer hoy?'),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: azul, borderRadius: BorderRadius.circular(24)),
              child: const Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tu espacio de trabajo', style: TextStyle(
                      color: Colors.white, fontSize: 19,
                      fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Gestiona tus productos fácilmente.',
                      style: TextStyle(color: Color(0xFFDCE8FF), fontSize: 13)),
                  ],
                )),
                Icon(Icons.widgets_rounded,
                  color: Color(0xFFBFDBFE), size: 48),
              ]),
            ),
            const SizedBox(height: 29),
            const Text('Menú principal', style: TextStyle(
              fontSize: 19, fontWeight: FontWeight.bold, color: oscuro)),
            const SizedBox(height: 17),
            // LayoutBuilder adapta la cantidad de columnas al ancho.
            LayoutBuilder(builder: (context, medidas) {
              final columnas = medidas.maxWidth < 500 ? 2 : 4;
              return GridView.count(
                crossAxisCount: columnas,
                crossAxisSpacing: 13,
                mainAxisSpacing: 13,
                childAspectRatio: columnas == 2 ? 0.78 : 0.70,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  tarjetaMenu('Listar productos', 'Ver inventario',
                    Icons.inventory_2_outlined, azul,
                    () => setState(() => pagina = 1)),
                  tarjetaMenu('Registrar producto', 'Agregar artículo',
                    Icons.add_box_outlined, const Color(0xFF0D9488),
                    () => setState(() => pagina = 2)),
                  tarjetaMenu('Mi perfil', 'Datos personales',
                    Icons.person_outline, const Color(0xFF8B5CF6),
                    () => setState(() => pagina = 3)),
                  tarjetaMenu('Cerrar sesión', 'Salir de mi cuenta',
                    Icons.logout_rounded, const Color(0xFFEA6474), cerrarSesion),
                ],
              );
            }),
            const SizedBox(height: 26),
            Center(child: Text('${productos.length} productos registrados',
              style: const TextStyle(color: gris))),
          ],
        ),
      ),
    ),
  );

  Widget listar() => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titulo('Mis productos', 'Explora los artículos de tu inventario.'),
            const SizedBox(height: 25),
            // map convierte cada elemento de la lista en una tarjeta visual.
            ...productos.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: const Color(0xFFEDF0F5)),
              ),
              child: Row(children: [
                Container(
                  width: 88,
                  height: 88,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14)),
                  child: imagenProducto(p),
                ),
                const SizedBox(width: 18),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nombre, style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold,
                      color: oscuro)),
                    const SizedBox(height: 8),
                    Text('S/ ${p.precio.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, color: azul,
                        fontWeight: FontWeight.bold)),
                  ],
                )),
              ]),
            )),
            const SizedBox(height: 20),
            boton('Agregar otro producto',
              () => setState(() => pagina = 2), Icons.add_rounded),
          ],
        ),
      ),
    ),
  );

  Widget registrar() => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titulo('Nuevo producto', 'Completa los datos del producto.'),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  campo('Nombre del producto', nombre,
                    Icons.shopping_bag_outlined),
                  const SizedBox(height: 18),
                  campo('Precio (S/)', precio, Icons.payments_outlined,
                    teclado: const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 25),
                  const Text('Imagen del producto', style: TextStyle(
                    fontWeight: FontWeight.w600, color: oscuro)),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    height: 165,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: fondo, borderRadius: BorderRadius.circular(16)),
                    child: fotoNueva == null
                      ? const Icon(Icons.add_photo_alternate_outlined,
                          size: 48, color: gris)
                      : Image.memory(
                          base64Decode(fotoNueva!.split(',').last),
                          fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 15),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final foto = await seleccionarFoto();
                      if (!mounted) return;
                      if (foto != null) setState(() => fotoNueva = foto);
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Seleccionar imagen'),
                  ),
                  const SizedBox(height: 27),
                  boton('Guardar producto', guardarProducto,
                    Icons.check_circle_outline),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget dato(IconData simbolo, String etiqueta, String valor) => Row(
    children: [
      icono(simbolo, azul),
      const SizedBox(width: 15),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(etiqueta, style: const TextStyle(fontSize: 12, color: gris)),
        const SizedBox(height: 5),
        Text(valor, style: const TextStyle(fontSize: 16,
          fontWeight: FontWeight.w600, color: oscuro)),
      ]),
    ],
  );

  Widget perfil() => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titulo('Mi perfil', 'Información personal y académica.'),
            const SizedBox(height: 25),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(25)),
              child: Column(children: [
                CircleAvatar(
                  radius: 76,
                  backgroundColor: const Color(0xFFEAF1FF),
                  // MemoryImage muestra los bytes de la foto seleccionada.
                  backgroundImage: fotoPerfil == null ? null : MemoryImage(
                    base64Decode(fotoPerfil!.split(',').last)),
                  child: fotoPerfil == null
                    ? const Icon(Icons.person_rounded, size: 88, color: azul)
                    : null,
                ),
                const SizedBox(height: 17),
                OutlinedButton.icon(
                  onPressed: () async {
                    final foto = await seleccionarFoto();
                    if (!mounted) return;
                    if (foto != null) setState(() => fotoPerfil = foto);
                  },
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Subir mi foto'),
                ),
                const SizedBox(height: 26),
                const Text('Steven Saldaña', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold,
                    color: oscuro)),
                const SizedBox(height: 8),
                const Text('@StevenSM', style: TextStyle(color: gris)),
                const SizedBox(height: 27),
                const Divider(color: Color(0xFFEDF0F5)),
                const SizedBox(height: 20),
                dato(Icons.cake_outlined, 'Edad', '22 años'),
                const SizedBox(height: 20),
                dato(Icons.school_outlined, 'Sección', 'C24-B'),
                const SizedBox(height: 20),
                dato(Icons.person_outline, 'Usuario', 'StevenSM'),
              ]),
            ),
          ],
        ),
      ),
    ),
  );

  Widget contenido() {
    if (!sesion) return login();
    switch (pagina) {
      case 0: return menu();
      case 1: return listar();
      case 2: return registrar();
      case 3: return perfil();
      default: return menu();
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Gestión de productos',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: fondo,
      colorScheme: ColorScheme.fromSeed(seedColor: azul, primary: azul),
      appBarTheme: const AppBarTheme(
        backgroundColor: fondo, foregroundColor: oscuro,
        elevation: 0,
        titleTextStyle: TextStyle(fontSize: 17,
          fontWeight: FontWeight.bold, color: oscuro)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fondo,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 19),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: azul,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)))),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: azul,
          padding: const EdgeInsets.symmetric(
            horizontal: 18, vertical: 15),
          side: const BorderSide(color: Color(0xFFDCE5F5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13)))),
    ),
    home: Scaffold(
      appBar: sesion ? AppBar(
        automaticallyImplyLeading: false,
        leading: pagina == 0 ? null : IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() => pagina = 0)),
        title: const Text('GESTIÓN DE PRODUCTOS'),
        actions: [
          if (pagina != 0) IconButton(
            tooltip: 'Menú principal',
            onPressed: () => setState(() => pagina = 0),
            icon: const Icon(Icons.home_outlined)),
          const SizedBox(width: 12),
        ],
      ) : null,
      body: contenido(),
    ),
  );
}
