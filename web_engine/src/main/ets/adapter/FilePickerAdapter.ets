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

import fileUri from '@ohos.file.fileuri';
import fs from '@ohos.file.fs';
import LogUtil from '../utils/LogUtil';
import LogMethod from '../common/LogDecorator';
import picker from '@ohos.file.picker';

import { BaseAdapter } from '../common/BaseAdapter';
import { inject, injectable } from 'inversify';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { ContextAdapter } from './ContextAdapter';
import { PermissionManagerAdapter } from './PermissionManagerAdapter';
import { SaveAsDialogParams, SelectFileDialogParams } from '../interface/CommonInterface';

const TAG: string = "FilePicker";

@injectable()
export class FilePickerAdapter extends BaseAdapter {
  private static PREFIX: string = "file://docs";
  private static MAX_SELECT_NUMBER: number = 500;
  private ctxAdapter: ContextAdapter;
  private permissionManagerAdapter: PermissionManagerAdapter;
  private defaultDescriptionId: number = $r("app.string.upload_default_type_description").id;
  private allFIleDescriptionId: number = $r("app.string.upload_all_file_description").id;

  constructor(@inject(ContextAdapter) ctxAdapter: ContextAdapter,
    @inject(PermissionManagerAdapter) permissionManagerAdapter: PermissionManagerAdapter) {
    super();
    this.ctxAdapter = ctxAdapter;
    this.permissionManagerAdapter = permissionManagerAdapter;
  }

  @LogMethod
  showDocumentViewPicker(params: SelectFileDialogParams, callback: (path: string) => void) {
    let DocumentSelectOptions = new picker.DocumentSelectOptions();
    if (params.multi_files) {
      DocumentSelectOptions.maxSelectNumber = FilePickerAdapter.MAX_SELECT_NUMBER;
    }
    const context = this.ctxAdapter.getContext();
    let allFileDescription = context.resourceManager.getStringSync(this.allFIleDescriptionId);
    if (params.extensions.length > 0) {
      DocumentSelectOptions.fileSuffixFilters = this.getFilterArray(params.extensions, params.descriptions);
      if (params.include_all_files) {
        DocumentSelectOptions.fileSuffixFilters.push(allFileDescription + "|.*");
      }
    } else {
      DocumentSelectOptions.fileSuffixFilters = [allFileDescription + "|.*"];
    }
    let documentPicker = new picker.DocumentViewPicker();
    documentPicker.select(DocumentSelectOptions).then((selectResult) => {
      selectResult = this.dirFilter(selectResult);
      callback(JSON.stringify(selectResult));
    }).catch((err: Error) => {
      callback('');
      LogUtil.error(TAG, `select failed with err: ${JSON.stringify(err)}`);
    });
  }

  @LogMethod
  showDirDocumentViewPicker(file_access_persist: boolean,
    callback: (path: string) => void) {
    let DocumentSelectOptions = new picker.DocumentSelectOptions();
    DocumentSelectOptions.selectMode = picker.DocumentSelectMode.FOLDER;
    let documentPicker = new picker.DocumentViewPicker();
    documentPicker.select(DocumentSelectOptions)
      .then((selectResult) => {
        try {
          if (file_access_persist) {
            this.permissionManagerAdapter.fileAccessPersist(selectResult);
            this.permissionManagerAdapter.saveUris(selectResult);
          }
          selectResult = this.dirFilter(selectResult);
          callback(JSON.stringify(selectResult));
        } catch (err) {
          callback('');
          LogUtil.error(TAG, `select Foloder failed with err: ${JSON.stringify(err)}`);
        }
      }).catch((err: Error) => {
      callback('');
      LogUtil.error(TAG, `select failed with err: ${JSON.stringify(err)}`);
    });
  }

  @LogMethod
  showSaveAsDocumentViewPicker(params: SaveAsDialogParams, callback: (path: string) => void) {
    let DocumentSaveOptions = new picker.DocumentSaveOptions();
    DocumentSaveOptions.newFileNames = [`${params.file_name}`];
    DocumentSaveOptions.defaultFilePathUri = FilePickerAdapter.PREFIX + params.dir_name;
    const context = this.ctxAdapter.getContext();
    let allFileDescription = context.resourceManager.getStringSync(this.allFIleDescriptionId);
    if (params.extensions.length > 0) {
      let filterDescriptions: Array<string> = this.getFilterArray(params.extensions, params.descriptions);
      DocumentSaveOptions.fileSuffixChoices = [filterDescriptions[0]];
      if (params.include_all_files) {
        DocumentSaveOptions.fileSuffixChoices.push(allFileDescription + "|.*");
      }
    } else {
      DocumentSaveOptions.fileSuffixChoices = [allFileDescription + "|.*"];
    }
    let documentPicker = new picker.DocumentViewPicker();
    documentPicker.save(DocumentSaveOptions).then((saveResult) => {
      saveResult = this.dirFilter(saveResult);
      callback(JSON.stringify(saveResult));
    }).catch((err: Error) => {
      callback('');
      LogUtil.error(TAG, `save failed with err: ${JSON.stringify(err)}`);
    });
  }

  private dirFilter(docs: string[]): string[] {
    let copy: string[] = [];
    docs.forEach((path) => {
      // Convert to uri get systeam path
      let uri = new fileUri.FileUri(path);
      if (uri.authority === 'media') {
        let file: fs.File | undefined;
        let copyFile: fs.File | undefined;
        try {
          let filePath = this.ctxAdapter.getContext().tempDir;
          file = fs.openSync(path, fs.OpenMode.READ_ONLY);
          copyFile = fs.openSync(filePath + '/' + uri.name, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
          fs.copyFileSync(file.fd, copyFile.fd);
          copy.push(filePath + '/' + uri.name);
        } catch (err) {
          LogUtil.error(TAG, `copy failed: ${JSON.stringify(err)}`);
        } finally {
          try {
            if (file) {
              fs.closeSync(file);
            }
          } catch (err) {
            LogUtil.error(TAG, `close file failed: ${JSON.stringify(err)}`);
          }
          try {
            if (copyFile) {
              fs.closeSync(copyFile);
            }
          } catch (err) {
            LogUtil.error(TAG, `close copyFile failed: ${JSON.stringify(err)}`);
          }
        }
      } else {
        copy.push(uri.path);
      }
    });
    return copy;
  }

  private getFilterArray(filters: Array<Array<string>>, descriptions: Array<string>): Array<string> {
    const context = this.ctxAdapter.getContext();
    let defaultDescription = context.resourceManager.getStringSync(this.defaultDescriptionId);
    let copy = new Array<string>();
    for (let i = 0; i < filters.length; i++) {
      let description: string = defaultDescription;
      if (descriptions[i]) {
        description = descriptions[i];
      } else if (filters[i].length == 1) {
        const typeId = uniformTypeDescriptor.getUniformDataTypeByFilenameExtension("." + filters[i][0]);
        let typeObj: uniformTypeDescriptor.TypeDescriptor = uniformTypeDescriptor.getTypeDescriptor(typeId);
        if (typeObj) {
          description = typeObj.description;
        }
      }
      copy.push(description + "(*." + filters[i].join(";*.") + ")|." + filters[i].join(",."));
    }
    return copy;
  }  
}
