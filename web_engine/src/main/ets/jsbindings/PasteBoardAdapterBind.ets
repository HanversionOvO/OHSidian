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

import image from '@ohos.multimedia.image';
import JsBindingUtils from '../utils/JsBindingUtils';
import Inject from '../common/InjectModule';
import type { OhosPasteDataRecord } from '../interface/CommonInterface';
import lazy { PasteBoardAdapter } from '../adapter/PasteBoardApadter';

function implPasteBoardAdapter(): PasteBoardAdapter {
  return Inject.getOrCreate(PasteBoardAdapter);
}

function setPasteData(recordInfo: OhosPasteDataRecord, arrayBuff: ArrayBuffer) : void {
  implPasteBoardAdapter().setPasteData(recordInfo, arrayBuff);
}

function readPasteBoardText(callback: Function) : void {
  implPasteBoardAdapter().readPasteBoardText(callback);
}

function clear() : void {
  implPasteBoardAdapter().clear();
}

function isExistMimeType(callback: Function, type: string) : void {
  implPasteBoardAdapter().isExistMimeType(callback, type);
}

function readPasteBoardHTML(callback: Function) : void {
  implPasteBoardAdapter().readPasteBoardHTML(callback);
}

function readImageBuff(callback: Function){
  implPasteBoardAdapter().readImageBuff(callback);
}

function readImageInfo(callback: Function) {
  implPasteBoardAdapter().readImageInfo(callback);
}

function writeImage(buff: ArrayBuffer, height: number, width: number,
                    pixelFormat: image.PixelMapFormat, alphaType: image.AlphaType) : void {
  implPasteBoardAdapter().writeImage(buff, height, width, pixelFormat, alphaType);
}

function writeData(data: ArrayBuffer, format: string) : void {
  implPasteBoardAdapter().writeData(data, format);
}

function readPasteBoardData(callback: Function, format: string) : void {
  implPasteBoardAdapter().readPasteBoardData(callback, format);
}

function readPasteBoardURI(callback: (filePaths: Array<string>) => void) : void {
  implPasteBoardAdapter().readPasteBoardURI(callback);
}

export class PasteBoardAdapterBind {
  static bind() {
    JsBindingUtils.bindFunction('PasteBoardAdapter.ReadPasteBoardText', readPasteBoardText);
    JsBindingUtils.bindFunction('PasteBoardAdapter.Clear', clear);
    JsBindingUtils.bindFunction('PasteBoardAdapter.IsExistMimeType', isExistMimeType);
    JsBindingUtils.bindFunction('PasteBoardAdapter.ReadPasteBoardHTML', readPasteBoardHTML);
    JsBindingUtils.bindFunction('PasteBoardAdapter.ReadImageBuff', readImageBuff);
    JsBindingUtils.bindFunction('PasteBoardAdapter.WriteImage', writeImage);
    JsBindingUtils.bindFunction('PasteBoardAdapter.WriteData', writeData);
    JsBindingUtils.bindFunction('PasteBoardAdapter.ReadPasteBoardData', readPasteBoardData);
    JsBindingUtils.bindFunction('PasteBoardAdapter.SetPasteData', setPasteData);
    JsBindingUtils.bindFunction('PasteBoardAdapter.ReadPasteBoardURI',readPasteBoardURI);
    JsBindingUtils.bindFunction('PasteBoardAdapter.ReadImageInfo',readImageInfo);
  }
}
