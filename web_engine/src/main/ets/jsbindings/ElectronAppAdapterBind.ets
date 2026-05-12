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

import JsBindingUtils from '../utils/JsBindingUtils';
import Inject from "../common/InjectModule";
import lazy { ElectronAppAdapter } from '../adapter/ElectronAppAdapter';
import display from '@ohos.display';

function implElectronAppAdapter(): ElectronAppAdapter {
  return Inject.getOrCreate(ElectronAppAdapter);
}

function getPreferredLanguageList(): Array<string> {
  return implElectronAppAdapter().getPreferredLanguageList();
}

function getSystemRegion(): string {
  return implElectronAppAdapter().getSystemRegion();
}

function getSystemLocale(): string {
  return implElectronAppAdapter().getSystemLocale();
}

function getFileIcon(callback: Function): void {
  return implElectronAppAdapter().getFileIcon(callback);
}

function relaunch(args: Array<string>, execPath: string): void {
  return implElectronAppAdapter().relaunch(args, execPath);
}

function openApplicationInfoEntry(): void {
  return implElectronAppAdapter().openApplicationInfoEntry();
}

function getFontSizeScale(): number {
  return implElectronAppAdapter().getFontSizeScale();
}

function setBadgeCount(count: number): void {
  return implElectronAppAdapter().setBadgeCount(count);
}

function getAvailableArea(displayId: number, callback: (availArea: display.Rect) => void) {
  implElectronAppAdapter().getAvailableArea(displayId, callback);
}

export class ElectronAppAdapterBind {
  static bind() {
    JsBindingUtils.bindFunction("ElectronApp.GetPreferredLanguageList", getPreferredLanguageList);
    JsBindingUtils.bindFunction("ElectronApp.GetSystemRegion", getSystemRegion);
    JsBindingUtils.bindFunction("ElectronApp.GetSystemLocale", getSystemLocale);
    JsBindingUtils.bindFunction("ElectronApp.GetFileIcon", getFileIcon);
    JsBindingUtils.bindFunction("ElectronApp.Relaunch", relaunch);
    JsBindingUtils.bindFunction("ElectronApp.OpenApplicationInfoEntry", openApplicationInfoEntry);
    JsBindingUtils.bindFunction("ElectronApp.GetFontSizeScale", getFontSizeScale);
    JsBindingUtils.bindFunction("ElectronApp.SetBadgeCount", setBadgeCount);
    JsBindingUtils.bindFunction("ElectronApp.GetAvailableArea", getAvailableArea);
  }
}
