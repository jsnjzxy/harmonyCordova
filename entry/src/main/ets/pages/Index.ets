import webview from '@ohos.web.webview'
import { BusinessError } from '@ohos.base';

import { BMCordovaWebViewProxy } from '../cordova/BMCordovaWebViewProxy';

@Entry
@Component
export struct WebTestPage {
  controller: BMCordovaWebViewProxy = BMCordovaWebViewProxy.createController();

  aboutToAppear(): void {
    try {
      // 启用网页调试功能
      webview.WebviewController.setWebDebuggingAccess(true);
    } catch (error) {
      let e: BusinessError = error as BusinessError;
      console.log(`Error Code: ${e.code}, Message: ${e.message}`);
      this.controller.refresh(); // 页面异常,刷新
    }
  }


  build() {
    Row() {
      Column({ space: 20 }) {
        Web({ src: $rawfile('www/index.html'), controller: this.controller.getWebViewController() })
          .onControllerAttached(() => {
            this.controller.onControllerAttached();
          })
          .javaScriptAccess(true)
          .javaScriptProxy(this.controller.javaScriptProxy)
          .onAlert((event) => {
            this.controller.onJsAlert(event);
            return true;
          })
          .onPrompt((event) => {
            this.controller.onJsPrompt(event);
            return true;
          })

      }.width('100%').height('100%')
    }
  }
}