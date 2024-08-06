import { CordovaPlugin } from './CordovaPlugin';

export class PluginEntry {
  readonly service: string;
  readonly onload: boolean;
  readonly plugin?: CordovaPlugin;
  readonly pluginClass?: string;

  constructor(service: string, onload: boolean = true, plugin?: CordovaPlugin, pluginClass?: string) {
    this.service = service;
    this.onload = onload;
    this.plugin = plugin;
    this.pluginClass = pluginClass;
  }
}