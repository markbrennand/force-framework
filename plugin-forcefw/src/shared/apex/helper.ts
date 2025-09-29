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
import { writeFileSync } from 'node:fs';
import { ApexTestResultData, ApexTestResultOutcome } from '@salesforce/apex-node/lib/src/tests/types.js';

export declare const enum FileType {
  CSV = 'csv',
  JSON = 'json'
}

export interface OutputFile {
  type: FileType;
  name: string;
}

export interface TestFailure {
  outcome: ApexTestResultOutcome;
  message: string;
  className: string;
  methodName: string;
  stackTrace: string;
}

export function getFailures(tests: ApexTestResultData[]): ApexTestResultData[] {
  return tests.filter(test => test.outcome !== ApexTestResultOutcome.Pass);
}

export function toTestFailure(test: ApexTestResultData): TestFailure {
  return {
    outcome: test.outcome,
    message: test.message ?? 'undefined',
    className: test.apexClass.name,
    methodName: test.methodName,
    stackTrace: test.stackTrace ?? 'undefined'
  };
}

export function getFile(fileName: string): OutputFile | undefined {
  if (fileName.endsWith('.csv')) {
    return { name: fileName.split('.csv')[0], type:FileType.CSV };
  } else if (fileName.endsWith('.json')) {
    return {name: fileName.split('.json')[0], type: FileType.JSON};
  } else {
    return undefined;
  }
}

export function saveResults(outputFile: OutputFile, failures: TestFailure[]): void {
  if (outputFile.type === FileType.CSV) {
    writeFileSync(outputFile.name + '.csv', 'Outcome,Class,Method,Message,StackTrace\r\n');
    failures.forEach(failure => {
      writeFileSync(
        outputFile.name + '.csv',
        escapeCsv(failure.outcome)
          + ','
          + escapeCsv(failure.className)
          + ','
          + escapeCsv(failure.methodName)
          + ',' + escapeCsv(failure.message)
          + ','
          + escapeCsv(failure.stackTrace)
          + '\r\n',
        { flag: 'a+' }
      );
    });
  } else if (outputFile.type === FileType.JSON) {
    writeFileSync(outputFile.name + '.json', JSON.stringify(failures, null, 2));
  }
}

export function caselessCompareTestFailure(a: TestFailure, b: TestFailure): number {
  return caselessCompareString(a.className, b.className);
}

export function caselessCompareString(a: string, b: string): number {
  const aLower = a.toLowerCase();
  const bLower = b.toLowerCase()
  return aLower === bLower ? 0 : aLower < bLower ? -1 : 1;
}

function escapeCsv(value: string): string {
  return '"' + value.replaceAll('"', '""') + '"';
}
