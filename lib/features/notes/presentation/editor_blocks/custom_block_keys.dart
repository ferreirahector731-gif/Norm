import 'package:appflowy_editor/appflowy_editor.dart';

class WhiteboardBlockKeys {
  const WhiteboardBlockKeys._();
  static const String type = 'whiteboard';
  static const String strokes = 'strokes';
}

class ImagePlaceholderKeys {
  const ImagePlaceholderKeys._();
  static const String type = 'image_placeholder';
  static const String caption = 'caption';
  // MULTIMODAL AI INGESTION POINT: Preparado para enviar bytes directos a
  // modelos Flash/Mini multimodales (Gemini/GPT-mini) para análisis
  // silencioso de imágenes, transcripción de audio o descripción de video.
  static const String bytePath = 'byte_path';
}

class VideoPlaceholderKeys {
  const VideoPlaceholderKeys._();
  static const String type = 'video_placeholder';
  static const String caption = 'caption';
  static const String bytePath = 'byte_path';
}

class AudioBlockKeys {
  const AudioBlockKeys._();
  static const String type = 'audio_block';
  static const String caption = 'caption';
  // MULTIMODAL AI INGESTION POINT: Preparado para enviar bytes directos a
  // modelos Flash/Mini multimodales (Gemini/GPT-mini) para transcripción
  // de audio o descripción de contenido hablado.
  static const String bytePath = 'byte_path';
  static const String duration = 'duration';
}

Node whiteboardNode() => Node(type: WhiteboardBlockKeys.type, attributes: {
  WhiteboardBlockKeys.strokes: '[]',
});

Node imagePlaceholderNode({String path = ''}) =>
    Node(type: ImagePlaceholderKeys.type, attributes: {
      ImagePlaceholderKeys.caption: '',
      ImagePlaceholderKeys.bytePath: path,
    });

Node videoPlaceholderNode({String path = ''}) =>
    Node(type: VideoPlaceholderKeys.type, attributes: {
      VideoPlaceholderKeys.caption: '',
      VideoPlaceholderKeys.bytePath: path,
    });

Node audioBlockNode({String path = '', String caption = ''}) =>
    Node(type: AudioBlockKeys.type, attributes: {
      AudioBlockKeys.caption: caption,
      AudioBlockKeys.bytePath: path,
      AudioBlockKeys.duration: 0.0,
    });
