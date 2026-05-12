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

import { inject, injectable } from 'inversify';
import { BusinessError } from '@ohos.base';
import display from '@ohos.display';
import { BaseAdapter } from '../common/BaseAdapter';
import LogUtil from '../utils/LogUtil';
import LogMethod from '../common/LogDecorator';
import { ContextAdapter } from './ContextAdapter';
import { common } from '@kit.AbilityKit';

export interface CompleteDisplay {
  id: number;
  baseDisplay: display.Display | undefined;
  availArea: display.Rect | undefined;
}

@injectable()
export class DisplayAdapter extends BaseAdapter {
  private static TAG: string = 'DisplayAdapter';
  private static VIRTUAL_ID: number = 1000;
  private fontSizeScale: number = 1.0;
  private ctxAdapter: ContextAdapter;
  private hasInit: boolean = false;
  private static invalidDisplay: CompleteDisplay = {
    id: -1,
    baseDisplay: undefined,
    availArea: undefined,
  };

  constructor(@inject(ContextAdapter) ctxAdapter: ContextAdapter) {
    super();
    this.ctxAdapter = ctxAdapter;
  }

  override init() {
    let activeContext = this.ctxAdapter.getActiveContext() as common.UIAbilityContext ||
                        this.ctxAdapter.getActiveContext() as common.UIExtensionContext;
    if (!activeContext) {
      return;
    }
    if (activeContext.config.fontSizeScale !== undefined) {
      this.fontSizeScale = activeContext.config.fontSizeScale;
    }
  }

  @LogMethod
  getDefaultDisplay(callback: (completeDisplay: CompleteDisplay) => void) { 
    try {
      let displayClass: display.Display = display.getDefaultDisplaySync();
      displayClass.getAvailableArea().then((availArea) => {
        let completeDisplay: CompleteDisplay = {
          id: displayClass.id,
          baseDisplay: displayClass,
          availArea: availArea,
        }
        callback(completeDisplay);
      }).catch((err: BusinessError) => {
        LogUtil.error(DisplayAdapter.TAG, `Failed to get the available area in this display.
          Code: ${err.code}, message: ${err.message}`);
        callback(DisplayAdapter.invalidDisplay);
      })
    } catch (exception) {
      LogUtil.error(DisplayAdapter.TAG,
        'Failed to obtain the default display object. Code: ' + JSON.stringify(exception));
      callback(DisplayAdapter.invalidDisplay);
    }
  }
 
  @LogMethod
  getALLDisplays(callback: (completeDisplays: Array<CompleteDisplay>,
                            length: number) => void) {
    try {
      display.getAllDisplays((err: BusinessError, baseDisplays: Array<display.Display>) => {
        const errCode: number = err.code;
        if (errCode) {
          LogUtil.error(DisplayAdapter.TAG,
            'Failed to obtain all the display objects. Code: ' + JSON.stringify(err));
          callback([], 0);
          return;
        }
 
        Promise.all(baseDisplays.map(baseDisplay => baseDisplay.getAvailableArea()))
          .then(availAreas => {
            let completeDisplays: Array<CompleteDisplay> =
              baseDisplays.map((baseDisplay, index) => ({
                id: baseDisplay.id,
                baseDisplay: baseDisplay,
                availArea: availAreas[index] }
              ) as CompleteDisplay);
            callback(completeDisplays, completeDisplays.length);
          })
          .catch((err: BusinessError) => {
            LogUtil.error(DisplayAdapter.TAG, `Failed to get the available area in all displays.
              Code: ${err.code}, message: ${err.message}`);
            callback([], 0);
          });
      });
    } catch (exception) {
      callback([], 0);
      LogUtil.error(DisplayAdapter.TAG,
        'Failed to obtain all the display object. Code: ' + JSON.stringify(exception));
    }
  }

  @LogMethod
  registerDisplayMonitor() {
    try {
      display.on("add", this.onAddCallback);
      display.on("remove", this.onRemoveCallback);
      display.on("change", this.onChangeCallback);
    } catch (exception) {
      LogUtil.error(DisplayAdapter.TAG, 'Failed to register callback. Code: ' + JSON.stringify(exception));
    }
  }

  private checkVirtualId(displayId: number) : boolean {
    if(displayId >= DisplayAdapter.VIRTUAL_ID){
        return true;
    }
    return false;
  }

  private onAddCallback = (data: number) => {
    try {
      if (this.checkVirtualId(data)) {
        LogUtil.warn(DisplayAdapter.TAG, JSON.stringify(data) + ' is a virtual display in onAddCallback');
        return;
      }
      this.nativeContext.OnDisplayChangeCallback("add", data);
    } catch (exception) {
      LogUtil.error(DisplayAdapter.TAG, 'Add event callback fail. Code: ' + JSON.stringify(exception));
    }
  }

  private onRemoveCallback = (data: number) => {
    try {
      if (this.checkVirtualId(data)) {
        LogUtil.warn(DisplayAdapter.TAG, JSON.stringify(data) + ' is a virtual display in onRemoveCallback');
        return;
      }
      this.nativeContext.OnDisplayChangeCallback("remove", data);
    } catch (exception) {
      LogUtil.error(DisplayAdapter.TAG, 'remove event callback fail. Code: ' + JSON.stringify(exception));
    }
  }

  private onChangeCallback = (data: number) => {
    try {
      if (this.checkVirtualId(data)) {
        LogUtil.warn(DisplayAdapter.TAG, JSON.stringify(data) + ' is a virtual display in onChangeCallback');
        return;
      }
      this.nativeContext.OnDisplayChangeCallback("change", data);
    } catch (exception) {
      LogUtil.error(DisplayAdapter.TAG, 'Change event callback fail. Code: ' + JSON.stringify(exception));
    }
  }

  @LogMethod
  getFontSizeScale(): number {
    if (!this.hasInit) {
      this.init();
      this.hasInit = true;
    }
    return this.fontSizeScale;
  }

  onSystemFontSizeChange(fontSizeZoom: number = 1.0) {
    this.fontSizeScale = fontSizeZoom;
    this.nativeContext.OnFontSizeChangeCallback(fontSizeZoom);
  }
}
