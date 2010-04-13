/**
 * @author vampas
 */
package org.ufsoft.dac.components {

  import net.zengrong.logging.Firebug;

  import mx.core.Application;
  import mx.controls.Button;
  import mx.messaging.ChannelSet;
  import org.ufsoft.dac.events.ConnectionEvent;

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
      Firebug.debug("ConnectionButton.as catched event");
      if ( event.type == ConnectionEvent.CONNECTED ) {
        setStyle("icon", connectionUp);
        this.toolTip = "Connected";
      } else if ( event.type == ConnectionEvent.DISCONNECTED ) {
        setStyle("icon", connectionDown);
        this.toolTip = "Disconnected";
      } else {
        setStyle("icon", connectionConnecting);
        this.toolTip = "Connecting";
      }
    }
  }
}
