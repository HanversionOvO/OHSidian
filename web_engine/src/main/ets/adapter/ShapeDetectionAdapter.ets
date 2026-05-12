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
import LogUtil from '../utils/LogUtil';
import { BusinessError } from '@ohos.base';
import image from '@ohos.multimedia.image';
import { faceDetector, textRecognition } from '@kit.CoreVisionKit';
import LogMethod from '../common/LogDecorator';

const tag: string = 'ShapeDetection';

interface PixelPoint {
  x: number;
  y: number;
}

interface TextLine {
  topLeft: PixelPoint;
  topRight: PixelPoint;
  bottomRight: PixelPoint;
  bottomLeft: PixelPoint;
  value: string;
}

interface Face {
  leftEye: PixelPoint;
  rightEye: PixelPoint;
  nose: PixelPoint;
  mouth: PixelPoint;
  x: number;
  y: number;
  width: number;
  height: number;
}

@injectable()
export class ShapeDetectionAdapter extends BaseAdapter {
  @LogMethod
  TextDetect(buffer: ArrayBuffer, width: number, height: number, callback: Function): void {
    let textlines: Array<TextLine> = [];
    let opts: image.InitializationOptions = { editable: true, pixelFormat: image.PixelMapFormat.RGBA_8888, size: { height: height, width: width } };
    image.createPixelMap(buffer, opts, (error: BusinessError, pixelMap: image.PixelMap) => {
      if (error) {
        LogUtil.error(tag, `createPixelMap failed, caused by:${JSON.stringify(error)}`);
        callback([], 0);
        return;
      }
      const visionInfo: textRecognition.VisionInfo = {
        pixelMap: pixelMap
      };
      textRecognition.recognizeText(visionInfo,
        (error: BusinessError, data: textRecognition.TextRecognitionResult) => {
          for (let i = 0; i < data.blocks.length; i++) {
            for (let j = 0; j < data.blocks[i].lines.length; j++) {
              const cornerpoints = data.blocks[i].lines[j].cornerPoints;
              const line: TextLine = {
                topLeft: { x: cornerpoints[0].x, y: cornerpoints[0].y },
                topRight: { x: cornerpoints[1].x, y: cornerpoints[1].y },
                bottomRight: { x: cornerpoints[2].x, y: cornerpoints[2].y },
                bottomLeft: { x: cornerpoints[3].x, y: cornerpoints[3].y },
                value: data.blocks[i].lines[j].value
              }
              textlines.push(line);
            }
          }
          callback(textlines, textlines.length);
        });
    })
  }

  @LogMethod
  FaceDetect(buffer: ArrayBuffer, width: number, height: number, callback: Function): void {
    let opts: image.InitializationOptions =
      { editable: true, pixelFormat: image.PixelMapFormat.RGBA_8888, size: { height: height, width: width } };
    image.createPixelMap(buffer, opts, async (error: BusinessError, pixelMap: image.PixelMap) => {
      if (error) {
        LogUtil.error(tag, `createPixelMap failed, caused by:${JSON.stringify(error)}`);
        callback([], 0);
        return;
      }
      let visionInfo: faceDetector.VisionInfo = {
        pixelMap: pixelMap
      };
      let data: faceDetector.Face[] = await faceDetector.detect(visionInfo);
      if (data.length === 0) {
        LogUtil.error(tag, "No face is detected in the image.");
        callback([], 0);
        return;
      }
      const faces = data.map(face => {
        const vertexs = face.points;
        const faceVertex: Face = {
          leftEye: { x: vertexs[0].x, y: vertexs[0].y },
          rightEye: { x: vertexs[1].x, y: vertexs[1].y },
          nose: { x: vertexs[2].x, y: vertexs[2].y },
          //The mouth is calculated as the left lip plus the right lip divided by two
          mouth: { x: (vertexs[3].x + vertexs[4].x) / 2, y: (vertexs[3].y + vertexs[4].y) / 2 },
          x: face.rect.left,
          y: face.rect.top,
          width: face.rect.width,
          height: face.rect.height
        };
        return faceVertex;
      });
      callback(faces, faces.length);
    })
  }
}
