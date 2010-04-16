/**
 * @author vampas
 */
package org.ufsoft.baca.events {

  import flash.events.Event;

  public class ApplicationEvent extends Event {

    public static const RUNNING:String = "running";

    public function ApplicationEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false) {
      super(type, bubbles, cancelable);
    }

    override public function clone():Event {
      var event:ApplicationEvent = new ApplicationEvent(type, bubbles, cancelable);
      return event;
    }
  }
}
