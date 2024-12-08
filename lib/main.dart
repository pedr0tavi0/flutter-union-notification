// Importação dos pacotes necessários
import 'package:flutter/material.dart'; // Para usar widgets e estrutura de design do Flutter
import 'dart:async'; // Para usar o Timer e StreamSubscription
import 'package:easy_geofencing/easy_geofencing.dart'; // Para geofencing
import 'package:easy_geofencing/enums/geofence_status.dart'; // Para acessar o status do geofencing
import 'package:geolocator/geolocator.dart'; // Para acessar a localização do dispositivo
import 'notification/notification.dart'; // Para mostrar notificações locais
import 'package:timezone/data/latest.dart' as tz; // Para inicializar os fusos horários, necessário para notificações

// Função principal que inicializa o app
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Garante que a inicialização dos widgets seja concluída antes de qualquer outra operação assíncrona
  await NotificationService.init(); // Inicializa o serviço de notificações
  tz.initializeTimeZones(); // Inicializa os fusos horários para notificações
  runApp(const MyApp()); // Inicia o aplicativo
}

// Classe principal do aplicativo que define o MaterialApp
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geofencing com Notificações', // Título do aplicativo
      theme: ThemeData( // Define o tema do aplicativo
        primarySwatch: Colors.blue, // Cor primária do tema
      ),
      home: const MyHomePage(title: 'Geofencing com Notificações'), // Página inicial do aplicativo
    );
  }
}

// Página inicial do aplicativo
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.title}); // Construtor que recebe um título para a página

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState(); // Cria o estado da página
}

// Estado da página principal
class _MyHomePageState extends State<MyHomePage> {
  // Variáveis para gerenciar o status do geofencing e a lógica de temporizador
  StreamSubscription<GeofenceStatus>? geofenceStatusStream; // Para escutar as mudanças de status do geofencing
  String geofenceStatus = 'Fora da área definida'; // Status inicial da área (fora da área)
  Timer? timer; // Temporizador para checar a posição a cada intervalo

  // Definições de latitude, longitude e raio da área de geofencing
  final double definedLatitude = -22.355431;
  final double definedLongitude = -47.334057;
  final double definedRadius = 94.00;

  // Função chamada ao inicializar o estado da página
  @override
  void initState() {
    super.initState(); // Chama o initState da superclasse
    startGeofencing(); // Inicia o geofencing
  }

  // Função que inicializa o serviço de geofencing
  void startGeofencing() {
    // Inicia o serviço de geofencing, passando a latitude, longitude, raio e o intervalo para verificação
    EasyGeofencing.startGeofenceService(
      pointedLatitude: definedLatitude.toString(),
      pointedLongitude: definedLongitude.toString(),
      radiusMeter: definedRadius.toString(),
      eventPeriodInSeconds: 30, // Intervalo de 30 segundos para verificar se a posição mudou
    );

    // Escuta os eventos do geofencing e chama a função de atualização do status quando houver mudanças
    geofenceStatusStream = EasyGeofencing.getGeofenceStream()?.listen((GeofenceStatus status) {
      updateGeofenceStatus(status); // Atualiza o status com base no evento de geofencing
    });

    // Configura um temporizador para checar a posição a cada 30 segundos
    timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await checkPosition(); // Chama a função para verificar a posição manualmente
    });
  }

  // Função que verifica a posição atual do dispositivo
  Future<void> checkPosition() async {
    // Obtém a posição atual do dispositivo com alta precisão
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // Calcula a distância entre a posição atual e a posição definida
    double distance = await Geolocator.distanceBetween(position.latitude, position.longitude, definedLatitude, definedLongitude);

    // Atualiza o status de geofencing com base na distância
    if (distance <= definedRadius) {
      updateGeofenceStatus(GeofenceStatus.enter); // Se estiver dentro do raio, assume que entrou na área
    } else {
      updateGeofenceStatus(GeofenceStatus.exit); // Caso contrário, assume que saiu da área
    }
  }

  // Função que atualiza o status de geofencing e exibe a notificação, se necessário
  void updateGeofenceStatus(GeofenceStatus status) {
    setState(() {
      geofenceStatus = status == GeofenceStatus.enter
          ? "Dentro da área definida" // Se o status for "enter", o usuário está dentro da área
          : "Fora da área definida"; // Se for "exit", o usuário está fora da área
    });

    // Envia uma notificação se o status for "enter"
    if (status == GeofenceStatus.enter) {
      NotificationService.showInstantNotification(
        "Você entrou na área!", // Título da notificação
        "Bem-vindo à área definida no mapa.", // Corpo da notificação
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!), // Exibe o título na barra de navegação
      ),
      body: Center(
        // Exibe o status de geofencing no centro da tela
        child: Text(
          geofenceStatus, // Texto que informa se está dentro ou fora da área
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Função chamada quando a página for descartada
  @override
  void dispose() {
    timer?.cancel(); // Cancela o temporizador
    geofenceStatusStream?.cancel(); // Cancela o stream do geofencing
    super.dispose(); // Chama o dispose da superclasse
  }
}

