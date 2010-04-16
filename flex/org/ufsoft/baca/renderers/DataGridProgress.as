/**
 * @author vampas
 */

package org.ufsoft.baca.renderers {
  import mx.containers.HBox;
  import mx.controls.ProgressBar;
  import mx.controls.dataGridClasses.*;

  public class DataGridProgress extends HBox {

    private var pb:ProgressBar;

    public function DataGridProgress():void {
      pb = new ProgressBar();
      pb.percentWidth = 100;
      pb.mode = "manual";
      pb.minimum = 0;
      pb.maximum = 100;
      pb.label="%3%%";
      pb.labelPlacement="center";
      //pb.labelWidth=0;
      //pb.horizontalGap=0;
      this.setStyle("verticalAlign","middle");
      addChild(pb);
    }

    override public function set data(value:Object):void {
      super.data = value;
    }

    override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number) : void{
      super.updateDisplayList(unscaledWidth, unscaledHeight);
      pb.setProgress(data.progress, 100);
    }
  }
}
