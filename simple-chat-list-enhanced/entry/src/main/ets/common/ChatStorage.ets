import preferences from '@ohos.data.preferences';
import distributedKVStore from '@ohos.data.distributedKVStore';
import distributedDeviceManager from '@ohos.distributedDeviceManager';
import webSocket from '@ohos.net.webSocket';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Item, messageObj, MessageStatus, MessageType } from './CommonConstants';

export interface SerializableMessage {
  id: number;
  sender: string;
  msg: ResourceStr;
  type: string;
  duration: number;
  timestamp: number;
  status: string;
  isRecalled: boolean;
  isRead: boolean;
  replyToId: number | null;
  replyToMsg: ResourceStr | null;
  replyToSender: string | null;
}

export interface SerializableContact {
  id: number;
  imageIndex: number;
  name: string;
  isNewMessage: boolean;
  time: ResourceStr;
  isTop: boolean;
  unreadCount: number;
  lastMessageTime: number;
  draft: string;
  isGroup: boolean;
  members: string[];
  messages: SerializableMessage[];
}

export interface ChatSyncEnvelope {
  version: number;
  updatedAt: number;
  contacts: SerializableContact[];
}

export interface DeviceStateInfo {
  action: distributedDeviceManager.DeviceStateChange;
  device: distributedDeviceManager.DeviceBasicInfo;
}

export interface DiscoverInfo {
  device: distributedDeviceManager.DeviceBasicInfo;
}

export interface DiscoverFailureInfo {
  reason: number;
}

export interface BindTargetResult {
  deviceId: string;
}

export type ContactsChangedListener = (contacts: SerializableContact[]) => void;

const AVATAR_MAP: Resource[] = [
  $r('app.media.avatar_pink'),
  $r('app.media.avatar_blue'),
  $r('app.media.avatar_purple'),
  $r('app.media.Public_avatar')
];

const AVATAR_NAME_MAP: Record<string, number> = {
  'avatar_pink': 0,
  'avatar_blue': 1,
  'avatar_purple': 2,
  'Public_avatar': 3
};

export class ChatStorage {
  private static instance: ChatStorage | null = null;
  private prefs: preferences.Preferences | null = null;
  private kvManager: distributedKVStore.KVManager | null = null;
  private kvStore: distributedKVStore.SingleKVStore | null = null;
  private deviceManager: distributedDeviceManager.DeviceManager | null = null;
  private relaySocket: webSocket.WebSocket | null = null;
  private contactsChangedListeners: ContactsChangedListener[] = [];
  private availableDeviceIds: string[] = [];
  private discoveredDeviceIds: string[] = [];
  private bindingDeviceIds: string[] = [];
  private localDeviceId: string = '';
  private pendingRelayEnvelope: ChatSyncEnvelope | null = null;
  private isDistributedReady: boolean = false;
  private isDeviceListenerReady: boolean = false;
  private isDiscoveryListenerReady: boolean = false;
  private isDiscovering: boolean = false;
  private isSyncCompleteListenerReady: boolean = false;
  private isRelayConnecting: boolean = false;
  private isRelayReady: boolean = false;
  private relayReconnectTimer: number = -1;
  private readonly STORE_NAME: string = 'chat_storage';
  private readonly DISTRIBUTED_STORE_ID: string = 'chat_distributed_store';
  private readonly RELAY_URL: string = 'ws://10.0.2.2:8787/chat-sync';
  private readonly KEY_CONTACTS: string = 'contacts_data';
  private readonly KEY_INITIALIZED: string = 'is_initialized';
  private readonly KEY_SYNC_VERSION: string = 'contacts_sync_version';

  private constructor() {}

  static getInstance(): ChatStorage {
    if (!ChatStorage.instance) {
      ChatStorage.instance = new ChatStorage();
    }
    return ChatStorage.instance;
  }

  async init(context: common.Context): Promise<void> {
    if (this.prefs) {
      await this.initDistributedStore(context);
      this.initRelaySync();
      return;
    }
    try {
      this.prefs = await preferences.getPreferences(context, this.STORE_NAME);
      console.info('[ChatStorage] Preferences initialized successfully');
      await this.initDistributedStore(context);
      this.initRelaySync();
    } catch (err) {
      console.error('[ChatStorage] Failed to init preferences: ' + JSON.stringify(err));
    }
  }

  onContactsChanged(listener: ContactsChangedListener): void {
    if (this.contactsChangedListeners.indexOf(listener) === -1) {
      this.contactsChangedListeners.push(listener);
    }
  }

  offContactsChanged(listener: ContactsChangedListener): void {
    let index = this.contactsChangedListeners.indexOf(listener);
    if (index !== -1) {
      this.contactsChangedListeners.splice(index, 1);
    }
  }

  private notifyContactsChanged(contacts: SerializableContact[]): void {
    this.contactsChangedListeners.forEach((listener: ContactsChangedListener) => {
      listener(contacts);
    });
  }

  private async initDistributedStore(context: common.Context): Promise<void> {
    if (this.isDistributedReady) {
      return;
    }
    try {
      this.kvManager = distributedKVStore.createKVManager({
        bundleName: 'com.example.myapplication',
        context: context
      });

      let options: distributedKVStore.Options = {
        createIfMissing: true,
        encrypt: false,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S1
      };

      this.kvStore = await this.kvManager.getKVStore<distributedKVStore.SingleKVStore>(
        this.DISTRIBUTED_STORE_ID,
        options
      );
      this.isDistributedReady = true;
      this.initDeviceManager();
      this.subscribeDistributedChanges();
      this.subscribeSyncComplete();
      await this.pullDistributedContacts();
      this.syncDistributedContacts(distributedKVStore.SyncMode.PULL_ONLY);
      console.info('[ChatStorage] Distributed store initialized successfully');
    } catch (err) {
      console.warn('[ChatStorage] Distributed store is unavailable: ' + JSON.stringify(err));
    }
  }

  private initRelaySync(): void {
    if (this.relaySocket || this.isRelayConnecting) {
      return;
    }
    this.isRelayConnecting = true;
    try {
      let socket = webSocket.createWebSocket();
      this.relaySocket = socket;

      socket.on('open', (err: BusinessError, data: Object) => {
        this.isRelayConnecting = false;
        if (err) {
          console.warn('[ChatStorage] Relay open failed: ' + JSON.stringify(err));
          this.scheduleRelayReconnect();
          return;
        }
        this.isRelayReady = true;
        console.info('[ChatStorage] Relay connected: ' + JSON.stringify(data));
        this.flushPendingRelayEnvelope();
        this.publishLocalContactsToRelay();
      });

      socket.on('message', (err: BusinessError, data: string | ArrayBuffer) => {
        if (err) {
          console.warn('[ChatStorage] Relay message failed: ' + JSON.stringify(err));
          return;
        }
        this.handleRelayMessage(data);
      });

      socket.on('close', (err: BusinessError) => {
        console.warn('[ChatStorage] Relay closed: ' + JSON.stringify(err));
        this.isRelayReady = false;
        this.isRelayConnecting = false;
        this.relaySocket = null;
        this.scheduleRelayReconnect();
      });

      socket.on('error', (err: BusinessError) => {
        console.warn('[ChatStorage] Relay error: ' + JSON.stringify(err));
        this.isRelayReady = false;
        this.isRelayConnecting = false;
      });

      socket.connect(this.RELAY_URL).then(() => {
        console.info('[ChatStorage] Relay connect requested: ' + this.RELAY_URL);
      }).catch((err: BusinessError) => {
        console.warn('[ChatStorage] Failed to connect relay: ' + JSON.stringify(err));
        this.isRelayConnecting = false;
        this.isRelayReady = false;
        this.relaySocket = null;
        this.scheduleRelayReconnect();
      });
    } catch (err) {
      console.warn('[ChatStorage] Relay is unavailable: ' + JSON.stringify(err));
      this.isRelayConnecting = false;
      this.isRelayReady = false;
      this.relaySocket = null;
      this.scheduleRelayReconnect();
    }
  }

  private scheduleRelayReconnect(): void {
    if (this.relayReconnectTimer !== -1) {
      return;
    }
    this.relayReconnectTimer = setTimeout(() => {
      this.relayReconnectTimer = -1;
      this.initRelaySync();
    }, 3000);
  }

  private async publishLocalContactsToRelay(): Promise<void> {
    if (!this.prefs) {
      return;
    }
    try {
      let contacts = await this.loadContacts();
      if (contacts.length === 0) {
        return;
      }
      let updatedAt = await this.prefs.get(this.KEY_SYNC_VERSION, 0) as number;
      this.publishRelayContacts(contacts, updatedAt);
    } catch (err) {
      console.warn('[ChatStorage] Failed to publish local contacts to relay: ' + JSON.stringify(err));
    }
  }

  private publishRelayContacts(contacts: SerializableContact[], updatedAt: number): void {
    let envelope: ChatSyncEnvelope = {
      version: 1,
      updatedAt: updatedAt,
      contacts: contacts
    };
    this.sendRelayEnvelope(envelope);
  }

  private flushPendingRelayEnvelope(): void {
    if (!this.pendingRelayEnvelope) {
      return;
    }
    let envelope = this.pendingRelayEnvelope;
    this.pendingRelayEnvelope = null;
    this.sendRelayEnvelope(envelope);
  }

  private sendRelayEnvelope(envelope: ChatSyncEnvelope): void {
    if (!this.relaySocket || !this.isRelayReady) {
      this.pendingRelayEnvelope = envelope;
      this.initRelaySync();
      return;
    }
    this.relaySocket.send(JSON.stringify(envelope)).then(() => {
      console.info('[ChatStorage] Relay contacts sent, updatedAt: ' + envelope.updatedAt);
    }).catch((err: BusinessError) => {
      console.warn('[ChatStorage] Failed to send relay contacts: ' + JSON.stringify(err));
      this.pendingRelayEnvelope = envelope;
      this.isRelayReady = false;
      this.relaySocket = null;
      this.scheduleRelayReconnect();
    });
  }

  private handleRelayMessage(data: string | ArrayBuffer): void {
    if (typeof data !== 'string') {
      console.warn('[ChatStorage] Relay message ignored because it is not text');
      return;
    }
    console.info('[ChatStorage] Relay contacts received');
    this.applyDistributedContacts(data);
  }

  private initDeviceManager(): void {
    if (this.deviceManager) {
      this.refreshAvailableDeviceIds();
      return;
    }
    try {
      this.deviceManager = distributedDeviceManager.createDeviceManager('com.example.myapplication');
      this.localDeviceId = this.deviceManager.getLocalDeviceId();
      this.refreshAvailableDeviceIds();
      this.subscribeDeviceChanges();
      this.subscribeDiscoveryChanges();
      this.startDeviceDiscovery();
    } catch (err) {
      console.warn('[ChatStorage] Device manager is unavailable: ' + JSON.stringify(err));
    }
  }

  private subscribeDeviceChanges(): void {
    if (!this.deviceManager || this.isDeviceListenerReady) {
      return;
    }
    this.isDeviceListenerReady = true;
    try {
      this.deviceManager.on('deviceStateChange', (data: DeviceStateInfo) => {
        console.info('[ChatStorage] Device state changed: ' + JSON.stringify(data));
        this.refreshAvailableDeviceIds();
        if (data.action === distributedDeviceManager.DeviceStateChange.AVAILABLE) {
          this.syncDistributedContacts(distributedKVStore.SyncMode.PULL_ONLY);
        }
      });
    } catch (err) {
      console.warn('[ChatStorage] Failed to subscribe device changes: ' + JSON.stringify(err));
    }
  }

  private subscribeDiscoveryChanges(): void {
    if (!this.deviceManager || this.isDiscoveryListenerReady) {
      return;
    }
    this.isDiscoveryListenerReady = true;
    try {
      this.deviceManager.on('discoverSuccess', (data: DiscoverInfo) => {
        console.info('[ChatStorage] Device discovered: ' + JSON.stringify(data));
        this.rememberDevice(data.device);
        this.bindDiscoveredDevice(data.device);
        this.syncDistributedContacts(distributedKVStore.SyncMode.PUSH_PULL);
      });
      this.deviceManager.on('discoverFailure', (data: DiscoverFailureInfo) => {
        console.warn('[ChatStorage] Device discovery failed: ' + JSON.stringify(data));
      });
    } catch (err) {
      console.warn('[ChatStorage] Failed to subscribe discovery changes: ' + JSON.stringify(err));
    }
  }

  private startDeviceDiscovery(): void {
    if (!this.deviceManager || this.isDiscovering) {
      return;
    }
    try {
      this.deviceManager.startDiscovering({ discoverTargetType: 1 });
      this.isDiscovering = true;
      console.info('[ChatStorage] Device discovery started');
    } catch (err) {
      console.warn('[ChatStorage] Failed to start device discovery: ' + JSON.stringify(err));
    }
  }

  private rememberDevice(device: distributedDeviceManager.DeviceBasicInfo): void {
    if (!device.deviceId || device.deviceId === this.localDeviceId) {
      return;
    }
    if (this.discoveredDeviceIds.indexOf(device.deviceId) === -1) {
      this.discoveredDeviceIds.push(device.deviceId);
    }
  }

  private bindDiscoveredDevice(device: distributedDeviceManager.DeviceBasicInfo): void {
    if (!this.deviceManager || !device.deviceId || device.deviceId === this.localDeviceId) {
      return;
    }
    if (this.availableDeviceIds.indexOf(device.deviceId) !== -1 ||
      this.bindingDeviceIds.indexOf(device.deviceId) !== -1) {
      return;
    }

    this.bindingDeviceIds.push(device.deviceId);
    try {
      this.deviceManager.bindTarget(device.deviceId, {
        bindType: 1,
        targetPkgName: 'com.example.myapplication',
        appName: 'Simple Chat',
        appOperation: 'Sync chat messages',
        customDescription: 'Sync chat messages across your devices.'
      }, (err: BusinessError, data: BindTargetResult) => {
        let index = this.bindingDeviceIds.indexOf(device.deviceId);
        if (index !== -1) {
          this.bindingDeviceIds.splice(index, 1);
        }
        if (err) {
          console.warn('[ChatStorage] Failed to bind discovered device: ' + JSON.stringify(err));
          return;
        }
        console.info('[ChatStorage] Device bind completed: ' + JSON.stringify(data));
        this.refreshAvailableDeviceIds();
        this.syncDistributedContacts(distributedKVStore.SyncMode.PUSH_PULL);
      });
    } catch (err) {
      let index = this.bindingDeviceIds.indexOf(device.deviceId);
      if (index !== -1) {
        this.bindingDeviceIds.splice(index, 1);
      }
      console.warn('[ChatStorage] Failed to request device bind: ' + JSON.stringify(err));
    }
  }

  private refreshAvailableDeviceIds(): string[] {
    if (!this.deviceManager) {
      return [];
    }
    try {
      let devices = this.deviceManager.getAvailableDeviceListSync();
      let deviceIds: string[] = [];
      devices.forEach((device: distributedDeviceManager.DeviceBasicInfo) => {
        this.addDeviceId(deviceIds, device.deviceId);
      });
      this.availableDeviceIds = deviceIds;
      console.info('[ChatStorage] Available devices: ' + JSON.stringify(devices));
      return deviceIds;
    } catch (err) {
      console.warn('[ChatStorage] Failed to get available devices: ' + JSON.stringify(err));
      return this.availableDeviceIds;
    }
  }

  private subscribeSyncComplete(): void {
    if (!this.kvStore || this.isSyncCompleteListenerReady) {
      return;
    }
    this.isSyncCompleteListenerReady = true;
    try {
      this.kvStore.on('syncComplete', (result: Array<[string, number]>) => {
        console.info('[ChatStorage] Sync complete: ' + JSON.stringify(result));
        this.pullDistributedContacts();
      });
    } catch (err) {
      console.warn('[ChatStorage] Failed to subscribe sync complete: ' + JSON.stringify(err));
    }
  }

  private syncDistributedContacts(mode: distributedKVStore.SyncMode): void {
    if (!this.kvStore) {
      return;
    }
    let deviceIds = this.refreshAvailableDeviceIds();
    this.discoveredDeviceIds.forEach((deviceId: string) => {
      this.addDeviceId(deviceIds, deviceId);
    });
    if (deviceIds.length === 0) {
      console.info('[ChatStorage] No available device to sync');
      this.startDeviceDiscovery();
      return;
    }
    try {
      this.kvStore.sync(deviceIds, mode, 0);
      console.info('[ChatStorage] Sync requested, devices: ' + deviceIds.join(',') + ', mode: ' + mode);
    } catch (err) {
      console.warn('[ChatStorage] Failed to request sync: ' + JSON.stringify(err));
    }
  }

  private addDeviceId(deviceIds: string[], deviceId: string): void {
    if (deviceId && deviceId !== this.localDeviceId && deviceIds.indexOf(deviceId) === -1) {
      deviceIds.push(deviceId);
    }
  }

  private subscribeDistributedChanges(): void {
    if (!this.kvStore) {
      return;
    }
    try {
      this.kvStore.on(
        'dataChange',
        distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_ALL,
        (changeNotification: distributedKVStore.ChangeNotification) => {
          this.handleDistributedChange(changeNotification);
        }
      );
    } catch (err) {
      console.warn('[ChatStorage] Failed to subscribe distributed changes: ' + JSON.stringify(err));
    }
  }

  private async pullDistributedContacts(): Promise<void> {
    if (!this.kvStore) {
      return;
    }
    try {
      let value = await this.kvStore.get(this.KEY_CONTACTS) as string;
      await this.applyDistributedContacts(value);
    } catch (err) {
      console.info('[ChatStorage] No distributed contacts to pull yet');
    }
  }

  private async handleDistributedChange(changeNotification: distributedKVStore.ChangeNotification): Promise<void> {
    let entries = changeNotification.insertEntries.concat(changeNotification.updateEntries);
    for (let entry of entries) {
      let jsonStr = this.getEntryStringValue(entry);
      if (entry.key === this.KEY_CONTACTS && jsonStr) {
        console.info('[ChatStorage] Distributed contacts changed from device: ' + changeNotification.deviceId);
        await this.applyDistributedContacts(jsonStr);
      }
    }
  }

  private getEntryStringValue(entry: distributedKVStore.Entry): string | null {
    if (typeof entry.value === 'string') {
      return entry.value;
    }
    if (typeof entry.value === 'object') {
      let value = (entry.value as distributedKVStore.Value).value;
      if (typeof value === 'string') {
        return value;
      }
    }
    return null;
  }

  private parseSyncEnvelope(jsonStr: string): ChatSyncEnvelope | null {
    try {
      return JSON.parse(jsonStr) as ChatSyncEnvelope;
    } catch (err) {
      console.error('[ChatStorage] Failed to parse sync data: ' + JSON.stringify(err));
      return null;
    }
  }

  private cloneContact(contact: SerializableContact): SerializableContact {
    return JSON.parse(JSON.stringify(contact)) as SerializableContact;
  }

  private getMessageKey(message: SerializableMessage): string {
    if (message.id) {
      return message.id.toString();
    }
    return `${message.sender}_${message.type}_${message.timestamp}_${JSON.stringify(message.msg)}`;
  }

  private getMessageSortValue(message: SerializableMessage): number {
    if (message.timestamp) {
      return message.timestamp;
    }
    return message.id || 0;
  }

  private mergeMessage(localMessage: SerializableMessage, incomingMessage: SerializableMessage): SerializableMessage {
    let merged: SerializableMessage = JSON.parse(JSON.stringify(localMessage)) as SerializableMessage;
    if (incomingMessage.isRecalled) {
      merged.isRecalled = true;
    }
    if (incomingMessage.isRead) {
      merged.isRead = true;
    }
    if (incomingMessage.status !== merged.status) {
      merged.status = incomingMessage.status;
    }
    if (incomingMessage.replyToId !== null && merged.replyToId === null) {
      merged.replyToId = incomingMessage.replyToId;
      merged.replyToMsg = incomingMessage.replyToMsg;
      merged.replyToSender = incomingMessage.replyToSender;
    }
    return merged;
  }

  private mergeMessages(
    localMessages: SerializableMessage[],
    incomingMessages: SerializableMessage[]
  ): [SerializableMessage[], boolean] {
    let changed = false;
    let messageMap: Map<string, SerializableMessage> = new Map();

    localMessages.forEach((message: SerializableMessage) => {
      messageMap.set(this.getMessageKey(message), JSON.parse(JSON.stringify(message)) as SerializableMessage);
    });

    incomingMessages.forEach((message: SerializableMessage) => {
      let key = this.getMessageKey(message);
      let existing = messageMap.get(key);
      if (!existing) {
        messageMap.set(key, JSON.parse(JSON.stringify(message)) as SerializableMessage);
        changed = true;
        return;
      }

      let merged = this.mergeMessage(existing, message);
      if (JSON.stringify(merged) !== JSON.stringify(existing)) {
        messageMap.set(key, merged);
        changed = true;
      }
    });

    let mergedMessages: SerializableMessage[] = Array.from(messageMap.values());
    mergedMessages.sort((left: SerializableMessage, right: SerializableMessage) => {
      let diff = this.getMessageSortValue(left) - this.getMessageSortValue(right);
      if (diff !== 0) {
        return diff;
      }
      return (left.id || 0) - (right.id || 0);
    });
    return [mergedMessages, changed];
  }

  private mergeContact(
    localContact: SerializableContact | undefined,
    incomingContact: SerializableContact
  ): [SerializableContact, boolean] {
    if (!localContact) {
      let created = this.cloneContact(incomingContact);
      created.draft = '';
      return [created, true];
    }

    let changed = false;
    let localClone = this.cloneContact(localContact);
    let incomingClone = this.cloneContact(incomingContact);
    let mergedMessagesResult = this.mergeMessages(localClone.messages || [], incomingClone.messages || []);
    let mergedMessages = mergedMessagesResult[0];
    if (mergedMessagesResult[1]) {
      changed = true;
    }

    let localLastTime = localClone.lastMessageTime || 0;
    let incomingLastTime = incomingClone.lastMessageTime || 0;
    let base = incomingLastTime > localLastTime ? incomingClone : localClone;
    let merged = this.cloneContact(base);
    merged.messages = mergedMessages;
    merged.draft = localClone.draft || '';

    if (mergedMessages.length > 0) {
      let lastMessage = mergedMessages[mergedMessages.length - 1];
      let messageTime = lastMessage.timestamp || Date.now();
      if (messageTime !== merged.lastMessageTime) {
        changed = true;
      }
      merged.lastMessageTime = messageTime;
    }

    if (JSON.stringify(merged) !== JSON.stringify(localContact)) {
      changed = true;
    }
    return [merged, changed];
  }

  private mergeContacts(
    localContacts: SerializableContact[],
    incomingContacts: SerializableContact[]
  ): [SerializableContact[], boolean] {
    let changed = false;
    let contactMap: Map<number, SerializableContact> = new Map();
    localContacts.forEach((contact: SerializableContact) => {
      contactMap.set(contact.id, this.cloneContact(contact));
    });

    incomingContacts.forEach((contact: SerializableContact) => {
      let mergeResult = this.mergeContact(contactMap.get(contact.id), contact);
      contactMap.set(contact.id, mergeResult[0]);
      if (mergeResult[1]) {
        changed = true;
      }
    });

    let mergedContacts: SerializableContact[] = Array.from(contactMap.values());
    mergedContacts.sort((left: SerializableContact, right: SerializableContact) => {
      if (left.isTop && !right.isTop) {
        return -1;
      }
      if (!left.isTop && right.isTop) {
        return 1;
      }
      return left.id - right.id;
    });

    return [mergedContacts, changed];
  }

  private async applyDistributedContacts(jsonStr: string): Promise<void> {
    if (!this.prefs) {
      return;
    }
    let envelope = this.parseSyncEnvelope(jsonStr);
    if (!envelope) {
      return;
    }
    let localVersion = await this.prefs.get(this.KEY_SYNC_VERSION, 0) as number;
    let localContacts = await this.loadContacts();
    let mergeResult = this.mergeContacts(localContacts, envelope.contacts || []);
    if (!mergeResult[1]) {
      if (envelope.updatedAt > localVersion) {
        await this.prefs.put(this.KEY_SYNC_VERSION, envelope.updatedAt);
        await this.prefs.flush();
      }
      return;
    }
    let mergedContacts = mergeResult[0];
    let updatedAt = Math.max(envelope.updatedAt, localVersion, Date.now());
    await this.persistContacts(mergedContacts, updatedAt);
    this.notifyContactsChanged(mergedContacts);
    await this.publishContacts(mergedContacts, updatedAt);
    this.publishRelayContacts(mergedContacts, updatedAt);
  }

  async applyContinuationContacts(contactsJson: string, updatedAt: number): Promise<void> {
    if (!contactsJson) {
      return;
    }
    let contacts = JSON.parse(contactsJson) as SerializableContact[];
    let envelope: ChatSyncEnvelope = {
      version: 1,
      updatedAt: updatedAt || Date.now(),
      contacts: contacts
    };
    await this.applyDistributedContacts(JSON.stringify(envelope));
  }

  private async publishContacts(contacts: SerializableContact[], updatedAt: number): Promise<void> {
    if (!this.kvStore) {
      return;
    }
    try {
      let envelope: ChatSyncEnvelope = {
        version: 1,
        updatedAt: updatedAt,
        contacts: contacts
      };
      await this.kvStore.put(this.KEY_CONTACTS, JSON.stringify(envelope));
      this.syncDistributedContacts(distributedKVStore.SyncMode.PUSH_PULL);
    } catch (err) {
      console.warn('[ChatStorage] Failed to publish contacts to distributed store: ' + JSON.stringify(err));
    }
  }

  private async persistContacts(contacts: SerializableContact[], updatedAt: number): Promise<void> {
    if (!this.prefs) {
      console.warn('[ChatStorage] Preferences not initialized, skip save');
      return;
    }
    await this.prefs.put(this.KEY_CONTACTS, JSON.stringify(contacts));
    await this.prefs.put(this.KEY_INITIALIZED, true);
    await this.prefs.put(this.KEY_SYNC_VERSION, updatedAt);
    await this.prefs.flush();
  }

  async isDataInitialized(): Promise<boolean> {
    if (!this.prefs) {
      return false;
    }
    return await this.prefs.has(this.KEY_INITIALIZED);
  }

  async saveContacts(contacts: SerializableContact[]): Promise<void> {
    if (!this.prefs) {
      console.warn('[ChatStorage] Preferences not initialized, skip save');
      return;
    }
    try {
      let updatedAt = Date.now();
      await this.persistContacts(contacts, updatedAt);
      await this.publishContacts(contacts, updatedAt);
      this.publishRelayContacts(contacts, updatedAt);
      console.info('[ChatStorage] Contacts saved successfully, count: ' + contacts.length);
    } catch (err) {
      console.error('[ChatStorage] Failed to save contacts: ' + JSON.stringify(err));
    }
  }

  async loadContacts(): Promise<SerializableContact[]> {
    if (!this.prefs) {
      console.warn('[ChatStorage] Preferences not initialized, return empty');
      return [];
    }
    try {
      let jsonStr = await this.prefs.get(this.KEY_CONTACTS, '[]') as string;
      return JSON.parse(jsonStr) as SerializableContact[];
    } catch (err) {
      console.error('[ChatStorage] Failed to load contacts: ' + JSON.stringify(err));
      return [];
    }
  }

  async saveContactMessages(contactId: number, messages: SerializableMessage[]): Promise<void> {
    if (!this.prefs) {
      return;
    }
    try {
      await this.prefs.put(`messages_${contactId}`, JSON.stringify(messages));
      await this.prefs.flush();
    } catch (err) {
      console.error('[ChatStorage] Failed to save messages for contact ' + contactId + ': ' + JSON.stringify(err));
    }
  }

  async loadContactMessages(contactId: number): Promise<SerializableMessage[]> {
    if (!this.prefs) {
      return [];
    }
    try {
      let jsonStr = await this.prefs.get(`messages_${contactId}`, '[]') as string;
      return JSON.parse(jsonStr) as SerializableMessage[];
    } catch (err) {
      console.error('[ChatStorage] Failed to load messages for contact ' + contactId + ': ' + JSON.stringify(err));
      return [];
    }
  }

  async saveDraft(contactId: number, draft: string): Promise<void> {
    if (!this.prefs) {
      return;
    }
    try {
      await this.prefs.put(`draft_${contactId}`, draft);
      await this.prefs.flush();
    } catch (err) {
      console.error('[ChatStorage] Failed to save draft: ' + JSON.stringify(err));
    }
  }

  async loadDraft(contactId: number): Promise<string> {
    if (!this.prefs) {
      return '';
    }
    try {
      return await this.prefs.get(`draft_${contactId}`, '') as string;
    } catch (err) {
      console.error('[ChatStorage] Failed to load draft: ' + JSON.stringify(err));
      return '';
    }
  }

  async clearAll(): Promise<void> {
    if (!this.prefs) {
      return;
    }
    try {
      await this.prefs.clear();
      await this.prefs.flush();
      console.info('[ChatStorage] All data cleared');
    } catch (err) {
      console.error('[ChatStorage] Failed to clear data: ' + JSON.stringify(err));
    }
  }
}

export function avatarToIndex(image: Resource): number {
  try {
    let imageText = JSON.stringify(image);
    for (let name of Object.keys(AVATAR_NAME_MAP)) {
      if (imageText.includes(name)) {
        return AVATAR_NAME_MAP[name];
      }
    }
  } catch (err) {
    console.warn('[ChatStorage] Failed to map avatar: ' + JSON.stringify(err));
  }
  return 3;
}

export function indexToAvatar(index: number): Resource {
  if (index >= 0 && index < AVATAR_MAP.length) {
    return AVATAR_MAP[index];
  }
  return AVATAR_MAP[3];
}

export function messageToSerializable(msg: messageObj): SerializableMessage {
  return {
    id: msg.id || Date.now(),
    sender: msg.sender,
    msg: msg.msg,
    type: msg.type || MessageType.TEXT,
    duration: msg.duration || 0,
    timestamp: msg.timestamp || Date.now(),
    status: msg.status || MessageStatus.SENT,
    isRecalled: msg.isRecalled || false,
    isRead: msg.isRead || false,
    replyToId: msg.replyTo ? (msg.replyTo.id || null) : null,
    replyToMsg: msg.replyTo ? msg.replyTo.msg : null,
    replyToSender: msg.replyTo ? msg.replyTo.sender : null
  };
}

export function serializableToMessage(sMsg: SerializableMessage): messageObj {
  let replyTo: messageObj | null = null;
  if (sMsg.replyToId !== null && sMsg.replyToMsg !== null) {
    replyTo = {
      id: sMsg.replyToId,
      sender: sMsg.replyToSender || '',
      msg: sMsg.replyToMsg,
      type: MessageType.TEXT,
      timestamp: 0,
      status: MessageStatus.SENT
    };
  }

  return {
    id: sMsg.id,
    sender: sMsg.sender,
    msg: sMsg.msg,
    type: sMsg.type as MessageType,
    duration: sMsg.duration,
    timestamp: sMsg.timestamp,
    status: sMsg.status as MessageStatus,
    isRecalled: sMsg.isRecalled,
    isRead: sMsg.isRead,
    replyTo: replyTo
  };
}

export function contactToSerializable(contact: Item): SerializableContact {
  return {
    id: contact.id,
    imageIndex: avatarToIndex(contact.image),
    name: contact.name,
    isNewMessage: contact.isNewMessage,
    time: contact.time,
    isTop: contact.isTop,
    unreadCount: contact.unreadCount || 0,
    lastMessageTime: contact.lastMessageTime || Date.now(),
    draft: contact.draft || '',
    isGroup: contact.isGroup || false,
    members: contact.members || [],
    messages: contact.message.map((msg: messageObj) => messageToSerializable(msg))
  };
}

export function serializableToContact(contact: SerializableContact): Item {
  return {
    id: contact.id,
    image: indexToAvatar(contact.imageIndex),
    name: contact.name,
    message: contact.messages.map((msg: SerializableMessage) => serializableToMessage(msg)),
    isNewMessage: contact.isNewMessage,
    time: contact.time,
    isTop: contact.isTop,
    unreadCount: contact.unreadCount,
    lastMessageTime: contact.lastMessageTime,
    isTyping: false,
    draft: contact.draft,
    isGroup: contact.isGroup,
    members: contact.members
  };
}
