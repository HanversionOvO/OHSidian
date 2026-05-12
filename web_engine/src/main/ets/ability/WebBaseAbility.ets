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

import UIAbility from '@ohos.app.ability.UIAbility';
import LogUtil from '../utils/LogUtil';
import window from '@ohos.window';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import JsBindingUtils from '../utils/JsBindingUtils';
import { NativeContext, WindowPreferences } from '../interface/CommonInterface';
import { CommandType, ConfigData, ContextType } from '../common/Constants';
import CheckEmptyUtils from '../utils/CheckEmptyUtils';
import { WebProxy } from '../interface/WebProxy';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'WebBaseAbility';

export class WebBaseAbility extends UIAbility implements WebProxy {
  protected xcomponentId: string = '';
  protected startUri: string = '';
  protected windowStage: window.WindowStage | undefined = undefined;
  protected nativeContext: NativeContext =
    JsBindingUtils.getNativeContext(ContextType.kMainProcess);
  protected hideTitleBar: boolean = true;
  protected originWindowId: number = -1;
  protected useDarkMode: boolean = false;
  protected isStateless: boolean = false;

  // Electron
  protected electronRelaunchArgs: string[] = [];
  protected minimizable: boolean = !this.hideTitleBar;
  protected maximizable: boolean = !this.hideTitleBar;
  protected closable: boolean = !this.hideTitleBar;
  protected alwaysOntop: boolean = false;
  protected resizable: boolean = true;
  protected isModal: boolean = false;
  protected isPanel: boolean = false;

  private initParameters(want: Want) {
    if (want && want.parameters) {
      if (want.parameters['xcomponentId'] !== undefined) {
        this.xcomponentId = want.parameters['xcomponentId'] as string;
      }
      if (want.parameters["useDarkMode"] !== undefined) {
        this.useDarkMode = want.parameters['useDarkMode'] as boolean;
      }
      if (want.parameters["hideTitleBar"] !== undefined) {
        this.hideTitleBar = want.parameters['hideTitleBar'] as boolean;
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
      if (want.parameters['isPanel'] !== undefined) {
        this.isPanel = want.parameters['isPanel'] as boolean;
      }
      if (want.parameters["electronRelaunchArgs"] !== undefined) {
        (want.parameters["electronRelaunchArgs"] as string[]).forEach((arg: string) => {
          this.electronRelaunchArgs.push(arg);
        });
        LogUtil.info(TAG, 'electronRelaunchArgs = ' + JSON.stringify(this.electronRelaunchArgs));
      }
      if (want.parameters["isStateless"] !== undefined) {
        this.isStateless = want.parameters['isStateless'] as boolean;
      }
    }

    if (want["uri"]) {
      let storePath = want['uri'] as string;
      // convert storage path to uri
      this.startUri = storePath.replace("file://docs/", "file:///");
    }
  }

  protected getContentPath(): string {
    return 'pages/Index';
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    this.initParameters(want);

    if (CheckEmptyUtils.isEmpty(this.xcomponentId)) {
      LogUtil.info(TAG, 'onCreate, Allocate xcomponent id');
      let widgetId = this.nativeContext.ExecuteCommand(CommandType.kGetWidget, {}).widget_Id;
      this.xcomponentId = ConfigData.WINDOW_PREFIX + widgetId;
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    this.windowStage = windowStage;
    this.originWindowId = windowStage?.getMainWindowSync().getWindowProperties().id;
  }

  // implements WebProxy interface
  getWindowStage(): window.WindowStage | undefined {
    return this.windowStage;
  }

  getWindow(): window.Window | undefined {
    return this.windowStage?.getMainWindowSync();
  }

  getWindowContext(): common.Context {
    return this.context;
  }

  getWindowId(): string {
    return this.xcomponentId;
  }

  getOriginWindowId(): number {
    return this.originWindowId;
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

  setWindowTitle(title: string) {
    this.context.setMissionLabel(title)
      .catch((err: BusinessError) => {
        LogUtil.error(TAG, 'Failed to set title: ' + JSON.stringify(err));
      });
  }

  createSubWindow(name: string): Promise<window.Window> {
    return new Promise<window.Window>((resolve, reject) => {
      if (!this.windowStage) {
        reject('Failed to get windowStage');
        return;
      }
      this.windowStage.createSubWindow(name)
        .then((data: window.Window) => {
          resolve(data);
        }).catch((error: BusinessError) => {
        reject(error);
      })
    });
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
