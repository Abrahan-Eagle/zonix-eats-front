import 'package:about/about.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'pubspec.dart';
import 'package:zonix/features/utils/app_colors.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIos = theme.platform == TargetPlatform.iOS || theme.platform == TargetPlatform.macOS;

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());  // Mostrar un cargador mientras se obtienen los datos
        }

        final packageInfo = snapshot.data!;
        final aboutPage = AboutPage(
          values: {
            'version': packageInfo.version,
            'buildNumber': packageInfo.buildNumber,
            'year': DateTime.now().year.toString(),
            'author': Pubspec.authorsName.join(', '),
          },
          title: const Text(
            'Acerca de Zonix',
            style: TextStyle(
              fontSize: 24, // Ajusta el tamaño del texto si es necesario
              fontWeight: FontWeight.bold,
            ),
          ),
          applicationVersion: 'Versión ${packageInfo.version}, Build #${packageInfo.buildNumber}',
          applicationDescription: Text(
            getAppDescription(),
            textAlign: TextAlign.justify,
          ),
          applicationIcon: Container(
            margin: const EdgeInsets.only(bottom: 0), // Ajuste de margen sin valores negativos
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Ajusta el tamaño de la imagen de acuerdo al ancho de la pantalla
                double imageSize = constraints.maxWidth * 0.3; // 60% del ancho de la pantalla

                return Image.asset(
                  Theme.of(context).brightness == Brightness.dark
                      ? 'assets/images/2.png'
                      : 'assets/images/1.png',
                  width: imageSize,
                  height: imageSize,
                );
              },
            ),
          ),
          applicationLegalese: '© ${DateTime.now().year} ${Pubspec.authorsName.join(', ')}. Todos los derechos reservados.',
          children: const <Widget>[
            MarkdownPageListTile(
              filename: 'README.md',
              title: Text('Ver Readme'),
              icon: Icon(Icons.all_inclusive),
            ),
            MarkdownPageListTile(
              filename: 'CHANGELOG.md',
              title: Text('Ver Cambios'),
              icon: Icon(Icons.view_list),
            ),
            MarkdownPageListTile(
              filename: 'LICENSE.md',
              title: Text('Ver Licencia'),
              icon: Icon(Icons.description),
            ),
            MarkdownPageListTile(
              filename: 'CONTRIBUTING.md',
              title: Text('Contribuciones'),
              icon: Icon(Icons.share),
            ),
            MarkdownPageListTile(
              filename: 'CODE_OF_CONDUCT.md',
              title: Text('Código de Conducta'),
              icon: Icon(Icons.sentiment_satisfied),
            ),
            LicensesPageListTile(
              title: Text('Licencias de Código Abierto'),
              icon: Icon(Icons.favorite),
            ),
          ],
        );

        return isIos ? _buildCupertinoApp(aboutPage) : _buildMaterialApp(aboutPage);
      },
    );
  }

  Widget _buildMaterialApp(Widget aboutPage) {
    return MaterialApp(
      title: 'Acerca de Zonix',
      debugShowCheckedModeBanner: false, // Quitar el banner de depuración
      home: SafeArea(child: aboutPage),
      theme: ThemeData(
        primaryColor: AppColors.purple,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.purple,
          foregroundColor: AppColors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.purple,
          foregroundColor: AppColors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildCupertinoApp(Widget aboutPage) {
    return CupertinoApp(
      title: 'Acerca de Zonix (Cupertino)',
      home: SafeArea(child: aboutPage),
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
      ),
    );
  }
}
