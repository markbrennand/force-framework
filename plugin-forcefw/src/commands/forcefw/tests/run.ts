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
import { exit } from 'node:process';
import { SfCommand, Flags } from '@salesforce/sf-plugins-core';
import { Messages } from '@salesforce/core';
import { TestService } from '@salesforce/apex-node/lib/src/tests/testService.js';
import { TestLevel, TestResult, SyncTestConfiguration, AsyncTestConfiguration, ApexTestResultOutcome, ApexTestResultData } from '@salesforce/apex-node/lib/src/tests/types.js';
import { getFailures, toTestFailure, getFile, saveResults, TestFailure, OutputFile, caselessCompareString, caselessCompareTestFailure } from '../../../shared/apex/helper.js';

Messages.importMessagesDirectoryFromMetaUrl(import.meta.url);
const messages = Messages.loadMessages('@markbrennand/plugin-forcefw', 'forcefw.tests.run');

export default class Run extends SfCommand<void> {
  public static readonly summary = messages.getMessage('summary');
  public static readonly description = messages.getMessage('description');
  public static readonly examples = messages.getMessages('examples');

  public static readonly flags = {
    'target-org': Flags.optionalOrg(),
    'output-file': Flags.file({
      summary: messages.getMessage('flags.output-file.summary'),
      char: 'f',
    }),
    verbose: Flags.boolean({
      summary: messages.getMessage('flags.verbose.summary'),
      char: 'v',
      default: false,
    }),
  };

  private verbose = false;

  private static getOutputFile(name: string): OutputFile | undefined {
    if(name) {
      const outputFile = getFile(name);
      if (!outputFile) {
        console.error('Filename ' + name + ' must have a .csv or .json suffix'); // eslint-disable-line no-console
        exit(1);
      }
      return outputFile;
    } else {
      return undefined;
    }
  }

  public async run(): Promise<void> {
    const { flags } = await this.parse(Run);
    this.verbose = flags.verbose;

    const outputFile = Run.getOutputFile(flags['output-file'] ?? '');
    const service = new TestService(flags['target-org'].getConnection('64.0'));
    const allFailures = await this.runTestsAsync(service);
    const reRunClasses = allFailures
      .filter((test) => test.message?.match('.*UNABLE_TO_LOCK_ROW.*'))
      .map((test) => test.apexClass.name)
      .filter((value, index, array) => array.indexOf(value) === index)
      .sort(caselessCompareString);

    if (this.verbose && reRunClasses.length > 0) {
      this.log('-- following tests will be re-run: ' + reRunClasses.join(', '));
    }

    const nonReRunnableFailures = allFailures
      .filter((test) => !test.message?.includes('UNABLE_TO_LOCK_ROW'))
      .map((test) => toTestFailure(test))
      .sort(caselessCompareTestFailure);

    const results = await this.runTestsSync(service, reRunClasses, nonReRunnableFailures);
    const hasErrors = results.length > 0;
    if (hasErrors) {
      if (outputFile) {
        saveResults(outputFile, results);
      }

      if (this.verbose) {
        this.log('-- failures');
        for (const result of results) {
          if (result.outcome === ApexTestResultOutcome.Skip) {
            this.log(result.className + '.' + result.methodName + '() was skipped');
          } else if (result.outcome === ApexTestResultOutcome.CompileFail) {
            this.log(result.className + '.' + result.methodName + '() could not be compiled');
          } else {
            this.log(result.className + '.' + result.methodName + '() failed with error ' + result.message);
          }
        }
      }
    }

    this.log(hasErrors ? '' + results.length + ' test(s) failed.' : 'All tests passed');
    exit(hasErrors ? 1 : 0);
  }

  private async runTestsAsync(service: TestService): Promise<ApexTestResultData[]> {
    if (this.verbose) {
      this.log('-- starting asynchronous tests');
    }

    const asyncConfig = { skipCodeCoverage: true, testLevel: TestLevel.RunLocalTests } as AsyncTestConfiguration;
    const asyncResult = await service.runTestAsynchronous(asyncConfig) as TestResult;
    const results = getFailures(asyncResult.tests);

    if(this.verbose) {
      this.log('-- asynchronous tests finished with ' + results.length + ' failure(s)');
    }

    return results;
  }

  private async runTestsSync(service: TestService, reRunClasses: string[], results: TestFailure[]): Promise<TestFailure[]> {
    let allResults = results;
    for (const classToRun of reRunClasses) {
      const syncConfig = {
        testLevel: TestLevel.RunSpecifiedTests,
        skipCodeCoverage: true,
        tests: [ { className: classToRun } ],
      } as SyncTestConfiguration;

      if(this.verbose) {
        this.log('-- re-running ' + classToRun + ' tests synchronously');
      }

      const syncResult = await service.runTestSynchronous(syncConfig) as TestResult; // eslint-disable-line no-await-in-loop
      const failures = getFailures(syncResult.tests).map((test) => toTestFailure(test));

      if(this.verbose) {
        this.log('-- synchronous tests finished with ' + failures.length + ' failures');
      }

      allResults = [...allResults, ...failures];
    }

    return allResults;
  }
}
