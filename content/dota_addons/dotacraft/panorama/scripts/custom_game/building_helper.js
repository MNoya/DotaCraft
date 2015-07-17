'use strict';

var state = 'disabled';
var size = 0;
var pressedShift = false;

function StartBuildingHelper( params )
{
  if (params !== undefined)
  {
    state = params["state"];
    size = params["size"];
    pressedShift = GameUI.IsShiftDown();
  }
  if (state === 'active')
  {
    $.Schedule(0.001, StartBuildingHelper);
    var mPos = GameUI.GetCursorPosition();

    mPos[0] = (mPos[0] * 1.0 / $( "#BuildingHelperBase").desiredlayoutwidth ) * 1920;
    mPos[1] = (mPos[1] * 1.0 / $( "#BuildingHelperBase").desiredlayoutheight) * 1080;

    var grid1x1 = 38
    $( "#GreenSquare").style['height'] = String(grid1x1 * size) + "px;";
    $( "#GreenSquare").style['width'] = String(grid1x1 * size) + "px;";
    $( "#GreenSquare").style['margin'] = String(mPos[1] - (grid1x1/2 * size)) + "px 0px 0px " + String(mPos[0] - (grid1x1/2 * size)) + "px;";
    $( "#GreenSquare").style['transform'] = "rotateX( 30deg );";

    if ((!GameUI.IsShiftDown() && pressedShift))
    {
      EndBuildingHelper();
    }
  }
}

function EndBuildingHelper()
{
  state = 'disabled'
  $( "#GreenSquare").style['margin'] = "-1000px 0px 0px 0px;";
}

function SendBuildCommand( params )
{
  var mPos = GameUI.GetCursorPosition();
  var GamePos = Game.ScreenXYToWorld(mPos[0], mPos[1]);
  GameEvents.SendCustomGameEventToServer( "building_helper_build_command", { "X" : GamePos[0], "Y" : GamePos[1], "Z" : GamePos[2] } );
  pressedShift = GameUI.IsShiftDown();
  if (!GameUI.IsShiftDown()) // Remove the green square unless the player is holding shift
  {
    EndBuildingHelper();
  }
}

function SendCancelCommand( params )
{
  state = 'disabled'
  $( "#GreenSquare").style['margin'] = "-1000px 0px 0px 0px;"; 
  GameEvents.SendCustomGameEventToServer( "building_helper_cancel_command", {} );
}

(function () {
  GameEvents.Subscribe( "building_helper_enable", StartBuildingHelper);
})();