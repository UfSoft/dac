/**
 * @author vampas
 */
package org.ufsoft.baca {
  import mx.core.Application;

  import mx.controls.Alert;
  import org.osflash.thunderbolt.Logger;

  import flash.net.SharedObject;
  import flash.utils.setTimeout;
  import mx.collections.ArrayCollection;
  import mx.collections.ItemResponder;
  import mx.controls.ComboBox;
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

  import org.ufsoft.baca.conversions.Conversion;
  import org.ufsoft.baca.events.*;
  import org.ufsoft.baca.i18n.*;

  public class DacApplication extends Application {

    private static const CONNECT_TIMEOUT        :Number = 5;
    private static const MAX_CONNECTION_FAILURES:Number = 10;

    private var serverAMFUrl:                 String;
    private var serverStreamingUrl:           String;
    private var serverPollingUrl:             String;
    private var serverLongPollingUrl:         String;
    private var streamingChannel:             StreamingAMFChannel;
    private var pollingChannel:               AMFChannel;
    private var longPollingChannel:           AMFChannel;
    private var servicesChannel:              AMFChannel;
    private var appChannelSet:                ChannelSet;
    private var conversionsConsumer   :       Consumer;
    private var newConversionsConsumer:       Consumer;
    private var updatedConversionsConsumer:   Consumer;
    private var completedConversionsConsumer: Consumer;
    private var remoteService:                RemoteObject;
    private var connectionFailures:           Number = 0;

    private var cookie:                       SharedObject;
    private var locale:                       Locale;
    private var STREAMING_AVAILABLE:          Boolean;
    private var CONNECTED_ONCE:               Boolean=false;

    public var languagesComboBox:             ComboBox;

    [Bindable]
    [Embed('/assets/rtp.png')] public var rtpLogo:Class;

    public function DacApplication() {
      super();

      /* serverAMFUrl = 'http://{server.name}:{server.port}/rpc';
      serverStreamingUrl = 'http://{server.name}:{server.port}/amf-streaming';
      serverPollingUrl = 'http://{server.name}:{server.port}/amf-polling';
      serverLongPollingUrl = 'http://{server.name}:{server.port}/amf-long-polling'; */

      serverAMFUrl = '/rpc';
      serverStreamingUrl = '/amf-streaming';
      serverPollingUrl = '/amf-polling';
      serverLongPollingUrl = '/amf-long-polling';

      addEventListener(FlexEvent.CREATION_COMPLETE, applicationCreated);
      addEventListener(FlexEvent.INITIALIZE, setupInitialLocale);
      // Disable Logging
      //Logger.hide = true;

      // Cookies!!!
      cookie = SharedObject.getLocal("BroadcastAudioConverterAnywhere");
      STREAMING_AVAILABLE = cookie.data.streaming_available || true;
      locale = Locale.getInstance();
      locale.load(cookie.data.locale || 'pt_PT');
    }

    private function translationLoaded(event:TranslationEvent):void {
      Logger.info("Translation Loaded. Storing locale in cookie");
      cookie.data.locale = Locale.getInstance().getLocale();
      cookie.flush();
    }

    private function setupInitialLocale(event:FlexEvent):void {
    }

    private function applicationCreated(event:Event):void {
      Logger.info("Application Created", cookie.data);
      Logger.info("Dispatching ApplicationEvent.RUNNING");

      this.dispatchEvent(new ApplicationEvent(ApplicationEvent.RUNNING));
    }

    public function getChannel():ChannelSet {
      if ( appChannelSet != null ) {
        // channel set is defined already, return it
        return appChannelSet;
      }
      Logger.info("Creating channel");
      // Create a channel set and add channel(s) to it
      appChannelSet = new ChannelSet();

      if ( STREAMING_AVAILABLE ) {
        Logger.info("Streaming available. Adding streaming channel");
        streamingChannel = new StreamingAMFChannel("amf-streaming",
                                                  serverStreamingUrl);
        streamingChannel.connectTimeout = CONNECT_TIMEOUT;
        appChannelSet.addChannel(streamingChannel);
      }

      pollingChannel = new AMFChannel("amf-polling", serverPollingUrl);
      pollingChannel.pollingInterval = 2; // in seconds
      pollingChannel.connectTimeout = CONNECT_TIMEOUT;
      appChannelSet.addChannel(pollingChannel);

      longPollingChannel = new AMFChannel("amf-long-polling", serverPollingUrl);
      longPollingChannel.pollingInterval = 5; // in seconds
      longPollingChannel.connectTimeout = CONNECT_TIMEOUT;
      appChannelSet.addChannel(longPollingChannel);

      servicesChannel = new AMFChannel("rpc", serverAMFUrl)
      appChannelSet.addChannel(servicesChannel);

      appChannelSet.addEventListener(ChannelEvent.CONNECT, channelConnected);
      appChannelSet.addEventListener(ChannelEvent.DISCONNECT, channelDisconnected);
      appChannelSet.addEventListener(ChannelFaultEvent.FAULT, channelFault);

      return appChannelSet;
    }

    private function channelFault(event:ChannelFaultEvent):void {
      if ( event.channelId == "amf-streaming" && !CONNECTED_ONCE ) {
        Logger.info("Permanently disabling streaming support")
        STREAMING_AVAILABLE = false;
        cookie.data.streaming_available = STREAMING_AVAILABLE;
        cookie.flush();
      }
      Logger.error("channelFault", String(event));
      connectionFailures += 1;
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
        connectionFailures = 0;
        Logger.info("Load locale2");
        locale.load(cookie.data.locale || 'pt_PT');
        if ( ! CONNECTED_ONCE ) {
          CONNECTED_ONCE = true;
        }
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
      } else if ( connectionFailures <= MAX_CONNECTION_FAILURES ) {
          setTimeout(queryConnection, 10);
      } else {
        Logger.warn("Desconnecting all channels");
        appChannelSet.disconnectAll();
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

    public function getRemoteService():RemoteObject {
      if ( remoteService == null) {
        remoteService = new RemoteObject("WebServices");
        remoteService.channelSet = getChannel();
        remoteService.showBusyCursor = true;
        remoteService.addEventListener(FaultEvent.FAULT, remoteServiceFault);
      }
      return remoteService;
    }

    public function queryQueueContents():void {
      var token:AsyncToken = getRemoteService().get_process_queue();
      token.addResponder(new ItemResponder(queryQueueContentsResult,
                                           queryQueueContentsFault,
                                           token));
    }

    private function queryQueueContentsResult(event:ResultEvent, token:AsyncToken):void {
      var conversions:ArrayCollection = event.result as ArrayCollection;
      var queue_event:QueueEvent = new QueueEvent(QueueEvent.LIST, conversions);
      this.dispatchEvent(queue_event);
    }

    private function queryQueueContentsFault(event:FaultEvent, token:AsyncToken):void {
      Logger.info("queryQueueContentsFault", String(event));
    }

    private function remoteServiceFault(event:FaultEvent):void {
      Logger.error("remoteServiceFault", event);
    }
  }
}
