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
import lazy { PopupWindowAdapter } from '../adapter/PopupWindowAdapter';
import type { NewWindowParam, WindowBound } from '../interface/CommonInterface';

function implPopupWindowAdapter(): PopupWindowAdapter {
  return Inject.getOrCreate(PopupWindowAdapter);
}

function createWindow(param: NewWindowParam) {
  implPopupWindowAdapter().createWindow(param);
}

function closeWindow(id: number) {
  implPopupWindowAdapter().closeWindow(id);
}

function showWindow(id: number) {
  implPopupWindowAdapter().showWindow(id);
}

function hideWindow(id: number) {
  implPopupWindowAdapter().hideWindow(id);
}

function activateWindow(id: number) {
  implPopupWindowAdapter().activateWindow(id);
}

function setBounds(id: number,
                   bounds: WindowBound) {
  implPopupWindowAdapter().setBounds(id, bounds);
}

function setWindowLimits(minWidth: number, minHeight: number, maxWidth: number, maxHeight: number, id: number) {
  implPopupWindowAdapter().setWindowLimits(minWidth, minHeight, maxWidth, maxHeight, id);
}

export class PopupWindowAdapterBind {
  static bind() {
    JsBindingUtils.bindFunction("PopupWindow.CreateWindow", createWindow);
    JsBindingUtils.bindFunction("PopupWindow.CloseWindow", closeWindow);
    JsBindingUtils.bindFunction("PopupWindow.ShowWindow", showWindow);
    JsBindingUtils.bindFunction("PopupWindow.HideWindow", hideWindow);
    JsBindingUtils.bindFunction("PopupWindow.ActivateWindow", activateWindow);
    JsBindingUtils.bindFunction("PopupWindow.SetBounds", setBounds);
    JsBindingUtils.bindFunction("PopupWindow.SetWindowLimits", setWindowLimits);
  }
}
