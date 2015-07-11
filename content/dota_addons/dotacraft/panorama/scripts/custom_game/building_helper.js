'use strict';

var state = 'disabled';
var size = 0;

function StartBuildingHelper( params )
{
  if (params !== undefined)
  {
    state = params["state"];
    size = params["size"];
  }
  if (state === 'active')
  {
    $.Schedule(0.03, StartBuildingHelper);
    var mPos = GameUI.GetCursorPosition();

    $( "#GreenSquare").style['height'] = String(50 * size) + "px;";
    $( "#GreenSquare").style['width'] = String(50 * size) + "px;";
    $( "#GreenSquare").style['margin'] = String(mPos[1] - (25 * size)) + "px 0px 0px " + String(mPos[0] - (25 * size)) + "px;";
    $( "#GreenSquare").style['transform'] = "rotateX( 30deg );";
  }
}

function SendBuildCommand( params )
{
  var mPos = GameUI.GetCursorPosition();
  var GamePos = Game.ScreenXYToWorld(mPos[0], mPos[1]);
  GameEvents.SendCustomGameEventToServer( "building_helper_build_command", { "X" : GamePos[0], "Y" : GamePos[1], "Z" : GamePos[2] } );
  if (!GameUI.IsShiftDown()) // Remove the green square unless the player is holding shift
  {
    state = 'disabled'
    $( "#GreenSquare").style['margin'] = "-1000px 0px 0px 0px;";
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