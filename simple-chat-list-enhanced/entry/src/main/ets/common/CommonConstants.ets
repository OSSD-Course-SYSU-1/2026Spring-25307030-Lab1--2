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

// 消息类型枚举
export enum MessageType {
  TEXT = 'text',       // 文本消息
  EMOJI = 'emoji',     // 表情消息
  IMAGE = 'image',     // 图片消息
  VOICE = 'voice',     // 语音消息
  SYSTEM = 'system'    // 系统消息
}

// 消息状态枚举
export enum MessageStatus {
  SENDING = 'sending',     // 发送中
  SENT = 'sent',           // 已发送
  DELIVERED = 'delivered', // 已送达
  READ = 'read',           // 已读
  FAILED = 'failed'        // 发送失败
}

export class messageObj {
  id?: number = Date.now();              // 消息唯一ID
  sender: string = '';                   // 发送者: 'others' | 'myself'
  msg: ResourceStr = '';                 // 消息内容
  type?: MessageType = MessageType.TEXT; // 消息类型（可选，默认为文本）
  duration?: number = 0;                 // 语音时长(秒)
  timestamp?: number = Date.now();       // 时间戳
  status?: MessageStatus = MessageStatus.SENT;  // 消息状态
  isRecalled?: boolean = false;          // 是否已撤回
  isRead?: boolean = false;              // 是否已读
  replyTo?: messageObj | null = null;    // 引用回复的消息
}

@Observed
export class Item {
  id: number = 0;
  image: Resource = $r('app.media.Public_avatar');
  name: string = '';
  message: Array<messageObj> = [];
  isNewMessage: boolean = false;
  time: ResourceStr = '';
  @Track isTop: boolean = false;
  unreadCount?: number = 0;              // 未读消息数
  lastMessageTime?: number = Date.now(); // 最后消息时间
  isTyping?: boolean = false;            // 对方是否正在输入
  draft?: string = '';                   // 草稿内容
  isGroup?: boolean = false;             // 是否为群聊
  members?: string[] = [];               // 群成员列表
}

// 表情数据
export class EmojiData {
  // 常用表情列表
  static readonly EMOJI_LIST: string[] = [
    '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
    '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩',
    '😘', '😗', '😚', '😙', '🥲', '😋', '😛', '😜',
    '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐',
    '🤨', '😐', '😑', '😶', '😏', '😒', '🙄', '😬',
    '🤥', '😌', '😔', '😪', '🤤', '😴', '😷', '🤒',
    '🤕', '🤢', '🤮', '🤧', '🥵', '🥶', '🥴', '😵',
    '🤯', '🤠', '🥳', '🥸', '😎', '🤓', '🧐', '😕',
    '😟', '🙁', '☹️', '😮', '😯', '😲', '😳', '🥯',
    '😦', '😧', '😨', '😰', '😥', '😢', '😭', '😱',
    '😖', '😣', '😞', '😓', '😩', '😫', '🥺', '😤',
    '😡', '😠', '🤬', '👋', '🤚', '🖐️', '✋', '🖖'
  ]
}

// 图片数据
export class ImageData {
  // 示例图片列表
  static readonly IMAGE_LIST: string[] = [
    'chat_image_1',
    'chat_image_2',
    'chat_image_3',
    'chat_image_4',
    'chat_image_5',
    'chat_image_6'
  ]
}

export class CommonConstants {
  static readonly MESSAGE_LIST: Item[] = [
    {
      id: 0,
      image: $r('app.media.avatar_pink'),
      name: 'Jack',
      message: [
        {
          sender: 'others',
          msg: $r('app.string.Where_are_you')
        },
        {
          sender: 'myself',
          msg: $r('app.string.Just_went_out')
        },
        {
          sender: 'others',
          msg: $r('app.string.Where_are_you')
        },
        {
          sender: 'others',
          msg: $r('app.string.Where_are_you')
        },
        {
          sender: 'others',
          msg: $r('app.string.Where_are_you')
        },
        {
          sender: 'others',
          msg: $r('app.string.Where_are_you')
        },
        {
          sender: 'others',
          msg: $r('app.string.Where_are_you')
        },
        {
          sender: 'others',
          msg: $r('app.string.Where_are_you')
        },
        {
          sender: 'others',
          msg: $r('app.string.Where_are_you')
        },
        {
          sender: 'others',
          msg: $r('app.string.Where_are_you')
        },
        {
          sender: 'others',
          msg: $r('app.string.Where_are_you')
        },
        {
          sender: 'others',
          msg: $r('app.string.Where_are_you')
        },
        {
          sender: 'others',
          msg: $r('app.string.Where_are_you')
        },
        {
          sender: 'others',
          msg: $r('app.string.Where_are_you')
        },
        {
          sender: 'others',
          msg: $r('app.string.Where_are_you')
        },
        {
          sender: 'others',
          msg: $r('app.string.Where_are_you')
        },
        {
          sender: 'others',
          msg: $r('app.string.Where_are_you')
        },
        {
          sender: 'others',
          msg: $r('app.string.Where_are_you')
        },
        {
          sender: 'others',
          msg: $r('app.string.Where_are_you')
        },
        {
          sender: 'others',
          msg: $r('app.string.Where_are_you')
        },
        {
          sender: 'others',
          msg: $r('app.string.have_arrived_at_the_coffee_shop')
        }
      ],
      isNewMessage: false,
      time: $r('app.string.Message_time'),
      isTop: false
    },
    {
      id: 1,
      image: $r('app.media.avatar_blue'),
      name: 'Tom',
      message: [
        {
          sender: 'others',
          msg: $r('app.string.go_eat_together')
        }
      ],
      isNewMessage: true,
      time: $r('app.string.Message_time'),
      isTop: false
    },
    {
      id: 2,
      image: $r('app.media.avatar_purple'),
      name: 'Sam',
      message: [{
        sender: 'others',
        msg: $r('app.string.No_problem')
      }],
      isNewMessage: false,
      time: $r('app.string.Message_time'),
      isTop: false
    },
    {
      id: 3,
      image: $r('app.media.avatar_blue'),
      name: 'Taylor',
      message: [{
        sender: 'others',
        msg: 'ok'
      }],
      isNewMessage: false,
      time: $r('app.string.Message_time'),
      isTop: false
    },
    {
      id: 4,
      image: $r('app.media.avatar_purple'),
      name: 'John',
      message: [{
        sender: 'others',
        msg: $r('app.string.Nice_day')
      }],
      isNewMessage: true,
      time: $r('app.string.Message_time'),
      isTop: false
    },
    {
      id: 5,
      image: $r('app.media.avatar_pink'),
      name: 'Mark',
      message: [{
        sender: 'others',
        msg: $r('app.string.Ok')
      }],
      isNewMessage: false,
      time: $r('app.string.Message_time'),
      isTop: false
    },
    {
      id: 6,
      image: $r('app.media.avatar_pink'),
      name: 'Peter',
      message: [
        {
          sender: 'others',
          msg: $r('app.string.Dont_have_time')
        }
      ],
      isNewMessage: false,
      time: $r('app.string.Message_time'),
      isTop: false
    },
    {
      id: 7,
      image: $r('app.media.avatar_purple'),
      name: 'Daniel',
      message: [{
        sender: 'others',
        msg: $r('app.string.Completed')
      }],
      isNewMessage: false,
      time: $r('app.string.Message_time'),
      isTop: false
    },
    {
      id: 8,
      image: $r('app.media.avatar_blue'),
      name: 'David',
      message: [{
        sender: 'others',
        msg: $r('app.string.Where_are_you')
      }],
      isNewMessage: false,
      time: $r('app.string.Message_time'),
      isTop: false
    },
    {
      id: 9,
      image: $r('app.media.avatar_pink'),
      name: 'Linda',
      message: [{
        sender: 'others',
        msg: $r('app.string.Half_past_eight')
      }],
      isNewMessage: false,
      time: $r('app.string.Message_time'),
      isTop: false
    },
    {
      id: 10,
      image: $r('app.media.avatar_blue'),
      name: 'Jennifer',
      message: [{
        sender: 'others',
        msg: $r('app.string.Come_on')
      }],
      isNewMessage: false,
      time: $r('app.string.Message_time'),
      isTop: false
    },
    {
      id: 11,
      image: $r('app.media.avatar_purple'),
      name: 'Susan',
      message: [{
        sender: 'others',
        msg: $r('app.string.Not')
      }],
      isNewMessage: false,
      time: $r('app.string.Message_time'),
      isTop: false
    },
    {
      id: 12,
      image: $r('app.media.avatar_blue'),
      name: 'Betty',
      message: [{
        sender: 'others',
        msg: $r('app.string.No_problem')
      }],
      isNewMessage: false,
      time: $r('app.string.Message_time'),
      isTop: false
    }
  ]
}