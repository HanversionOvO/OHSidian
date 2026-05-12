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
import { PanAction } from '../common/Constants';

@injectable()
export class MultiInputAdapter extends BaseAdapter {
  private isPanEventValid(event: GestureEvent | undefined): boolean {
    if (!event || event.sourceTool === SourceTool.Unknown) {
      return false;
    }
    // When sourceTool is mouse, only pass mouse wheel event trigger
    // by mouse middle button, ignore wheel event trigger by long
    // pressing and moving
    if (event.sourceTool === SourceTool.MOUSE) {
      if (event.fingerList.length > 0 && event.fingerList[0].id === 0) {
        return true;
      }
      return false;
    } else if (event.sourceTool === SourceTool.Finger) {
      // When sourceTool is Finger, Prevent wheel event trigger
      // The scroll wheel event of the touch screen is triggered by
      // the touch event
      return false;
    }
    return true;
  }

  OnPanEvent(action: number, id: string, event: GestureEvent | undefined) {
    let isValidEvent = false;
    switch (action) {
      case PanAction.kCancel:
        isValidEvent = true;
        break;
      default:
        isValidEvent = this.isPanEventValid(event);
    }

    if (isValidEvent) {
      this.nativeContext.OnPanEventCB(action, id, event);
    }
  }

  OnPinchEvent(pinch_step: string, id: string, event: GestureEvent) {
    this.nativeContext.OnPinchEventCB(pinch_step, id, event);
  }
}
