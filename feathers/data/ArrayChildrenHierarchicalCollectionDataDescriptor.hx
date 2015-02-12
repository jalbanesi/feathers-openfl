/*
Feathers
Copyright 2012-2014 Joshua Tynjala. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.data;
/**
 * A hierarchical data descriptor where children are defined as arrays in a
 * property defined on each branch. The property name defaults to <code>"children"</code>,
 * but it may be customized.
 *
 * <p>The basic structure of the data source takes the following form. The
 * root must always be an Array.</p>
 * <pre>
 * [
 *     {
 *         text: "Branch 1",
 *         children:
 *         [
 *             { text: "Child 1-1" },
 *             { text: "Child 1-2" }
 *         ]
 *     },
 *     {
 *         text: "Branch 2",
 *         children:
 *         [
 *             { text: "Child 2-1" },
 *             { text: "Child 2-2" },
 *             { text: "Child 2-3" }
 *         ]
 *     }
 * ]</pre>
 */
class ArrayChildrenHierarchicalCollectionDataDescriptor implements IHierarchicalCollectionDataDescriptor
{
	/**
	 * Constructor.
	 */
	public function ArrayChildrenHierarchicalCollectionDataDescriptor()
	{
	}

	/**
	 * The field used to access the Array of a branch's children.
	 */
	public var childrenField:String = "children";

	/**
	 * @inheritDoc
	 */
	public function getLength(data:Dynamic, ...rest:Array):Int
	{
		var branch:Array = data as Array;
		var indexCount:Int = rest.length;
		for(i in 0 ... indexCount)
		{
			var index:Int = rest[i] as Int;
			branch = branch[index][childrenField] as Array;
		}

		return branch.length;
	}

	/**
	 * @inheritDoc
	 */
	public function getItemAt(data:Dynamic, index:Int, ...rest:Array):Object
	{
		rest.unshift(index);
		var branch:Array = data as Array;
		var indexCount:Int = rest.length - 1;
		for(i in 0 ... indexCount)
		{
			index = rest[i] as Int;
			branch = branch[index][childrenField] as Array;
		}
		var lastIndex:Int = rest[indexCount] as Int;
		return branch[lastIndex];
	}

	/**
	 * @inheritDoc
	 */
	public function setItemAt(data:Dynamic, item:Dynamic, index:Int, ...rest:Array):Void
	{
		rest.unshift(index);
		var branch:Array = data as Array;
		var indexCount:Int = rest.length - 1;
		for(i in 0 ... indexCount)
		{
			index = rest[i] as Int;
			branch = branch[index][childrenField] as Array;
		}
		var lastIndex:Int = rest[indexCount];
		branch[lastIndex] = item;
	}

	/**
	 * @inheritDoc
	 */
	public function addItemAt(data:Dynamic, item:Dynamic, index:Int, ...rest:Array):Void
	{
		rest.unshift(index);
		var branch:Array = data as Array;
		var indexCount:Int = rest.length - 1;
		for(i in 0 ... indexCount)
		{
			index = rest[i] as Int;
			branch = branch[index][childrenField] as Array;
		}
		var lastIndex:Int = rest[indexCount];
		branch.splice(lastIndex, 0, item);
	}

	/**
	 * @inheritDoc
	 */
	public function removeItemAt(data:Dynamic, index:Int, ...rest:Array):Object
	{
		rest.unshift(index);
		var branch:Array = data as Array;
		var indexCount:Int = rest.length - 1;
		for(i in 0 ... indexCount)
		{
			index = rest[i] as Int;
			branch = branch[index][childrenField] as Array;
		}
		var lastIndex:Int = rest[indexCount];
		var item:Dynamic = branch[lastIndex];
		branch.splice(lastIndex, 1);
		return item;
	}

	/**
	 * @inheritDoc
	 */
	public function getItemLocation(data:Dynamic, item:Dynamic, result:Array<Int> = null, ...rest:Array):Array<Int>
	{
		if(!result)
		{
			result = new Array();
		}
		else
		{
			result.length = 0;
		}
		var branch:Array = data as Array;
		var restCount:Int = rest.length;
		for(i in 0 ... restCount)
		{
			var index:Int = rest[i] as Int;
			result[i] = index;
			branch = branch[index][childrenField] as Array;
		}

		var isFound:Bool = this.findItemInBranch(branch, item, result);
		if(!isFound)
		{
			result.length = 0;
		}
		return result;
	}

	/**
	 * @inheritDoc
	 */
	public function isBranch(node:Dynamic):Bool
	{
		return node.hasOwnProperty(this.childrenField) && node[this.childrenField] is Array;
	}

	/**
	 * @private
	 */
	private function findItemInBranch(branch:Array, item:Dynamic, result:Array<Int>):Bool
	{
		var index:Int = branch.indexOf(item);
		if(index >= 0)
		{
			result.push(index);
			return true;
		}

		var branchLength:Int = branch.length;
		for(i in 0 ... branchLength)
		{
			var branchItem:Dynamic = branch[i];
			if(this.isBranch(branchItem))
			{
				result.push(i);
				var isFound:Bool = this.findItemInBranch(branchItem[childrenField] as Array, item, result);
				if(isFound)
				{
					return true;
				}
				result.pop();
			}
		}
		return false;
	}
}
