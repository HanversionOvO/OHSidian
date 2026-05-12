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
import Inject from '../common/InjectModule';
import lazy { IMFAdapter } from '../adapter/IMFAdapter';
import type {
  IMFAdapterCursorInfo,
  IMFAdapterInputAttribute,
  IMFAdapterTextConfig } from '../interface/CommonInterface';

function implIMFAdapter(): IMFAdapter {
  return Inject.getOrCreate(IMFAdapter);
}

function attachTextInput(textConfigIMF: IMFAdapterTextConfig, requestKeyboardReason: number,
  callback: (ret: boolean) => void) {
  implIMFAdapter().attachTextInput(textConfigIMF, requestKeyboardReason, callback);
}

function cursorUpdate(cursorInfoIMF: IMFAdapterCursorInfo) {
  implIMFAdapter().cursorUpdate(cursorInfoIMF);
}

function detachTextInput(callback: (ret: boolean) => void) {
  implIMFAdapter().detachTextInput(callback);
}

function updateAttribute(inputAttributeIMF: IMFAdapterInputAttribute) {
  implIMFAdapter().updateAttribute(inputAttributeIMF);
}

function offListenIME() {
  implIMFAdapter().offListenIME();
}
 
function showTextInput(requestKeyboardReason: number) {
  implIMFAdapter().showTextInput(requestKeyboardReason);
}

export class IMFAdapterBind {
  static bind() {
    JsBindingUtils.bindFunction("IMFAdapter.AttachTextInput", attachTextInput);
    JsBindingUtils.bindFunction("IMFAdapter.CursorUpdate", cursorUpdate);
    JsBindingUtils.bindFunction("IMFAdapter.DetachTextInput", detachTextInput);
    JsBindingUtils.bindFunction("IMFAdapter.UpdateAttribute", updateAttribute);
    JsBindingUtils.bindFunction("IMFAdapter.ShowTextInput", showTextInput);
    JsBindingUtils.bindFunction("IMFAdapter.OffListenIME", offListenIME);
  }
}
