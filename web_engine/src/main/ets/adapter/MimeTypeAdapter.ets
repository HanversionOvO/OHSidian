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

import { injectable } from 'inversify';
import { BaseAdapter } from '../common/BaseAdapter';
import LogMethod from '../common/LogDecorator';
import { uniformTypeDescriptor } from '@kit.ArkData';
import LogUtil from '../utils/LogUtil';

@injectable()
export class MimeTypeAdapter extends BaseAdapter {
  @LogMethod
  GetExtensionByMimeType(mimeType: string): string[] {
    try {
      const typeId = uniformTypeDescriptor.getUniformDataTypeByMIMEType(mimeType);
      let typeObj: uniformTypeDescriptor.TypeDescriptor = uniformTypeDescriptor.getTypeDescriptor(typeId);
      if (typeObj) {
        let copy: string[] = []
        typeObj.filenameExtensions.forEach((ext) => {
          if (ext.startsWith(".")) {
            copy.push(ext.slice(1));
          } else {
            copy.push(ext);
          }
        })
        return copy;
      } else {
        return [];
      }
    } catch (err) {
      LogUtil.error('MimeTypeAdapter', `GetExtensionByMimeType failed: ${err}`);
    }
    return [];
  }

  @LogMethod
  GetMimeTypeByExtension(extension: string): string[] {
    try {
      const typeId = uniformTypeDescriptor.getUniformDataTypeByFilenameExtension("." + extension);
      let typeObj: uniformTypeDescriptor.TypeDescriptor = uniformTypeDescriptor.getTypeDescriptor(typeId);
      if (typeObj) {
        return typeObj.mimeTypes;
      } else {
        return [];
      }
    } catch (err) {
      LogUtil.error('MimeTypeAdapter', `GetMimeTypeByExtension failed: ${err}`);
    }
    return [];
  }
}
