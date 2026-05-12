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
import { AbilityManager } from '../common/AbilityManager';
import { BaseAdapter } from '../common/BaseAdapter';
import LogMethod from '../common/LogDecorator';
import pointer from '@ohos.multimodalInput.pointer';
import { image } from '@kit.ImageKit';
import LogUtil from '../utils/LogUtil';
import { BusinessError } from '@kit.BasicServicesKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { SystemFloatingWindowManager } from '../common/SystemFloatingWindowManager';

const TAG: string = 'Cursor';

@injectable()
export class CursorAdapter extends BaseAdapter {
  private abilityManager: AbilityManager;
  private systemFloatingWindowManager : SystemFloatingWindowManager;

  constructor(
    @inject(AbilityManager) abilityManager: AbilityManager,
    @inject(SystemFloatingWindowManager) systemFloatingWindowManager: SystemFloatingWindowManager
  ) {
    super();
    this.abilityManager = abilityManager;
    this.systemFloatingWindowManager = systemFloatingWindowManager;
  }

  private getWindow(id: string | number) {
    let window = this.abilityManager.getProxy(id)?.getWindow();
    if (!window) {
      window = this.systemFloatingWindowManager.getWindow(id);
    }
    return window;
  }

  @LogMethod
  setCursor(id: number, type: number) {
    let window = this.getWindow(id);
    if (window) {
      let windowId = window.getWindowProperties().id;
      pointer.setPointerStyle(windowId, type)
        .catch((error: BusinessError) => {
          LogUtil.error(TAG, "Failed to set cursor. Cause: " + JSON.stringify(error));
        });
    }
  }

  @LogMethod
  setCursorVisible(visible: boolean) {
    pointer.setPointerVisible(visible)
      .catch((error: BusinessError) => {
        LogUtil.error(TAG, "Failed to set cursor visible. Cause: " + JSON.stringify(error));
      });
  }

  @LogMethod
  setCustomCursor(id: string,
    width: number,
    height: number,
    hotspotX: number,
    hotspotY: number,
    buff: ArrayBuffer) {
    let opts: image.InitializationOptions = {
      editable: false,
      pixelFormat: image.PixelMapFormat.BGRA_8888,
      size: {
        height: height,
        width: width
      }
    };
    image.createPixelMap(buff, opts)
      .then((cursorImage: image.PixelMap) => {
        let window = this.getWindow(id);
        if (window) {
          let windowId = window.getWindowProperties().id;
          if (deviceInfo.sdkApiVersion >= 15) {
            let cuisor: pointer.CustomCursor = {
              pixelMap: cursorImage,
              focusX: hotspotX,
              focusY: hotspotY
            }
            pointer.setCustomCursor(windowId, cuisor, { followSystem: false })
              .catch((error: BusinessError) => {
                LogUtil.error(TAG, "Failed to set setCustomCursor. Cause: " + JSON.stringify(error));
              });
          } else {
            pointer.setCustomCursorSync(windowId, cursorImage, hotspotX, hotspotY);
          }
        }
      })
      .catch((error: BusinessError) => {
        LogUtil.error(TAG, "Failed to create pixel map. Cause: " + JSON.stringify(error));
      });
  }
}
