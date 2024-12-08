// Importação do pacote necessário para trabalhar com notificações locais
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// Importação do pacote para trabalhar com fusos horários
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // Instância do plugin de notificações locais
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Função que será chamada quando uma notificação for recebida
  static Future<void> onDidReceiveNotification(NotificationResponse notificationResponse) async {
    print("Notification receive"); // Imprime uma mensagem de log ao receber uma notificação
  }

  // Função de inicialização do serviço de notificações
  static Future<void> init() async {
    // Configurações para a inicialização da notificação no Android (ícone da notificação)
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings("@mipmap/ic_launcher");
    // Configurações para a inicialização da notificação no iOS
    const DarwinInitializationSettings iOSInitializationSettings = DarwinInitializationSettings();

    // Configuração unificada de inicialização para ambas as plataformas
    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings, // Definição das configurações Android
      iOS: iOSInitializationSettings, // Definição das configurações iOS
    );
    // Inicializa o plugin de notificações locais com as configurações definidas
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotification, // Define a função de callback para quando uma notificação for recebida
      onDidReceiveBackgroundNotificationResponse: onDidReceiveNotification, // Define a função de callback para quando a notificação for recebida em segundo plano
    );

    // Solicita permissão para notificações no Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Função para mostrar uma notificação instantânea
  static Future<void> showInstantNotification(String title, String body) async {
    // Definição das configurações da notificação para Android e iOS
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        'instant_notification_channel_id', // ID do canal de notificações
        'Instant Notifications', // Nome do canal de notificações
        importance: Importance.max, // Define a importância da notificação (máxima)
        priority: Priority.high, // Define a prioridade da notificação (alta)
      ),
      iOS: DarwinNotificationDetails(), // Definições para iOS (padrão)
    );

    // Exibe a notificação com o título e corpo passados
    await flutterLocalNotificationsPlugin.show(
      0, // ID da notificação
      title, // Título da notificação
      body, // Corpo da notificação
      platformChannelSpecifics, // Detalhes da notificação conforme a plataforma
      payload: 'instant_notification', // Dados adicionais (payload) que podem ser passados
    );
  }

  // Função para agendar uma notificação para uma hora futura
  static Future<void> scheduleNotification(int id, String title, String body, DateTime scheduledTime) async {
    // Agendamento da notificação para a hora especificada
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id, // ID da notificação
      title, // Título da notificação
      body, // Corpo da notificação
      tz.TZDateTime.from(scheduledTime, tz.local), // Converte a hora para o fuso horário local
      const NotificationDetails( // Detalhes da notificação para Android e iOS
        iOS: DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          'reminder_channel', // ID do canal de lembretes
          'Reminder Channel', // Nome do canal de lembretes
          importance: Importance.high, // Importância alta para garantir que a notificação seja visível
          priority: Priority.high, // Prioridade alta para garantir que a notificação seja visível imediatamente
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exact, // Modo de agendamento exato para Android
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, // Interpretação exata da data e hora
      matchDateTimeComponents: DateTimeComponents.dateAndTime, // Garante que a notificação seja agendada para uma data e hora específicas
    );
  }
}
