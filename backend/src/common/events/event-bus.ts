import { EventEmitter } from 'events';

/**
 * Global event bus for cross-module communication.
 * Used to bridge P2P runtime events to the WebSocket gateway.
 */
export const eventBus = new EventEmitter();

