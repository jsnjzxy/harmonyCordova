import { uri as _uri} from '@kit.ArkTS';

class URLPattern {
  scheme: RegExp | null;
  host: RegExp | null;
  port: number | null;
  path: RegExp | null;

  constructor(scheme: string | null, host: string | null, port: string | null, path: string | null) {
    this.scheme = scheme ? new RegExp(this.regexFromPattern(scheme, false), 'i') : null;
    this.host = this.compileHostPattern(host);
    this.port = port ? parseInt(port, 10) : null;
    this.path = path ? new RegExp(this.regexFromPattern(path, true)) : null;
  }

  private regexFromPattern(pattern: string, allowWildcards: boolean): string {
    const toReplace = "\\.[]{}()^$?+|";
    let regex = '';
    for (let i = 0; i < pattern.length; i++) {
      const c = pattern.charAt(i);
      if (c === '*' && allowWildcards) {
        regex += '.';
      } else if (toReplace.includes(c)) {
        regex += '\\';
      }
      regex += c;
    }
    return regex;
  }

  private compileHostPattern(host: string | null): RegExp | null {
    if (!host) return null;
    if (host === '*') return null;
    if (host.startsWith('*.')) {
      return new RegExp(`([a-z0-9.-]*\\.)?${this.regexFromPattern(host.substring(2), false)}`, 'i');
    }
    return new RegExp(this.regexFromPattern(host, false), 'i');
  }

  matches(uri: _uri.URI): boolean {
    return (!this.scheme || this.scheme.test(uri.scheme)) &&
      (!this.host || this.host.test(uri.host)) &&
      (!this.port || this.port === Number(uri.port)) &&
      (!this.path || this.path.test(uri.path));
  }
}

export class AllowList {
  private allowList: URLPattern[] | null;
  private static readonly TAG = "CordovaAllowList";

  constructor() {
    this.allowList = [];
  }

  addAllowListEntry(origin: string, subdomains: boolean): void {
    if (this.allowList === null) return;

    if (origin === "*") {
      console.log(`${AllowList.TAG}: Unlimited access to network resources`);
      this.allowList = null;
    } else {
      const parts = /^((\*|[A-Za-z-]+):(\/\/)?)?(\*|((\*\.)?[^*\/:]+))?(:([0-9]+))?(\/.*)?/.exec(origin);
      if (parts) {
        const scheme = parts[2];
        let host = parts[4];
        const port = parts[8];
        const path = parts[9];

        if ((scheme === 'file' || scheme === 'content') && !host) host = '*';
        if (!scheme) {
          this.allowList.push(new URLPattern('http', host, port, path));
          this.allowList.push(new URLPattern('https', host, port, path));
        } else {
          this.allowList.push(new URLPattern(scheme, host, port, path));
        }
      }
    }
  }

  isUrlAllowListed(uri: string): boolean {
    if (this.allowList === null) return true;

    const parsedUri = new _uri.URI(uri);
    return this.allowList.some(pattern => pattern.matches(parsedUri));
  }
}