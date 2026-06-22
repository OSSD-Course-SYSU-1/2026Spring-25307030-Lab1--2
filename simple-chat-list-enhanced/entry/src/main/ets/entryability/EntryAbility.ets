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

import {
  abilityAccessCtrl,
  AbilityConstant,
  ConfigurationConstant,
  PermissionRequestResult,
  Permissions,
  UIAbility,
  Want
} from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { ChatStorage } from '../common/ChatStorage';
import {
  APP_CONTINUATION_CONTACT_ID,
  APP_CONTINUATION_CONTACTS_JSON,
  APP_CONTINUATION_ROUTE,
  APP_CONTINUATION_TOKEN,
  APP_CONTINUATION_UPDATED_AT,
  APP_CURRENT_CONTACT_ID,
  APP_CURRENT_ROUTE,
  ROUTE_INDEX,
  WANT_CONTINUATION_CONTACT_ID,
  WANT_CONTINUATION_CONTACTS_JSON,
  WANT_CONTINUATION_FLAG,
  WANT_CONTINUATION_ROUTE,
  WANT_CONTINUATION_UPDATED_AT,
  WANT_INLINE_DATA_LIMIT,
  readNumberParam,
  readStringParam
} from '../common/ContinuationState';

const DOMAIN = 0x0000;
const SYNC_PERMISSIONS: Array<Permissions> = ['ohos.permission.DISTRIBUTED_DATASYNC'];

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(0x0000, 'testTag', `setColorMode failed.code=${err.code},message=${err.message}`);
    }
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
    this.restoreContinuationFromWant(want);
  }

  async onContinue(wantParam: Record<string, Object>): Promise<AbilityConstant.OnContinueResult> {
    try {
      let route = AppStorage.get<string>(APP_CURRENT_ROUTE) || ROUTE_INDEX;
      let contactId = AppStorage.get<number>(APP_CURRENT_CONTACT_ID) || -1;
      let chatStorage = ChatStorage.getInstance();
      await chatStorage.init(this.context);
      let contacts = await chatStorage.loadContacts();
      let contactsJson = JSON.stringify(contacts);
      let updatedAt = Date.now();

      wantParam[WANT_CONTINUATION_FLAG] = 'true';
      wantParam[WANT_CONTINUATION_ROUTE] = route;
      wantParam[WANT_CONTINUATION_CONTACT_ID] = contactId;
      wantParam[WANT_CONTINUATION_UPDATED_AT] = updatedAt;
      if (contactsJson.length <= WANT_INLINE_DATA_LIMIT) {
        wantParam[WANT_CONTINUATION_CONTACTS_JSON] = contactsJson;
      }

      console.info('[EntryAbility] Continuation state saved, route: ' + route +
        ', contactId: ' + contactId + ', bytes: ' + contactsJson.length);
      return AbilityConstant.OnContinueResult.AGREE;
    } catch (err) {
      console.error('[EntryAbility] Failed to save continuation state: ' + JSON.stringify(err));
      return AbilityConstant.OnContinueResult.REJECT;
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onNewWant');
    this.restoreContinuationFromWant(want);
  }

  private restoreContinuationFromWant(want: Want): void {
    let params = want.parameters;
    if (readStringParam(params, WANT_CONTINUATION_FLAG) !== 'true') {
      return;
    }

    let route = readStringParam(params, WANT_CONTINUATION_ROUTE, ROUTE_INDEX);
    let contactId = readNumberParam(params, WANT_CONTINUATION_CONTACT_ID, -1);
    let contactsJson = readStringParam(params, WANT_CONTINUATION_CONTACTS_JSON);
    let updatedAt = readNumberParam(params, WANT_CONTINUATION_UPDATED_AT, Date.now());

    AppStorage.setOrCreate(APP_CONTINUATION_ROUTE, route);
    AppStorage.setOrCreate(APP_CONTINUATION_CONTACT_ID, contactId);
    AppStorage.setOrCreate(APP_CONTINUATION_CONTACTS_JSON, contactsJson);
    AppStorage.setOrCreate(APP_CONTINUATION_UPDATED_AT, updatedAt);
    AppStorage.setOrCreate(APP_CONTINUATION_TOKEN, Date.now());

    if (contactsJson) {
      let chatStorage = ChatStorage.getInstance();
      chatStorage.init(this.context).then(() => {
        chatStorage.applyContinuationContacts(contactsJson, updatedAt);
      }).catch((err: BusinessError) => {
        console.warn('[EntryAbility] Failed to restore continuation contacts: ' + JSON.stringify(err));
      });
    }
    console.info('[EntryAbility] Continuation state received, route: ' + route + ', contactId: ' + contactId);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    this.requestDistributedPermission().finally(() => {
      this.loadMainContent(windowStage);
    });
  }

  private async requestDistributedPermission(): Promise<void> {
    try {
      let atManager = abilityAccessCtrl.createAtManager();
      let result: PermissionRequestResult =
        await atManager.requestPermissionsFromUser(this.context, SYNC_PERMISSIONS);
      console.info('[EntryAbility] Distributed permission result: ' + JSON.stringify(result));
    } catch (err) {
      console.warn('[EntryAbility] Failed to request distributed permission: ' + JSON.stringify(err));
    }
  }

  private loadMainContent(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');

      let windowClass: window.Window = windowStage.getMainWindowSync(); // Get the main window of the application.
      // 1. Set the window to full screen.
      let isLayoutFullScreen = true;
      windowClass.setWindowLayoutFullScreen(isLayoutFullScreen).then(() => {
        console.info('Succeeded in setting the window layout to full-screen mode.');
      }).catch((err: BusinessError) => {
        console.error('Failed to set the window layout to full-screen mode. Cause:' + JSON.stringify(err));
      });

      let type = window.AvoidAreaType.TYPE_SYSTEM;
      let avoidArea = windowClass.getWindowAvoidArea(type);
      let topRectHeight = avoidArea.topRect.height; // Get the height of the status bar area.
      AppStorage.setOrCreate('topRectHeight', topRectHeight);
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
