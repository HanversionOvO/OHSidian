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

import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

import { WindowPreferences } from './CommonInterface';

export interface WebProxy {
  getWindowStage: () => window.WindowStage | undefined;
  getWindow: () => window.Window | undefined;
  getWindowContext: () => common.Context | undefined;
  getWindowId: () => string;
  setWindowTitle: (title:string) => void;
  createSubWindow: (name: string) => Promise<window.Window>;
  getOriginWindowId: () => number;
  // Electron
  getWindowPreferences: () => WindowPreferences;
  setWindowPreferences: (preferences: WindowPreferences) => void;
};

export class FakeWebProxy implements WebProxy {
  getWindowStage(): window.WindowStage | undefined {
    return undefined;
  }

  getWindow(): window.Window | undefined {
    return undefined;
  }

  getWindowContext(): common.Context | undefined {
    return undefined;
  }

  getWindowId(): string {
    return '';
  }

  getOriginWindowId(): number {
    return -1;
  }

  setWindowTitle(title:string) {}

  createSubWindow(name: string): Promise<window.Window> {
    return new Promise<window.Window>((resolve, reject) => {
      reject('fake window.')
    });
  }

  getWindowPreferences(): WindowPreferences {
    return {
      hideTitleBar: true,
      maximizable: true,
      minimizable: true,
      closable: true
    };
  }

  setWindowPreferences(preferences: WindowPreferences) {}
}