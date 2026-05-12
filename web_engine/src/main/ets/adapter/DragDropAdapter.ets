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

import { inject, injectable } from 'inversify';
import dragController from "@ohos.arkui.dragController"
import { deviceInfo } from '@kit.BasicServicesKit';
import image from '@ohos.multimedia.image';
import UDC from '@ohos.data.unifiedDataChannel';
import { AbilityManager } from '../common/AbilityManager';
import { BaseAdapter } from '../common/BaseAdapter';
import LogUtil from '../utils/LogUtil';
import LogMethod from '../common/LogDecorator';
import { OhosDragParamToJs } from '../interface/CommonInterface';
import lazy { DragParamManager } from '../common/DragParamManager';
import { SystemFloatingWindowManager } from '../common/SystemFloatingWindowManager';

const TAG: string = 'OhosDrag';

@injectable()
export class DragDropAdapter extends BaseAdapter {
  private pixmap: image.PixelMap | undefined = undefined

  private abilityManager: AbilityManager;
  private systemFloatingWindowManager: SystemFloatingWindowManager;
  private dragSourceWindowId: string = "";
  private dragParamManager: DragParamManager;

  constructor(
    @inject(DragParamManager) manager: DragParamManager,
    @inject(AbilityManager) abilityManager: AbilityManager,
    @inject(SystemFloatingWindowManager) systemFloatingWindowManager: SystemFloatingWindowManager,
  ) {
    super();
    this.dragParamManager = manager;
    this.abilityManager = abilityManager;
    this.systemFloatingWindowManager = systemFloatingWindowManager;
  }

  @LogMethod
  async startDrag(dragParams: OhosDragParamToJs) {
    this.dragSourceWindowId = dragParams.windowId;
    if (dragParams.pixelMapTouchX > dragParams.pixelMapWidth
        || dragParams.pixelMapTouchY > dragParams.pixelMapHeight) {
      LogUtil.error(TAG, `startDrag fail: touch point param is invalid, 
                    touchX:${dragParams.pixelMapTouchX},
                    touchY:${dragParams.pixelMapTouchY}, 
                    width:${dragParams.pixelMapWidth},
                    height:${dragParams.pixelMapHeight}`);
      return;
    }
    let touchX: Dimension = 
        ((dragParams.pixelMapTouchX / dragParams.pixelMapWidth) * 100 + '%') as Dimension;
    let touchY: Dimension = 
        ((dragParams.pixelMapTouchY / dragParams.pixelMapHeight) * 100 + '%') as Dimension;
    let unifiedData: UDC.UnifiedData | undefined;
    if (deviceInfo.sdkApiVersion >= 15) {
      unifiedData = this.dragParamManager.handleDragDataForEntries(dragParams);
    } else {
      unifiedData = this.dragParamManager.handleDragRecords(dragParams);
    }
    let dragInfo: dragController.DragInfo = {
      pointerId: 0,
      data: unifiedData,
      extraParams: '',
      previewOptions: {numberBadge: false, mode: DragPreviewMode.DISABLE_SCALE},
      touchPoint: {
        x: touchX,
        y: touchY
      }
    }

    let opts: image.InitializationOptions = {
      editable: false,
      pixelFormat: image.PixelMapFormat.BGRA_8888,
      size: {
        height: dragParams.pixelMapHeight,
        width: dragParams.pixelMapWidth
      }
    }
    try {
      this.pixmap = await image.createPixelMap(dragParams.pixelMapBuffer, opts);
    } catch (error) {
      LogUtil.error(TAG, `pixelmap create fail :${JSON.stringify(error)}`);
      return;
    }
    let dragItemInfo: DragItemInfo = {
      pixelMap: this.pixmap,
      builder: ()=>{},
      extraInfo: "ohosDrag"
    }
    this.executeDragAction(dragItemInfo, dragInfo);
  }

  private executeDragAction(dragItemInfo: DragItemInfo, dragInfo: dragController.DragInfo) {
    let uiContext = this.dragParamManager.getUiContext(this.dragSourceWindowId);
    if (!uiContext) {
      this.clearDragParam();
      LogUtil.error(TAG, `executeDrag fail : uiContext not exist`);
      return;
    }
    try {
      let customBuilders = new Array<CustomBuilder | DragItemInfo>();
      customBuilders.push(dragItemInfo);
      let dragAction = uiContext.getDragController().createDragAction(customBuilders, dragInfo);
      if (!dragAction) {
        this.clearDragParam();
        LogUtil.error(TAG, `dragAction create fail`);
        return;
      }
      dragAction.on('statusChange', this.dragActionStatusListener(dragAction));
      dragAction.startDrag().catch((err: Error) => {
        this.clearDragParam();
        LogUtil.error(TAG, `dragAction startDrag fail :${JSON.stringify(err)}`);
      })
    } catch(err) {
      this.clearDragParam();
      LogUtil.error(TAG, `dragAction fail :${JSON.stringify(err)}`);
    }
  }

  dragEnterData(xComponentId: string, summary: Summary) {
    let dropData = this.dragParamManager.handleDropDataForEnter(summary);
    this.nativeContext.OnDragEnterCB(xComponentId, dropData, dropData.fileUris);
  }

  dragMove(id: string, windowX: number, windowY: number): void {
    let windowClass = this.abilityManager.getProxy(id)?.getWindow();
    if (!windowClass) {
      windowClass = this.systemFloatingWindowManager.getWindow(id);
    }
    try {
      const mainWindowProp = windowClass?.getWindowProperties();
      let xComBorder: number = mainWindowProp?.drawableRect.left || 0;
      let xComTop: number = mainWindowProp?.drawableRect.top || 0;
      windowX -= xComBorder;
      windowY -= xComTop;
      this.nativeContext.OnDragMoveCB(id, windowX, windowY);
    } catch (err) {
      LogUtil.error(TAG, 'Failed to obtain window properties:' + JSON.stringify(err));
    }
  }

  dragLeave(xComponentId: string) {
    this.nativeContext.OnDragLeaveCB(xComponentId);
  }

  dropData(xComponentId: string, dragData: UnifiedData) {
    let dropData = this.dragParamManager.handleDropDataForDrop(dragData);
    this.nativeContext.OnDropCB(xComponentId, dropData, dropData.fileUris);
  }

  private dragActionStatusListener(dragAction: dragController.DragAction) {
    return (dragAndDropInfo: dragController.DragAndDropInfo) => {
      if (dragAndDropInfo.status === dragController.DragStatus.ENDED) {
        if (dragAction) {
          dragAction.off('statusChange');
        }
        this.nativeContext.OnDragEndCB(this.dragSourceWindowId);
        this.clearDragParam();
      }
    };
  }

  private clearDragParam() {
    if (this.pixmap) {
      this.pixmap.release().catch((err: Error) => {
        LogUtil.error(TAG, `pixmap release failed:${JSON.stringify(err)}`);
      })
    }
    this.dragSourceWindowId = "";
    this.dragParamManager.clearParam();
  }
}
