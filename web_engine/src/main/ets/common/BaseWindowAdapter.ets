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

import { inject } from 'inversify';
import { common } from '@kit.AbilityKit';
import window from '@ohos.window';

import { BaseAdapter } from './BaseAdapter';
import { ContextAdapter } from '../adapter/ContextAdapter';
import { WindowPreferences } from '../interface/CommonInterface';
import { WebProxy } from '../interface/WebProxy';

export class BaseWindowAdapter extends BaseAdapter implements WebProxy {
  protected ctxAdapter: ContextAdapter;
  protected windowClass: window.Window | undefined = undefined;
  protected xcomponentId: string = '';
  protected originWindowId: number = -1;

  constructor(
    @inject(ContextAdapter) ctxAdapter: ContextAdapter
  ) {
    super();
    this.ctxAdapter = ctxAdapter;
  }

  initialize(xcomponentId: string, windowClass: window.Window) {
    this.xcomponentId = xcomponentId;
    this.windowClass = windowClass;
    this.originWindowId = windowClass.getWindowProperties().id;
  }

  // implements WebProxy interface
  getWindowStage(): window.WindowStage | undefined {
    return undefined;
  }

  getWindow(): window.Window | undefined {
    return this.windowClass;
  }

  getWindowContext(): common.Context | undefined {
    return this.ctxAdapter.getActiveContext();
  }

  getWindowId(): string {
    return this.xcomponentId;
  }

  getOriginWindowId(): number {
    return this.originWindowId;
  }

  setWindowTitle(title:string) {}

  createSubWindow(name: string): Promise<window.Window> {
    return new Promise<window.Window>((resolve, reject) => {
      reject('no reached.')
    });
  }

  getWindowPreferences(): WindowPreferences {
    return {
      hideTitleBar: true,
      maximizable: true,
      minimizable: true,
      closable: true,
    };
  }

  setWindowPreferences(preferences: WindowPreferences) {}
}
