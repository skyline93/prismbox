package app.prismbox.assets

import android.content.ContentResolver
import android.content.Context
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import java.util.concurrent.Executors

/**
 * 资产原生 API 实现
 * 提供从系统相册获取资产元数据（如收藏状态）的功能
 */
class AssetNativeApiImpl(context: Context) : AssetNativeApi {
    
    private val ctx: Context = context.applicationContext
    private val resolver: ContentResolver = ctx.contentResolver
    
    companion object {
        private const val TAG = "AssetNativeApi"
        
        /** 处理线程池 */
        private val threadPool = Executors.newFixedThreadPool(2)
        
        /** 检查是否支持收藏查询（Android 11+） */
        private val isFavoriteSupported: Boolean
            get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R
    }
    
    /**
     * 获取单个资产的收藏状态
     *
     * 通过 MediaStore.MediaColumns.IS_FAVORITE 字段查询资产是否被标记为收藏
     * 仅支持 Android 11 (API 30) 及以上版本
     *
     * @param assetId 资产 ID（MediaStore 的 _ID）
     * @param callback 完成回调，返回收藏状态（true/false）
     */
    override fun getIsFavorite(assetId: String, callback: (Result<Boolean>) -> Unit) {
        threadPool.execute {
            try {
                val isFavorite = queryIsFavorite(assetId)
                callback(Result.success(isFavorite))
            } catch (e: Exception) {
                Log.w(TAG, "Failed to get favorite status for asset: $assetId", e)
                // 发生错误时返回 false（而不是错误，保持与设计一致）
                callback(Result.success(false))
            }
        }
    }
    
    /**
     * 批量获取资产元数据
     *
     * 批量获取多个资产的元数据，包括收藏状态
     * 比逐个调用 getIsFavorite 更高效
     *
     * @param assetIds 资产 ID 列表
     * @param callback 完成回调，返回资产元数据列表
     */
    override fun getAssetMetadata(assetIds: List<String>, callback: (Result<List<AssetMetadata>>) -> Unit) {
        threadPool.execute {
            try {
                val results = queryAssetMetadata(assetIds)
                callback(Result.success(results))
            } catch (e: Exception) {
                Log.w(TAG, "Failed to get asset metadata", e)
                // 发生错误时返回空列表（而不是错误，保持与设计一致）
                callback(Result.success(emptyList()))
            }
        }
    }
    
    /**
     * 查询单个资产的收藏状态
     */
    private fun queryIsFavorite(assetId: String): Boolean {
        // Android 10 及以下版本不支持收藏查询
        if (!isFavoriteSupported) {
            return false
        }
        
        val id = assetId.toLongOrNull()
        if (id == null) {
            return false
        }
        
        // 构建查询
        val projection = arrayOf(MediaStore.MediaColumns.IS_FAVORITE)
        val selection = "${MediaStore.MediaColumns._ID} = ?"
        val selectionArgs = arrayOf(id.toString())
        
        // 查询 Files 表（包含图片和视频）
        resolver.query(
            MediaStore.Files.getContentUri("external"),
            projection,
            selection,
            selectionArgs,
            null
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val favoriteIndex = cursor.getColumnIndex(MediaStore.MediaColumns.IS_FAVORITE)
                if (favoriteIndex != -1) {
                    val isFavorite = cursor.getInt(favoriteIndex) != 0
                    return isFavorite
                }
            }
        }
        
        // 资产不存在或查询失败
        return false
    }
    
    /**
     * 批量查询资产元数据
     */
    private fun queryAssetMetadata(assetIds: List<String>): List<AssetMetadata> {
        if (assetIds.isEmpty()) {
            return emptyList()
        }
        
        // Android 10 及以下版本不支持收藏查询，返回所有资产的 isFavorite = false
        if (!isFavoriteSupported) {
            return assetIds.map { AssetMetadata(id = it, isFavorite = false) }
        }
        
        // 验证并转换 ID
        val validIds = assetIds.mapNotNull { it.toLongOrNull() }
        
        if (validIds.isEmpty()) {
            return emptyList()
        }
        
        val results = mutableListOf<AssetMetadata>()
        
        // 构建批量查询
        val projection = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.IS_FAVORITE
        )
        
        // 使用 IN 子句批量查询
        val placeholders = validIds.joinToString(",") { "?" }
        val selection = "${MediaStore.MediaColumns._ID} IN ($placeholders)"
        val selectionArgs = validIds.map { it.toString() }.toTypedArray()
        
        resolver.query(
            MediaStore.Files.getContentUri("external"),
            projection,
            selection,
            selectionArgs,
            null
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndex(MediaStore.MediaColumns._ID)
            val favoriteIndex = cursor.getColumnIndex(MediaStore.MediaColumns.IS_FAVORITE)
            
            if (idIndex == -1 || favoriteIndex == -1) {
                return emptyList()
            }
            
            while (cursor.moveToNext()) {
                val id = cursor.getLong(idIndex).toString()
                val isFavorite = cursor.getInt(favoriteIndex) != 0
                results.add(AssetMetadata(id = id, isFavorite = isFavorite))
            }
        }
        
        return results
    }
}

