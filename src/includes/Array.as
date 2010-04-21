(function():void{
  include 'addMethodsTo.as';
  Array.prototype.index = -1;
  addMethodsTo(Array, {
    hasNext:function():Boolean{
      return this.index < this.length - 1;
    },
    next:function():*{
      if(this.hasNext)
	return this[++this.index];
      return null;
    },
    reset:function():void{
      this.index = 0;
    },
    current:function():*{
      if(this.index > -1 && this.length > 0)
        return this[this.index]
      return null;
    }
  });
})();
