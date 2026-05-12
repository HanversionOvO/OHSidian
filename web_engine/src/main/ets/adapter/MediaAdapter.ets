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

import { injectable, inject } from 'inversify';
import { BusinessError } from '@ohos.base';
import image from '@ohos.multimedia.image';
import { Size } from '@kit.ArkUI';
import { AbilityManager } from '../common/AbilityManager';
import { BaseAdapter } from '../common/BaseAdapter';
import LogUtil from '../utils/LogUtil';
import LogMethod from '../common/LogDecorator';
import { camera } from '@kit.CameraKit';

const TAG: string = 'media';

@injectable()
export class MediaAdapter extends BaseAdapter {
  private previewReceiver: image.ImageReceiver;
  private defaultSize: Size = {
    width: 320,
    height: 240
  };
  private abilityManager: AbilityManager;

  constructor(
    @inject(AbilityManager) abilityManager: AbilityManager) {
    super();
    this.previewReceiver =
      image.createImageReceiver(this.defaultSize, image.ImageFormat.JPEG, 8);
    this.abilityManager = abilityManager;
  }

  @LogMethod
  getPreviewSurfaceId(callback?: Function) {
    this.previewReceiver.getReceivingSurfaceId().then((id:string) => {
      callback && callback(id);
    }).catch((err: BusinessError) => {
      LogUtil.error(TAG, `Failed to get Preview Surface:` + JSON.stringify(err));
    });
  }

  @LogMethod
  getImageReceiver() {
    this.previewReceiver.on('imageArrival', () => {
      let img: image.Image = this.nativeContext.readImageFromReceiver(this.previewReceiver);
      if (img) {
        img.release();
      } else {
        LogUtil.error(TAG, 'image undefined');
      }
    })
  }
  
  getCameraOrientation(): number {
    let context = getContext(this);
    let cameraManager = camera.getCameraManager(context);
    let cameraDevices = cameraManager.getSupportedCameras();
    if (cameraDevices.length) {
      return cameraDevices[0].cameraOrientation;
    }
    LogUtil.error(TAG, 'cameraDevices is null, get cameraDevices failed');
    return 0;
  }

  @LogMethod
  beep() {
    LogUtil.info(TAG, 'Beep is called');
  }
}
