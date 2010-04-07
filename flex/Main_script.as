import mx.controls.Alert;
/* import firebug like debugger */
import com.flexspy.FlexSpy;
/* import firebug logging support, just use:
   Firebug.debug('my debug messsage')
*/
import net.zengrong.logging.Firebug;

import mx.messaging.Consumer;
import mx.messaging.Producer;
import mx.messaging.ChannelSet;
import mx.messaging.channels.AMFChannel;
import mx.messaging.events.MessageEvent;
import mx.messaging.events.MessageFaultEvent;
import mx.messaging.messages.AsyncMessage;

protected const TOPIC:String = 'messages';
protected var channelSet:ChannelSet;
protected var consumer:Consumer;
protected var producer:Producer;
protected var serverUrl:String;

[Bindable]
protected var subscribed:Boolean = false;


/**
 * Create the AMF Channels
 * that messages will be
 * sent and recieved from.
 */
public function getChannelSet():ChannelSet {
  if (channelSet != null ) {
    // User has not changed URL.
    // Use existing channelSet.
    return channelSet;
  }
  serverUrl = 'http://{server.name}:{server.port}/services';
  var channel:AMFChannel = new AMFChannel("streaming-channel", serverUrl);

  // Create a channel set and add channel(s) to it
  channelSet = new ChannelSet();
  channelSet.addChannel(channel);

  Firebug.debug("Created channelSet", channelSet);

  return channelSet;
}

/**
 * Create a Consumer with url from user input.
 */
protected function getConsumer():Consumer {
  if (consumer != null && consumer.channelSet == channelSet) {
    // return existing consumer
    return consumer;
  }

  // Create a new Consumer
  // and set it's destination
  // name to the topic we want
  // to subscribe to.
  consumer = new Consumer();
  consumer.destination = TOPIC;
  consumer.channelSet = getChannelSet();

  Firebug.debug("Created consumer", consumer);

  return consumer;
}


/**
 * Create a message Producer with url from user input.
 */

protected function getProducer():Producer {
  if (producer != null && producer.channelSet == channelSet) {
    // return existing consumer
    return producer;
  }

  producer = new Producer();
  producer.destination = TOPIC;
  producer.channelSet = getChannelSet();

  return producer;
}

/**
  * Subscribe to the 'messages' topic.
  */
protected function subscribeMessaging():void {
  Firebug.debug("Subscribing to Regular Messages");
  var consumer:Consumer = getConsumer();
  consumer.addEventListener(MessageEvent.MESSAGE,
                            consumer_msgHandler, false, 0 , true);
  consumer.addEventListener(MessageFaultEvent.FAULT,
                            faultHandler, false, 0, true);
  consumer.subscribe();

  subscribed = true;
}

protected function unSubscribeMessaging():void {
  Firebug.debug("Un-Subscribing to Regular Messages");
  var consumer:Consumer = getConsumer();
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
  Firebug.debug(22, event);
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

/**
  * Publish a message to all clients.
  */
protected function publishMessage():void {
  var producer:Producer = getProducer();
  var msg:AsyncMessage = new AsyncMessage();
  msg.body = 'foo';
  producer.send(msg);
}


private function creationComplete() : void {
  subscribeMessaging();
  Firebug.debug("getChannelSet()");
  Firebug.debug(getChannelSet());
  Firebug.debug("Getting Consumer");
  Firebug.debug(trace(getConsumer()));
  Firebug.debug("Publishing Message");
  publishMessage()
}
