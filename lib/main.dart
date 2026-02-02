import 'package:fluent_ui/fluent_ui.dart'; // We only need this one!
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:window_manager/window_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Window.initialize();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  await Window.setEffect(effect: WindowEffect.mica, dark: true);
  runApp(const MediaPlayerApp());
}

class MediaPlayerApp extends StatelessWidget {
  const MediaPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'My Media Player',
      themeMode: ThemeMode.dark,
      darkTheme: FluentThemeData(
        brightness: Brightness.dark,
        accentColor: Colors.blue, // Fixed: SystemAccentColor -> Colors.blue
        visualDensity: VisualDensity.standard,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const PlayerScreen(),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player player;
  late final VideoController controller;
  String? currentFileName;

  @override
  void initState() {
    super.initState();
    player = Player();
    controller = VideoController(player);
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );
    if (result != null) {
      await player.open(Media(result.files.single.path!));
      setState(() {
        currentFileName = result.files.single.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        automaticallyImplyLeading: false,
        title: DragToMoveArea(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(currentFileName ?? "Select a Video"),
          ),
        ),
        actions: DragToMoveArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(FluentIcons.chrome_minimize),
                onPressed: windowManager.minimize,
              ),
              IconButton(
                icon: const Icon(FluentIcons.chrome_close),
                onPressed: windowManager.close,
              ),
            ],
          ),
        ),
      ),
      pane: NavigationPane(
        displayMode: PaneDisplayMode.compact,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.video),
            title: const Text("Now Playing"),
            body: Center(
              child: player.state.width == null
                  // 1. If no video is loaded, show the button
                  ? Button(
                      onPressed: pickVideo,
                      child: const Text("Open Video File"),
                    )
                  // 2. If video IS loaded, show the video player
                  // We removed the "MaterialDesktopVideoControlsTheme" wrapper
                  // The default Video widget automatically picks the right UI for Windows
                  : Video(
                      controller: controller,
                      // If you find the controls too small or want to force the Desktop look:
                      controls: MaterialDesktopVideoControls,
                    ),
            ),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.library),
            title: const Text("Library"),
            body: const Center(child: Text("Library Feature Coming Soon")),
          ),
        ],
      ),
    );
  }
}
