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
import { BusinessError } from '@ohos.base';
import print from '@ohos.print';
import fs, { ListFileOptions } from '@ohos.file.fs';

import { BaseAdapter } from '../common/BaseAdapter';
import LogUtil from '../utils/LogUtil';
import LogMethod from '../common/LogDecorator';

import promptAction from '@ohos.promptAction'
import { ContextAdapter } from './ContextAdapter';

const TAG: string = 'Print';

@injectable()
export class PrintAdapter extends BaseAdapter {
  private printFilesPath: string [] = [];
  private ctxAdapter: ContextAdapter;

  constructor(@inject(ContextAdapter) ctxAdapter: ContextAdapter) {
    super();
    this.ctxAdapter = ctxAdapter;
    this.init();
  }

  override init() {
    let dirPath = this.ctxAdapter.getContext().getApplicationContext().tempDir + "/print";
    fs.mkdir(dirPath).catch((err: BusinessError) => {
      LogUtil.error(TAG, 'mkdir error: ' + JSON.stringify(err));
    });
  }

  @LogMethod
  showPrintDialog(value: string) {
    // TODO: need adapter print file
    let dirPath = this.ctxAdapter.getContext().getApplicationContext().tempDir + "/print";
    let listFileOption: ListFileOptions = {
      recursion: false,
      listNum: 0,
      filter: {}
    }
    fs.listFile(dirPath, listFileOption).then((filenames: Array<string>) => {
      for (let i = 0; i < filenames.length; i++) {
        let pngPath = dirPath + '/' + filenames[i];
        let tempFile: fs.File = fs.openSync(pngPath);
        let fileFd = 'fd://' + tempFile.fd;
        this.printFilesPath.push(fileFd);
      }
      print.print(this.printFilesPath, this.ctxAdapter.getActiveContext())
        .then((printTask: print.PrintTask) => {
          printTask.on('succeed', () => {
            LogUtil.info(TAG, 'print state is succeed');
          })
          printTask.on('cancel', () => {
            LogUtil.info(TAG, 'print state is cancel');
          })
        }).catch((error: Error) => {
        LogUtil.error(TAG, 'print err ' + JSON.stringify(error));
      })
    }).catch((err: BusinessError) => {
      LogUtil.error(TAG, 'list file error: ' + JSON.stringify(err));
    });
  }

  @LogMethod
  PrintPdfFiles(pdfData: ArrayBuffer) {
    let printAdapter: print.PrintDocumentAdapter = {
      onStartLayoutWrite(jobId: string,
                         oldAttrs: print.PrintAttributes,
                         newAttrs: print.PrintAttributes,
                         fd: number,
                         writeResultCallback: (jobId: string, writeResult: print.PrintFileCreationState) => void): void {
        const contentBuf: Uint8Array = new Uint8Array(pdfData);
        fs.writeSync(fd, contentBuf.buffer);
        writeResultCallback(jobId, print.PrintFileCreationState.PRINT_FILE_CREATED_UNRENDERED);
      },
      onJobStateChanged(jobId: string, state: print.PrintDocumentAdapterState): void {}
    }
    // default print start parameter
    let printAttributes: print.PrintAttributes = {
      pageSize: print.PrintPageType.PAGE_ISO_A4,
      directionMode: print.PrintDirectionMode.DIRECTION_MODE_AUTO,
      colorMode: print.PrintColorMode.COLOR_MODE_MONOCHROME,
      duplexMode: print.PrintDuplexMode.DUPLEX_MODE_NONE
    }
    print.print('', printAdapter, printAttributes, this.ctxAdapter.getActiveContext())
      .then(() => {
        LogUtil.info(TAG, 'Succeeded in print pdf files.');
      }).catch((err: BusinessError) => {
      LogUtil.error(TAG, 'Failed to print pdf files. Cause:' + JSON.stringify(err));
    });
  }

  @LogMethod
  showPrintTipsDialog() {
    try {
      promptAction.showDialog({
        title: $r('app.string.print_title'),
        message: $r('app.string.print_tip'),
        buttons: [
          {
            text: $r('app.string.print_ok'),
            color: $r('app.color.print_tip_button')
          },
        ],
      }).catch((err: Error) => {
          LogUtil.error(TAG, 'showDialog error:' + err);
        })
    } catch (error) {
      LogUtil.error(TAG, 'list file error: ' + JSON.stringify(error));
    }
    ;
  }
}
