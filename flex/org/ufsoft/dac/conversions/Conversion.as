package org.ufsoft.dac.conversions
{
  [Bindable]
  [RemoteClass(alias='org.ufsoft.dac.conversions.Conversion')]
  public dynamic class Conversion extends Object
  {
    public var id:            uint;
    public var filename:      String;
    public var out_filename:  String;
    public var progress:      uint;
    public var converted:     Boolean;
    public var url:           String;
  }
}
