import mx.controls.Alert;
import net.zengrong.logging.Firebug;
import mx.collections.ArrayCollection;
import mx.messaging.Consumer;
import mx.messaging.events.MessageEvent;
import mx.messaging.events.MessageFaultEvent;
import org.ufsoft.dac.controls.*;


protected var queueConsumer:Consumer;

[Bindable]
private var conversions:ArrayCollection;
protected var subscribed:Boolean = false;

private function creationComplete() : void {

  conversions = new ArrayCollection();
  var obj:Object = new Object;
  obj.id = "1";
  obj.filename = "Fake Filename.mp2";
  obj.progress = 50;
  conversions.addItem(obj);
  Firebug.debug(conversions);
  subscribeMessaging()
}

/**
 * Create a Consumer with url from user input.
 */
protected function getQueueConsumer():Consumer {
  if (queueConsumer != null && queueConsumer.channelSet == parentApplication.getChannelSet()) {
    // return existing consumer
    return queueConsumer;
  }

  // Create a new Consumer
  // and set it's destination
  // name to the topic we want
  // to subscribe to.
  queueConsumer = new Consumer();
  queueConsumer.selector = 'queue';
  queueConsumer.destination = 'messages';
  queueConsumer.channelSet = parentApplication.getChannelSet();

  return queueConsumer;
}

/**
  * Subscribe to the 'messages' topic.
  */
protected function subscribeMessaging():void {
  Firebug.debug("Subscribing to Queue Messages");
  var consumer:Consumer = getQueueConsumer();
  consumer.addEventListener(MessageEvent.MESSAGE,
                            consumer_msgHandler, false, 0 , true);
  consumer.addEventListener(MessageFaultEvent.FAULT,
                            faultHandler, false, 0, true);
  consumer.subscribe();

  subscribed = true;
}

protected function unSubscribeMessaging():void {
  Firebug.debug("Un-Subscribing to Queue Messages");
  var consumer:Consumer = getQueueConsumer();
  if (consumer.subscribed) {
    consumer.unsubscribe();
  }

  subscribed = false;
}

/**
 * Handle an incoming message.
 */
protected function consumer_msgHandler(event:MessageEvent):void {
  //messages.addItem(String(event.message.body));
  Firebug.debug(11, event);
  //Alert.show(trace(event.message), 'Incoming Message',
  //           Alert.OK, this, null, null);
}


/**
 * Handle a failed message.
 */
protected function faultHandler(event:MessageFaultEvent):void {
  Alert.show(event.faultString, 'Message Fault',
             Alert.OK, this, null, null);
}
