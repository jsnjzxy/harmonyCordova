import { util } from '@kit.ArkTS';

export type ArgsType = number | string | boolean | JSON | object | Object | Array<number> | Array<string> | Array<boolean> | Array<JSON> | Array<object> | Array<Object> | ArrayBuffer;

export class CordovaArgs {
  private baseArgs: ArgsType[];

  constructor(args: ArgsType[]) {
    this.baseArgs = args;
  }

  get(index: number): ArgsType {
    if (this.baseArgs[index] === undefined) {
      throw new Error('Index out of bounds');
    }
    return this.baseArgs[index];
  }

  getBoolean(index: number): boolean {
    const val = this.get(index);
    if (typeof val !== 'boolean') {
      throw new Error('Value at index is not a boolean');
    }
    return val;
  }

  getDouble(index: number): number {
    const val = this.get(index);
    if (typeof val !== 'number') {
      throw new Error('Value at index is not a number');
    }
    return val;
  }

  getInt(index: number): number {
    const val = this.getDouble(index); // JavaScript only has one number type
    if (!Number.isInteger(val)) {
      throw new Error('Value at index is not an integer');
    }
    return val;
  }

  getJSONArray(index: number): ArgsType[] {
    const val = this.get(index);
    if (!Array.isArray(val)) {
      throw new Error('Value at index is not an array');
    }
    return val;
  }

  getJSONObject(index: number): object {
    const val = this.get(index);
    if (typeof val !== 'object' || Array.isArray(val)) {
      throw new Error('Value at index is not an object');
    }
    return val;
  }

  getLong(index: number): number {
    return this.getInt(index); // JavaScript only has one number type, no long
  }

  getString(index: number): string {
    const val = this.get(index);
    if (typeof val !== 'string') {
      throw new Error('Value at index is not a string');
    }
    return val;
  }

  opt(index: number): ArgsType {
    return this.baseArgs[index];
  }

  optBoolean(index: number): boolean {
    const val = this.baseArgs[index];
    return typeof val === 'boolean' ? val : false;
  }

  optDouble(index: number): number {
    const val = this.baseArgs[index];
    return typeof val === 'number' ? val : NaN;
  }

  optInt(index: number): number {
    const val = this.optDouble(index);
    return Number.isNaN(val) ? 0 : Math.floor(val);
  }

  optJSONArray(index: number): Array<object> {
    const val = this.opt(index);
    return Array.isArray(val) ? val : [];
  }

  optJSONObject(index: number): object {
    const val = this.opt(index);
    return typeof val === 'object' && val !== null && !Array.isArray(val) ? val : new Object;
  }

  optLong(index: number): number {
    return this.optInt(index);
  }

  optString(index: number): string {
    const val = this.opt(index);
    return typeof val === 'string' ? val : '';
  }

  isNull(index: number): boolean {
    return this.baseArgs[index] === null || this.baseArgs[index] === undefined;
  }

  getArrayBuffer(index: number): Uint8Array {
    let base64 = new util.Base64Helper();
    const encoded = this.getString(index);
    return base64.decodeSync(encoded);
  }
}