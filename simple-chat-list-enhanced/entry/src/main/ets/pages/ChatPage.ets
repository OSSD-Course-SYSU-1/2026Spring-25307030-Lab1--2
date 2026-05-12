/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { Item, messageObj, MessageType, MessageStatus, EmojiData, ImageData } from '../common/CommonConstants';

@Component
export struct ChatPage {
  private scroller: Scroller = new Scroller();
  @State messageList: Array<string> = [];
  @State inputMessage: string = '';
  @State isRefreshing: boolean = false;
  pathStack: NavPathStack = new NavPathStack();
  @State itemInfo: Item = {
    id: 0,
    image: $r('app.media.Public_avatar'),
    name: '',
    message: [],
    isNewMessage: false,
    time: '',
    isTop: false,
    unreadCount: 0,
    lastMessageTime: Date.now(),
    isTyping: false,
    draft: '',
    isGroup: false,
    members: []
  };
  @State itemMessage: messageObj[] = [];
  @State showItemMessage: messageObj[] = [];
  @State startIndex: number = 0;
  
  // 新增状态变量
  @State showEmojiPanel: boolean = false;        // 表情面板显示状态
  @State showImagePanel: boolean = false;        // 图片面板显示状态
  @State showMorePanel: boolean = false;         // 更多功能面板显示状态
  @State isRecording: boolean = false;           // 录音状态
  @State recordDuration: number = 0;             // 录音时长
  private recordTimer: number = -1;              // 录音计时器
  
  // 更多功能状态
  @State showSearchPanel: boolean = false;       // 搜索面板
  @State searchText: string = '';                // 搜索文本
  @State selectedMessage: messageObj | null = null;     // 选中的消息（用于操作）
  @State showContextMenu: boolean = false;       // 上下文菜单
  @State contextMenuX: number = 0;               // 菜单X坐标
  @State contextMenuY: number = 0;               // 菜单Y坐标
  @State replyToMessage: messageObj | null = null;      // 引用回复的消息
  @State showForwardPanel: boolean = false;      // 转发面板
  @State isTypingStatus: boolean = false;        // 正在输入状态
  private typingTimer: number = -1;              // 输入计时器
  
  // 草稿存储（使用 Map 存储每个联系人的草稿）
  private static draftMap: Map<number, string> = new Map();
  private currentContactId: number = 0;          // 当前联系人ID
  
  getLastTenElements(arr: messageObj[]) {
    this.startIndex = Math.max(0, this.startIndex -= 10);
    if (!Array.isArray(arr) || arr.length < 10 || this.startIndex === 0) {
      this.showItemMessage = arr;
      return;
    }
    const lastTenElements = arr.slice(this.startIndex, this.startIndex + 10);
    this.showItemMessage.unshift(...lastTenElements);
  }
  
  // 发送消息通用方法
  sendMessage(msg: string, type: MessageType, duration?: number) {
    let newMsg: messageObj = {
      id: Date.now(),
      sender: 'myself',
      msg: msg,
      type: type,
      duration: duration || 0,
      timestamp: Date.now(),
      status: MessageStatus.SENT,
      isRecalled: false,
      isRead: false,
      replyTo: this.replyToMessage
    };
    this.itemMessage.push(newMsg);
    this.showItemMessage = this.itemMessage.slice(-10);
    this.scroller.scrollEdge(Edge.Bottom);
    this.replyToMessage = null; // 清除引用
    
    // 模拟对方正在输入
    this.simulateOtherTyping();
  }
  
  // 模拟对方正在输入
  simulateOtherTyping() {
    setTimeout(() => {
      this.itemInfo.isTyping = true;
      setTimeout(() => {
        this.itemInfo.isTyping = false;
      }, 3000);
    }, 1000);
  }
  
  // 开始录音
  startRecording() {
    this.isRecording = true;
    this.recordDuration = 0;
    this.recordTimer = setInterval(() => {
      this.recordDuration++;
    }, 1000);
  }
  
  // 停止录音
  stopRecording() {
    if (this.recordTimer !== -1) {
      clearInterval(this.recordTimer);
      this.recordTimer = -1;
    }
    this.isRecording = false;
    
    if (this.recordDuration > 0) {
      this.sendMessage('语音消息', MessageType.VOICE, this.recordDuration);
    }
    this.recordDuration = 0;
  }
  
  // 标记为未读
  markAsUnread() {
    this.itemInfo.isNewMessage = true;
    this.itemInfo.unreadCount = 1;
    this.pathStack.pop();
  }
  
  // 撤回消息
  recallMessage(msg: messageObj) {
    let index = this.itemMessage.findIndex(m => m.id === msg.id);
    if (index !== -1) {
      this.itemMessage[index].isRecalled = true;
      this.showItemMessage = this.itemMessage.slice(-10);
      
      // 添加系统消息
      let systemMsg: messageObj = {
        id: Date.now(),
        sender: 'system',
        msg: '你撤回了一条消息',
        type: MessageType.SYSTEM,
        timestamp: Date.now()
      };
      this.itemMessage.push(systemMsg);
      this.showItemMessage = this.itemMessage.slice(-10);
    }
  }
  
  // 复制消息
  copyMessage(msg: messageObj) {
    // 在实际应用中，这里应该调用系统剪贴板API
    // 这里仅做演示
    console.log('复制消息:', msg.msg);
  }
  
  // 转发消息
  forwardMessage(msg: messageObj) {
    this.selectedMessage = msg;
    this.showForwardPanel = true;
  }
  
  // 引用回复
  replyMessage(msg: messageObj) {
    this.replyToMessage = msg;
  }
  
  // 删除消息
  deleteMessage(msg: messageObj) {
    let index = this.itemMessage.findIndex(m => m.id === msg.id);
    if (index !== -1) {
      this.itemMessage.splice(index, 1);
      this.showItemMessage = this.itemMessage.slice(-10);
    }
  }
  
  // 标记已读
  markAsRead() {
    this.itemMessage.forEach(msg => {
      if (msg.sender === 'others') {
        msg.isRead = true;
      }
    });
    this.itemInfo.unreadCount = 0;
  }
  
  // 搜索消息
  searchMessages(keyword: string): messageObj[] {
    if (!keyword) return this.itemMessage;
    return this.itemMessage.filter(msg => {
      if (typeof msg.msg === 'string') {
        return msg.msg.includes(keyword);
      }
      return false;
    });
  }
  
  // 格式化时间
  formatTime(timestamp: number | undefined): string {
    if (!timestamp) return '';
    let date = new Date(timestamp);
    let hours = date.getHours().toString().padStart(2, '0');
    let minutes = date.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }
  
  // 格式化完整时间
  formatFullTime(timestamp: number | undefined): string {
    if (!timestamp) return '';
    let date = new Date(timestamp);
    let month = (date.getMonth() + 1).toString().padStart(2, '0');
    let day = date.getDate().toString().padStart(2, '0');
    let hours = date.getHours().toString().padStart(2, '0');
    let minutes = date.getMinutes().toString().padStart(2, '0');
    return `${month}-${day} ${hours}:${minutes}`;
  }
  
  // 输入状态变化
  onInputChange(value: string) {
    this.inputMessage = value;
    
    // 保存草稿到静态 Map
    ChatPage.draftMap.set(this.currentContactId, value);
    
    // 模拟正在输入状态
    if (this.typingTimer !== -1) {
      clearTimeout(this.typingTimer);
    }
    this.isTypingStatus = true;
    this.typingTimer = setTimeout(() => {
      this.isTypingStatus = false;
    }, 2000);
  }
  
  // 显示上下文菜单
  showMenu(msg: messageObj, x: number, y: number) {
    this.selectedMessage = msg;
    this.contextMenuX = x;
    this.contextMenuY = y;
    this.showContextMenu = true;
  }

  build() {
    NavDestination() {
      Column() {
        // 搜索面板
        if (this.showSearchPanel) {
          Column() {
            Row() {
              TextInput({ placeholder: '搜索消息...', text: this.searchText })
                .width('80%')
                .height(40)
                .onChange((value) => {
                  this.searchText = value;
                })
              
              Button('取消')
                .fontSize(14)
                .onClick(() => {
                  this.showSearchPanel = false;
                  this.searchText = '';
                })
            }
            .width('100%')
            .padding(8)
            .justifyContent(FlexAlign.SpaceAround)
            
            List() {
              ForEach(this.searchMessages(this.searchText), (item: messageObj) => {
                ListItem() {
                  Row() {
                    Text(item.msg as string)
                      .fontSize(14)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.formatFullTime(item.timestamp))
                      .fontSize(12)
                      .fontColor('#999999')
                  }
                  .width('100%')
                  .padding(8)
                }
              })
            }
            .width('100%')
            .height(200)
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .border({ width: { bottom: 1 }, color: '#E5E5E5' })
        }
        
        // 正在输入提示
        if (this.itemInfo.isTyping) {
          Row() {
            Text(`${this.itemInfo.name} 正在输入...`)
              .fontSize(12)
              .fontColor('#999999')
          }
          .width('100%')
          .padding({ left: 16, top: 4, bottom: 4 })
          .backgroundColor('#F5F5F5')
        }
        
        Column() {
          // [Start Refresh]
          Refresh({ refreshing: $$this.isRefreshing }) {
            // [Start initialIndex_scrollEdge]
            List({ space: 10, scroller: this.scroller, initialIndex: this.itemInfo.message.length - 1 }) {
              ForEach(this.showItemMessage, (item: messageObj, index: number) => {
                ListItem() {
                  // 撤回消息显示
                  if (item.isRecalled) {
                    Row() {
                      Text('消息已撤回')
                        .fontSize(12)
                        .fontColor('#999999')
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.Center)
                    .padding(8)
                  } 
                  // 系统消息
                  else if (item.type === MessageType.SYSTEM) {
                    Row() {
                      Text(item.msg as string)
                        .fontSize(12)
                        .fontColor('#999999')
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.Center)
                    .padding(8)
                  }
                  // 普通消息
                  else if (item.sender === 'others') {
                    // 对方消息
                    Column() {
                      // 引用回复显示
                      if (item.replyTo) {
                        Row() {
                          Text(`回复: ${item.replyTo.msg}`)
                            .fontSize(12)
                            .fontColor('#999999')
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        }
                        .width('70%')
                        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                        .backgroundColor('#E8E8E8')
                        .borderRadius(4)
                        .margin({ bottom: 4 })
                      }
                      
                      Row() {
                        Image(this.itemInfo.image)
                          .width(36)
                          .height(36)
                          .margin({ right: 8 })
                        
                        // 根据消息类型显示不同内容
                        if (item.type === MessageType.IMAGE) {
                          Column() {
                            Image($r('app.media.Public_avatar'))
                              .width(100)
                              .height(100)
                              .borderRadius(8)
                              .objectFit(ImageFit.Cover)
                            Text('图片消息')
                              .fontSize(12)
                              .fontColor('#999999')
                              .margin({ top: 4 })
                          }
                          .backgroundColor('#F1F3F5')
                          .borderRadius(12)
                          .padding(8)
                        } else if (item.type === MessageType.VOICE) {
                          Row() {
                            Image($r('app.media.mic_filled'))
                              .width(20)
                              .height(20)
                              .margin({ right: 4 })
                            Text(`${item.duration}"`)
                              .fontSize(14)
                              .fontColor('#666666')
                          }
                          .backgroundColor('#F1F3F5')
                          .borderRadius(12)
                          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                        } else {
                          Text(item.msg)
                            .fontSize(item.type === MessageType.EMOJI ? 32 : 16)
                            .constraintSize({ maxWidth: '70%' })
                            .backgroundColor('#F1F3F5')
                            .borderRadius(12)
                            .padding({
                              top: 8,
                              bottom: 8,
                              left: 12,
                              right: 12
                            })
                        }
                      }
                      .width('100%')
                      .constraintSize({ minHeight: 48 })
                      .justifyContent(FlexAlign.Start)
                      
                      // 时间和已读状态
                      Row() {
                        Text(this.formatTime(item.timestamp))
                          .fontSize(10)
                          .fontColor('#CCCCCC')
                      }
                      .width('100%')
                      .justifyContent(FlexAlign.Start)
                      .padding({ left: 44 })
                    }
                    .width('100%')
                    .onClick(() => {
                      this.showMenu(item, 100, 100);
                    })
                  } else {
                    // 自己的消息
                    Column() {
                      // 引用回复显示
                      if (item.replyTo) {
                        Row() {
                          Text(`回复: ${item.replyTo.msg}`)
                            .fontSize(12)
                            .fontColor('#999999')
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                        }
                        .width('70%')
                        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                        .backgroundColor('#E8E8E8')
                        .borderRadius(4)
                        .margin({ bottom: 4 })
                      }
                      
                      Row() {
                        // 根据消息类型显示不同内容
                        if (item.type === MessageType.IMAGE) {
                          Column() {
                            Image($r('app.media.Public_avatar'))
                              .width(100)
                              .height(100)
                              .borderRadius(8)
                              .objectFit(ImageFit.Cover)
                            Text('图片消息')
                              .fontSize(12)
                              .fontColor('#999999')
                              .margin({ top: 4 })
                          }
                          .backgroundColor('#95EC69')
                          .borderRadius(12)
                          .padding(8)
                        } else if (item.type === MessageType.VOICE) {
                          Row() {
                            Text(`${item.duration}"`)
                              .fontSize(14)
                              .fontColor('#666666')
                              .margin({ right: 4 })
                            Image($r('app.media.mic_filled'))
                              .width(20)
                              .height(20)
                          }
                          .backgroundColor('#95EC69')
                          .borderRadius(12)
                          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                        } else {
                          Text(item.msg)
                            .fontSize(item.type === MessageType.EMOJI ? 32 : 16)
                            .backgroundColor('#95EC69')
                            .borderRadius(12)
                            .padding({
                              top: 8,
                              bottom: 8,
                              left: 12,
                              right: 12
                            })
                        }
                        
                        Image($r('app.media.Public_avatar'))
                          .width(36)
                          .height(36)
                          .margin({ left: 8 })
                      }
                      .width('100%')
                      .height(item.type === MessageType.IMAGE ? 120 : 48)
                      .justifyContent(FlexAlign.End)
                      
                      // 时间和已读状态
                      Row() {
                        Text(this.formatTime(item.timestamp))
                          .fontSize(10)
                          .fontColor('#CCCCCC')
                        
                        // 已读状态
                        if (item.status === MessageStatus.READ) {
                          Text('已读')
                            .fontSize(10)
                            .fontColor('#4CAF50')
                            .margin({ left: 4 })
                        } else if (item.status === MessageStatus.SENT) {
                          Text('已发送')
                            .fontSize(10)
                            .fontColor('#999999')
                            .margin({ left: 4 })
                        }
                      }
                      .width('100%')
                      .justifyContent(FlexAlign.End)
                      .padding({ right: 44 })
                    }
                    .width('100%')
                    .onClick(() => {
                      this.showMenu(item, 100, 100);
                    })
                  }
                }
              })
            }
            .onAppear(() => {
              this.scroller.scrollEdge(Edge.Bottom);
              this.markAsRead();
            })
            .scrollBar(BarState.Off)
            .contentEndOffset(8)
            .width('100%')
            .height('100%')
          }
          .width('100%')
          .height('100%')
          .refreshOffset(64)
          .pullToRefresh(true)
          .onRefreshing(() => {
            setTimeout(() => {
              this.getLastTenElements(this.itemMessage);
              this.isRefreshing = false;
            }, 1500)
          })
        }
        .width('100%')
        .height('calc(100% - 80vp)')
        .padding({
          left: 16,
          right: 16
        })
        .justifyContent(FlexAlign.Start)
        .expandSafeArea([SafeAreaType.KEYBOARD])

        // 上下文菜单
        if (this.showContextMenu && this.selectedMessage) {
          Column() {
            if (this.selectedMessage && this.selectedMessage.sender === 'myself' && !this.selectedMessage.isRecalled) {
              Button('撤回')
                .width('100%')
                .onClick(() => {
                  if (this.selectedMessage) {
                    this.recallMessage(this.selectedMessage);
                  }
                  this.showContextMenu = false;
                })
            }
            
            if (this.selectedMessage && !this.selectedMessage.isRecalled) {
              Button('复制')
                .width('100%')
                .onClick(() => {
                  if (this.selectedMessage) {
                    this.copyMessage(this.selectedMessage);
                  }
                  this.showContextMenu = false;
                })
              
              Button('转发')
                .width('100%')
                .onClick(() => {
                  if (this.selectedMessage) {
                    this.forwardMessage(this.selectedMessage);
                  }
                  this.showContextMenu = false;
                })
              
              Button('引用')
                .width('100%')
                .onClick(() => {
                  if (this.selectedMessage) {
                    this.replyMessage(this.selectedMessage);
                  }
                  this.showContextMenu = false;
                })
            }
            
            Button('删除')
              .width('100%')
              .onClick(() => {
                if (this.selectedMessage) {
                  this.deleteMessage(this.selectedMessage);
                }
                this.showContextMenu = false;
              })
            
            Button('取消')
              .width('100%')
              .backgroundColor('#F5F5F5')
              .onClick(() => {
                this.showContextMenu = false;
              })
          }
          .width(120)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .padding(8)
          .position({ x: this.contextMenuX, y: this.contextMenuY })
          .shadow({ radius: 10, color: '#000000', offsetX: 2, offsetY: 2 })
        }

        // 表情选择面板
        if (this.showEmojiPanel) {
          Column() {
            Grid() {
              ForEach(EmojiData.EMOJI_LIST, (emoji: string, index: number) => {
                GridItem() {
                  Text(emoji)
                    .fontSize(28)
                    .width('100%')
                    .height('100%')
                    .textAlign(TextAlign.Center)
                    .onClick(() => {
                      this.sendMessage(emoji, MessageType.EMOJI);
                      this.showEmojiPanel = false;
                    })
                }
              })
            }
            .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
            .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr 1fr')
            .columnsGap(8)
            .rowsGap(8)
            .width('100%')
            .height(280)
            .padding(8)
          }
          .width('100%')
          .height(300)
          .backgroundColor('#FFFFFF')
          .border({ width: { top: 1 }, color: '#E5E5E5' })
        }

        // 图片选择面板
        if (this.showImagePanel) {
          Column() {
            Grid() {
              ForEach(ImageData.IMAGE_LIST, (imageName: string, index: number) => {
                GridItem() {
                  Column() {
                    Image($r('app.media.Public_avatar'))
                      .width('100%')
                      .height('80%')
                      .objectFit(ImageFit.Cover)
                      .borderRadius(8)
                    Text(`图片 ${index + 1}`)
                      .fontSize(12)
                      .fontColor('#666666')
                  }
                  .width('100%')
                  .height('100%')
                  .justifyContent(FlexAlign.Center)
                  .onClick(() => {
                    this.sendMessage(imageName, MessageType.IMAGE);
                    this.showImagePanel = false;
                  })
                }
              })
            }
            .columnsTemplate('1fr 1fr 1fr')
            .rowsTemplate('1fr 1fr')
            .columnsGap(8)
            .rowsGap(8)
            .width('100%')
            .height(200)
            .padding(8)
          }
          .width('100%')
          .height(220)
          .backgroundColor('#FFFFFF')
          .border({ width: { top: 1 }, color: '#E5E5E5' })
        }

        // 更多功能面板
        if (this.showMorePanel) {
          Column() {
            Row() {
              // 图片选项
              Column() {
                Image($r('app.media.Public_avatar'))
                  .width(48)
                  .height(48)
                Text('图片')
                  .fontSize(12)
                  .margin({ top: 4 })
              }
              .width(60)
              .height(80)
              .justifyContent(FlexAlign.Center)
              .onClick(() => {
                this.showMorePanel = false;
                this.showImagePanel = true;
              })
              
              // 搜索选项
              Column() {
                Image($r('app.media.Public_avatar'))
                  .width(48)
                  .height(48)
                Text('搜索')
                  .fontSize(12)
                  .margin({ top: 4 })
              }
              .width(60)
              .height(80)
              .justifyContent(FlexAlign.Center)
              .onClick(() => {
                this.showMorePanel = false;
                this.showSearchPanel = !this.showSearchPanel;
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.Start)
            .padding({ left: 16 })
          }
          .width('100%')
          .height(120)
          .backgroundColor('#FFFFFF')
          .border({ width: { top: 1 }, color: '#E5E5E5' })
          .justifyContent(FlexAlign.Center)
        }

        // 转发面板
        if (this.showForwardPanel) {
          Column() {
            Text('选择转发对象')
              .fontSize(16)
              .margin({ bottom: 8 })
            
            List() {
              ForEach(['Jack', 'Tom', 'Sam', 'Taylor', 'John'], (name: string) => {
                ListItem() {
                  Row() {
                    Text(name)
                      .fontSize(14)
                  }
                  .width('100%')
                  .padding(8)
                  .onClick(() => {
                    // 转发消息
                    if (this.selectedMessage) {
                      this.sendMessage(this.selectedMessage.msg as string, 
                        this.selectedMessage.type || MessageType.TEXT);
                    }
                    this.showForwardPanel = false;
                  })
                }
              })
            }
            .width('100%')
            .height(200)
            
            Button('取消')
              .onClick(() => {
                this.showForwardPanel = false;
              })
          }
          .width('100%')
          .height(300)
          .backgroundColor('#FFFFFF')
          .padding(16)
          .border({ width: { top: 1 }, color: '#E5E5E5' })
        }

        // 录音提示
        if (this.isRecording) {
          Column() {
            Text('正在录音...')
              .fontSize(16)
              .fontColor('#FFFFFF')
            Text(`${this.recordDuration} 秒`)
              .fontSize(14)
              .fontColor('#FFFFFF')
              .margin({ top: 4 })
            
            // 添加停止录音按钮
            Button('停止录音')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor('#FF4444')
              .borderRadius(20)
              .margin({ top: 8 })
              .padding({ left: 16, right: 16, top: 6, bottom: 6 })
              .onClick(() => {
                this.stopRecording();
              })
          }
          .width('80%')
          .height(120)
          .backgroundColor('rgba(0, 0, 0, 0.85)')
          .justifyContent(FlexAlign.Center)
          .borderRadius(12)
          .position({ x: '10%', y: '30%' })  // 使用绝对定位，放在屏幕中间偏上
          .shadow({ radius: 20, color: 'rgba(0, 0, 0, 0.3)', offsetX: 0, offsetY: 4 })
        }

        // 引用回复提示
        if (this.replyToMessage) {
          Row() {
            Text(`回复: ${this.replyToMessage.msg}`)
              .fontSize(12)
              .fontColor('#666666')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            
            Text('✕')
              .fontSize(16)
              .fontColor('#999999')
              .margin({ left: 8 })
              .onClick(() => {
                this.replyToMessage = null;
              })
          }
          .width('100%')
          .padding(8)
          .backgroundColor('#F0F0F0')
        }

        // 底部输入栏
        Column() {
          Row() {
            Row({ space: 12 }) {
              // 语音按钮
              Image($r('app.media.mic_filled'))
                .width(28)
                .height(28)
                .onClick(() => {
                  if (this.isRecording) {
                    this.stopRecording();
                  } else {
                    this.startRecording();
                  }
                })

              // 表情按钮
              Image($r('app.media.emoji'))
                .width(28)
                .height(28)
                .onClick(() => {
                  this.showEmojiPanel = !this.showEmojiPanel;
                  this.showImagePanel = false;
                  this.showMorePanel = false;
                })
            }

            // [Start TextInput]
            TextInput({ placeholder: 'input your word...', text: this.inputMessage })
              .height(40)
              .width(200)
              .margin({
                left: 12,
                right: 12
              })
              .onBlur(() => {
                this.scroller.scrollEdge(Edge.Bottom);
              })
              .onChange((value) => {
                this.onInputChange(value);
              })
            // [End TextInput]

            Row() {
              Row({ space: 12 }) {
                // 更多功能按钮
                Image($r('app.media.plus_circle'))
                  .width(28)
                  .height(28)
                  .onClick(() => {
                    this.showMorePanel = !this.showMorePanel;
                    this.showEmojiPanel = false;
                    this.showImagePanel = false;
                  })
                
                // [Start SendMessage]
                Image(this.inputMessage === '' ? $r('app.media.send_off') : $r('app.media.send_on'))
                  .width(28)
                  .height(28)
                  .onClick(() => {
                    if (this.inputMessage.trim() === '') {
                      return;
                    }
                    this.sendMessage(this.inputMessage, MessageType.TEXT);
                    this.inputMessage = '';
                  })
                // [End SendMessage]
              }
            }
          }
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .padding({
          top: 8,
          bottom: 8
        })
        .backgroundColor('#F1F3F5')
        .width('100%')
        .height(80)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .title(this.itemInfo.name)
    .height('100%')
    .width('100%')
    .menus([
      {
        value: '搜索消息',
        icon: $r('app.media.Public_avatar'),
        action: () => {
          this.showSearchPanel = !this.showSearchPanel;
        }
      },
      {
        value: '标记为未读',
        icon: $r('app.media.Public_avatar'),
        action: () => {
          this.markAsUnread();
        }
      },
      {
        value: '清空聊天记录',
        icon: $r('app.media.Public_avatar'),
        action: () => {
          this.itemMessage = [];
          this.showItemMessage = [];
        }
      }
    ])
    .onReady((content: NavDestinationContext) => {
      this.itemInfo = JSON.parse(JSON.stringify(content.pathInfo.param));
      this.currentContactId = this.itemInfo.id;  // 保存当前联系人ID
      this.itemMessage = this.itemInfo.message;
      this.startIndex = this.itemMessage.length - 10;
      this.showItemMessage = this.itemMessage.slice(-10);
      
      // 恢复草稿
      let savedDraft = ChatPage.draftMap.get(this.currentContactId);
      if (savedDraft) {
        this.inputMessage = savedDraft;
      }
    })
  }
}
