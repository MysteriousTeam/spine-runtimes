
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:ffi/ffi.dart';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'spine_flutter_bindings_generated.dart';
import 'package:path/path.dart' as Path;

int majorVersion() => _bindings.spine_major_version();
int minorVersion() => _bindings.spine_minor_version();

Future<Pointer<spine_atlas>> loadAtlas(AssetBundle assetBundle, String atlasFileName) async {
  final atlasData = await assetBundle.loadString(atlasFileName);
  final atlasDataNative = atlasData.toNativeUtf8();
  final atlas = _bindings.spine_atlas_load(atlasDataNative.cast());
  calloc.free(atlasDataNative);
  if (atlas.ref.error.address != nullptr.address) {
    final Pointer<Utf8> error = atlas.ref.error.cast();
    final message = error.toDartString();
    _bindings.spine_atlas_dispose(atlas);
    throw Exception("Couldn't load atlas: " + message);
  }

  final atlasDir = Path.dirname(atlasFileName);
  List<Image> atlasPages = [];
  for (int i = 0; i < atlas.ref.numImagePaths; i++) {
    final Pointer<Utf8> atlasPageFile = atlas.ref.imagePaths[i].cast();
    final imagePath = Path.join(atlasDir, atlasPageFile.toDartString());
    atlasPages.add(await Image(image: AssetImage(imagePath)));
  }

  return atlas;
}

Pointer<spine_skeleton_data> loadSkeletonDataJson(Pointer<spine_atlas> atlas, String json) {
  final jsonNative = json.toNativeUtf8();
  final skeletonData = _bindings.spine_skeleton_data_load_json(atlas, jsonNative.cast());
  if (skeletonData.ref.error.address != nullptr.address) {
    final Pointer<Utf8> error = skeletonData.ref.error.cast();
    final message = error.toDartString();
    _bindings.spine_skeleton_data_dispose(skeletonData);
    throw Exception("Couldn't load skeleton data: " + message);
  }
  return skeletonData;
}

Pointer<spine_skeleton_data> loadSkeletonDataBinary(Pointer<spine_atlas> atlas, ByteData binary) {
  final Pointer<Uint8> binaryNative = malloc.allocate(binary.lengthInBytes);
  binaryNative.asTypedList(binary.lengthInBytes).setAll(0, binary.buffer.asUint8List());
  final skeletonData = _bindings.spine_skeleton_data_load_binary(atlas, binaryNative.cast(), binary.lengthInBytes);
  malloc.free(binaryNative);
  if (skeletonData.ref.error.address != nullptr.address) {
    final Pointer<Utf8> error = skeletonData.ref.error.cast();
    final message = error.toDartString();
    _bindings.spine_skeleton_data_dispose(skeletonData);
    throw Exception("Couldn't load skeleton data: " + message);
  }
  return skeletonData;
}

Pointer<spine_skeleton_drawable> createSkeletonDrawable(Pointer<spine_skeleton_data> skeletonData) {
  return _bindings.spine_skeleton_drawable_create(skeletonData);
}

void updateSkeletonDrawable(Pointer<spine_skeleton_drawable> drawable, double deltaTime) {
  _bindings.spine_skeleton_drawable_update(drawable, deltaTime);
}

class RenderCommand {
  late Vertices vertices;
  late int atlasPageIndex;
  RenderCommand? next;

  RenderCommand(Pointer<spine_render_command> nativeCmd) {
    atlasPageIndex = nativeCmd.ref.atlasPage;
    int numVertices = nativeCmd.ref.numVertices;
    int numIndices = nativeCmd.ref.numIndices;
    // We pass the native data as views directly to Vertices.raw. According to the sources, the data
    // is copied, so it doesn't matter that we free up the underlying memory on the next
    // render call. See the implementation of Vertices.raw() here:
    // https://github.com/flutter/engine/blob/5c60785b802ad2c8b8899608d949342d5c624952/lib/ui/painting/vertices.cc#L21
    vertices = Vertices.raw(VertexMode.triangles,
        nativeCmd.ref.positions.asTypedList(numVertices * 2),
        textureCoordinates: nativeCmd.ref.uvs.asTypedList(numVertices * 2),
        colors: nativeCmd.ref.colors.asTypedList(numVertices),
        indices: nativeCmd.ref.indices.asTypedList(numIndices));
  }
}

List<RenderCommand> renderSkeletonDrawable(Pointer<spine_skeleton_drawable> drawable) {
  Pointer<spine_render_command> nativeCmd = _bindings.spine_skeleton_drawable_render(drawable);
  List<RenderCommand> commands = [];
  while(nativeCmd.address != nullptr.address) {
    commands.add(RenderCommand(nativeCmd));
    nativeCmd = nativeCmd.ref.next;
  }
  return commands;

}

const String _libName = 'spine_flutter';

final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

final SpineFlutterBindings _bindings = SpineFlutterBindings(_dylib);