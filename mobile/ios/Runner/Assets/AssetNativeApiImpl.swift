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
        print("[AssetNativeApi] Asset not found: \(assetId), returning false")
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
}

