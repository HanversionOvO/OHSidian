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

import { IParams } from '../interface/CommonInterface';
import { PanAction } from '../common/Constants';
import { DragDropAdapter } from '../adapter/DragDropAdapter';
import Inject from '../common/InjectModule';
import LogUtil from '../utils/LogUtil';
import { MultiInputAdapter } from '../adapter/MultiInputAdapter';
import { DragParamManager } from '../common/DragParamManager';

@Component
export struct WebSubWindow {
  private static TAG: string = 'WebSubWindow';
  @LocalStorageLink('subWindowParams') params: IParams = {
    id: '',
    size: [0, 0], // [width, height]
    callback: (ready: boolean, id: string) => {
    },
    initColorRgb: '#ffffff',
  };
  private xComponentId: string = this.params.id;
  private LIBRARY_NAME: string = 'adapter';
  private callback: (ready: boolean, id: string) => void = this.params.callback;
  private XCOMPONENT_NAME: string = 'subXcomponent';
  private MODULE_NAME: string = this.xComponentId + ':' + this.XCOMPONENT_NAME;
  private dragDropAdapter: DragDropAdapter = Inject.get(DragDropAdapter);
  private multiInputAdapter: MultiInputAdapter = Inject.get(MultiInputAdapter);
  private dragParamManager = Inject.get(DragParamManager);

  aboutToAppear(): void {
    this.dragParamManager.addDragContextData({
      id: this.xComponentId,
      uiContext: this.getUIContext(),
    });
  }

  aboutToDisappear(): void {
    this.dragParamManager.removeDragContextData(this.xComponentId);
  }

  build() {
    XComponent({
      id: this.MODULE_NAME,
      type: XComponentType.SURFACE,
      libraryname: this.LIBRARY_NAME
    })
      .backgroundColor(this.params.initColorRgb)
      .focusable(true)
      .defaultFocus(true)
      .gesture(
        PanGesture({ direction: PanDirection.Vertical | PanDirection.Horizontal })
          .onActionStart((event: GestureEvent) => {
            this.multiInputAdapter.OnPanEvent(PanAction.kStart, this.xComponentId, event);
          })
          .onActionUpdate((event: GestureEvent) => {
            this.multiInputAdapter.OnPanEvent(PanAction.kUpdate, this.xComponentId, event);
          })
          .onActionEnd((event: GestureEvent) => {
            this.multiInputAdapter.OnPanEvent(PanAction.kEnd, this.xComponentId, event);
          })
          .onActionCancel(() => {
            this.multiInputAdapter.OnPanEvent(PanAction.kCancel, this.xComponentId, undefined);
          })
      )
      .onDragEnter((event?: DragEvent) => {
        LogUtil.info(WebSubWindow.TAG, 'OhosDrag WebWindow onDragEnter xComponentId:' + this.xComponentId);
        this.dragDropAdapter.dragEnterData(this.xComponentId, (event as DragEvent).getSummary());
      })
      .onDragMove((event?: DragEvent) => {
        let windowX = event?.getWindowX();
        let windowY = event?.getWindowY();
        windowX = vp2px(windowX);
        windowY = vp2px(windowY);
        this.dragDropAdapter.dragMove(this.xComponentId, windowX, windowY);
      })
      .onDragLeave(() => {
        LogUtil.info(WebSubWindow.TAG, 'OhosDrag WebWindow onDragLeave xComponentId:' + this.xComponentId);
        this.dragDropAdapter.dragLeave(this.xComponentId);
      })
      .onDrop((event?: DragEvent) => {
        if (!event) {
          LogUtil.error(WebSubWindow.TAG, 'OhosDrag WebSubWindow DragDrop onDrop event is null');
          return;
        }
        LogUtil.info(WebSubWindow.TAG, 'OhosDrag WebWindow onDrop xComponentId:' + this.xComponentId);
        let dragData: UnifiedData = (event as DragEvent).getData() as UnifiedData;
        this.dragDropAdapter.dropData(this.xComponentId, dragData);
      })
      .onLoad(() => {
        LogUtil.info(WebSubWindow.TAG, 'onLoad xComponentId:' + this.xComponentId);
        this.callback(true, this.xComponentId);
      })
      .id(this.XCOMPONENT_NAME)
  }
}
