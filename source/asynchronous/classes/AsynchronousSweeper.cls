/**
 * @description
 * <p>
 * Schedulable wrapper that triggers the Asynchronous framework's Sweeper run.
 * <p>
 * The Sweeper is responsible for housekeeping tasks such as:
 * - Restarting or re-queuing eligible jobs
 * - Advancing jobs stuck in transitional states
 * - Performing framework maintenance as needed
 * <p>
 * This class is intended to be invoked by a Salesforce cron schedule.
 * The execute method simply delegates to AsynchronousV1.startSweeper(),
 * which enqueues a lightweight job (AsynchronousScheduler.RunSweeper) to
 * perform the actual sweep logic asynchronously.
 * <p>
 * See <a href=../../source/asynchronous/README.md target="_blank">README</a> for full details of the Asynchronous API.
 * <p>
 * Copyright (c) 2025 Mark Brennand, released under <a href=../../LICENSE target="_blank">MIT License</a>.
 *
 * @author Mark Brennand
 */
global with sharing class AsynchronousSweeper implements Schedulable {

    /**
     * @description
     * <p>
     * Entry point invoked by the Salesforce scheduler.
     * Delegates to startSweeper to enqueue the Sweeper job.
     *
     * @param context System-provided schedulable context
     */
    global void execute(SchedulableContext context) {
        AsynchronousV1.startSweeper();
    }
}