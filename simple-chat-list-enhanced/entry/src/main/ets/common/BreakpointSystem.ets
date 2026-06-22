// 多端适配断点系统
// sm: < 600vp (手机)
// md: 600-840vp (平板竖屏/小平板)
// lg: > 840vp (平板横屏/2in1设备/模型机)

import mediaQuery from '@ohos.mediaquery';

export enum BreakpointType {
  SM = 'sm',
  MD = 'md',
  LG = 'lg'
}

// 断点范围常量
export class BreakpointConstants {
  static readonly RANGE_SM: [number, number] = [0, 600];
  static readonly RANGE_MD: [number, number] = [600, 840];
  static readonly RANGE_LG: [number, number] = [840, Infinity];
}

// 联系人列表页布局配置
export class ListPageConfig {
  listWidth: string = '100%';
  chatWidth: string = '0%';
  showSideBySide: boolean = false;
  avatarSize: number = 48;
  itemHeight: number = 72;
  fontSize: number = 16;
  titleFontSize: number = 20;
  paddingH: number = 12;
  maxContentWidth: string = '100%';
}

// 聊天页布局配置
export class ChatPageConfig {
  inputWidth: number = 200;
  inputHeight: number = 40;
  emojiSize: number = 32;
  emojiPanelHeight: number = 350;
  imagePanelHeight: number = 300;
  msgAvatarSize: number = 36;
  msgFontSize: number = 16;
  imageMsgSize: number = 100;
  bottomBarHeight: number = 80;
  iconSize: number = 28;
  maxInputWidth: string = '60%';
  columnsTemplate8: string = '1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr';
  columnsTemplate3: string = '1fr 1fr 1fr';
}

// 布局参数配置 - 根据断点返回不同的布局参数
export class LayoutConfig {
  // 联系人列表页布局
  static getListPageConfig(bp: BreakpointType): ListPageConfig {
    switch (bp) {
      case BreakpointType.SM: {
        let config = new ListPageConfig();
        config.listWidth = '100%';
        config.chatWidth = '0%';
        config.showSideBySide = false;
        config.avatarSize = 48;
        config.itemHeight = 72;
        config.fontSize = 16;
        config.titleFontSize = 20;
        config.paddingH = 12;
        config.maxContentWidth = '100%';
        return config;
      }
      case BreakpointType.MD: {
        let config = new ListPageConfig();
        config.listWidth = '40%';
        config.chatWidth = '60%';
        config.showSideBySide = true;
        config.avatarSize = 52;
        config.itemHeight = 80;
        config.fontSize = 16;
        config.titleFontSize = 22;
        config.paddingH = 16;
        config.maxContentWidth = '100%';
        return config;
      }
      case BreakpointType.LG: {
        let config = new ListPageConfig();
        config.listWidth = '30%';
        config.chatWidth = '70%';
        config.showSideBySide = true;
        config.avatarSize = 56;
        config.itemHeight = 88;
        config.fontSize = 18;
        config.titleFontSize = 24;
        config.paddingH = 24;
        config.maxContentWidth = '1200vp';
        return config;
      }
      default:
        return LayoutConfig.getListPageConfig(BreakpointType.SM);
    }
  }

  // 聊天页布局
  static getChatPageConfig(bp: BreakpointType): ChatPageConfig {
    switch (bp) {
      case BreakpointType.SM: {
        let config = new ChatPageConfig();
        config.inputWidth = 200;
        config.inputHeight = 40;
        config.emojiSize = 32;
        config.emojiPanelHeight = 350;
        config.imagePanelHeight = 300;
        config.msgAvatarSize = 36;
        config.msgFontSize = 16;
        config.imageMsgSize = 100;
        config.bottomBarHeight = 80;
        config.iconSize = 28;
        config.maxInputWidth = '60%';
        config.columnsTemplate8 = '1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr';
        config.columnsTemplate3 = '1fr 1fr 1fr';
        return config;
      }
      case BreakpointType.MD: {
        let config = new ChatPageConfig();
        config.inputWidth = 320;
        config.inputHeight = 44;
        config.emojiSize = 36;
        config.emojiPanelHeight = 400;
        config.imagePanelHeight = 350;
        config.msgAvatarSize = 40;
        config.msgFontSize = 17;
        config.imageMsgSize = 140;
        config.bottomBarHeight = 88;
        config.iconSize = 32;
        config.maxInputWidth = '70%';
        config.columnsTemplate8 = '1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr';
        config.columnsTemplate3 = '1fr 1fr 1fr 1fr';
        return config;
      }
      case BreakpointType.LG: {
        let config = new ChatPageConfig();
        config.inputWidth = 500;
        config.inputHeight = 48;
        config.emojiSize = 40;
        config.emojiPanelHeight = 450;
        config.imagePanelHeight = 400;
        config.msgAvatarSize = 44;
        config.msgFontSize = 18;
        config.imageMsgSize = 180;
        config.bottomBarHeight = 96;
        config.iconSize = 36;
        config.maxInputWidth = '80%';
        config.columnsTemplate8 = '1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr';
        config.columnsTemplate3 = '1fr 1fr 1fr 1fr 1fr';
        return config;
      }
      default:
        return LayoutConfig.getChatPageConfig(BreakpointType.SM);
    }
  }
}

// 断点监听器 - 监听窗口尺寸变化
export class BreakpointSystem {
  private currentBreakpoint: BreakpointType = BreakpointType.SM;
  private smListener: mediaQuery.MediaQueryListener | null = null;
  private mdListener: mediaQuery.MediaQueryListener | null = null;
  private lgListener: mediaQuery.MediaQueryListener | null = null;
  private onBreakpointChange: (bp: BreakpointType) => void = () => {};

  constructor(callback: (bp: BreakpointType) => void) {
    this.onBreakpointChange = callback;
  }

  // 注册监听
  register() {
    try {
      let smListener: mediaQuery.MediaQueryListener = mediaQuery.matchMediaSync('(0vp<=width)<600vp');
      smListener.on('change', (result: mediaQuery.MediaQueryResult) => {
        if (result.matches) {
          this.currentBreakpoint = BreakpointType.SM;
          this.onBreakpointChange(BreakpointType.SM);
        }
      });
      this.smListener = smListener;

      let mdListener: mediaQuery.MediaQueryListener = mediaQuery.matchMediaSync('(600vp<=width)<840vp');
      mdListener.on('change', (result: mediaQuery.MediaQueryResult) => {
        if (result.matches) {
          this.currentBreakpoint = BreakpointType.MD;
          this.onBreakpointChange(BreakpointType.MD);
        }
      });
      this.mdListener = mdListener;

      let lgListener: mediaQuery.MediaQueryListener = mediaQuery.matchMediaSync('(840vp<=width)');
      lgListener.on('change', (result: mediaQuery.MediaQueryResult) => {
        if (result.matches) {
          this.currentBreakpoint = BreakpointType.LG;
          this.onBreakpointChange(BreakpointType.LG);
        }
      });
      this.lgListener = lgListener;
    } catch (e) {
      console.error('BreakpointSystem register error: ' + JSON.stringify(e));
    }
  }

  // 取消监听
  unregister() {
    if (this.smListener) {
      this.smListener.off('change');
    }
    if (this.mdListener) {
      this.mdListener.off('change');
    }
    if (this.lgListener) {
      this.lgListener.off('change');
    }
  }

  // 获取当前断点
  getCurrentBreakpoint(): BreakpointType {
    return this.currentBreakpoint;
  }
}
