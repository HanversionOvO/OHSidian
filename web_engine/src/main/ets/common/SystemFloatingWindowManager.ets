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

import window from '@ohos.window';
import { injectable } from 'inversify';

interface ISystemFloatingWindowParams {
  id: string,
  window: window.Window
}

@injectable()
export class SystemFloatingWindowManager {
  private storage: Map<string, (ISystemFloatingWindowParams)[]> =
    new Map<string, (ISystemFloatingWindowParams)[]>();

  private paramNormalization(abilityId: string | number): string {
    if (typeof abilityId === 'number') {
      return 'browser' + abilityId;
    }
    return abilityId;
  }

  public addSystemFloatingWindow(abilityId: string | number,
    data: ISystemFloatingWindowParams) {
    let id = this.paramNormalization(abilityId);
    let windows = this.storage.get(id);
    if (windows) {
      windows.push(data);
    } else {
      this.storage.set(id, [data]);
    }
  }

  public removeSystemFloatingWindow(abilityId: string | number,
    systemFloatingWindowId: string | number) {
    let id = this.paramNormalization(abilityId);
    let windows = this.storage.get(id);
    if (windows) {
      for (let i = 0; i < windows.length; i++) {
        if (windows[i].id === this.paramNormalization(systemFloatingWindowId)) {
          windows.splice(i, 1);
        }
      }
    }
  }

  public getMainWindowId(windowId: string | number): string | undefined {
    let id = this.paramNormalization(windowId);
    for (let key of this.storage.keys()) {
      let value = this.storage.get(key);
      if (value) {
        for (let i = 0; i < value.length; i++) {
          if (id === value[i].id) {
            return key;
          }
        }
      }
    }
    return undefined;
  }

  public getWindow(windowId: string | number): window.Window | undefined {
    let id = this.paramNormalization(windowId);
    for (let key of this.storage.keys()) {
      let value = this.storage.get(key);
      if (value) {
        for (let i = 0; i < value.length; i++) {
          if (id === value[i].id) {
            return value[i].window;
          }
        }
      }
    }
    return undefined;
  }
};
