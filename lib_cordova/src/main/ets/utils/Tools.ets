export class Tools {
  /**
   * 判断数据是否为空
   * @param value
   * @returns
   */
  static isEmpty(value: Object | null | undefined): boolean {
    if (value === null || value === undefined || value === '') {
      return true
    }
    if (Array.isArray(value)) {
      return value.length === 0
    }
    if (value instanceof Map || value instanceof Set) {
      return value.size === 0
    }
    if (value?.toLocaleString() === '[object Object]') {
      return JSON.stringify(value) === "{}"
    }
    return false
  }

  /**
   * json 转 数组 Array<Object>
   * @param obj 任意类型数据 Object
   * @returns 数组 Array<Object>
   */
  static jsonToObjArr(obj: Object | undefined | null): Array<Object> {
    let result: Array<Object> = new Array();
    if (obj === undefined || obj === null) {
      return result;
    }

    if (typeof obj === 'string') {
      try {
        let jsonObj: Object = JSON.parse(obj);
        if (jsonObj instanceof Array) {
          result = jsonObj;
        } else if (typeof jsonObj === "string") {
          jsonObj = JSON.parse(jsonObj);
          if (jsonObj instanceof Array) {
            result = jsonObj;
          } else if (typeof jsonObj === "string") {
            jsonObj = JSON.parse(jsonObj);
            if (jsonObj instanceof Array) {
              result = jsonObj;
            }
          }
        } else {

        }
      } catch (e) {
      }
    } else if (obj instanceof Array) {
      result = obj;
    } else {
      try {
        let resultArr: Array<Object> = new Array<Object>();
        let objArr: Array<Object> = new Array<Object>(Object.values(obj));
        objArr.forEach((value, index) => {
          resultArr.push(value);
        });
        return resultArr;
      } catch (e) {
      }
    }
    return result;
  }
}