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

import hilog from '@ohos.hilog';

/**
 *  log package tool class
 */
export default class LogUtil {
  private static DOMAIN: number = 0x0000;
  private static TAG: string = '[WebEngine]';

  /**
   * print debug level log
   *
   * @param {string} tag - Page or class tag
   * @param {string} msg - Log needs to be printed
   */
  static debug(tag: string, msg: string): void {
    hilog.debug(LogUtil.DOMAIN, LogUtil.TAG, 'tag: %{public}s --> %{public}s', tag, msg);
  }

  /**
   * print info level log
   *
   * @param {string} tag - Page or class tag
   * @param {string} msg - Log needs to be printed
   */
  static info(tag: string, msg: string): void {
    hilog.info(LogUtil.DOMAIN, LogUtil.TAG, 'tag: %{public}s --> %{public}s', tag, msg);
  }

  /**
   * print warn level log
   *
   * @param {string} tag - Page or class tag
   * @param {string} msg - Log needs to be printed
   */
  static warn(tag: string, msg: string): void {
    hilog.warn(LogUtil.DOMAIN, LogUtil.TAG, 'tag: %{public}s --> %{public}s', tag, msg);
  }

  /**
   * print error level log
   *
   * @param {string} tag - Page or class tag
   * @param {string} msg - Log needs to be printed
   */
  static error(tag: string, msg: string): void {
    hilog.error(LogUtil.DOMAIN, LogUtil.TAG, 'tag: %{public}s --> %{public}s', tag, msg);
  }
}
