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

import { BaseAdapter } from '../common/BaseAdapter';
import LogMethod from '../common/LogDecorator';
import { injectable } from 'inversify';
import LogUtil from '../utils/LogUtil';
import { browser } from '@kit.MDMKit';
import { util } from '@kit.ArkTS';

const TAG: string = 'BrowserPolicy';

@injectable()
export class BrowserPolicyAdapter extends BaseAdapter {
  @LogMethod
  getManagedBrowserPolicy(): string {
    try {
      let buffer: ArrayBuffer = browser.getSelfManagedBrowserPolicy();
      let intBuffer: Uint8Array = new Uint8Array(buffer);
      let decoder: util.TextDecoder = util.TextDecoder.create("utf-8");
      let stringData: string = decoder.decodeWithStream(intBuffer);
      return stringData;
    }
    catch(err) {
      LogUtil.error(TAG, `Failed to get managed browser policy. Code is, ${err.code}, ${err.message}`);
      return '';
    }
}
}
