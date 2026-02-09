import Flutter
import Photos

/// 资产原生 API 实现
/// 提供从系统相册获取资产元数据（如收藏状态）的功能
class AssetNativeApiImpl: AssetNativeApi {
  
  /// PHAsset 获取选项
  private static let fetchOptions: PHFetchOptions = {
    let options = PHFetchOptions()
    options.wantsIncrementalChangeDetails = false
    return options
  }()
  
  /// 处理队列
  private static let processingQueue = DispatchQueue(
    label: "asset.native.processing",
    qos: .userInitiated,
    attributes: .concurrent
  )
  
  /// 获取单个资产的收藏状态
  ///
  /// 通过 PHAsset.isFavorite 属性获取资产是否被标记为收藏
  ///
  /// - Parameters:
  ///   - assetId: 资产 ID（本地资源标识符）
  ///   - completion: 完成回调，返回收藏状态（true/false）
  func getIsFavorite(assetId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
    Self.processingQueue.async {
      // 通过 localIdentifier 获取 PHAsset
      let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: Self.fetchOptions)
      
      guard let asset = assets.firstObject else {
        // 资产不存在，返回 false（而不是错误，保持与设计一致）
        completion(.success(false))
        return
      }
      
      // 返回收藏状态
      completion(.success(asset.isFavorite))
    }
  }
  
  /// 批量获取资产元数据
  ///
  /// 批量获取多个资产的元数据，包括收藏状态
  /// 比逐个调用 getIsFavorite 更高效
  ///
  /// - Parameters:
  ///   - assetIds: 资产 ID 列表
  ///   - completion: 完成回调，返回资产元数据列表
  func getAssetMetadata(assetIds: [String], completion: @escaping (Result<[AssetMetadata], Error>) -> Void) {
    Self.processingQueue.async {
      // 批量获取 PHAsset
      let assets = PHAsset.fetchAssets(withLocalIdentifiers: assetIds, options: Self.fetchOptions)
      
      var results: [AssetMetadata] = []
      results.reserveCapacity(assets.count)
      
      // 遍历所有获取到的资产
      assets.enumerateObjects { (asset, _, _) in
        let metadata = AssetMetadata(
          id: asset.localIdentifier,
          isFavorite: asset.isFavorite
        )
        results.append(metadata)
      }
      
      completion(.success(results))
    }
  }

  /// 设置系统相册中资产的收藏状态（写回系统）
  ///
  /// 需要相册「读写」权限；仅「读取」或「有限访问」无法修改收藏。
  /// - Parameters:
  ///   - assetId: 资产 localIdentifier
  ///   - isFavorite: 是否收藏
  ///   - completion: 完成回调，无权限或资产不存在时返回 failure
  func setIsFavorite(assetId: String, isFavorite: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
    Self.processingQueue.async {
      // 检查相册写权限（修改收藏需要 readWrite）
      let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
      switch status {
      case .authorized:
        break
      case .limited:
        completion(.failure(NSError(
          domain: "AssetNativeApi",
          code: 1,
          userInfo: [NSLocalizedDescriptionKey: "需要「完全访问」相册才能修改收藏状态，当前为「选中的照片」"]
        )))
        return
      case .denied, .restricted:
        completion(.failure(NSError(
          domain: "AssetNativeApi",
          code: 2,
          userInfo: [NSLocalizedDescriptionKey: "没有相册访问权限，无法修改收藏状态"]
        )))
        return
      case .notDetermined:
        // 未决定时先请求权限（在主线程请求，结果异步回调后再执行写操作）
        DispatchQueue.main.async {
          PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
            Self.processingQueue.async {
              guard newStatus == .authorized else {
                completion(.failure(NSError(
                  domain: "AssetNativeApi",
                  code: 2,
                  userInfo: [NSLocalizedDescriptionKey: "需要相册读写权限才能修改收藏状态"]
                )))
                return
              }
              Self.performSetFavorite(assetId: assetId, isFavorite: isFavorite, completion: completion)
            }
          }
        }
        return
      @unknown default:
        completion(.failure(NSError(
          domain: "AssetNativeApi",
          code: 2,
          userInfo: [NSLocalizedDescriptionKey: "无法获取相册权限状态"]
        )))
        return
      }
      Self.performSetFavorite(assetId: assetId, isFavorite: isFavorite, completion: completion)
    }
  }

  private static func performSetFavorite(assetId: String, isFavorite: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: fetchOptions)
    guard let asset = assets.firstObject else {
      completion(.failure(NSError(
        domain: "AssetNativeApi",
        code: 3,
        userInfo: [NSLocalizedDescriptionKey: "未找到资产: \(assetId)"]
      )))
      return
    }
    PHPhotoLibrary.shared().performChanges({
      let request = PHAssetChangeRequest(for: asset)
      request.isFavorite = isFavorite
    }) { success, error in
      if success {
        completion(.success(()))
      } else {
        completion(.failure(error ?? NSError(
          domain: "AssetNativeApi",
          code: 4,
          userInfo: [NSLocalizedDescriptionKey: "修改收藏状态失败"]
        )))
      }
    }
  }
}

