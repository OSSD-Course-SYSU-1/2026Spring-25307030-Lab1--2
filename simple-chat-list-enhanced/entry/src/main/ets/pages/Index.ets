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

import { ChatPage } from './ChatPage';
import { Item, CommonConstants } from '../common/CommonConstants';
import { ChatStorage, contactToSerializable, serializableToContact, SerializableContact } from '../common/ChatStorage';
import {
  APP_CONTINUATION_CONTACT_ID,
  APP_CONTINUATION_CONTACTS_JSON,
  APP_CONTINUATION_ROUTE,
  APP_CONTINUATION_TOKEN,
  APP_CURRENT_CONTACT_ID,
  APP_CURRENT_ROUTE,
  ROUTE_CHAT,
  ROUTE_INDEX
} from '../common/ContinuationState';

@Entry
@Component
struct Index {
  @State isFlag: boolean = false;
  private pageStack: NavPathStack = new NavPathStack();
  @State sortedList: Item[] = [];
  @State dragItem: Item = {
    id: -1,
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
  private scroller: Scroller = new Scroller();
  private chatStorage: ChatStorage = ChatStorage.getInstance();
  private isStorageReady: boolean = false;
  private isSyncListenerReady: boolean = false;
  @StorageProp('topRectHeight') topRectHeight: number = 0;
  @StorageLink('chat_continuation_token') continuationToken: number = 0;

  @Builder
  PagesMap(name: string, param: string) {
    if (name === 'ChatPage') {
      ChatPage()
    }
  }

  sortList(shouldSave: boolean = false) {
    this.sortedList = this.sortedList.sort((a, b) => {
      if (a.isTop && !b.isTop) {
        return -1;
      } else if (!a.isTop && b.isTop) {
        return 1;
      }
      return a.id - b.id;
    })
    if (shouldSave) {
      this.saveContacts();
    }
  }

  async loadContacts() {
    await this.chatStorage.init(getContext(this));
    this.isStorageReady = true;
    this.bindSyncListener();
    let storedContacts = await this.chatStorage.loadContacts();
    if (storedContacts.length > 0) {
      this.sortedList = storedContacts.map((item) => serializableToContact(item));
    } else {
      this.sortedList = CommonConstants.MESSAGE_LIST;
    }
    this.sortList();
    setTimeout(() => {
      this.consumeContinuationState();
    }, 100);
  }

  async saveContacts() {
    if (!this.isStorageReady) {
      return;
    }
    await this.chatStorage.saveContacts(this.sortedList.map((item: Item) => contactToSerializable(item)));
  }

  bindSyncListener() {
    if (this.isSyncListenerReady) {
      return;
    }
    this.isSyncListenerReady = true;
    this.chatStorage.onContactsChanged((contacts: SerializableContact[]) => {
      this.sortedList = contacts.map((item: SerializableContact) => serializableToContact(item));
      this.sortList();
    });
  }

  rememberIndexContinuationState() {
    AppStorage.setOrCreate(APP_CURRENT_ROUTE, ROUTE_INDEX);
    AppStorage.setOrCreate(APP_CURRENT_CONTACT_ID, -1);
  }

  rememberChatContinuationState(contactId: number) {
    AppStorage.setOrCreate(APP_CURRENT_ROUTE, ROUTE_CHAT);
    AppStorage.setOrCreate(APP_CURRENT_CONTACT_ID, contactId);
  }

  consumeContinuationState() {
    let token = AppStorage.get<number>(APP_CONTINUATION_TOKEN) || 0;
    if (token === 0) {
      return;
    }

    let contactsJson = AppStorage.get<string>(APP_CONTINUATION_CONTACTS_JSON) || '';
    if (contactsJson) {
      try {
        let contacts = JSON.parse(contactsJson) as SerializableContact[];
        if (contacts.length > 0) {
          this.sortedList = contacts.map((item: SerializableContact) => serializableToContact(item));
          this.sortList();
        }
      } catch (err) {
        console.warn('[Index] Failed to parse continuation contacts: ' + JSON.stringify(err));
      }
    }

    let route = AppStorage.get<string>(APP_CONTINUATION_ROUTE) || ROUTE_INDEX;
    let contactId = AppStorage.get<number>(APP_CONTINUATION_CONTACT_ID) || -1;
    if (route === ROUTE_CHAT && contactId >= 0) {
      let target = this.sortedList.find((item: Item) => item.id === contactId);
      if (target) {
        this.rememberChatContinuationState(target.id);
        this.pageStack.pushPathByName('ChatPage', target);
      } else if (this.sortedList.length === 0) {
        return;
      }
    }

    AppStorage.setOrCreate(APP_CONTINUATION_TOKEN, 0);
    AppStorage.setOrCreate(APP_CONTINUATION_CONTACTS_JSON, '');
  }

  getLastMessageText(item: Item): ResourceStr {
    if (item.message.length === 0) {
      return '';
    }
    return item.message[item.message.length - 1].msg;
  }

  // Switch top status.
  toggleTop(item: Item) {
    item.isTop = !item.isTop;
    this.sortList(true);
  }

  aboutToAppear() {
    this.rememberIndexContinuationState();
    this.loadContacts();
  }

  onPageShow() {
    this.consumeContinuationState();
  }

  // [Start dragFloatView]
  @Builder
  dragFloatView(item: Item) {
    Row() {
      if (item.isNewMessage) {
        Badge({
          value: '',
          position: BadgePosition.RightTop,
          style: { badgeSize: 8, badgeColor: '#FA2A2D' }
        }) {
          Image(item.image)
            .width(48)
            .height(48)
        }
      } else {
        Image(item.image)
          .width(48)
          .height(48)
      }

      Row() {
        Column() {
          Text(item.name)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 })
            .textAlign(TextAlign.Start)
          Text(this.getLastMessageText(item))
            .fontSize(16)
            .maxLines(1)
            .constraintSize({ maxWidth: '70%' })
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start)

        Text(item.time)
          .fontSize(12)
          .margin({ bottom: 20 })
          .fontColor(item.isTop ? Color.Black : Color.Gray)
      }
      .width('80%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .height(72)
    .backgroundColor(item.isTop ? '#4497FF' : 'rgba(240,240,240,1)')
    .justifyContent(FlexAlign.SpaceAround)
  }

  // [End dragFloatView]

  // [Start itemEnd]
  @Builder
  itemEnd(item: Item, index: number) {
    Row() {
      Image($r(item.isTop ? 'app.media.up_off' : 'app.media.up_on'))
        .width(24)
        .height(24)
        .margin({ right: 8 })
        .onClick(() => {
          this.toggleTop(item);
        })
      Image($r('app.media.delete'))
        .width(24)
        .height(24)
        .onClick(() => {
          this.sortedList.splice(index, 1);
          this.saveContacts();
        })
    }
    .padding(4)
    .height('100%')
    .backgroundColor('#F1F3F5')
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  // [End itemEnd]

  build() {
    Navigation(this.pageStack) {
      Stack({ alignContent: Alignment.BottomEnd }) {
        if (this.continuationToken !== 0) {
          Text('')
            .width(0)
            .height(0)
            .onAppear(() => {
              this.consumeContinuationState();
            })
        }

        Column() {
          List({ space: 1, scroller: this.scroller }) {
            ForEach(this.sortedList, (item: Item, index: number) => {
              ListItem() {
                Row() {
                  // [Start Badge]
                  if (item.isNewMessage) {
                    // The Badge component can be used to add tags to list items.
                    Badge({
                      value: '',
                      position: BadgePosition.RightTop,
                      style: { badgeSize: 8, badgeColor: '#FA2A2D' }
                    }) {
                      Image(item.image)
                        .width(48)
                        .height(48)
                    }
                  } else {
                    Image(item.image)
                      .width(48)
                      .height(48)
                  }
                  // [End Badge]

                  Column() {
                    Row() {
                      Column() {
                        Text(item.name)
                          .fontSize(16)
                          .fontWeight(FontWeight.Bold)
                          .margin({ bottom: 8 })
                          .textAlign(TextAlign.Start)
                        Text(this.getLastMessageText(item))
                          .fontSize(16)
                          .maxLines(1)
                          .constraintSize({ maxWidth: '70%' })
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                      .height('100%')
                      .justifyContent(FlexAlign.Center)
                      .alignItems(HorizontalAlign.Start)

                      Text(item.time)
                        .fontSize(12)
                        .margin({ bottom: 20 })
                        .fontColor(item.isTop ? Color.Black : Color.Gray)
                    }
                    .width('80%')
                    .justifyContent(FlexAlign.SpaceBetween)

                    //Add underline.
                    Line().width('328vp').height(1).stroke(Color.Black).backgroundColor('#F5F5F5')
                  }
                }
                .width('100%')
                .height(72)
                .padding({ left: 4, right: 4 })
                .borderRadius(16)
                .backgroundColor(item.isTop ? 'rgba(10, 89, 247, 0.2)' : '#FFFFFF')
                .justifyContent(FlexAlign.SpaceAround)
              }
              // [Start visibility]
              .visibility(item == this.dragItem ? Visibility.Hidden : Visibility.Visible)
              // [End visibility]
              .onClick(() => {
                // Jump to chat page.
                this.rememberChatContinuationState(item.id);
                this.pageStack.pushPathByName('ChatPage', item);
              })
              .transition({ type: TransitionType.Delete, opacity: 0 })
              // [Start swipeAction]
              .swipeAction({
                end: {
                  builder: () => {
                    this.itemEnd(item, index);
                  },
                  actionAreaDistance: 56,
                  onAction: () => {
                    this.getUIContext().animateTo({ duration: 1000 }, () => {
                      this.sortedList.splice(index, 1);
                      this.saveContacts();
                    })
                  }
                },
                edgeEffect: SwipeEdgeEffect.Spring
              })

              // [End swipeAction]
            }, (item: Item) => item.id.toString() + item.isTop)
          }
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)
          .contentEndOffset(8)
          .sticky(StickyStyle.Header)
          // [Start onWillScroll]
          .onWillScroll(() => {
            if (this.scroller.currentOffset().yOffset > 100) {
              this.isFlag = true;
            } else {
              this.isFlag = false;
            }
          })
          // [End onWillScroll]
          .onItemMove(() => {
            return true;
          })
          // [Start onItemDragStart]
          .onItemDragStart((event: ItemDragInfo, itemIndex: number) => {
            // Triggered when starting to drag and drop list elements.
            this.dragItem = this.sortedList[itemIndex];
            return this.dragFloatView(this.sortedList[itemIndex]);
          })
          // [End onItemDragStart]
          // [Start onItemDragMove]
          .onItemDragMove((event: ItemDragInfo, itemIndex: number, insertIndex: number) => {
            // Triggered when dragging and moving within the range of a list element.
            this.getUIContext().animateTo({ duration: 200, curve: Curve.Linear }, () => {
              let deleteIndex = this.sortedList.indexOf(this.dragItem);
              this.sortedList.splice(deleteIndex, 1);
              this.sortedList.splice(insertIndex, 0, this.dragItem);
              this.saveContacts();
            })
          })
          // [End onItemDragMove]
          .onItemDrop(() => {
            this.dragItem = {
              id: -1,
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
            this.saveContacts();
          })
        }
        .padding(10)
        .width('100%')
        .height('100%')

        // [Start Back_to_top]
        if (this.isFlag) {
          Image($r('app.media.arrow_up_circle_fill'))
            .width(36)
            .height(36)
            .margin({ right: 10, bottom: 10 })
            .onClick(() => {
              this.scroller.scrollToIndex(0, true);
              this.isFlag = false;
            })
        }
        // [End Back_to_top]
      }
      .width('100%')
      .height('100%')
    }
    .title($r('app.string.Sample_title'))
    .titleMode(NavigationTitleMode.Mini)
    .hideBackButton(true)
    .mode(NavigationMode.Stack)
    .navDestination(this.PagesMap)
    .padding({ top: this.getUIContext().px2vp(this.topRectHeight) })
  }
}
