/*
 * Copyright (c) 2023-2025 Haitai FangYuan Co., Ltd.
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of
 *    conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list
 *    of conditions and the following disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used
 *    to endorse or promote products derived from this software without specific prior written
 *    permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import { injectable, inject } from 'inversify';
import bundleManager from '@ohos.bundle.bundleManager';
import { BusinessError } from '@ohos.base';
import display from '@ohos.display';
import I18n from '@ohos.i18n';
import { common, Want } from '@kit.AbilityKit';

import { AbilityManager } from '../common/AbilityManager';
import { BaseAdapter } from '../common/BaseAdapter';
import { ContextAdapter } from './ContextAdapter';
import { notificationManager } from '@kit.NotificationKit';
import LogUtil from '../utils/LogUtil';
import LogMethod from '../common/LogDecorator';

const TAG: string = 'ElectronApp';

@injectable()
export class ElectronAppAdapter extends BaseAdapter {
  private abilityManager: AbilityManager;
  private bundleName: string = 'com.huawei.ohos_electron';
  private bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
                        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_METADATA;
  private ctxAdapter: ContextAdapter;
  private fontSizeScale: number = 1.0;

  constructor(
    @inject(ContextAdapter) ctxAdapter: ContextAdapter,
    @inject(AbilityManager) abilityManager: AbilityManager,
  ) {
    super();
    this.ctxAdapter = ctxAdapter;
    this.abilityManager = abilityManager;
    try {
      let data = bundleManager.getBundleInfoForSelfSync(this.bundleFlags);
      this.bundleName = data.name;
    } catch (err) {
      let message = (err as BusinessError).message;
      LogUtil.error(TAG, `getBundleInfoForSelfSync failed.: ${message}`);
    }
  }

  @LogMethod
  getPreferredLanguageList(): Array<string> {
    let preferredLanguageList: Array<string> = [];
    try {
      preferredLanguageList = I18n.System.getPreferredLanguageList(); // 获取系统当前偏好语言列表
    } catch(error) {
      let err: BusinessError = error as BusinessError;
      LogUtil.error(TAG, `call System.getPreferredLanguageList failed, error code: ${err.code}, message: ${err.message}.`);
    }
    return preferredLanguageList;
  }

  @LogMethod
  getSystemRegion(): string {
    return I18n.System.getSystemRegion();
  }

  @LogMethod
  getSystemLocale(): string {
    return I18n.System.getSystemLocale();
  }

  @LogMethod
  getFileIcon(callback: Function): void {
    let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;
    try {
      bundleManager.getBundleInfoForSelf(bundleFlags).then((data) => {
        let context = this.ctxAdapter.getActiveContext();
        context?.resourceManager.getMediaContent(data.appInfo.iconId, (error: BusinessError, value: Uint8Array) => {
          if (error != null) {
            LogUtil.error(TAG, 'getMediaContent failed. Cause: ' + error);
          } else {
            let media = value;
            callback(media);
          }
        });
      }).catch((err: BusinessError) => {
        LogUtil.error(TAG, 'getBundleInfoForSelf failed. Cause:' + err.message)
      });
    } catch (err) {
      let message = (err as BusinessError).message;
      LogUtil.error(TAG, 'getBundleInfoForSelf failed. Cause:' + message)
    }
  }

  @LogMethod
  relaunch(args: Array<string>, execPath: string): void {
    let applicationContext = this.ctxAdapter.getContext().getApplicationContext();
    let want: Want = {
      bundleName: this.bundleName,
      abilityName: 'EntryAbility'
    };
    want.parameters = {
      'electronRelaunchArgs' : args,
      'electronRelaunchExecPath': execPath
    };
    try {
      applicationContext.restartApp(want);
    } catch (err) {
      LogUtil.error(TAG, 'restartApp fail, error:' + JSON.stringify(err))
    }
  }

  @LogMethod
  openApplicationInfoEntry(): void {
    let context = this.ctxAdapter.getActiveContext() as common.UIAbilityContext;
    context.startAbility({
      bundleName: 'com.huawei.hmos.settings',
      abilityName: 'com.huawei.hmos.settings.MainAbility',
      uri: 'application_info_entry',
      parameters: {
        pushParams: this.bundleName
      }
    });
  }

  @LogMethod
  getFontSizeScale(): number {
    return this.fontSizeScale;
  }

  @LogMethod
  setBadgeCount(count: number): void {
    notificationManager.setBadgeNumber(count).then(() => {
      LogUtil.debug(TAG, "setBadgeNumber success");
    }).catch((err: BusinessError) => {
      LogUtil.error(TAG, `setBadgeNumber fail: ${JSON.stringify(err)}`);
    });
  }

  @LogMethod
  getAvailableArea(displayId: number, callback: (availArea: display.Rect) => void) {
    let displayClass: display.Display = display.getDisplayByIdSync(displayId);
    if (!displayClass) {
      LogUtil.error(TAG, 'getDisplayByIdSync failed.');
      callback({ left: 0, top: 0, width: 0, height: 0 });
      return;
    }
    displayClass.getAvailableArea().then((availArea) => {
      LogUtil.error(TAG, 'getAvailableArea success. Area: ' + JSON.stringify(availArea));
      callback(availArea);
    }).catch((err: BusinessError) => {
      LogUtil.error(TAG, 'getAvailableArea failed. Cause: ' + JSON.stringify(err));
      callback({ left: 0, top: 0, width: 0, height: 0 });
    });
  }
};
