/**
 * @author vampas
 */
package org.ufsoft.dac.events {

  import org.osflash.thunderbolt.Logger;

  import flash.events.Event;
  import mx.collections.ArrayCollection;

  public class QueueEvent extends Event {

    public static const LIST:String      = "list";
    public var conversions:ArrayCollection;

    public function QueueEvent(type:String,
                                    _conversions:ArrayCollection,
                                    bubbles:Boolean=true,
                                    cancelable:Boolean=false) {
      super(type, bubbles, cancelable);
      conversions = _conversions;
      Logger.debug("New QueueEvent", String(this));
    }

    override public function clone():Event {
      var event:QueueEvent = new QueueEvent(type,
                                            conversions,
                                            bubbles,
                                            cancelable);
      return event;
    }
  }
}
