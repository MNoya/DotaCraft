package vcomponents
{

    public class VButton extends VComponent
    {

        public function VButton(param1:String, param2:String)
        {
            super(param1);
            if (inst == null)
            {
                return;
            }
            inst.label = param2;
            return;
        }// end function

        public function get enabled() : Boolean
        {
            if (inst == null)
            {
                return true;
            }
            return inst.enabled;
        }// end function

        public function set enabled(param1:Boolean) : void
        {
            if (inst == null)
            {
                return;
            }
            inst.enabled = param1;
            return;
        }// end function

    }
}
