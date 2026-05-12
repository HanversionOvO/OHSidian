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
import { OhosDragParamToJs, OhosDropData } from '../interface/CommonInterface';
import UDC from '@ohos.data.unifiedDataChannel';
import UTD from '@ohos.data.uniformTypeDescriptor';
import LogUtil from '../utils/LogUtil';
import unifiedDataChannel from '@ohos.data.unifiedDataChannel';
import { fileUri } from '@kit.CoreFileKit';
import fs from '@ohos.file.fs';
import { ConfigData } from './Constants';
import uniformTypeDescriptor from '@ohos.data.uniformTypeDescriptor';
import { deviceInfo } from '@kit.BasicServicesKit';
import { uniformDataStruct } from '@kit.ArkData';

interface IDragParams {
  id: string,
  uiContext: UIContext | undefined
};

interface CustomDragData {
  uniformDataType: string,
  bufferData: ArrayBuffer
}

AppStorage.setOrCreate('dragParamList', new Map<string,IDragParams>());

const BOOKMARK_DEFINED_TYPE: string = "ApplicationDefinedType-bookmark";
const WEB_CUSTOM_DEFINED_TYPE: string = "ApplicationDefinedType-webCustom";
const APPLICATION_DEFINE_TYPE: string = "ApplicationDefinedType";
const FILE_DRAG_DEFAULT_NAME = "/storage/User/currentUser/file.txt";
const IMAGE_DRAG_DEFAULT_NAME = "/storage/User/currentUser/file.png";
const VIDEO_DRAG_DEFAULT_NAME = "/storage/User/currentUser/file.mp4";
const AUDIO_DRAG_DEFAULT_NAME = "/storage/User/currentUser/file.mp3";
const FOLDER_DRAG_DEFAULT_NAME = "/storage/User/currentUser";
const HYPERLINK_DRAG_DEFAULT_URL = "https://www.exampleholder.com";
const HYPERLINK_DRAG_DEFAULT_TITLE = "ExampleHolder";
const PLAINTEXT_DRAG_DEFAULT_VALUE = "ExamplePlainText";
const UTD_FILE_URI = "general.file-uri";
const TAG: string = 'OhosDrag';

@injectable()
export class DragParamManager {
  constructor() {
    let appStorageLink: SubscribedAbstractProperty<Map<string,IDragParams>> = AppStorage.link('dragParamList');
    this.appStorage = appStorageLink.get();
  }
  private appStorage: Map<string,IDragParams>;
  private dragData: UDC.UnifiedData | undefined = undefined

  private paramNormalization(windowId: string | number): string {
    if (typeof windowId === 'number') {
      return ConfigData.WINDOW_PREFIX + windowId;
    }
    return windowId;
  }

  public addDragContextData(data: IDragParams) {
    if (data && data.id) {
      this.appStorage.set(data.id, data);
    }
  }

  public removeDragContextData(windowId: string | number) {
    let id = this.paramNormalization(windowId);
    this.appStorage.delete(id);
  }

  public setUiContext(windowId: string | number, uiContext: UIContext): void {
    let id = this.paramNormalization(windowId);
    let current = this.appStorage.get(id);
    if (current) {
      current.uiContext = uiContext;
      this.appStorage.set(id, current);
    }
  }

  public getUiContext(windowId: string | number): UIContext | undefined {
    let id = this.paramNormalization(windowId);
    let current = this.appStorage.get(id);
    if (current) {
      return current.uiContext;
    }
    return undefined;
  }

  /**
   * For the single-entry when data dragging
   * @param dragParams Initial drag-and-drop data
   * @returns Drag data required by the drag framework.
   */
  public handleDragRecords(dragParams: OhosDragParamToJs): UDC.UnifiedData | undefined {
    this.dragData = undefined;
    let dragContents: Array<UDC.UnifiedRecord> = [];
    let dragDataHtml: UDC.HTML|undefined = undefined;
    let dragDataText: UDC.PlainText|undefined = undefined;
    let dragDataHyperlink: UDC.Hyperlink|undefined = undefined;
    if (dragParams.text) {
      LogUtil.info(TAG, `handleDragRecords text-length:${dragParams.text.length}`);
      dragDataText = new UDC.PlainText();
      dragDataText.textContent = dragParams.text;
      dragContents.push(dragDataText);
      dragDataHtml = new UDC.HTML();
      dragDataHtml.plainContent = dragParams.text;
      dragContents.push(dragDataHtml);
    }
    if (dragParams.html) {
      LogUtil.info(TAG, `handleDragRecords html-length:${dragParams.html.length}`);
      if (!dragDataHtml) {
        dragDataHtml = new UDC.HTML();
        dragContents.push(dragDataHtml);
      }
      dragDataHtml.htmlContent = dragParams.html;
      if (dragParams.text) {
        dragDataHtml.plainContent = dragParams.text;
      }
    }
    if (dragParams.urlTitle) {
      LogUtil.info(TAG, `handleDragRecords urlTitle-length:${dragParams.urlTitle.length}`);
      dragDataHyperlink = new UDC.Hyperlink();
      dragDataHyperlink.description = dragParams.urlTitle;
      dragContents.push(dragDataHyperlink);
    }
    if (dragParams.url) {
      LogUtil.info(TAG, `handleDragRecords url-length:${dragParams.url.length}`);
      if (dragDataHyperlink !== undefined) {
        dragDataHyperlink.url = dragParams.url;
      } else {
        dragDataHyperlink = new UDC.Hyperlink();
        dragDataHyperlink.url = dragParams.url;
        dragContents.push(dragDataHyperlink);
      }
    }
    if (dragParams.webImageFilePath) {
      LogUtil.info(TAG, `handleDragRecords webImageFilePath-length:${dragParams.webImageFilePath.length}`);
      let image: UDC.Image | undefined = this.handleImageDragUri(dragParams.webImageFilePath);
      if (image) {
        dragContents.push(image);
      }
    }
    if (dragParams.electronFilePath) {
      LogUtil.info(TAG, `handleDragRecords electronFilePath-length:${dragParams.electronFilePath.length}`);
      let file: UDC.File | undefined = this.handleFileDragUri(dragParams.electronFilePath);
      if (file) {
        dragContents.push(file);
      }
    }
    if (dragParams.bookmarkBuffer.byteLength > 0) {
      LogUtil.info(TAG, `handleDragRecords bookmarkBuffer-length:${dragParams.bookmarkBuffer.byteLength}`);
      let record = new unifiedDataChannel.ApplicationDefinedRecord();
      record.applicationDefinedType = BOOKMARK_DEFINED_TYPE;
      record.rawData = new Uint8Array(dragParams.bookmarkBuffer);
      dragContents.push(record);
    }
    if (dragParams.webCustomBuffer.byteLength > 0) {
      LogUtil.info(TAG, `handleDragRecords webCustomBuffer-length:${dragParams.webCustomBuffer.byteLength}`);
      let record = new unifiedDataChannel.ApplicationDefinedRecord();
      record.applicationDefinedType = WEB_CUSTOM_DEFINED_TYPE;
      record.rawData = new Uint8Array(dragParams.webCustomBuffer);
      dragContents.push(record);
    }
    if (dragContents.length === 0) {
      LogUtil.error(TAG, `handleDragRecords fail, dragContents is empty`);
      return this.dragData;
    }
    this.dragData = new UDC.UnifiedData(dragContents[0]);
    for (let i = 1; i < dragContents.length; i++) {
      this.dragData.addRecord(dragContents[i]);
    }
    return this.dragData;
  }

  /**
   * For the multi-entry when data dragging
   * @param dragParams Initial drag-and-drop data
   * @returns Drag data required by the drag framework.
   */
  public handleDragDataForEntries(dragParams: OhosDragParamToJs): UDC.UnifiedData | undefined {
    this.dragData = undefined;
    let dragContents:(uniformDataStruct.PlainText |uniformDataStruct.HTML |uniformDataStruct.Hyperlink
                    |uniformDataStruct.FileUri |CustomDragData)[] = [];

    let plainText = this.handleTextDragDataForEntries(dragParams);
    if (plainText) {
      dragContents.push(plainText);
    }
    let htmlUds = this.handleHtmlDragDataForEntries(dragParams);
    if (htmlUds) {
      dragContents.push(htmlUds);
    }
    let hyperlinkUds = this.handleHyperlinkDragDataForEntries(dragParams);
    if (hyperlinkUds) {
      dragContents.push(hyperlinkUds);
    }
    let imageUds = this.handleWebImageForEntries(dragParams);
    if (imageUds) {
      LogUtil.info(TAG, `handleDragDataForEntries webImageFilePath-length:${dragParams.webImageFilePath.length}`);
      dragContents.push(imageUds);
    }
    let bookmarkStruct = this.handleBookmarkDragDataForEntries(dragParams);
    if (bookmarkStruct) {
      dragContents.push(bookmarkStruct);
    }
    let webCustomDataStruct = this.handleWebCustomDataForEntries(dragParams);
    if (webCustomDataStruct) {
      dragContents.push(webCustomDataStruct);
    }
    if (dragContents.length == 0) {
      LogUtil.error(TAG, `handleDragDataForEntries fail, dragContents is empty`);
      return;
    }
    let record = new unifiedDataChannel.UnifiedRecord(dragContents[0].uniformDataType, dragContents[0]);
    for (let i = 1; i < dragContents.length; i++) {
      record.addEntry(dragContents[i].uniformDataType, dragContents[i]);
    }
    this.dragData = new UDC.UnifiedData(record);
    return this.dragData;
  }

  public handleDropDataForEnter(summary: Summary) : OhosDropData {
    let dropData: OhosDropData = {
      text: "",
      url: "",
      urlTitle: "",
      html: "",
      fileUris: new Array,
      bookmarkBuffer: new ArrayBuffer(0),
      webCustomBuffer: new ArrayBuffer(0)
    };
    if (this.dragData && this.dragData.getRecords() && this.dragData.getRecords().length > 0) {
      if (deviceInfo.sdkApiVersion >= 15) {
        this.handleDropDataFromRecordsForEntries(this.dragData.getRecords(), dropData);
      } else {
        this.handleDropDataFromRecords(this.dragData.getRecords(), dropData);
      }
      return dropData;
    }
    let records: Array<string> = JSON.parse(JSON.stringify(summary.summary));
    if (!records || records.length === 0) {
      LogUtil.warn(TAG, `On handleDropDataForEnter summary records is null`);
      return dropData;
    }
    for(let i = 0; i < records.length; i++) {
      if (records[i].length > 0 && !records[i][0]) {
        LogUtil.error(TAG, `On handleDropDataForEnter dragData summary is empty`);
        continue;
      }
      let summaryType = records[i][0];
      LogUtil.info(TAG, `On handleDropDataForEnter dragData summary type:${summaryType}`);
      switch (summaryType) {
        case UTD.UniformDataType.PLAIN_TEXT:
          dropData.text = PLAINTEXT_DRAG_DEFAULT_VALUE;
          break;
        case UTD.UniformDataType.HYPERLINK:
          dropData.url = HYPERLINK_DRAG_DEFAULT_URL;
          dropData.urlTitle = HYPERLINK_DRAG_DEFAULT_TITLE;
          break;
        case UTD.UniformDataType.FILE:
          dropData.fileUris.push(FILE_DRAG_DEFAULT_NAME);
          break;
        case UTD.UniformDataType.IMAGE:
          dropData.fileUris.push(IMAGE_DRAG_DEFAULT_NAME);
          break;
        case UTD.UniformDataType.VIDEO:
          dropData.fileUris.push(VIDEO_DRAG_DEFAULT_NAME);
          break;
        case UTD.UniformDataType.AUDIO:
          dropData.fileUris.push(AUDIO_DRAG_DEFAULT_NAME);
          break;
        case UTD.UniformDataType.FOLDER:
        case UTD_FILE_URI:
          // on drag enter event,there is no actual data. use temporary data
          dropData.fileUris.push(FILE_DRAG_DEFAULT_NAME);
          break;
        default:
          LogUtil.info(TAG, `On handleDropDataForEnter dragData,
                       type: ${summaryType} do not need default data`);
          break;
      }
    }
    return dropData;
  }

  public handleDropDataForDrop(dragData: UnifiedData) : OhosDropData {
    let dropData: OhosDropData = {
      text: "",
      url: "",
      urlTitle: "",
      html: "",
      fileUris: new Array,
      bookmarkBuffer: new ArrayBuffer(0),
      webCustomBuffer: new ArrayBuffer(0)
    };
    if (!dragData) {
      LogUtil.warn(TAG, `On handleDropDataForDrop dragData is undefined`);
      return dropData;
    }
    let records: Array<UDC.UnifiedRecord> = dragData.getRecords();
    if (!records) {
      LogUtil.warn(TAG, `On handleDropDataForDrop dragData records is undefined`);
      return dropData;
    }
    if (deviceInfo.sdkApiVersion >= 15) {
      this.handleDropDataFromRecordsForEntries(records, dropData);
    } else {
      this.handleDropDataFromRecords(records, dropData);
    }
    return dropData;
  }

  /**
   * For the single-entry when data dragging
   * @param dragParams Initial drag-and-drop data
   * @returns Drag data required by the drag framework.
   */
  private handleDropDataFromRecords(records: Array<UDC.UnifiedRecord>, dropData: OhosDropData) {
    records.forEach((record) => {
      let recordType = record.getType();
      LogUtil.info(TAG, `handleDropDataFromRecords, recordType: ${recordType}`);
      switch (recordType) {
        case UTD.UniformDataType.PLAIN_TEXT:
          let plainText = record as unifiedDataChannel.PlainText;
          dropData.text = plainText.textContent;
          LogUtil.info(TAG, `handleDropDataFromRecords, text data length: ${dropData.text.length}`);
          break;
        case UTD.UniformDataType.HYPERLINK:
          let hyperlink = record as unifiedDataChannel.Hyperlink;
          dropData.url = hyperlink.url;
          dropData.urlTitle = hyperlink.description ? hyperlink.description : "";
          LogUtil.info(TAG, `handleDropDataFromRecords, url data length: ${dropData.url.length}`);
          LogUtil.info(TAG, `handleDropDataFromRecords, url title data length: ${dropData.urlTitle.length}`);
          break;
        case UTD.UniformDataType.HTML:
          let html = record as unifiedDataChannel.HTML;
          dropData.html = html.htmlContent;
          LogUtil.info(TAG, `handleDropDataFromRecords, html data length: ${dropData.html.length}`);
          break;
        case APPLICATION_DEFINE_TYPE:
          this.loadApplicationDefineData(dropData);
          break;
        case UTD.UniformDataType.FILE:
        case UTD.UniformDataType.IMAGE:
        case UTD.UniformDataType.VIDEO:
        case UTD.UniformDataType.AUDIO:
        case UTD.UniformDataType.FOLDER:
          // web page images do not require push filePath
          let webImage = this.getRecord(UTD.UniformDataType.IMAGE) as UDC.Image;
          if (!webImage) {
            let file = record as unifiedDataChannel.File;
            dropData.fileUris.push(file.uri);
          }
          LogUtil.info(TAG, `handleDropDataFromRecords, fileUris data length: ${dropData.fileUris.length}`);
          break;
        default:
          LogUtil.warn(TAG, `On handleDropDataFromRecords dragData, type: ${recordType} not support`);
          break;
      }
    })
    LogUtil.info(TAG, `handleDropDataFromRecords, fileUris size: ${dropData.fileUris.length}`);
  }

  /**
   * For the multi-entry when data drop
   * @param dragParams Initial drag-and-drop data
   * @returns Drag data required by the drag framework.
   */
  private handleDropDataFromRecordsForEntries(records: Array<UDC.UnifiedRecord>, dropData: OhosDropData) {
    records.forEach((record) => {
      let entryMap = record.getEntries();
      record.getTypes().forEach((recordType) => {
        LogUtil.info(TAG, `handleDropDataFromRecordsForEntries, recordType: ${recordType}`);
        switch (recordType) {
          case UTD.UniformDataType.PLAIN_TEXT:
            let plainText: uniformDataStruct.PlainText = entryMap[uniformTypeDescriptor.UniformDataType.PLAIN_TEXT] as uniformDataStruct.PlainText
            if (plainText) {
              dropData.text = plainText.textContent;
            }
            LogUtil.info(TAG, `handleDropDataFromRecordsForEntries, text data length: ${dropData.text.length}`);
            break;
          case UTD.UniformDataType.HYPERLINK:
            let hyperlink: uniformDataStruct.Hyperlink =
              entryMap[uniformTypeDescriptor.UniformDataType.HYPERLINK] as uniformDataStruct.Hyperlink;
            if (hyperlink) {
              dropData.url = hyperlink.url;
              dropData.urlTitle = hyperlink.description ? hyperlink.description : "";
            }
            LogUtil.info(TAG, `handleDropDataFromRecordsForEntries, url data length: ${dropData.url.length}`);
            LogUtil.info(TAG, `handleDropDataFromRecordsForEntries, url title data length: ${dropData.urlTitle.length}`);
            break;
          case UTD.UniformDataType.HTML:
            let html: uniformDataStruct.HTML =
              entryMap[uniformTypeDescriptor.UniformDataType.HTML] as uniformDataStruct.HTML;
            if (html) {
              dropData.html = html.htmlContent;
            }
            LogUtil.info(TAG, `handleDropDataFromRecordsForEntries, html data length: ${dropData.html.length}`);
            break;
          case BOOKMARK_DEFINED_TYPE:
            let bookmarkData: ArrayBuffer|undefined = this.loadApplicationDefineDataForEntries(BOOKMARK_DEFINED_TYPE);
            if (bookmarkData) {
              dropData.bookmarkBuffer = bookmarkData;
            }
            break;
          case WEB_CUSTOM_DEFINED_TYPE:
            let webCustomData = this.loadApplicationDefineDataForEntries(WEB_CUSTOM_DEFINED_TYPE);
            dropData.webCustomBuffer = webCustomData;
            break;
          case UTD_FILE_URI:
            // web page images do not require push filePath
            let webImage = this.getRecordForEntries(UTD_FILE_URI) as uniformDataStruct.FileUri;
            if (!webImage) {
              let fileUri = entryMap[UTD_FILE_URI] as uniformDataStruct.FileUri;
              if (fileUri) {
                LogUtil.info(TAG, `handleDropDataFromRecordsForEntries, FILE_URI data length: ${fileUri.oriUri.length}`);
                dropData.fileUris.push(fileUri.oriUri);
              }
            }
            break;
          case UTD.UniformDataType.FILE:
          case UTD.UniformDataType.IMAGE:
          case UTD.UniformDataType.VIDEO:
          case UTD.UniformDataType.AUDIO:
          case UTD.UniformDataType.FOLDER:
            let file = record as unifiedDataChannel.File;
            LogUtil.info(TAG, `handleDropDataFromRecordsForEntries, ${recordType} data length: ${file.uri.length}`);
            dropData.fileUris.push(file.uri);
            break;
          default:
            LogUtil.warn(TAG, `On handleDropDataFromRecordsForEntries dragData, type: ${recordType} not support`);
            break;
        }
      })
    })
    LogUtil.info(TAG, `handleDropDataFromRecordsForEntries, fileUris size: ${dropData.fileUris.length}`);
  }

  private handleTextDragDataForEntries(dragParams: OhosDragParamToJs) {
    let plainText : uniformDataStruct.PlainText|undefined = undefined;
    if (dragParams.text) {
      LogUtil.info(TAG, `handleDragDataForEntries text-length:${dragParams.text.length}`);
      plainText = {
        uniformDataType : uniformTypeDescriptor.UniformDataType.PLAIN_TEXT,
        textContent:dragParams.text
      }
    }
    return plainText;
  }

  private handleHtmlDragDataForEntries(dragParams: OhosDragParamToJs) {
    let html : uniformDataStruct.HTML|undefined = undefined;
    if (dragParams.html) {
      LogUtil.info(TAG, `handleDragDataForEntries html-length:${dragParams.html.length}`);
      html = {
        uniformDataType: uniformTypeDescriptor.UniformDataType.HTML,
        htmlContent: dragParams.html
      }
      if (dragParams.text) {
        html.plainContent = dragParams.text;
      }
    }
    return html;
  }

  private handleHyperlinkDragDataForEntries(dragParams: OhosDragParamToJs) {
    let hyperlink : uniformDataStruct.Hyperlink|undefined = undefined;
    if (dragParams.urlTitle) {
      LogUtil.info(TAG, `handleDragDataForEntries urlTitle-length:${dragParams.urlTitle.length}`);
      hyperlink = {
        uniformDataType: uniformTypeDescriptor.UniformDataType.HYPERLINK,
        url: "",
        description: dragParams.urlTitle
      }
    }
    if (dragParams.url) {
      LogUtil.info(TAG, `handleDragDataForEntries url-length:${dragParams.url.length}`);
      if (hyperlink !== undefined) {
        hyperlink.url = dragParams.url;
      } else {
        hyperlink = {
          uniformDataType: uniformTypeDescriptor.UniformDataType.HYPERLINK,
          url: dragParams.url,
          description: dragParams.urlTitle
        }
      }
    }
    return hyperlink;
  }

  private handleWebImageForEntries(dragParams: OhosDragParamToJs) {
    let dragImage : uniformDataStruct.FileUri|undefined = undefined;
    if (dragParams.webImageFilePath) {
      LogUtil.info(TAG, `handleDragDataForEntries webImageFilePath-length:${dragParams.webImageFilePath.length}`);
      let image: UDC.Image | undefined = this.handleImageDragUri(dragParams.webImageFilePath);
      if (image) {
        dragImage = {
          uniformDataType: UTD_FILE_URI,
          oriUri: image.imageUri,
          fileType: UTD.UniformDataType.IMAGE
        }
        LogUtil.info(TAG, `handleDragDataForEntries oriUri-length:${dragImage.oriUri.length}`);
      }
    }
    return dragImage;
  }

  private handleBookmarkDragDataForEntries(dragParams: OhosDragParamToJs) {
    let bookmarkStruct: CustomDragData|undefined = undefined;
    if (dragParams.bookmarkBuffer.byteLength > 0) {
      LogUtil.info(TAG, `handleDragDataForEntries bookmarkBuffer-length:${dragParams.bookmarkBuffer.byteLength}`);
      bookmarkStruct = {
        uniformDataType: BOOKMARK_DEFINED_TYPE,
        bufferData: dragParams.bookmarkBuffer,
      }
    }
    return bookmarkStruct;
  }

  private handleWebCustomDataForEntries(dragParams: OhosDragParamToJs) {
    let webCustomStruct: CustomDragData|undefined = undefined;
    if (dragParams.webCustomBuffer.byteLength > 0) {
      LogUtil.info(TAG, `handleDragDataForEntries webCustomBuffer-length:${dragParams.webCustomBuffer.byteLength}`);
      webCustomStruct = {
        uniformDataType: WEB_CUSTOM_DEFINED_TYPE,
        bufferData: dragParams.webCustomBuffer,
      }
    }
    return webCustomStruct;
  }

  private handleImageDragUri(webImageFilePath: string) : UDC.Image | undefined {
    if (!webImageFilePath) {
      LogUtil.error(TAG, `get drag image info fail, webImageFilePath is empty`);
      return;
    }
    try {
      let res: boolean = fs.accessSync(webImageFilePath);
      if (!res) {
        LogUtil.error(TAG, `get drag image info failed, image not exists`);
        return;
      }
      let uri: string = fileUri.getUriFromPath(webImageFilePath);
      let image: UDC.Image = new UDC.Image();
      image.imageUri = uri;
      return image;
    } catch(err) {
      LogUtil.error(TAG, `get drag image info failed with error message: ${err.message},
                    error code: ${err.code}`);
    }
    return;
  }

  private handleFileDragUri(FileUri: string): UDC.File | undefined {
    if (!FileUri) {
      LogUtil.error(TAG, `get drag file info fail, FileUri is empty`);
      return;
    }
    try {
      let res: boolean = fs.accessSync(FileUri);
      if (!res) {
        LogUtil.error(TAG, `get drag file info failed, file not exists`);
        return;
      }
      let uri: string = fileUri.getUriFromPath(FileUri);
      let file: UDC.File = new UDC.File();
      file.uri = uri;
      return file;
    } catch(err) {
      LogUtil.error(TAG, `get drag file info failed with error message: ${err.message},
                    error code: ${err.code}`);
    }
    return;
  }

  private loadApplicationDefineData(dropData: OhosDropData) {
    let applicationDefinedItem = this.getRecord(APPLICATION_DEFINE_TYPE) as UDC.ApplicationDefinedRecord;
    if (!applicationDefinedItem) {
      LogUtil.error(TAG, 'loadApplicationDefineData,APPLICATION_DEFINE_TYPE:item undefined');
      return;
    }
    if (applicationDefinedItem.rawData.byteLength > 0) {
      if (applicationDefinedItem.applicationDefinedType === BOOKMARK_DEFINED_TYPE) {
        dropData.bookmarkBuffer = applicationDefinedItem.rawData;
        LogUtil.info(TAG, `loadApplicationDefineData, bookmarkBuffer data length: ${dropData.bookmarkBuffer.byteLength}`);
      } else if (applicationDefinedItem.applicationDefinedType === WEB_CUSTOM_DEFINED_TYPE) {
        dropData.webCustomBuffer = applicationDefinedItem.rawData;
        LogUtil.info(TAG, `loadApplicationDefineData, webCustomBuffer data length: ${dropData.webCustomBuffer.byteLength}`);
      } else {
        LogUtil.warn(TAG, `On loadApplicationDefineData dragData,
            APPLICATION_DEFINE_TYPE: ${applicationDefinedItem.applicationDefinedType} not support`);
      }
    }
  }

  private loadApplicationDefineDataForEntries(applicationType: string): ArrayBuffer | undefined{
    let applicationDefinedItem = this.getRecordForEntries(applicationType) as CustomDragData;
    if (!applicationDefinedItem) {
      LogUtil.error(TAG, `loadApplicationDefineDataForEntries, type:${applicationType} do not find data`);
      return undefined;
    }
    if (applicationDefinedItem.bufferData.byteLength > 0) {
      LogUtil.info(TAG, `loadApplicationDefineDataForEntries, type: ${applicationType},
                        data length: ${applicationDefinedItem.bufferData.byteLength}`);
      return applicationDefinedItem.bufferData;
    }
    return undefined;
  }

  private getRecord(recordType: string) : UDC.UnifiedRecord | undefined {
    if (!this.dragData) {
      return;
    }
    let records = this.dragData.getRecords();
    for (let i = 0; i < records.length; i++) {
      if (records[i].getType() === recordType) {
        return records[i];
      }
    }
    return;
  }

  private getRecordForEntries(entryType: string) : uniformDataStruct.FileUri | CustomDragData | undefined {
    if (!this.dragData || this.dragData.getRecords().length == 0) {
      return;
    }
    // In the case of multiple entries, there is only one record
    let entryMap = this.dragData.getRecords()[0].getEntries();
    return entryMap[entryType] as CustomDragData | uniformDataStruct.FileUri | undefined;
  }

  public clearParam() : void {
    this.dragData = undefined;
  }
};
