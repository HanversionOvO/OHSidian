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

import LogUtil from '../utils/LogUtil';
import window from '@ohos.window';
import Want from '@ohos.app.ability.Want';
import JsBindingUtils from '../utils/JsBindingUtils';
import { NativeContext, WindowPreferences } from '../interface/CommonInterface';
import { CommandType, ConfigData, ContextType } from '../common/Constants';
import CheckEmptyUtils from '../utils/CheckEmptyUtils';
import { WebProxy } from '../interface/WebProxy';
import { common, EmbeddedUIExtensionAbility, UIExtensionContentSession } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'WebBaseExtensionAbility';

export class WebBaseExtensionAbility extends EmbeddedUIExtensionAbility implements WebProxy {
  protected xcomponentId: string = ''; // Guest module id
  protected startUri: string = '';
  protected hostModuleId: number = 0; // Host module id
  protected hostModuleType: number = 0; // Host module type, Ability or SubWindow
  protected userData: string = ''; // Host module specified
  protected session: UIExtensionContentSession | undefined = undefined;
  protected nativeContext: NativeContext =
    JsBindingUtils.getNativeContext(ContextType.kMainProcess);
  protected hideTitleBar: boolean = true;

  // Electron
  protected electronRelaunchArgs: string[] = [];
  protected minimizable: boolean = !this.hideTitleBar;
  protected maximizable: boolean = !this.hideTitleBar;
  protected closable: boolean = !this.hideTitleBar;
  protected alwaysOntop: boolean = false;
  protected resizable: boolean = true;
  protected isModal: boolean = false;

  private initParameters(want: Want) {
    if (want && want.parameters) {
      if (want.parameters['xcomponentId'] !== undefined) {
        this.xcomponentId = want.parameters['xcomponentId'] as string;
      }
      if (want.parameters["hideTitleBar"] !== undefined) {
        this.hideTitleBar = want.parameters['hideTitleBar'] as boolean;
      }
      if (want.parameters['hostModuleId'] !== undefined) {
        this.hostModuleId = want.parameters['hostModuleId'] as number;
      }
      if (want.parameters['hostModuleType'] !== undefined) {
        this.hostModuleType = want.parameters['hostModuleType'] as number;
      }
      if (want.parameters['userData'] !== undefined) {
        this.userData = want.parameters['userData'] as string;
      }
      if (want.parameters['minimizable'] !== undefined) {
        this.minimizable = want.parameters['minimizable'] as boolean;
      }
      if (want.parameters['maximizable'] !== undefined) {
        this.maximizable = want.parameters['maximizable'] as boolean;
      }
      if (want.parameters['closable'] !== undefined) {
        this.closable = want.parameters['closable'] as boolean;
      }
      if (want.parameters["electronRelaunchArgs"] !== undefined) {
        (want.parameters["electronRelaunchArgs"] as string[]).forEach((arg: string) => {
          this.electronRelaunchArgs.push(arg);
        });
        LogUtil.info(TAG, 'electronRelaunchArgs = ' + JSON.stringify(this.electronRelaunchArgs));
      }
    }

    if (want["uri"]) {
      let storePath = want['uri'] as string;
      // convert storage path to uri
      this.startUri = storePath.replace("file://docs/", "file:///");
    }
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    this.initParameters(want);

    if (CheckEmptyUtils.isEmpty(this.xcomponentId)) {
      LogUtil.info(TAG, 'onCreate, Allocate xcomponent id');
      let widgetId = this.nativeContext.ExecuteCommand(CommandType.kGetWidget, {}).widget_Id;
      this.xcomponentId = ConfigData.WINDOW_PREFIX + widgetId;
    }

    this.session = session;
  }

  // implements WebProxy interface
  getWindowStage(): window.WindowStage | undefined {
    return undefined;
  }

  getWindow(): window.Window | undefined {
    return undefined;
  }

  getWindowContext(): common.Context {
    return this.context;
  }

  getWindowId(): string {
    return this.xcomponentId;
  }

  closeWindow() {
    this.context.terminateSelf()
      .then(() => {
        LogUtil.info(TAG, 'terminate Self id: ' + this.getWindowId());
      })
      .catch((err: BusinessError) => {
        LogUtil.error(TAG, 'Failed to terminate Self: ' + JSON.stringify(err));
      });
  }

  setWindowTitle(title:string) {}

  createSubWindow(name: string): Promise<window.Window> {
    return new Promise<window.Window>((resolve, reject) => {
      if (!this.session) {
        reject('Failed to get Session');
        return;
      }
      const windowProxy = this.session.getUIExtensionWindowProxy();
      const subWindowOpts: window.SubWindowOptions = {
        title: 'This is a subwindow',
        decorEnabled: false
      };
      windowProxy?.createSubWindowWithOptions(name, subWindowOpts)
        .then((data: window.Window) => {
          resolve(data);
        }).catch((error: BusinessError) => {
        reject(error);
      })
    });
  }

  getOriginWindowId(): number {
    return -1;
  }

  getWindowPreferences(): WindowPreferences {
    return {
      hideTitleBar: this.hideTitleBar,
      maximizable: this.maximizable,
      minimizable: this.minimizable,
      closable: this.closable
    };
  }

  setWindowPreferences(preferences: WindowPreferences) {
    this.hideTitleBar = preferences.hideTitleBar;
    this.maximizable = preferences.maximizable;
    this.minimizable = preferences.minimizable;
    this.closable = preferences.closable;
  }
};
