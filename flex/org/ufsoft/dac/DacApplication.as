/**
 * @author vampas
 */
package org.ufsoft.dac {
  import mx.core.Application;

  import mx.controls.Alert;
  /* import firebug like debugger */
  import com.flexspy.FlexSpy;
  /* import firebug logging support, just use:
     Firebug.debug('my debug messsage')
  */
  import net.zengrong.logging.Firebug;

  import mx.collections.ArrayCollection;
  import mx.collections.ItemResponder;
  import mx.events.FlexEvent;
  import mx.messaging.Consumer;
  import mx.messaging.Producer;
  import mx.messaging.ChannelSet;
  import mx.messaging.channels.AMFChannel;
  import mx.messaging.channels.StreamingAMFChannel;
  import mx.messaging.events.ChannelEvent;
  import mx.messaging.events.ChannelFaultEvent;
  import mx.messaging.events.MessageEvent;
  import mx.messaging.events.MessageFaultEvent;
  import mx.messaging.messages.AsyncMessage;
  import mx.rpc.AsyncToken;
  import mx.rpc.remoting.mxml.RemoteObject;
  import mx.rpc.events.ResultEvent;
  import mx.rpc.events.FaultEvent;

  import org.ufsoft.dac.conversions.Conversion;
  import org.ufsoft.dac.events.ConnectionEvent;
  import org.ufsoft.dac.events.ConversionEvent;
  import org.ufsoft.dac.events.QueueEvent;

  public class DacApplication extends Application {
    private var serverAMFUrl:                 String;
    private var serverStreamingUrl:           String;
    private var streamingChannel:             StreamingAMFChannel;
    private var servicesChannel:              AMFChannel;
    private var appChannelSet:                ChannelSet;
    private var conversionsConsumer   :       Consumer;
    private var newConversionsConsumer:       Consumer;
    private var updatedConversionsConsumer:   Consumer;
    private var completedConversionsConsumer: Consumer;
    private var remoteService:                RemoteObject;

    [Bindable]
    [Embed('/assets/rtp.png')] public var rtpLogo:Class;
    [Embed('/assets/connect_no.png')] public var connectionDown:Class;
    /*[Embed('/assets/connect_creating.png')] private var connectionConnecting:Class;
    [Embed('/assets/connect_established.png')] private var connectionUp:Class;
    private var connectionStatus:Image = connectionConnecting;*/

    public function DacApplication() {
      super();
      serverAMFUrl = 'http://{server.name}:{server.port}/rpc';
      serverStreamingUrl = 'http://{server.name}:{server.port}/amf-streaming';
      addEventListener(FlexEvent.CREATION_COMPLETE, applicationCreated);
    }

    private function applicationCreated(event:Event):void {

      Firebug.debug("Application Created");

      // XXX: MultiTopicConsumer
      newConversionsConsumer = getConsumer("conversions", "new");
      newConversionsConsumer.addEventListener(MessageEvent.MESSAGE, newConversionEvent);
      this.addEventListener(ConnectionEvent.CONNECTED, newConversionsConsumer.subscribe);
      this.addEventListener(ConnectionEvent.DISCONNECTED, newConversionsConsumer.unsubscribe);

      updatedConversionsConsumer = getConsumer("conversions", "update");
      updatedConversionsConsumer.addEventListener(MessageEvent.MESSAGE, updatedConversionEvent);
      this.addEventListener(ConnectionEvent.CONNECTED, updatedConversionsConsumer.subscribe);
      this.addEventListener(ConnectionEvent.DISCONNECTED, updatedConversionsConsumer.unsubscribe);

      completedConversionsConsumer = getConsumer("conversions", "complete");
      completedConversionsConsumer.addEventListener(MessageEvent.MESSAGE, completedConversionEvent);
      this.addEventListener(ConnectionEvent.CONNECTED, completedConversionsConsumer.subscribe);
      this.addEventListener(ConnectionEvent.DISCONNECTED, completedConversionsConsumer.unsubscribe);
    }

    public function getChannel():ChannelSet {
      if ( appChannelSet != null ) {
        // channel set is defined already, return it
        return appChannelSet;
      }
      Firebug.debug("Creating channel");
      // Create a channel set and add channel(s) to it
      appChannelSet = new ChannelSet();
      streamingChannel = new StreamingAMFChannel("amf-streaming", serverStreamingUrl);
      appChannelSet.addChannel(streamingChannel);
      servicesChannel = new AMFChannel("rpc", serverAMFUrl)
      appChannelSet.addChannel(servicesChannel);
      appChannelSet.addEventListener(ChannelEvent.CONNECT, channelConnected);
      appChannelSet.addEventListener(ChannelEvent.DISCONNECT, channelDisconnected);
      appChannelSet.addEventListener(ChannelFaultEvent.FAULT, channelFault);
      return appChannelSet;
    }

    private function channelFault(event:ChannelFaultEvent):void {
      Firebug.debug(String(event));
    }

    private function channelConnected(event:ChannelEvent):void {
      Firebug.debug("Channel Connected", String(event));
      if ( event.reconnecting ) {
        this.dispatchEvent(new ConnectionEvent(ConnectionEvent.RECONNECTING));
        /*newConversionsConsumer.unsubscribe();
        updatedConversionsConsumer.unsubscribe();
        completedConversionsConsumer.unsubscribe();*/
      } else {
        this.dispatchEvent(new ConnectionEvent(ConnectionEvent.CONNECTED));
        /*newConversionsConsumer.subscribe();
        updatedConversionsConsumer.subscribe();
        completedConversionsConsumer.subscribe();*/
      }
      queryQueueContents();
    }

    private function channelDisconnected(event:ChannelEvent):void {
      Firebug.debug("Channel DisConnected");
      if ( event.reconnecting ) {
        this.dispatchEvent(new ConnectionEvent(ConnectionEvent.RECONNECTING));
      } else {
        this.dispatchEvent(new ConnectionEvent(ConnectionEvent.DISCONNECTED));
      }
      /*newConversionsConsumer.unsubscribe();
      updatedConversionsConsumer.unsubscribe();
      completedConversionsConsumer.unsubscribe();*/
    }

    public function getConsumer(destination:String, subtopic:String=null):Consumer {
      Firebug.debug("Creating consumer");
      var consumer:Consumer = new Consumer()
      consumer.destination = destination;
      if ( subtopic != null) {
        consumer.subtopic = subtopic;
      }
      consumer.channelSet = getChannel();
      consumer.resubscribeAttempts = 10;
      consumer.resubscribeInterval = 5000;  // 5 seconds between attemps
      consumer.subscribe();
      return consumer;
    }

    private function conversionEvent(event:MessageEvent):void {
      Firebug.debug(777, String(event.message));
      var conversion:Conversion = event.message.body as Conversion;
      var conversion_event:ConversionEvent = new ConversionEvent(ConversionEvent.NEW, conversion);
      this.dispatchEvent(conversion_event);
    }

    private function newConversionEvent(event:MessageEvent):void {
      var conversion:Conversion = event.message.body as Conversion;
      var conversion_event:ConversionEvent = new ConversionEvent(ConversionEvent.NEW, conversion);
      this.dispatchEvent(conversion_event);
      Firebug.debug("Dispatched ConversionEvent.NEW:", String(conversion_event));
    }

    private function updatedConversionEvent(event:MessageEvent):void {
      var conversion:Conversion = event.message.body as Conversion;
      var conversion_event:ConversionEvent = new ConversionEvent(ConversionEvent.UPDATED, conversion);
      this.dispatchEvent(conversion_event);
      Firebug.debug("Dispatched ConversionEvent.UPDATED:", String(conversion_event));
    }
    private function completedConversionEvent(event:MessageEvent):void {
      var conversion:Conversion = event.message.body as Conversion;
      var conversion_event:ConversionEvent = new ConversionEvent(ConversionEvent.COMPLETE, conversion);
      this.dispatchEvent(conversion_event);
    }

    public function queryQueueContents():void {
      if ( remoteService == null) {
        remoteService = new RemoteObject("WebServices");
        remoteService.channelSet = getChannel();
        remoteService.showBusyCursor = true;
        remoteService.addEventListener(FaultEvent.FAULT, remoteServiceFault);
      }
      Firebug.debug("QUERING QUEUE CONTENTS");
      var token:AsyncToken = remoteService.get_process_queue();
      Firebug.debug("QUERING QUEUE CONTENTS - Got Token");
      token.addResponder(new ItemResponder(queryQueueContentsResult,
                                           queryQueueContentsFault,
                                           token));
      Firebug.debug("QUERING QUEUE CONTENTS - Added Responder");
      //remoteService.get_process_queue.addEventListener("result", queryQueueContentsResult);
    }

    private function queryQueueContentsResult(event:ResultEvent, token:AsyncToken):void {
      Firebug.debug("QUERING QUEUE CONTENTS - Got Result", String(event), String(event.result));
      var conversions:ArrayCollection = event.result as ArrayCollection;
      Firebug.debug("QUERING QUEUE CONTENTS - conversions", String(conversions));
      var queue_event:QueueEvent = new QueueEvent(QueueEvent.LIST, conversions);
      this.dispatchEvent(queue_event);
    }

    private function queryQueueContentsFault(event:FaultEvent, token:AsyncToken):void {
      Firebug.debug("QUERING QUEUE CONTENTS - Got Fault");
      Firebug.debug("queryQueueContentsFault", String(event));
    }

    private function remoteServiceFault(event:FaultEvent):void {
      Firebug.debug("remoteServiceFault", String(event));
    }
  }
}
