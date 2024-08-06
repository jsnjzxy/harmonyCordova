export interface CordovaWebViewEngine {
  loadUrl(url: string, clearNavigationStack: boolean): void;

  getUrl(): string;

  clearCache(): void;

  clearHistory(): void;

  canGoBack(): boolean;

  goBack(): boolean;

  setPaused(value: boolean): void;

  destroy(): void;

  // evaluateJavascript(js: string, callback: ValueCallback<string>): void;
}