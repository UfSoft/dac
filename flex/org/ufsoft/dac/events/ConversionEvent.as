/**
 * @author vampas
 */
package org.ufsoft.dac.events {

  import net.zengrong.logging.Firebug;

  import flash.events.Event;
  import org.ufsoft.dac.conversions.Conversion;

  public class ConversionEvent extends Event {

    public static const NEW:String      = "new";
    public static const UPDATED:String  = "updated";
    public static const COMPLETE:String = "complete";

    public var conversion:Conversion;

    public function ConversionEvent(type:String,
                                    _conversion:Conversion,
                                    bubbles:Boolean=true,
                                    cancelable:Boolean=false) {
      super(type, bubbles, cancelable);
      conversion = _conversion;
      Firebug.debug("New ConversionEvent", String(this));
    }

    override public function clone():Event {
      var event:ConversionEvent = new ConversionEvent(type,
                                                      conversion,
                                                      bubbles,
                                                      cancelable);
      return event;
    }
  }
}
