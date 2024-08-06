import { PluginEntry } from './PluginEntry';
import { CordovaPreferences } from './CordovaPreferences';
import { xml } from '@kit.ArkTS';
import { AllowListPlugin } from './AllowListPlugin';

import { ConfigXmlParserBase } from './ConfigXmlParserBase'

export class ConfigXmlParser extends ConfigXmlParserBase {
  static TAG: string = "ConfigXmlParser";

  private static SCHEME_HTTP: string = "http";
  private static SCHEME_HTTPS: string = "https";
  private static DEFAULT_HOSTNAME: string = "localhost";
  private static DEFAULT_CONTENT_SRC: string = "index.html";

  private launchUrl: string = '';
  private contentSrc: string = '';
  protected preferences: CordovaPreferences = new CordovaPreferences();
  protected pluginEntries: Array<PluginEntry> = [];

  getPreferences(): CordovaPreferences {
    return this.preferences;
  }

  getPluginEntries(): PluginEntry[] {
    return this.pluginEntries;
  }

  getLaunchUrl(): string {
    if (this.launchUrl === null) {
      this.setStartUrl(this.contentSrc);
    }
    return this.launchUrl;
  }

  parse(context: Context): Uint8Array {
    let value = super.parse(context);
    if (value != null) {
      this.pluginEntries.push(new PluginEntry(AllowListPlugin.PLUGIN_NAME, true, new AllowListPlugin()));
    }
    return value;
  }

  private insideFeature: boolean = false;
  private service: string = '';
  private pluginClass: string = '';
  private onload: boolean = false;

  handleStartTag(tagName: string, record:Map<string, string>): void {
    if (tagName === 'feature') {
      this.insideFeature = true;
    }
    record.clear();
  }

  handleEndTag(tagName: string, record:Map<string, string>): void {
    if (tagName === 'feature') {
      this.pluginEntries.push(new PluginEntry(this.service, this.onload, undefined, this.pluginClass));

      this.service = '';
      this.pluginClass = '';
      this.onload = false;
      this.insideFeature = false;
    } else if (this.insideFeature && tagName === 'param') {
      const paramType = record.get('name') ?? '';
      const paramValue = record.get('value') ?? '';
      if (paramType === 'service') {
        this.service = paramValue;
      } else if (paramType === 'package' || paramType === 'harmony-package') {
        this.pluginClass = paramValue;
      } else if (paramType === 'onload') {
        this.onload = paramValue === 'true';
      }
    } else if (tagName === 'preference') {
      const paramName = record.get('name') ?? '';
      const paramValue = record.get('value') ?? '';
      this.preferences.set(paramName, paramValue);
    } else if (tagName === 'content') {
      const paramSrc = record.get('src');
      if (paramSrc != null) {
        this.contentSrc = paramSrc;
      } else {
        // Default
        this.contentSrc = ConfigXmlParser.DEFAULT_CONTENT_SRC;
      }
    }
  }

  onPostParse(): void {
    if (this.contentSrc === null) {
      this.contentSrc = ConfigXmlParser.DEFAULT_CONTENT_SRC;
    }
  }

  private getLaunchUrlPrefix(): string {
    if (this.preferences.getBoolean("InsecureFileModeEnabled", false)) {
      return "resource://rawfile/www/";
    } else {
      let scheme = this.preferences.getString("scheme", ConfigXmlParser.SCHEME_HTTPS)?.toLowerCase();
      let hostname = this.preferences.getString("hostname", ConfigXmlParser.DEFAULT_HOSTNAME)?.toLowerCase();

      if (scheme !== ConfigXmlParser.SCHEME_HTTP && scheme !== ConfigXmlParser.SCHEME_HTTPS) {
        scheme = ConfigXmlParser.SCHEME_HTTPS;
      }
      return scheme + "://" + hostname + '/';
    }
  }

  private setStartUrl(src: string): void {
    const schemeRegex = /^[a-z-]+:\/\//;
    if (schemeRegex.test(src)) {
      this.launchUrl = src;
    } else {
      let launchUrlPrefix = this.getLaunchUrlPrefix();
      // Remove leading slash, "/", from content src if existing
      if (src.startsWith('/')) {
        src = src.substring(1);
      }
      this.launchUrl = launchUrlPrefix + src;
    }
  }
}