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

import usb from '@ohos.usbManager';
import JsBindingUtils from '../utils/JsBindingUtils';
import Inject from '../common/InjectModule';
import lazy { DeviceAdapter } from '../adapter/DeviceAdapter';

function implDeviceAdapter(): DeviceAdapter {
  return Inject.getOrCreate(DeviceAdapter);
}

function getDevices(callback?: Function): boolean {
  return implDeviceAdapter().getDevices(callback);
}

function hasRight(deviceName: string): boolean {
  return implDeviceAdapter().hasRight(deviceName);
}

function registerHotplugCallback(callback: Function): void {
  implDeviceAdapter().registerHotplugCallback(callback);
}

function unregisterHotplugCallback(): void {
  implDeviceAdapter().unregisterHotplugCallback();
}

function requestRight(deviceName: string, callback: (isGranted: boolean) => void): void {
  implDeviceAdapter().requestRight(deviceName, callback);
}

function removeRight(deviceName: string): boolean {
  return implDeviceAdapter().removeRight(deviceName);
}

function openDevice(device: usb.USBDevice, callback: (pipe: usb.USBDevicePipe) => void): boolean {
  return implDeviceAdapter().openDevice(device, callback);
}

function getRawDescriptor(pipe: usb.USBDevicePipe, callback: (descriptor: Uint8Array, length: number) => void): void {
  implDeviceAdapter().getRawDescriptor(pipe, callback);
}

function getFileDescriptor(pipe: usb.USBDevicePipe): number {
  return implDeviceAdapter().getFileDescriptor(pipe);
}

function releaseInterface(pipe: usb.USBDevicePipe, iface: usb.USBInterface): number {
  return implDeviceAdapter().releaseInterface(pipe, iface);
}

function closePipe(pipe: usb.USBDevicePipe): number {
  return implDeviceAdapter().closePipe(pipe);
}

export class DeviceAdapterBind {
  static bind() {
    JsBindingUtils.bindFunction('DeviceAdapter.GetDevices', getDevices);
    JsBindingUtils.bindFunction('DeviceAdapter.HasRight', hasRight);
    JsBindingUtils.bindFunction('DeviceAdapter.RegisterHotplugCallback', registerHotplugCallback);
    JsBindingUtils.bindFunction('DeviceAdapter.UnregisterHotplugCallback', unregisterHotplugCallback);
    JsBindingUtils.bindFunction('DeviceAdapter.RequestRight', requestRight);
    JsBindingUtils.bindFunction('DeviceAdapter.RemoveRight', removeRight);
    JsBindingUtils.bindFunction('DeviceAdapter.OpenDevice', openDevice);
    JsBindingUtils.bindFunction('DeviceAdapter.GetRawDescriptor', getRawDescriptor);
    JsBindingUtils.bindFunction('DeviceAdapter.GetFileDescriptor', getFileDescriptor);
    JsBindingUtils.bindFunction('DeviceAdapter.ReleaseInterface', releaseInterface);
    JsBindingUtils.bindFunction('DeviceAdapter.ClosePipe', closePipe);
  }
}
