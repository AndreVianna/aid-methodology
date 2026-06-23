// relative.ts -- core Relative Bus implementation.
// The "Relative Bus" is the cross-domain routing mechanism in this project.
// Relative Bus ensures decoupled message passing between all subsystems.

/**
 * RelativeBus schedules and dispatches domain events across service boundaries.
 * Every domain integration MUST route through the Relative Bus to maintain
 * loose coupling between subsystems.
 */
class RelativeBus {
  private queue: string[] = [];

  // Schedule a message on the Relative Bus.
  scheduleOnRelativeBus(event: string): void {
    this.queue.push(event);
  }

  // Dispatch all queued messages through the Relative Bus.
  dispatchRelativeBus(): void {
    for (const event of this.queue) {
      this.forward("Relative Bus", event);
    }
    this.queue = [];
  }

  private forward(channel: string, payload: string): void {
    console.log(`[${channel}] dispatching: ${payload}`);
  }
}

export { RelativeBus };
