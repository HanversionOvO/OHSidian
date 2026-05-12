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
import { OcrAdapterImage, TextWord } from '../interface/CommonInterface';
import LogUtil from '../utils/LogUtil';
import LogMethod from '../common/LogDecorator';
import image from '@ohos.multimedia.image';
import { textRecognition } from '@kit.CoreVisionKit';
import { BusinessError } from '@ohos.base';

const TAG: string = 'Ocr';
const OCR_IMAGE_PIXEL_FORMAT: number = 3
const OCR_IMAGE_EDITABLE: boolean = false

@injectable()
export class OcrAdapter extends BaseAdapter {

  @LogMethod
  async ocrFunction(callback: Function, requestImage: OcrAdapterImage) {
    let wordsArray :Array<TextWord> = new Array();
    let imagePixel: image.PixelMap = await this.convertImagePixelMap(requestImage) as image.PixelMap;
    if (!imagePixel) {
      callback(wordsArray);
      LogUtil.error(TAG, `covert image piexel failed`);
      return;
    }
    let visionInfo: textRecognition.VisionInfo = {
      pixelMap: imagePixel as image.PixelMap
    };
    textRecognition.recognizeText(visionInfo, (error: BusinessError, data: textRecognition.TextRecognitionResult) => {
      if (error.code !== 0) {
        LogUtil.error(TAG, `textRecognition.recognizeText :${JSON.stringify(error.message)}`);
        callback(wordsArray);
        return;
      }
      for (const block of data.blocks) {
        for (const line of block.lines) {
          for (let word of line.words) {
            let word1: TextWord = word;
            wordsArray.push(word1);
          }
        }
      }
      callback(wordsArray, wordsArray.length);
      if(imagePixel) {
        imagePixel.release();
      }
    });
  }

  private async convertImagePixelMap(requestImage: OcrAdapterImage): Promise<image.PixelMap | undefined>  {
    let pixmap: image.PixelMap;
    if (requestImage.width === 0 || requestImage.height === 0) {
      LogUtil.warn(TAG, 'image is empty, no conversion required');
      return undefined;
    }
    let opts: image.InitializationOptions = {
      editable: OCR_IMAGE_EDITABLE,
      pixelFormat: OCR_IMAGE_PIXEL_FORMAT,
      size: {
        height: requestImage.height,
        width: requestImage.width
      }
    }
    try {
      pixmap = await image.createPixelMap(requestImage.buff, opts);
      return pixmap;
    } catch (error) {
      LogUtil.error(TAG, 'failed convert image pixel map because: ' +  JSON.stringify(error));
      return undefined;
    }
  }

}
