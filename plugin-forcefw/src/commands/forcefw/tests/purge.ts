/*
 * Copyright 2025, Salesforce, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { SfCommand, Flags } from '@salesforce/sf-plugins-core';
import { Messages } from '@salesforce/core';

Messages.importMessagesDirectoryFromMetaUrl(import.meta.url);
const messages = Messages.loadMessages('@markbrennand/plugin-forcefw', 'forcefw.tests.purge');

export default class Purge extends SfCommand<void> {
  public static readonly summary = messages.getMessage('summary');
  public static readonly description = messages.getMessage('description');
  public static readonly examples = messages.getMessages('examples');

  public static readonly flags = {
    'target-org': Flags.optionalOrg(),
    verbose: Flags.boolean({
      summary: messages.getMessage('flags.verbose.summary'),
      char: 'v',
      default: false,
    }),
    limit: Flags.integer({
      summary: messages.getMessage('flags.limit.summary'),
      char: 'l',
      default: undefined,
    }),
  };

  private verbose = false;

  public async run(): Promise<void> {
    const { flags } = await this.parse(Purge);
    this.verbose = flags.verbose;

    const connection = flags['target-org'].getConnection('64.0');

    const limit = flags.limit ?? 10000;
    let deleted = 0;

    while(deleted < limit) {
      const queryLimit = ((limit - deleted) < 200) ? (limit - deleted) : 200;

      // eslint-disable-next-line no-await-in-loop
      const results = (await connection.query('SELECT Id FROM ApexTestResult ORDER BY TestTimestamp LIMIT ' + queryLimit)).records;

      if (results.length === 0) {
        if (this.verbose && deleted === 0) {
          this.log('-- no test results found');
        }
        break;
      }

      if (this.verbose) {
        this.log('-- found ' + results.length + ' test results to delete');
      }

      const ids = results.map((result) => result.Id) as string[];
      await connection.delete('ApexTestResult', ids); // eslint-disable-line no-await-in-loop
      deleted += ids.length;
    }

    if (this.verbose && deleted > 0) {
      this.log('-- test results deleted');
    }
  }
}
