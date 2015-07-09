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

    var xOffset = Game.ScreenXYToWorld(0, 0)[0] % 64;
    var yOffset = Game.ScreenXYToWorld(0, 0)[1] % 64;

    var worldPosTL = [];
    var worldPosBR = [];
    var GamePosBR = [];
    var GamePosTL = Game.ScreenXYToWorld(mPos[0] - (25 * size), mPos[1] - (25 * size)); // top left point
    
    if (GamePosTL[2] > 10000000) // ScreenXYToWorld returns near inf if the mouse is off screen( happens when you pan sometimes?)
    {
      GamePosTL[2] = 0;
    }

    GamePosTL[0] = 64 * Math.floor(( GamePosTL[0]) / 64);
    GamePosTL[1] = 64 * Math.floor(( GamePosTL[1]) / 64);

    // bot right point should be a multiple of 64 away from the top left
    // 95% this is the place where the problems lie. Not sure why it has to be subtracted
    GamePosBR[0] = GamePosTL[0] + (64 * size);
    GamePosBR[1] = GamePosTL[1] - (64 * size);
    GamePosBR[2] = GamePosTL[2];


    worldPosTL[0] = Game.WorldToScreenX(GamePosTL[0], GamePosTL[1], GamePosTL[2]) + xOffset;
    worldPosTL[1] = Game.WorldToScreenY(GamePosTL[0], GamePosTL[1], GamePosTL[2]) + yOffset;

    worldPosBR[0] = Game.WorldToScreenX(GamePosBR[0], GamePosBR[1], GamePosBR[2]) + xOffset;
    worldPosBR[1] = Game.WorldToScreenY(GamePosBR[0], GamePosBR[1], GamePosBR[2]) + yOffset;

    var width = worldPosBR[0] - worldPosTL[0]; // why does it change when you move LtoR?????
    var height = worldPosBR[1] - worldPosTL[1];

    //$.Msg(GamePosTL, GamePosBR, worldPosTL, worldPosBR, width, " ", height);

    $( "#GreenSquare").style['height'] = String(height) + "px;";
    $( "#GreenSquare").style['width'] = String(width) + "px;";
    $( "#GreenSquare").style['margin'] = String(worldPosTL[1]) + "px 0px 0px " + String(worldPosTL[0]) + "px;";
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