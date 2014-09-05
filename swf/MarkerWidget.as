import skyui.widgets.WidgetBase;
import flash.display.BitmapData;

class MarkerWidget extends WidgetBase
{
	private var _targetDataArray: Array;
	private var _intervalId: Number = 0;
	private var _updateInterval: Number = 1000 / 60;
	
	public var marker:MovieClip;
	public var targetName:TextField;
	
	public function MarkerWidget()
	{
		super();
		
		_visible = false;
		targetName.text = "";
		
		_targetDataArray = new Array();
		
		setVAnchor("top");
		setHAnchor("left");
	}
	
	public function enterLockOn(): Void
	{
		onIntervalUpdate();
		_visible = true;
		_intervalId = setInterval(this, "onIntervalUpdate", _updateInterval);
	}
	
	public function leaveLockOn(): Void
	{
		_visible = false;
		clearInterval(_intervalId);
		_intervalId = 0;
	}
	
	public function InvokeTest(): Void
	{
		_targetDataArray.splice(0);
	}
	
	private function onIntervalUpdate(): Void
	{
		skse.plugins.numPlugins;
		_targetDataArray.splice(0);
		skse.plugins.lockon.RequestTargetInfo(_targetDataArray);
		if (_targetDataArray.formID)
		{
			var scale:Number = 120 - _targetDataArray.dist / 16;
			
			if (scale > 100)
				scale = 100;
			else if (scale < 50)
				scale = 50;
			
			this._xscale = scale;
			this._yscale = scale;
			// marker._xscale = scale;
			// marker._yscale = scale;
			targetName.text = _targetDataArray.targetName;
			
			marker._rotation += 2;
			setPositionX(640 + _targetDataArray.posX);
			setPositionY(360 + _targetDataArray.posY);
		}
		updateAfterEvent();
	}
}


