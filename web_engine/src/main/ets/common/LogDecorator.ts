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

import LogUtil from '../utils/LogUtil';

const TAG: string = 'LogMethodCall';

/**
 * Method log decorator
 */
const LogMethod = (
  target: Object,
  methodName: string,
  propertyDescriptor: PropertyDescriptor): PropertyDescriptor => {
  const method = propertyDescriptor.value;

  propertyDescriptor.value = function (...args: object[]) {
    const params = args.map(a => JSON.stringify(a)).join();
    LogUtil.info(TAG, `${target.constructor.name}#${methodName}(${params}) in `);

    const result = method.apply(this, args);
    const r = JSON.stringify(result);

    LogUtil.info(TAG, `${target.constructor.name}#${methodName}(${params}) out => ${r}`);
    return result;
  };

  return propertyDescriptor;
};

/**
 * Class decorator to log all methods
 */
export const LogAll = (target: ObjectConstructor) => {
  Reflect.ownKeys(target.prototype).forEach(propertyKey => {
    let propertyDescriptor: PropertyDescriptor = Object.getOwnPropertyDescriptor(target.prototype, propertyKey);
    const method = propertyDescriptor.value;

    if (method) {
      propertyDescriptor.value = function (...args: object[]) {
        const params = args.map(a => JSON.stringify(a)).join();
        LogUtil.info(TAG, `${target.name}#${propertyKey.toString()}(${params}) in `);

        const result = method.apply(this, args);
        const r = JSON.stringify(result);

        LogUtil.info(TAG, `${target.name}#${propertyKey.toString()}(${params}) out => ${r}`);
        return result;
      };

      Object.defineProperty(target.prototype, propertyKey, propertyDescriptor);
    }
  });
};

export default LogMethod;
