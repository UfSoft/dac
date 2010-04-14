/**
 * @author vampas
 */
package org.ufsoft.dac {
  import mx.core.Application;

  import mx.controls.Alert;
  import org.osflash.thunderbolt.Logger;

  import flash.utils.setTimeout;
  import mx.collections.ArrayCollection;
  import mx.collections.ItemResponder;
  import mx.events.FlexEvent;
  import mx.messaging.Consumer;
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
      // Disable Logging
      //Logger.hide = true;
    }

    private function applicationCreated(event:Event):void {
      Logger.info("Application Created");
    }

    public function getChannel():ChannelSet {
      if ( appChannelSet != null ) {
        // channel set is defined already, return it
        return appChannelSet;
      }
      Logger.info("Creating channel");
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
      Logger.error(String(event));
    }

    private function channelConnected(event:ChannelEvent):void {
      if ( event.reconnecting ) {
        Logger.warn("channelConnected - Reconnecting", String(event));
        this.dispatchEvent(new ConnectionEvent(ConnectionEvent.RECONNECTING));
        setTimeout(queryConnection, 10);
      } else if ( event.rejected ) {
        Logger.error("channelConnected - Rejected", String(event));
        this.dispatchEvent(new ConnectionEvent(ConnectionEvent.DISCONNECTED));
        setTimeout(queryConnection, 10);
      } else {
        Logger.info("channelConnected - Connected", String(event));
        this.dispatchEvent(new ConnectionEvent(ConnectionEvent.CONNECTED));
      }
    }

    private function channelDisconnected(event:ChannelEvent):void {
      if ( event.reconnecting ) {
        Logger.warn("channelDisconnected - Reconnecting", String(event));
        this.dispatchEvent(new ConnectionEvent(ConnectionEvent.RECONNECTING));
      } else if ( event.rejected ) {
        Logger.error("channelDisconnected - Rejected", String(event));
        this.dispatchEvent(new ConnectionEvent(ConnectionEvent.DISCONNECTED));
      } else {
        Logger.info("channelDisconnected - Disconnected", String(event));
        this.dispatchEvent(new ConnectionEvent(ConnectionEvent.DISCONNECTED));
      }
      setTimeout(queryConnection, 10);
    }

    private function queryConnection():void {
      if ( appChannelSet.connected ) {
        this.dispatchEvent(new ConnectionEvent(ConnectionEvent.CONNECTED));
      } else {
        setTimeout(queryConnection, 10);
      }
    }

    public function getConsumer(destination:String, subtopic:String=null):Consumer {
      Logger.info("Creating consumer: Destination", destination, "Sub-Topic:", subtopic);
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

    public function queryQueueContents():void {
      if ( remoteService == null) {
        remoteService = new RemoteObject("WebServices");
        remoteService.channelSet = getChannel();
        remoteService.showBusyCursor = true;
        remoteService.addEventListener(FaultEvent.FAULT, remoteServiceFault);
      }
      Logger.info("QUERING QUEUE CONTENTS");
      var token:AsyncToken = remoteService.get_process_queue();
      Logger.info("QUERING QUEUE CONTENTS - Got Token");
      token.addResponder(new ItemResponder(queryQueueContentsResult,
                                           queryQueueContentsFault,
                                           token));
      Logger.info("QUERING QUEUE CONTENTS - Added Responder");
      //remoteService.get_process_queue.addEventListener("result", queryQueueContentsResult);
    }

    private function queryQueueContentsResult(event:ResultEvent, token:AsyncToken):void {
      Logger.info("QUERING QUEUE CONTENTS - Got Result", String(event), String(event.result));
      var conversions:ArrayCollection = event.result as ArrayCollection;
      Logger.info("QUERING QUEUE CONTENTS - conversions", String(conversions));
      var queue_event:QueueEvent = new QueueEvent(QueueEvent.LIST, conversions);
      this.dispatchEvent(queue_event);
    }

    private function queryQueueContentsFault(event:FaultEvent, token:AsyncToken):void {
      Logger.info("QUERING QUEUE CONTENTS - Got Fault");
      Logger.info("queryQueueContentsFault", String(event));
    }

    private function remoteServiceFault(event:FaultEvent):void {
      Logger.error("remoteServiceFault", event);
    }
  }
}
