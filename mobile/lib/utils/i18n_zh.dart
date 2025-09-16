import 'package:pro_image_editor/pro_image_editor.dart';

/// 中文本地化配置
const I18n chineseI18n = I18n(
  cancel: '取消',
  undo: '撤销',
  redo: '重做',
  done: '完成',
  remove: '删除',
  doneLoadingMsg: '正在应用更改…',

  // 涂鸦/画笔编辑器
  paintEditor: I18nPaintEditor(
    moveAndZoom: '缩放',
    bottomNavigationBarText: '画笔',
    freestyle: '自由',
    arrow: '箭头',
    line: '直线',
    rectangle: '矩形',
    circle: '圆形',
    dashLine: '虚线',
    polygon: '多边形',
    blur: '模糊',
    pixelate: '像素化',
    lineWidth: '线宽',
    eraser: '橡皮擦',
    toggleFill: '切换填充',
    changeOpacity: '更改不透明度',
    undo: '撤销',
    redo: '重做',
    done: '完成',
    back: '返回',
    smallScreenMoreTooltip: '更多',
    opacity: '不透明度',
    color: '颜色',
    strokeWidth: '描边宽度',
    fill: '填充',
    cancel: '取消',
  ),

  // 裁剪/旋转编辑器
  cropRotateEditor: I18nCropRotateEditor(
    bottomNavigationBarText: '裁剪/旋转',
    rotate: '旋转',
    flip: '翻转',
    ratio: '比例',
    back: '返回',
    done: '完成',
    cancel: '取消',
    undo: '撤销',
    redo: '重做',
    smallScreenMoreTooltip: '更多',
    reset: '重置',
  ),

  // 文字编辑器
  textEditor: I18nTextEditor(
    bottomNavigationBarText: '文字',
    inputHintText: '输入文字',
    textAlign: '对齐',
    backgroundMode: '背景模式',
    fontScale: '字号',
    smallScreenMoreTooltip: '更多',
    back: '返回',
    done: '完成',
  ),

  // 滤镜编辑器
  filterEditor: I18nFilterEditor(
    bottomNavigationBarText: '滤镜',
    back: '返回',
    done: '完成',
    // filters: ,
  ),

  // 表情编辑器
  emojiEditor: I18nEmojiEditor(bottomNavigationBarText: '表情', search: '搜索'),

  // 贴纸编辑器
  stickerEditor: I18nStickerEditor(bottomNavigationBarText: '贴纸'),

  // 调整（亮度/对比度等）
  tuneEditor: I18nTuneEditor(
    bottomNavigationBarText: '调整',
    back: '返回',
    done: '完成',
    brightness: '亮度',
    contrast: '对比度',
    saturation: '饱和度',
    exposure: '曝光',
    hue: '色相',
    temperature: '色温',
    sharpness: '锐度',
    fade: '褪色',
    luminance: '明度',
    undo: '撤销',
    redo: '重做',
  ),

  // 模糊编辑器
  blurEditor: I18nBlurEditor(
    bottomNavigationBarText: '模糊',
    back: '返回',
    done: '完成',
  ),
);
