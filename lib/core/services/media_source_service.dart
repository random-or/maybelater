import 'package:photo_manager/photo_manager.dart';

class MediaSourceService {
  Future<PermissionState> requestPermission() async {
    return await PhotoManager.requestPermissionExtend();
  }

  Future<PermissionState> getPermissionState() async {
    return await PhotoManager.requestPermissionExtend();
  }

  Future<List<AssetEntity>> discoverScreenshots({
    int page = 0,
    int pageSize = 80,
  }) async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );
    if (paths.isEmpty) {
      return [];
    }

    // Find the "Screenshots" album or use the "Recent" / all-images path
    AssetPathEntity? targetPath;
    for (final path in paths) {
      if (path.name.toLowerCase() == 'screenshots') {
        targetPath = path;
        break;
      }
    }

    // Fallback to the all-images album
    if (targetPath == null) {
      for (final path in paths) {
        if (path.isAll) {
          targetPath = path;
          break;
        }
      }
    }

    if (targetPath != null) {
      return await targetPath.getAssetListPaged(page: page, size: pageSize);
    }

    return [];
  }

  Future<List<AssetEntity>> getAllImageAssets({
    int page = 0,
    int pageSize = 80,
  }) async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );
    if (paths.isEmpty) {
      return [];
    }

    for (final path in paths) {
      if (path.isAll) {
        return await path.getAssetListPaged(page: page, size: pageSize);
      }
    }

    return [];
  }

  /// Delete assets from the device (MediaStore).
  /// This will trigger an Android OS confirmation dialog on Android 10+.
  /// Returns a list of IDs that were successfully deleted.
  Future<List<String>> deleteAssets(List<String> assetIds) async {
    return await PhotoManager.editor.deleteWithIds(assetIds);
  }
}
