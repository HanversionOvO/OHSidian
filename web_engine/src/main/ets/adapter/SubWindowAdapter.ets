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
import window from '@ohos.window';
import { IParams,
         ISubWindowInfo,
         NewWindowParam,
         WindowBound } from '../interface/CommonInterface';
import { AbilityManager } from '../common/AbilityManager';
import { BaseAdapter } from '../common/BaseAdapter';
import LogUtil from '../utils/LogUtil';
import LogMethod from '../common/LogDecorator';
import { BusinessError } from '@kit.BasicServicesKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { SystemFloatingWindowManager } from '../common/SystemFloatingWindowManager';

const TAG: string = 'SubWindow';
const FEEDBACK_X: number = 2;
const MAX_TOTAL_SUB_WINDOW_NUM: number = 20;

@injectable()
export class SubWindowAdapter extends BaseAdapter {
  private abilityManager: AbilityManager;
  private systemFloatingWindowManager: SystemFloatingWindowManager;
  private subWindowList: (ISubWindowInfo)[] = [];
  private reusableSubWindow: Map<string, (ISubWindowInfo)[]> =
    new Map<string, (ISubWindowInfo)[]>();
  private globalCache: (ISubWindowInfo)[] = [];

  constructor(
    @inject(AbilityManager) abilityManager: AbilityManager,
    @inject(SystemFloatingWindowManager) systemFloatingWindowManager: SystemFloatingWindowManager,
  ) {
    super();
    this.abilityManager = abilityManager;
    this.systemFloatingWindowManager = systemFloatingWindowManager;
  }

  @LogMethod
  createSubWindow(param: NewWindowParam,
    callback: (ready: boolean, id: string) => void) {
    let parentId = param.parent_id
    let fixedBounds = this.adjustBounds(parentId, param.bounds);
    const reusableWindow =
      this.findReuseableSubWindow(parentId, fixedBounds.width, fixedBounds.height);
    if (reusableWindow) {
      try {
        let paramsLink: SubscribedAbstractProperty<IParams> =
          reusableWindow.localStorage.link('subWindowParams');
        let lastParams = paramsLink.get();
        lastParams.initColorRgb = param.init_color_argb;
        paramsLink.set(lastParams);
        this.resizeSubWindow(reusableWindow.subWindow, fixedBounds.width, fixedBounds.height);
        this.moveSubWindow(reusableWindow.subWindow, fixedBounds.left, fixedBounds.top, parentId);
        reusableWindow.subWindow.showWindow()
          .catch((err: BusinessError) => {
            LogUtil.error(TAG, 'Failed to reuseSubWindow: ' + reusableWindow.id + ',err:' + JSON.stringify(err));
            return;
          });
        callback(true, reusableWindow.id);
        return;
      } catch (e) {
        LogUtil.error(TAG,'reuseSubWindow error' + reusableWindow.id);
      }
    }
    const para: Record<string, IParams> = {
      'subWindowParams': {
        id: param.window_id,
        callback: callback,
        size: [fixedBounds.width, fixedBounds.height],
        initColorRgb: param.init_color_argb,
      }
    };
    let subStorage: LocalStorage = new LocalStorage(para);
    this.createNewWindow(parentId, param.window_id, fixedBounds, subStorage);
  }

  private getParentWindow(parentId: string): window.Window | undefined {
    let mainWindow = this.abilityManager.getProxy(parentId)?.getWindow();
    if (!mainWindow) {
      let mainWindowId = this.systemFloatingWindowManager.getMainWindowId(parentId);
      mainWindow = this.abilityManager.getProxy((mainWindowId as string))?.getWindow();
    }
    return mainWindow;
  }

  private adjustBounds(parentId: string, bounds: WindowBound): WindowBound {
    let out_bounds = bounds;
    let mainWindow = this.getParentWindow(parentId);
    if (!mainWindow) {
      return out_bounds;
    }
    const windowProp = mainWindow.getWindowProperties();
    if (windowProp && windowProp.drawableRect.left !== 0) {
      out_bounds.top += windowProp.drawableRect.left;
    } else {
      // In full-screen mode, when a sub-window is created, the window is
      // moved left by two pixels to adjust its position relative to the cursor point.
      out_bounds.top += FEEDBACK_X;
    }
    return out_bounds;
  }

  private findSubWindow(id: string): ISubWindowInfo | undefined {
    for (let i = 0; i < this.subWindowList.length; i++) {
      const item = this.subWindowList[i];
      if (item && item.id === id) {
        return item;
      }
    }
    return undefined;
  }

  private findReuseableSubWindow(parentId: string, width: number, height: number)
    : ISubWindowInfo | undefined {
    let reusableSubWindowList = this.reusableSubWindow.get(parentId);
    if (!reusableSubWindowList) {
      return undefined;
    }
    for (let i = 0; i < reusableSubWindowList.length; i++) {
      const reusableWindow = reusableSubWindowList[i];
      if (!reusableWindow) {
        continue;
      }
      const rect = reusableWindow.subWindow.getWindowProperties().windowRect;
      const maxDistance:number = 2;
      if (Math.abs(rect.width - width) <= maxDistance &&
        Math.abs(rect.height - height) <= maxDistance) {
        reusableSubWindowList.splice(i, 1);
        let found = false;
        for (let j = 0; j < this.globalCache.length; j++) {
          if (this.globalCache[j].parentId === reusableWindow.parentId &&
              this.globalCache[j].id === reusableWindow.id) {
            found = true;
            this.globalCache.splice(j, 1);
            break;
          }
        }
        if (!found) {
          LogUtil.error(TAG, 'Global cache is inconsistent with cache of ' + reusableWindow.parentId);
        }
        LogUtil.error(TAG, `reusableWindow ${reusableWindow.id} size ${reusableSubWindowList.length}`);
        this.subWindowList.push(reusableWindow);
        return reusableWindow;
      }
    }
    return undefined;
  }

  private createNewWindow(parentId: string,
                          id: string,
                          bounds: WindowBound,
                          subStorage: LocalStorage) {
    let proxy = this.abilityManager.getProxy(parentId);
    if (!proxy) {
      let mainWindowId = this.systemFloatingWindowManager.getMainWindowId(parentId);
      proxy = this.abilityManager.getProxy((mainWindowId as string));
    }
    proxy?.createSubWindow(id)
      .then((data: window.Window) => {
        this.initSubWindow(data, parentId, id, bounds, subStorage);
      }).catch((error: BusinessError) => {
      LogUtil.error(TAG, 'Failed to create the subWindow. Cause: ' + JSON.stringify(error));
    });
  }

  private initSubWindow(data: window.Window,
                        parentId: string,
                        id: string,
                        bounds: WindowBound,
                        subStorage: LocalStorage) {
    try {
      let windowClass = data;
      windowClass.keepKeyboardOnFocus(true);
      this.subWindowList.push({
        id: id,
        parentId: parentId,
        subWindow: windowClass,
        localStorage: subStorage
      });

      windowClass.on('windowSizeChange', (size) => {
        const prop = data.getWindowProperties();
        let windowBound: WindowBound = {
          left: prop.windowRect.left,
          top: prop.windowRect.top,
          width: prop.windowRect.width,
          height: prop.windowRect.height,
        };
        this.nativeContext.OnWindowSizeChange(id, windowBound);
      });

      this.moveSubWindow(windowClass, bounds.left, bounds.top, parentId);
      if (bounds.width > 0 && bounds.height > 0) {
        this.resizeSubWindow(windowClass, bounds.width, bounds.height);
      }
      windowClass.loadContent('pages/SubWindow', subStorage, (err) => {
        if (err.code) {
          LogUtil.error(TAG, 'Failed to load the content. Cause:' + JSON.stringify(err));
          return;
        }
        windowClass.setWindowFocusable(false)
          .then(() => {
            windowClass.showWindow()
              .catch((err: BusinessError) => {
                LogUtil.error(TAG, 'Failed to show SubWindow. Cause: ' + JSON.stringify(err));
              });
          }).catch(() => {
          LogUtil.error(TAG, 'set focusable false failed')
        });
      });
    } catch (exception) {
      LogUtil.error(TAG,'Failed to create sub window. Cause: ' + JSON.stringify(exception));
    }
  }

  private async resizeSubWindow(windowClass: window.Window, width: number, height: number) {
    return await windowClass.resize(width, height);
  }

  private moveSubWindow(windowClass: window.Window, x: number, y: number, parentId: string) {
    if (deviceInfo.sdkApiVersion >= 15) {
      let displayId : number | undefined;
      let mainWindow = this.getParentWindow(parentId);
      if (mainWindow) {
        const prop = mainWindow.getWindowProperties();
        displayId = prop.displayId;
      }
      try {
        let config: window.MoveConfiguration = {
          displayId: displayId
        };
        let promise = windowClass.moveWindowToAsync(x, y, config);
        promise.then(() => {
          LogUtil.info(TAG, `Succeeded in moving the window, display id: ${displayId}`);
        }).catch((err: BusinessError) => {
          LogUtil.error(TAG, `Failed to move the window. Cause code: ${err.code},
            message: ${err.message}, display id: ${displayId}`);
        });
      } catch (exception) {
        LogUtil.error(TAG, `Failed to move the window. Cause code: ${exception.code},
          message: ${exception.message}, display id: ${displayId}`);
      }
    } else {
      windowClass.moveWindowTo(x, y, (err) => {
        if (err.code) {
          LogUtil.error(TAG, 'Failed to move the subWindow. Cause:' + JSON.stringify(err));
        }
      });
    }
  }

  @LogMethod
  cancelSubWindow(id: string) {
    for (let i = 0; i < this.subWindowList.length; i++) {
      const item = this.subWindowList[i];
      if (item && item.id === id) {
        item.subWindow.minimize();
        this.addReuseWindow(item);
        this.subWindowList.splice(i, 1);
        break;
      }
    }
  }

  private addReuseWindow(item: ISubWindowInfo) {
    if (!item) {
      LogUtil.error(TAG, 'addReuseWindow fail');
    }
    let total = this.getTotalSubWindowNum();
    this.globalCache.push(item);
    let reuseWindowList = this.reusableSubWindow.get(item.parentId);
    if (reuseWindowList) {
      reuseWindowList.push(item);
    } else {
      this.reusableSubWindow.set(item.parentId, [item]);
    }
    if (total > MAX_TOTAL_SUB_WINDOW_NUM) {
      let oldest = this.globalCache.shift();
      if (oldest) {
        let target = this.reusableSubWindow.get(oldest.parentId);
        if (!target) {
          LogUtil.error(TAG, 'Global cache is inconsistent with cache of ' + oldest.parentId);
        } else {
          let found = false;
          for (let i = 0; i < target.length; i++) {
            if (oldest.id === target[i].id) {
              found = true;
              target.splice(i, 1);
              break;
            }
          }
          if (!found) {
            LogUtil.error(TAG, 'Global cache is inconsistent with cache of ' + oldest.parentId);
          }
        }
        oldest.subWindow.destroyWindow().catch((err: BusinessError) => {
          LogUtil.error(TAG, 'Failed to destroy the subWindow. Cause:' + JSON.stringify(err));
        });
      } else {
        LogUtil.error(TAG, 'Global cache should not be empty at this point');
      }
    }
  }

  private getTotalSubWindowNum(): number {
    return this.subWindowList.length + this.globalCache.length;
  }

  @LogMethod
  hideSubWindow(id: string) {
    const item = this.findSubWindow(id);
    item?.subWindow.minimize().catch((err: BusinessError) => {
      LogUtil.error(TAG, 'Failed to hide SubWindow. Cause: ' + JSON.stringify(err));
    });
  }

  @LogMethod
  showSubWindow(id: string) {
    const item = this.findSubWindow(id);
    item?.subWindow.showWindow().catch((err: BusinessError) => {
      LogUtil.error(TAG, 'Failed to show SubWindow. Cause: ' + JSON.stringify(err));
    });
  }

  @LogMethod
  setSubWindowBounds(id: string, r: WindowBound) {
    try {
      let windowClass = window.findWindow(id);
      windowClass?.resize(r.width, r.height, (err) => {
        if (err.code) {
          LogUtil.error(TAG, 'Failed to change the subWindow size. Cause:' + JSON.stringify(err));
          return;
        }
      });
      windowClass?.moveWindowTo(r.left, r.top, (err) => {
        if (err.code) {
          LogUtil.error(TAG, 'Failed to move the subwindow. Cause:' + JSON.stringify(err));
          return;
        }
      });
    } catch (exception) {
      LogUtil.error(TAG, 'Failed to find the Window. Cause: ' + JSON.stringify(exception));
    }
  }
}
