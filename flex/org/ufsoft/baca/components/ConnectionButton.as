/**
 * @author vampas
 */
package org.ufsoft.baca.components {

  import org.osflash.thunderbolt.Logger;

  import mx.core.Application;
  import mx.controls.Button;
  import mx.messaging.ChannelSet;
  import mx.resources.ResourceManager;
  import org.ufsoft.baca.events.ConnectionEvent;
  import org.ufsoft.baca.i18n.Locale;

  public class ConnectionButton extends Button {
    [Bindable]
    [Embed('/assets/connect_no.png')] private var connectionDown:Class;
    [Embed('/assets/connect_creating.png')] private var connectionConnecting:Class;
    [Embed('/assets/connect_established.png')] private var connectionUp:Class;

    private var channel:ChannelSet;

    public function ConnectionButton() {
      super()
      setStyle("icon", connectionConnecting);
      Application.application.addEventListener(ConnectionEvent.CONNECTED, handleConnectionEvent);
      Application.application.addEventListener(ConnectionEvent.DISCONNECTED, handleConnectionEvent);
      Application.application.addEventListener(ConnectionEvent.CONNECTING, handleConnectionEvent);
      Application.application.addEventListener(ConnectionEvent.RECONNECTING, handleConnectionEvent);
    }

    private function handleConnectionEvent(event:ConnectionEvent):void {
      Logger.debug("ConnectionButton.as catched event");
      if ( event.type == ConnectionEvent.CONNECTED ) {
        setStyle("icon", connectionUp);
        this.toolTip = ResourceManager.getInstance().getString('baca', "Connected");
      } else if ( event.type == ConnectionEvent.DISCONNECTED ) {
        setStyle("icon", connectionDown);
        this.toolTip = ResourceManager.getInstance().getString('baca', "Disconnected");
      } else {
        setStyle("icon", connectionConnecting);
        this.toolTip = ResourceManager.getInstance().getString('baca', "Connecting");
      }
    }
  }
}
