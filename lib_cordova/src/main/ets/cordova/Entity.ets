import "reflect-metadata"

/**
 * 在js中统一用JavaScriptProxy#name来调用原生的call(x,x)方法
 */
export interface JsInterface {
  /**
   * @param methodName  JS实际调用原生的方法
   * @param params  JS携带过来的参数，有一个callbackID参数
   * @returns
   */
  call(methodName: string, params: string): string
}

export enum MetaData {
  METHOD_DECORATE = "bridge:JavaScriptInterface",
  ASYNC = "bridge:Async"
}

/**
 * @param asyncCall
 * @returns
 */
export function JavaScriptInterface(asyncCall: boolean = true): MethodDecorator {
  return (target, propertyKey, descriptor) => {
    Reflect.defineMetadata(MetaData.METHOD_DECORATE, propertyKey, descriptor.value !);
    Reflect.defineMetadata(MetaData.ASYNC, asyncCall, descriptor.value !);
  }
}

export interface JavaScriptProxy {
  object: object,
  name: string,
  methodList: Array<string>,
  controller: WebviewController
}