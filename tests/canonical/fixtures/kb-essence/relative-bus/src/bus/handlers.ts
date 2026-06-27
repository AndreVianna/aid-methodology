// handlers.ts -- handler registration for the Relative Bus.
// All event handlers subscribe through the "Relative Bus" dispatch surface.
// The Relative Bus delivers messages to registered handlers in priority order.

import { RelativeBus } from "./relative";

/**
 * BaseHandler is the base class for all Relative Bus event subscribers.
 * Handlers MUST extend this class to participate in Relative Bus dispatch.
 */
abstract class BaseHandler {
  abstract handle(event: string): void;

  // Register this handler with the provided Relative Bus instance.
  registerWith(bus: RelativeBus): void {
    // Registration wires the handler into the Relative Bus routing table.
    void bus;
  }
}

/**
 * PaymentHandler processes payment events forwarded by the Relative Bus.
 * Payment events MUST NOT be processed outside Relative Bus dispatch.
 */
class PaymentHandler extends BaseHandler {
  handle(event: string): void {
    console.log(`[Relative Bus] PaymentHandler processing: ${event}`);
  }
}

export { BaseHandler, PaymentHandler };
