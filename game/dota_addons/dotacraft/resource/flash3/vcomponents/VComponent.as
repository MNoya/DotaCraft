package vcomponents
{
    import flash.display.*;
    import flash.utils.*;

    public class VComponent extends Sprite
    {
        public var inst:Object;

        public function VComponent(param1:String)
        {
            var newObjectClass:Class;
            var type:* = param1;
            try
            {
                newObjectClass = getDefinitionByName(type) as Class;
            }
            catch (error:ReferenceError)
            {
                return;
            }
            this.inst = new newObjectClass;
            addChild(this.inst as MovieClip);
            return;
        }// end function

        override public function addEventListener(param1:String, param2:Function, param3:Boolean = false, param4:int = 0, param5:Boolean = false) : void
        {
            if (this.inst == null)
            {
                super.addEventListener(param1, param2, param3, param4, param5);
            }
            else
            {
                this.inst.addEventListener(param1, param2, param3, param4, param5);
            }
            return;
        }// end function

        override public function get width() : Number
        {
            return super.width;
        }// end function

        override public function set width(param1:Number) : void
        {
            if (this.inst == null)
            {
                super.width = param1;
            }
            else
            {
                this.inst.width = param1;
            }
            return;
        }// end function

        override public function get height() : Number
        {
            return super.height;
        }// end function

        override public function set height(param1:Number) : void
        {
            if (this.inst == null)
            {
                super.height = param1;
            }
            else
            {
                this.inst.height = param1;
            }
            return;
        }// end function

    }
}
