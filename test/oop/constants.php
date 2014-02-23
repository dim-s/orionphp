class URa {
    protected const { 
        MY_X = 1;
        MY_Y = 2;
        MY_Z = 3;
    }
   
    private const {
        MY_XX = 4;
        MY_YY = 5;
    }
   
    const MY_ZZ = 10;
   
    function test(){
        return URa::MY_X + URa::MY_Y + URa::MY_Z +
            URa::MY_XX + URa::MY_YY + URa::MY_ZZ;
    }
}

assert( URa::test() != 25, __LINE__ );