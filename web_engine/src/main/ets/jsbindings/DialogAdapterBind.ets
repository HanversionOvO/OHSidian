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
import lazy { DialogAdapter } from '../adapter/DialogAdapter';

function implDialogAdapter(): DialogAdapter {
  return Inject.getOrCreate(DialogAdapter);
}

function showMessageBox(settings: string, buffer: ArrayBuffer, width: number, height: number,  callback: (button_id: number, checkbox_checked: boolean) => void): void {
  return implDialogAdapter().showMessageBox(settings, buffer, width, height, callback);
}

function showErrorBox(title: string, content: string, callback: (result: boolean) => void): void {
  return implDialogAdapter().showErrorBox(title, content, callback);
}

function showOpenDialog(settings: string, callback: (filePaths: string[], canceled: boolean) => void): void {
  return implDialogAdapter().showOpenDialog(settings, callback);
}

function showSaveDialog(settings: string, callback: (filePath: string, canceled: boolean) => void): void {
  return implDialogAdapter().showSaveDialog(settings, callback);
}

export class DialogAdapterBind {
  static bind() {
    JsBindingUtils.bindFunction("DialogAdapter.ShowMessageBox", showMessageBox);
    JsBindingUtils.bindFunction("DialogAdapter.ShowErrorBox", showErrorBox);
    JsBindingUtils.bindFunction("DialogAdapter.ShowOpenDialog", showOpenDialog);
    JsBindingUtils.bindFunction("DialogAdapter.ShowSaveDialog", showSaveDialog);
  }
}
